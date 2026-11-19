import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'sesion_service.dart';

class DisponibilidadException implements Exception {
  const DisponibilidadException(this.mensaje);
  final String mensaje;
}

class DisponibilidadService {
  DisponibilidadService({http.Client? client})
    : _client = client ?? http.Client();
  final http.Client _client;
  static const _url = '${AppConfig.apiBaseUrl}/agenda';
  Future<List<DateTime>> consultar({
    required DateTime fecha,
    required int servicioId,
    int? profesionalId,
  }) async {
    final uri = Uri.parse(_url).replace(
      queryParameters: {
        'fecha': fecha.toIso8601String().split('T').first,
        'servicioId': '$servicioId',
        if (profesionalId != null) 'profesionalId': '$profesionalId',
      },
    );
    final respuesta = await _esperar(_client.get(uri, headers: _encabezados()));
    final datos = _procesar(respuesta)['data'];
    if (datos is! List) {
      throw const FormatException('Disponibilidad no válida.');
    }
    final horas =
        datos
            .map((item) {
              if (item is! Map<String, dynamic> || item['fecha'] is! String) {
                throw const FormatException('Horario disponible no válido.');
              }
              final hora = DateTime.tryParse(item['fecha'] as String);
              if (hora == null ||
                  hora.year != fecha.year ||
                  hora.month != fecha.month ||
                  hora.day != fecha.day) {
                throw const FormatException('Fecha disponible no válida.');
              }
              return hora;
            })
            .toSet()
            .toList()
          ..sort();
    return horas;
  }

  Map<String, String> _encabezados() {
    if (!SesionService.activa) {
      throw const DisponibilidadException(
        'Tu sesión venció. Ingresa de nuevo.',
      );
    }
    return SesionService.encabezados();
  }

  Future<http.Response> _esperar(Future<http.Response> peticion) async {
    try {
      return await peticion.timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const DisponibilidadException(
        'La conexión tardó demasiado. Intenta de nuevo.',
      );
    } on http.ClientException {
      throw const DisponibilidadException(
        'No se pudo conectar con la API. Revisa tu conexión.',
      );
    }
  }

  Map<String, dynamic> _procesar(http.Response respuesta) {
    SesionService.revisarRespuesta(respuesta.statusCode);
    if (respuesta.statusCode == 401) {
      throw const DisponibilidadException(
        'Tu sesión venció. Ingresa de nuevo.',
      );
    }
    if (respuesta.statusCode == 403) {
      throw const DisponibilidadException(
        'No tienes permiso para realizar esta operación.',
      );
    }
    if (respuesta.statusCode >= 500) {
      throw const DisponibilidadException(
        'El servidor no está disponible. Intenta más tarde.',
      );
    }
    Map<String, dynamic> datos;
    try {
      final contenido = jsonDecode(utf8.decode(respuesta.bodyBytes));
      if (contenido is! Map<String, dynamic>) throw const FormatException();
      datos = contenido;
    } on FormatException {
      throw const DisponibilidadException(
        'La API devolvió una respuesta no válida.',
      );
    }
    if (respuesta.statusCode < 200 ||
        respuesta.statusCode >= 300 ||
        datos['success'] != true) {
      final mensaje = datos['message'];
      throw DisponibilidadException(
        mensaje is String && mensaje.isNotEmpty
            ? mensaje
            : 'No fue posible completar la operación.',
      );
    }
    return datos;
  }

  void cerrar() => _client.close();
}
