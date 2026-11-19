import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'sesion_service.dart';

class ComisionException implements Exception {
  const ComisionException(this.mensaje);
  final String mensaje;
}

class ComisionService {
  ComisionService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static const _url = '${AppConfig.apiBaseUrl}/Comisiones';

  Future<List<Map<String, dynamic>>> listar({
    int? profesionalId,
    int? liquidacionComisionId,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    if (profesionalId != null && profesionalId <= 0 ||
        liquidacionComisionId != null && liquidacionComisionId <= 0) {
      throw const ComisionException('Selecciona un identificador válido.');
    }
    final inicio = fechaInicio?.toIso8601String().split('T').first;
    final fin = fechaFin?.toIso8601String().split('T').first;
    if (inicio != null && fin != null && fin.compareTo(inicio) < 0) {
      throw const ComisionException(
        'La fecha final debe ser igual o posterior a la inicial.',
      );
    }
    final filtros = <String, String>{
      if (profesionalId != null) 'profesionalId': '$profesionalId',
      if (liquidacionComisionId != null)
        'liquidacionComisionId': '$liquidacionComisionId',
    };
    if (inicio != null) filtros['fechaInicio'] = inicio;
    if (fin != null) filtros['fechaFin'] = fin;
    final uri = Uri.parse(_url).replace(queryParameters: filtros);
    final datos = await _consultar(uri);
    if (datos is! List) {
      throw const ComisionException('El listado de comisiones no es válido.');
    }
    final comisiones = datos.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const ComisionException('La comisión recibida no es válida.');
      }
      return item;
    }).toList();
    // Si la respuesta incluye las relaciones, se comprueba que no contradigan el filtro.
    for (final comision in comisiones) {
      if (profesionalId != null &&
          comision.containsKey('profesionalId') &&
          comision['profesionalId'] != profesionalId) {
        throw const ComisionException(
          'El servidor devolvió comisiones de otro profesional.',
        );
      }
      if (liquidacionComisionId != null &&
          comision.containsKey('liquidacionComisionId') &&
          comision['liquidacionComisionId'] != liquidacionComisionId) {
        throw const ComisionException(
          'El servidor devolvió comisiones de otra liquidación.',
        );
      }
    }
    return comisiones;
  }

  // El contrato publica el ID de comisión, no el de cierre ni el de profesional.
  // La estructura de data se conservará hasta verificar una respuesta con servicios.
  Future<Object?> servicios(int comisionId) {
    if (comisionId <= 0) {
      throw const ComisionException(
        'El identificador de comisión no es válido.',
      );
    }
    return _consultar(Uri.parse('$_url/$comisionId/servicios'));
  }

  Future<Object?> _consultar(Uri uri) async {
    if (!SesionService.activa) {
      throw const ComisionException('Tu sesión venció. Ingresa de nuevo.');
    }
    final http.Response respuesta;
    try {
      respuesta = await _client
          .get(uri, headers: SesionService.encabezados())
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const ComisionException(
        'La conexión tardó demasiado. Intenta de nuevo.',
      );
    } on http.ClientException {
      throw const ComisionException(
        'No se pudo conectar con la API. Revisa tu conexión.',
      );
    }
    SesionService.revisarRespuesta(respuesta.statusCode);
    if (respuesta.statusCode == 401) {
      throw const ComisionException('Tu sesión venció. Ingresa de nuevo.');
    }
    if (respuesta.statusCode == 403) {
      throw const ComisionException(
        'No tienes permiso para consultar estas comisiones.',
      );
    }
    if (respuesta.statusCode >= 500) {
      throw const ComisionException(
        'El servidor no está disponible. Intenta más tarde.',
      );
    }
    Map<String, dynamic> contenido;
    try {
      final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
      if (datos is! Map<String, dynamic>) throw const FormatException();
      contenido = datos;
    } on FormatException {
      throw const ComisionException('La API devolvió una respuesta no válida.');
    }
    if (respuesta.statusCode < 200 ||
        respuesta.statusCode >= 300 ||
        contenido['success'] != true) {
      final mensaje = contenido['message'];
      throw ComisionException(
        mensaje is String && mensaje.isNotEmpty
            ? mensaje
            : 'No fue posible consultar las comisiones.',
      );
    }
    if (!contenido.containsKey('data')) {
      throw const ComisionException(
        'La respuesta de comisiones está incompleta.',
      );
    }
    return contenido['data'];
  }

  void cerrar() => _client.close();
}
