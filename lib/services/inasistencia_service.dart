import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'sesion_service.dart';
import '../models/inasistencia.dart';
import '../models/crear_inasistencia_request.dart';
import '../models/editar_inasistencia_request.dart';

class InasistenciaException implements Exception {
  const InasistenciaException(this.mensaje);
  final String mensaje;
}

class InasistenciaService {
  InasistenciaService({http.Client? client})
    : _client = client ?? http.Client();
  final http.Client _client;
  static const _url = '${AppConfig.apiBaseUrl}/eventualidades';
  Future<List<Inasistencia>> listar(int profesionalId) async {
    final uri = Uri.parse(_url)
        .replace(queryParameters: {'profesionalId': '$profesionalId'});
    final respuesta = await _esperar(_client.get(uri, headers: _encabezados()));
    final datos = _procesar(respuesta)['data'];
    if (datos is! List) {
      throw const FormatException('Listado de inasistencias no válido.');
    }
    final registros = datos.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Inasistencia no válida.');
      }
      return Inasistencia.fromJson(item);
    }).toList();
    if (registros.any((a) => a.profesionalId != profesionalId)) {
      throw const InasistenciaException(
        'La API devolvió inasistencias de otro profesional.',
      );
    }
    registros.sort((a, b) => b.fechaInicio.compareTo(a.fechaInicio));
    return registros;
  }

  Future<int> crear(CrearInasistenciaRequest request) async {
    final respuesta = await _esperar(
      _client.post(
        Uri.parse('$_url/masivo'),
        headers: _encabezados(),
        body: jsonEncode(request.toJson()),
      ),
    );
    final datos = _procesar(respuesta)['data'];
    if (datos is! Map<String, dynamic> || datos['creados'] is! int) {
      throw const FormatException('Resultado de creación no válido.');
    }
    return datos['creados'] as int;
  }

  Future<Inasistencia> editar(int id, EditarInasistenciaRequest request) async {
    final respuesta = await _esperar(
      _client.put(
        Uri.parse('$_url/$id'),
        headers: _encabezados(),
        body: jsonEncode(request.toJson()),
      ),
    );
    final datos = _procesar(respuesta)['data'];
    if (datos is! Map<String, dynamic>) {
      throw const FormatException('No se recibió la inasistencia guardada.');
    }
    return Inasistencia.fromJson(datos);
  }

  Future<void> eliminar(int id) async {
    final respuesta = await _esperar(
      _client.delete(Uri.parse('$_url/$id'), headers: _encabezados()),
    );
    _procesar(respuesta);
  }

  Map<String, String> _encabezados() {
    if (!SesionService.activa) {
      throw const InasistenciaException('Tu sesión venció. Ingresa de nuevo.');
    }
    return SesionService.encabezados();
  }

  Future<http.Response> _esperar(Future<http.Response> peticion) async {
    try {
      return await peticion.timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const InasistenciaException(
        'La conexión tardó demasiado. Intenta de nuevo.',
      );
    } on http.ClientException {
      throw const InasistenciaException(
        'No se pudo conectar con la API. Revisa tu conexión.',
      );
    }
  }

  Map<String, dynamic> _procesar(http.Response respuesta) {
    SesionService.revisarRespuesta(respuesta.statusCode);
    if (respuesta.statusCode == 401) {
      throw const InasistenciaException('Tu sesión venció. Ingresa de nuevo.');
    }
    if (respuesta.statusCode == 403) {
      throw const InasistenciaException(
        'No tienes permiso para realizar esta operación.',
      );
    }
    if (respuesta.statusCode >= 500) {
      throw const InasistenciaException(
        'El servidor no está disponible. Intenta más tarde.',
      );
    }
    Map<String, dynamic> datos;
    try {
      final contenido = jsonDecode(utf8.decode(respuesta.bodyBytes));
      if (contenido is! Map<String, dynamic>) throw const FormatException();
      datos = contenido;
    } on FormatException {
      throw const InasistenciaException(
        'La API devolvió una respuesta no válida.',
      );
    }
    if (respuesta.statusCode < 200 ||
        respuesta.statusCode >= 300 ||
        datos['success'] != true) {
      final mensaje = datos['message'];
      throw InasistenciaException(
        mensaje is String && mensaje.isNotEmpty
            ? mensaje
            : 'No fue posible completar la operación.',
      );
    }
    return datos;
  }

  void cerrar() => _client.close();
}
