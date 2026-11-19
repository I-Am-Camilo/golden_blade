import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/especialidad.dart';
import '../models/especialidad_request.dart';
import '../models/especialidades_response.dart';
import 'sesion_service.dart';

class EspecialidadException implements Exception {
  const EspecialidadException(this.mensaje);
  final String mensaje;
}

class EspecialidadService {
  EspecialidadService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;
  static const _url = '${AppConfig.apiBaseUrl}/Especialidades';

  Future<EspecialidadesResponse> listar() async {
    final respuesta = await _esperar(
      _client.get(Uri.parse(_url), headers: _encabezados()),
    );
    return EspecialidadesResponse.fromJson(_procesar(respuesta));
  }

  Future<Especialidad> crear(EspecialidadRequest request) async {
    final respuesta = await _esperar(
      _client.post(
        Uri.parse(_url),
        headers: _encabezados(),
        body: jsonEncode(request.toJson()),
      ),
    );
    return _especialidadGuardada(_procesar(respuesta));
  }

  Future<Especialidad> editar(int id, EspecialidadRequest request) async {
    final respuesta = await _esperar(
      _client.put(
        Uri.parse('$_url/$id'),
        headers: _encabezados(),
        body: jsonEncode(request.toJson()),
      ),
    );
    return _especialidadGuardada(_procesar(respuesta));
  }

  Future<Especialidad> obtener(int id) async {
    if (id <= 0) throw const EspecialidadException('Ingresa un ID válido.');
    final respuesta = await _esperar(
      _client.get(Uri.parse('$_url/$id'), headers: _encabezados()),
    );
    final especialidad = _especialidadGuardada(_procesar(respuesta));
    if (especialidad.id != id) {
      throw const EspecialidadException(
        'No se recibió la especialidad solicitada.',
      );
    }
    return especialidad;
  }

  Future<void> inactivar(int id) async {
    final respuesta = await _esperar(
      _client.delete(Uri.parse('$_url/$id'), headers: _encabezados()),
    );
    _procesar(respuesta);
  }

  Map<String, String> _encabezados() {
    if (!SesionService.activa) {
      throw const EspecialidadException('Tu sesión venció. Ingresa de nuevo.');
    }
    return SesionService.encabezados();
  }

  Future<http.Response> _esperar(Future<http.Response> peticion) async {
    try {
      return await peticion.timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const EspecialidadException(
        'La conexión tardó demasiado. Intenta de nuevo.',
      );
    } on http.ClientException {
      throw const EspecialidadException(
        'No se pudo conectar con la API. Revisa tu conexión.',
      );
    }
  }

  Map<String, dynamic> _procesar(http.Response respuesta) {
    SesionService.revisarRespuesta(respuesta.statusCode);
    if (respuesta.statusCode == 401) {
      throw const EspecialidadException('Tu sesión venció. Ingresa de nuevo.');
    }
    if (respuesta.statusCode == 403) {
      throw const EspecialidadException(
        'No tienes permiso para realizar esta operación.',
      );
    }
    if (respuesta.statusCode >= 500) {
      throw const EspecialidadException(
        'El servidor no está disponible. Intenta más tarde.',
      );
    }
    Map<String, dynamic> datos;
    try {
      final contenido = jsonDecode(utf8.decode(respuesta.bodyBytes));
      if (contenido is! Map<String, dynamic>) throw const FormatException();
      datos = contenido;
    } on FormatException {
      throw const EspecialidadException(
        'La API devolvió una respuesta no válida.',
      );
    }
    if (respuesta.statusCode < 200 ||
        respuesta.statusCode >= 300 ||
        datos['success'] != true) {
      final mensaje = datos['message'];
      throw EspecialidadException(
        mensaje is String && mensaje.isNotEmpty
            ? mensaje
            : 'No fue posible completar la operación.',
      );
    }
    return datos;
  }

  Especialidad _especialidadGuardada(Map<String, dynamic> datos) {
    final registro = datos['data'];
    if (registro is! Map<String, dynamic>) {
      throw const EspecialidadException(
        'No se recibió la especialidad guardada.',
      );
    }
    return Especialidad.fromJson(registro);
  }

  void cerrar() => _client.close();
}
