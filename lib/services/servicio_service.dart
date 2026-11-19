import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/servicio.dart';
import '../models/crear_servicio_request.dart';
import '../models/editar_servicio_request.dart';
import '../models/servicios_response.dart';
import 'sesion_service.dart';

class ServicioException implements Exception {
  const ServicioException(this.mensaje);
  final String mensaje;
}

class ServicioService {
  ServicioService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _url = '${AppConfig.apiBaseUrl}/Servicios';

  Future<ServiciosResponse> listar() async {
    final respuesta = await _esperar(
      _client.get(Uri.parse(_url), headers: _encabezados()),
    );
    return ServiciosResponse.fromJson(_procesar(respuesta));
  }

  Future<Servicio> crear(CrearServicioRequest request) async {
    final respuesta = await _esperar(
      _client.post(
        Uri.parse(_url),
        headers: _encabezados(),
        body: jsonEncode(request.toJson()),
      ),
    );
    return _servicioGuardado(_procesar(respuesta));
  }

  Future<Servicio> editar(int id, EditarServicioRequest request) async {
    final respuesta = await _esperar(
      _client.put(
        Uri.parse('$_url/$id'),
        headers: _encabezados(),
        body: jsonEncode(request.toJson()),
      ),
    );
    return _servicioGuardado(_procesar(respuesta));
  }

  Future<Servicio> obtener(int id) async {
    final respuesta = await _esperar(
      _client.get(Uri.parse('$_url/$id'), headers: _encabezados()),
    );
    return _servicioGuardado(_procesar(respuesta));
  }

  Map<String, String> _encabezados() {
    if (!SesionService.activa) {
      throw const ServicioException('Tu sesión venció. Ingresa de nuevo.');
    }
    return SesionService.encabezados();
  }

  Future<http.Response> _esperar(Future<http.Response> peticion) async {
    try {
      return await peticion.timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const ServicioException(
        'La conexión tardó demasiado. Intenta de nuevo.',
      );
    } on http.ClientException {
      throw const ServicioException(
        'No se pudo conectar con la API. Revisa tu conexión.',
      );
    }
  }

  Map<String, dynamic> _procesar(http.Response respuesta) {
    SesionService.revisarRespuesta(respuesta.statusCode);
    if (respuesta.statusCode == 401) {
      throw const ServicioException('Tu sesión venció. Ingresa de nuevo.');
    }
    if (respuesta.statusCode == 403) {
      throw const ServicioException(
        'No tienes permiso para realizar esta operación.',
      );
    }
    if (respuesta.statusCode >= 500) {
      throw const ServicioException(
        'El servidor no está disponible. Intenta más tarde.',
      );
    }
    Map<String, dynamic> datos;
    try {
      final contenido = jsonDecode(utf8.decode(respuesta.bodyBytes));
      if (contenido is! Map<String, dynamic>) throw const FormatException();
      datos = contenido;
    } on FormatException {
      throw const ServicioException('La API devolvió una respuesta no válida.');
    }
    if (respuesta.statusCode < 200 ||
        respuesta.statusCode >= 300 ||
        datos['success'] != true) {
      final mensaje = datos['message'];
      throw ServicioException(
        mensaje is String && mensaje.isNotEmpty
            ? mensaje
            : 'No fue posible completar la operación.',
      );
    }
    return datos;
  }

  Servicio _servicioGuardado(Map<String, dynamic> datos) {
    final registro = datos['data'];
    if (registro is! Map<String, dynamic>) {
      throw const ServicioException('No se recibió el servicio guardado.');
    }
    return Servicio.fromJson(registro);
  }

  void cerrar() => _client.close();
}
