import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/cierre.dart';
import '../models/crear_cierre_request.dart';
import 'sesion_service.dart';
import 'comision_service.dart';

class CierreException implements Exception {
  const CierreException(this.mensaje, {this.resultadoIncierto = false});
  final String mensaje;
  final bool resultadoIncierto;
}

class CierreService {
  CierreService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static const _url = '${AppConfig.apiBaseUrl}/liquidaciones-comisiones';

  Future<List<Cierre>> listar({
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    final uri = Uri.parse(_url).replace(
      queryParameters: {
        if (fechaInicio != null)
          'fechaInicio': fechaInicio.toIso8601String().split('T').first,
        if (fechaFin != null)
          'fechaFin': fechaFin.toIso8601String().split('T').first,
      },
    );
    final respuesta = await _esperar(_client.get(uri, headers: _encabezados()));
    final datos = _procesar(respuesta)['data'];
    if (datos is! List) {
      throw const FormatException('No se recibió un listado de cierres.');
    }
    final cierres = datos.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Cierre no válido.');
      }
      return Cierre.fromJson(item);
    }).toList();
    cierres.sort((a, b) => b.inicio.compareTo(a.inicio));
    return cierres;
  }

  Future<Cierre?> ultimo() async {
    final respuesta = await _esperar(
      _client.get(Uri.parse('$_url?ultimo=true'), headers: _encabezados()),
    );
    final datos = _procesar(respuesta)['data'];
    if (datos == null || (datos is List && datos.isEmpty)) return null;
    if (datos is Map<String, dynamic>) return Cierre.fromJson(datos);
    if (datos is List &&
        datos.length == 1 &&
        datos.first is Map<String, dynamic>) {
      return Cierre.fromJson(datos.first as Map<String, dynamic>);
    }
    throw const FormatException('No se pudo identificar el último cierre.');
  }

  // La API no publica GET por ID: el detalle se recupera del listado real.
  Future<Cierre> obtener(int id) async {
    final cierres = await listar();
    for (final cierre in cierres) {
      if (cierre.id == id) return cierre;
    }
    throw const CierreException(
      'No se encontró el cierre en la consulta del servidor.',
    );
  }

  Future<Cierre> crear(CrearCierreRequest request) async {
    final fechas = request.toJson();
    if ((fechas['fechaFin'] as String).compareTo(
          fechas['fechaInicio'] as String,
        ) <
        0) {
      throw const CierreException(
        'La fecha final debe ser igual o posterior a la inicial.',
      );
    }
    final encabezados = _encabezados();
    final http.Response respuesta;
    try {
      respuesta = await _esperar(
        _client.post(
          Uri.parse(_url),
          headers: encabezados,
          body: jsonEncode(fechas),
        ),
      );
    } on CierreException catch (error) {
      throw CierreException(error.mensaje, resultadoIncierto: true);
    }
    if (respuesta.statusCode >= 500) {
      throw const CierreException(
        'No se pudo confirmar la generación. Consulta los cierres antes de repetirla.',
        resultadoIncierto: true,
      );
    }
    try {
      final datos = _procesar(respuesta)['data'];
      if (datos is! Map<String, dynamic>) throw const FormatException();
      final cierre = Cierre.fromJson(datos);
      if (cierre.inicio.toIso8601String().split('T').first !=
              fechas['fechaInicio'] ||
          cierre.fin.toIso8601String().split('T').first != fechas['fechaFin']) {
        throw const FormatException();
      }
      return cierre;
    } on FormatException {
      throw const CierreException(
        'La respuesta no permitió verificar el cierre. Consulta el listado antes de generar otro.',
        resultadoIncierto: true,
      );
    } on CierreException catch (error) {
      throw CierreException(
        error.mensaje,
        resultadoIncierto:
            respuesta.statusCode >= 200 && respuesta.statusCode < 300,
      );
    }
  }

  // Solo se usa el filtro publicado por Swagger. No se envía el antiguo cierreId de Bruno.
  Future<List<Map<String, dynamic>>> comisiones(int cierreId) async {
    try {
      return await ComisionService(client: _client)
          .listar(liquidacionComisionId: cierreId);
    } on ComisionException catch (error) {
      throw CierreException(error.mensaje);
    }
  }

  Map<String, String> _encabezados() {
    if (!SesionService.activa) {
      throw const CierreException('Tu sesión venció. Ingresa de nuevo.');
    }
    return SesionService.encabezados();
  }

  Future<http.Response> _esperar(Future<http.Response> peticion) async {
    try {
      return await peticion.timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const CierreException(
        'La conexión tardó demasiado. Intenta de nuevo.',
      );
    } on http.ClientException {
      throw const CierreException(
        'No se pudo conectar con la API. Revisa tu conexión.',
      );
    }
  }

  Map<String, dynamic> _procesar(http.Response respuesta) {
    SesionService.revisarRespuesta(respuesta.statusCode);
    if (respuesta.statusCode == 401) {
      throw const CierreException('Tu sesión venció. Ingresa de nuevo.');
    }
    if (respuesta.statusCode == 403) {
      throw const CierreException(
        'No tienes permiso para realizar esta operación.',
      );
    }
    if (respuesta.statusCode >= 500) {
      throw const CierreException(
        'El servidor no está disponible. Intenta más tarde.',
      );
    }
    Map<String, dynamic> datos;
    try {
      final contenido = jsonDecode(utf8.decode(respuesta.bodyBytes));
      if (contenido is! Map<String, dynamic>) throw const FormatException();
      datos = contenido;
    } on FormatException {
      throw const CierreException('La API devolvió una respuesta no válida.');
    }
    if (respuesta.statusCode < 200 ||
        respuesta.statusCode >= 300 ||
        datos['success'] != true) {
      final mensaje = datos['message'];
      throw CierreException(
        mensaje is String && mensaje.isNotEmpty
            ? mensaje
            : 'No fue posible completar la operación.',
      );
    }
    return datos;
  }

  void cerrar() => _client.close();
}
