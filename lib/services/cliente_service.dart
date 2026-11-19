import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/cliente.dart';
import '../models/cliente_request.dart';
import '../models/reserva.dart';
import '../models/clientes_response.dart';
import 'sesion_service.dart';

class ClienteException implements Exception {
  const ClienteException(this.mensaje);
  final String mensaje;
}

class ClienteService {
  ClienteService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _url = '${AppConfig.apiBaseUrl}/Clientes';

  Future<ClientesResponse> listar() async {
    final respuesta = await _esperar(
      _client.get(Uri.parse(_url), headers: _encabezados()),
    );
    return ClientesResponse.fromJson(_procesar(respuesta));
  }

  Future<Cliente> crear(ClienteRequest request) async {
    final respuesta = await _esperar(
      _client.post(
        Uri.parse(_url),
        headers: _encabezados(),
        body: jsonEncode(request.toJson()),
      ),
    );
    _procesar(respuesta);
    return buscarPorDocumento(request.documento);
  }

  Future<Cliente> editar(int id, ClienteRequest request) async {
    final respuesta = await _esperar(
      _client.put(
        Uri.parse('$_url/$id'),
        headers: _encabezados(),
        body: jsonEncode(request.toJson()),
      ),
    );
    _procesar(respuesta);
    final guardado = await buscarPorDocumento(request.documento);
    if (guardado.id != id) {
      throw const ClienteException(
        'No fue posible confirmar el cliente actualizado. Actualiza el listado.',
      );
    }
    return guardado;
  }

  // GET recibe el documento; PUT recibe el ID. No son intercambiables.
  Future<Cliente> buscarPorDocumento(String documento) async {
    final uri = Uri.parse(_url)
        .replace(pathSegments: [...Uri.parse(_url).pathSegments, documento]);
    final respuesta = await _esperar(_client.get(uri, headers: _encabezados()));
    return _clienteGuardado(_procesar(respuesta));
  }

  Future<List<Reserva>> historial(int clienteId) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/Reservas')
        .replace(queryParameters: {'ClienteId': '$clienteId'});
    final respuesta = await _esperar(_client.get(uri, headers: _encabezados()));
    final datos = _procesar(respuesta)['data'];
    if (datos is! List) {
      throw const FormatException('El historial recibido no es válido.');
    }
    final reservas = datos.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Reserva no válida.');
      }
      return Reserva.fromJson(item);
    }).toList();
    if (reservas.any((reserva) => reserva.clienteId != clienteId)) {
      throw const ClienteException('La API devolvió reservas de otro cliente.');
    }
    reservas.sort((a, b) => b.fecha.compareTo(a.fecha));
    return reservas;
  }

  Future<void> eliminar(int id) async {
    if (id <= 0) throw const ClienteException('Selecciona un registro válido.');
    final respuesta = await _esperar(
      _client.delete(Uri.parse('$_url/$id'), headers: _encabezados()),
    );
    if ((respuesta.statusCode == 200 || respuesta.statusCode == 204) &&
        respuesta.body.trim().isEmpty) {
      return;
    }
    _procesar(respuesta);
  }

  Map<String, String> _encabezados() {
    if (!SesionService.activa) {
      throw const ClienteException('Tu sesión venció. Ingresa de nuevo.');
    }
    return SesionService.encabezados();
  }

  Future<http.Response> _esperar(Future<http.Response> peticion) async {
    try {
      return await peticion.timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const ClienteException(
        'La conexión tardó demasiado. Intenta de nuevo.',
      );
    } on http.ClientException {
      throw const ClienteException(
        'No se pudo conectar con la API. Revisa tu conexión.',
      );
    }
  }

  Map<String, dynamic> _procesar(http.Response respuesta) {
    SesionService.revisarRespuesta(respuesta.statusCode);
    if (respuesta.statusCode == 401) {
      throw const ClienteException('Tu sesión venció. Ingresa de nuevo.');
    }
    if (respuesta.statusCode == 403) {
      throw const ClienteException(
        'No tienes permiso para realizar esta operación.',
      );
    }
    if (respuesta.statusCode >= 500) {
      throw const ClienteException(
        'El servidor no está disponible. Intenta más tarde.',
      );
    }
    Map<String, dynamic> datos;
    try {
      final contenido = jsonDecode(utf8.decode(respuesta.bodyBytes));
      if (contenido is! Map<String, dynamic>) throw const FormatException();
      datos = contenido;
    } on FormatException {
      throw const ClienteException('La API devolvió una respuesta no válida.');
    }
    if (respuesta.statusCode < 200 ||
        respuesta.statusCode >= 300 ||
        datos['success'] != true) {
      final mensaje = datos['message'];
      throw ClienteException(
        mensaje is String && mensaje.isNotEmpty
            ? mensaje
            : 'No fue posible completar la operación.',
      );
    }
    return datos;
  }

  Cliente _clienteGuardado(Map<String, dynamic> datos) {
    final registro = datos['data'];
    if (registro is! Map<String, dynamic>) {
      throw const ClienteException('No se recibió el cliente guardado.');
    }
    return Cliente.fromJson(registro);
  }

  void cerrar() => _client.close();
}
