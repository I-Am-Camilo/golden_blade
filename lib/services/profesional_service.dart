import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/profesional.dart';
import '../models/crear_profesional_request.dart';
import '../models/editar_profesional_request.dart';
import '../models/profesionales_response.dart';
import 'sesion_service.dart';

class ProfesionalException implements Exception {
  const ProfesionalException(this.mensaje);
  final String mensaje;
}

class ProfesionalService {
  ProfesionalService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _url = '${AppConfig.apiBaseUrl}/Profesionales';

  Future<ProfesionalesResponse> listar({bool soloActivos = false}) async {
    final uri = Uri.parse(_url)
        .replace(queryParameters: {'soloActivos': soloActivos.toString()});
    final respuesta = await _esperar(_client.get(uri, headers: _encabezados()));
    return ProfesionalesResponse.fromJson(_procesar(respuesta));
  }

  // La ruta publicada conserva el nombre "especialiades", pero recibe un ID de servicio.
  Future<ProfesionalesResponse> porServicio(int servicioId) async {
    if (servicioId <= 0) {
      throw const ProfesionalException('Selecciona un servicio válido.');
    }
    final respuesta = await _esperar(
      _client.get(
        Uri.parse('$_url/$servicioId/especialiades'),
        headers: _encabezados(),
      ),
    );
    return ProfesionalesResponse.fromJson(_procesar(respuesta));
  }

  Future<Profesional> crear(CrearProfesionalRequest request) async {
    final respuesta = await _esperar(
      _client.post(
        Uri.parse(_url),
        headers: _encabezados(),
        body: jsonEncode(request.toJson()),
      ),
    );
    return _profesionalGuardado(_procesar(respuesta));
  }

  Future<Profesional> editar(int id, EditarProfesionalRequest request) async {
    if (id <= 0) {
      throw const ProfesionalException('Selecciona un profesional válido.');
    }
    final respuesta = await _esperar(
      _client.put(
        Uri.parse('$_url/$id'),
        headers: _encabezados(),
        body: jsonEncode(request.toJson()),
      ),
    );
    final guardado = _profesionalGuardado(_procesar(respuesta));
    if (guardado.id != id) {
      throw const ProfesionalException(
        'La respuesta no corresponde al profesional editado. Actualiza el listado.',
      );
    }
    return guardado;
  }

  Future<Profesional> obtener(int id) async {
    if (id <= 0) {
      throw const ProfesionalException('Selecciona un profesional válido.');
    }
    final respuesta = await _esperar(
      _client.get(Uri.parse('$_url/$id'), headers: _encabezados()),
    );
    final profesional = _profesionalGuardado(_procesar(respuesta));
    if (profesional.id != id) {
      throw const ProfesionalException(
        'El profesional recibido no corresponde al solicitado.',
      );
    }
    return profesional;
  }

  Future<void> eliminar(int id) async {
    if (id <= 0) {
      throw const ProfesionalException('Selecciona un profesional válido.');
    }
    final encabezados = _encabezados();
    final http.Response respuesta;
    try {
      respuesta = await _esperar(
        _client.delete(Uri.parse('$_url/$id'), headers: encabezados),
      );
    } on ProfesionalException {
      throw const ProfesionalException(
        'No se pudo confirmar la eliminación. Actualiza el listado antes de volver a intentarlo.',
      );
    }
    if (respuesta.statusCode >= 500) {
      throw const ProfesionalException(
        'El servidor no pudo confirmar la eliminación. Actualiza el listado antes de volver a intentarlo.',
      );
    }
    // DELETE no publica datos de respuesta obligatorios.
    if ((respuesta.statusCode == 200 || respuesta.statusCode == 204) &&
        respuesta.body.trim().isEmpty) {
      return;
    }
    _procesar(respuesta);
  }

  Map<String, String> _encabezados() {
    if (!SesionService.activa) {
      throw const ProfesionalException('Tu sesión venció. Ingresa de nuevo.');
    }
    return SesionService.encabezados();
  }

  Future<http.Response> _esperar(Future<http.Response> peticion) async {
    try {
      return await peticion.timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const ProfesionalException(
        'La conexión tardó demasiado. Intenta de nuevo.',
      );
    } on http.ClientException {
      throw const ProfesionalException(
        'No se pudo conectar con la API. Revisa tu conexión.',
      );
    }
  }

  Map<String, dynamic> _procesar(http.Response respuesta) {
    SesionService.revisarRespuesta(respuesta.statusCode);
    if (respuesta.statusCode == 401) {
      throw const ProfesionalException('Tu sesión venció. Ingresa de nuevo.');
    }
    if (respuesta.statusCode == 403) {
      throw const ProfesionalException(
        'No tienes permiso para realizar esta operación.',
      );
    }
    if (respuesta.statusCode >= 500) {
      throw const ProfesionalException(
        'El servidor no está disponible. Intenta más tarde.',
      );
    }
    Map<String, dynamic> datos;
    try {
      final contenido = jsonDecode(utf8.decode(respuesta.bodyBytes));
      if (contenido is! Map<String, dynamic>) throw const FormatException();
      datos = contenido;
    } on FormatException {
      throw const ProfesionalException(
        'La API devolvió una respuesta no válida.',
      );
    }
    if (respuesta.statusCode < 200 ||
        respuesta.statusCode >= 300 ||
        datos['success'] != true) {
      final mensaje = datos['message'];
      throw ProfesionalException(
        mensaje is String && mensaje.isNotEmpty
            ? mensaje
            : 'No fue posible completar la operación.',
      );
    }
    return datos;
  }

  Profesional _profesionalGuardado(Map<String, dynamic> datos) {
    final registro = datos['data'];
    if (registro is! Map<String, dynamic>) {
      throw const ProfesionalException(
        'No se recibió el profesional guardado.',
      );
    }
    return Profesional.fromJson(registro);
  }

  void cerrar() => _client.close();
}
