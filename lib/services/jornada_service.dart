import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'sesion_service.dart';
import '../models/jornada_laboral.dart';
import '../models/crear_jornada_request.dart';
import '../models/editar_jornada_request.dart';

class JornadaException implements Exception {
  const JornadaException(this.mensaje);
  final String mensaje;
}

class JornadaService {
  JornadaService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static const _url = '${AppConfig.apiBaseUrl}/horarios-laboral';
  Future<List<JornadaLaboral>> listar(int profesionalId) async {
    final respuesta = await _esperar(
      _client.get(
        Uri.parse('$_url/profesional/$profesionalId'),
        headers: _encabezados(),
      ),
    );
    final datos = _procesar(respuesta)['data'];
    if (datos is! List) {
      throw const FormatException('Listado de jornadas no válido.');
    }
    final jornadas = datos.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Jornada no válida.');
      }
      return JornadaLaboral.fromJson(item);
    }).toList();
    if (jornadas.any((j) => j.profesionalId != profesionalId)) {
      throw const JornadaException(
        'La API devolvió jornadas de otro profesional.',
      );
    }
    return jornadas;
  }

  Future<JornadaLaboral> crear(CrearJornadaRequest request) async {
    final respuesta = await _esperar(
      _client.post(
        Uri.parse(_url),
        headers: _encabezados(),
        body: jsonEncode(request.toJson()),
      ),
    );
    return _jornada(_procesar(respuesta));
  }

  Future<JornadaLaboral> editar(int id, EditarJornadaRequest request) async {
    final respuesta = await _esperar(
      _client.put(
        Uri.parse('$_url/$id'),
        headers: _encabezados(),
        body: jsonEncode(request.toJson()),
      ),
    );
    return _jornada(_procesar(respuesta));
  }

  JornadaLaboral _jornada(Map<String, dynamic> respuesta) {
    final datos = respuesta['data'];
    if (datos is! Map<String, dynamic>) {
      throw const FormatException('No se recibió la jornada guardada.');
    }
    return JornadaLaboral.fromJson(datos);
  }

  Map<String, String> _encabezados() {
    if (!SesionService.activa) {
      throw const JornadaException('Tu sesión venció. Ingresa de nuevo.');
    }
    return SesionService.encabezados();
  }

  Future<http.Response> _esperar(Future<http.Response> peticion) async {
    try {
      return await peticion.timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const JornadaException(
        'La conexión tardó demasiado. Intenta de nuevo.',
      );
    } on http.ClientException {
      throw const JornadaException(
        'No se pudo conectar con la API. Revisa tu conexión.',
      );
    }
  }

  Map<String, dynamic> _procesar(http.Response respuesta) {
    SesionService.revisarRespuesta(respuesta.statusCode);
    if (respuesta.statusCode == 401) {
      throw const JornadaException('Tu sesión venció. Ingresa de nuevo.');
    }
    if (respuesta.statusCode == 403) {
      throw const JornadaException(
        'No tienes permiso para realizar esta operación.',
      );
    }
    if (respuesta.statusCode >= 500) {
      throw const JornadaException(
        'El servidor no está disponible. Intenta más tarde.',
      );
    }
    Map<String, dynamic> datos;
    try {
      final contenido = jsonDecode(utf8.decode(respuesta.bodyBytes));
      if (contenido is! Map<String, dynamic>) throw const FormatException();
      datos = contenido;
    } on FormatException {
      throw const JornadaException('La API devolvió una respuesta no válida.');
    }
    if (respuesta.statusCode < 200 ||
        respuesta.statusCode >= 300 ||
        datos['success'] != true) {
      final mensaje = datos['message'];
      throw JornadaException(
        mensaje is String && mensaje.isNotEmpty
            ? mensaje
            : 'No fue posible completar la operación.',
      );
    }
    return datos;
  }

  void cerrar() => _client.close();
}
