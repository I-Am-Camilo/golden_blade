import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/reserva.dart';
import '../models/crear_reserva_request.dart';
import 'sesion_service.dart';

class ReservaException implements Exception {
  const ReservaException(this.mensaje, {this.resultadoIncierto = false});
  final String mensaje;
  // Si se perdió la respuesta del POST, consultar la agenda evita reenviar a ciegas.
  final bool resultadoIncierto;
}

class ReservaService {
  ReservaService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static const _url = '${AppConfig.apiBaseUrl}/Reservas';
  Future<int> crear(CrearReservaRequest request) async {
    final encabezados = _encabezados();
    if (request.clienteNuevo != null) {
      // Variante pública de Bruno: la empresa se indica en este encabezado.
      encabezados.remove('Authorization');
      encabezados['X-Empresa-Id'] = '${SesionService.actual!.empresaId}';
    }

    final http.Response respuesta;
    try {
      respuesta = await _esperar(
        _client.post(
          Uri.parse(_url),
          headers: encabezados,
          body: jsonEncode(request.toJson()),
        ),
      );
    } on ReservaException catch (error) {
      throw ReservaException(error.mensaje, resultadoIncierto: true);
    }
    if (respuesta.statusCode >= 500) {
      throw const ReservaException(
        'No se pudo confirmar el guardado. Consulta la agenda antes de intentar otra reserva.',
        resultadoIncierto: true,
      );
    }
    final Map<String, dynamic> contenido;
    try {
      contenido = _procesar(respuesta);
    } on ReservaException catch (error) {
      throw ReservaException(
        error.mensaje,
        resultadoIncierto:
            respuesta.statusCode >= 200 && respuesta.statusCode < 300,
      );
    }
    final datos = contenido['data'];
    if (datos is! Map<String, dynamic> ||
        datos['id'] is! int ||
        (datos['id'] as int) <= 0 ||
        (request.clienteNuevo == null &&
            datos['clienteId'] != request.clienteId) ||
        (request.clienteNuevo != null &&
            (datos['clienteId'] is! int || (datos['clienteId'] as int) <= 0)) ||
        datos['servicioId'] != request.servicioId) {
      throw const ReservaException(
        'La API informó un guardado, pero no permitió identificar la reserva. Consulta la agenda.',
        resultadoIncierto: true,
      );
    }
    return datos['id'] as int;
  }

  Future<Reserva> obtener(int id) async {
    final respuesta = await _esperar(
      _client.get(Uri.parse('$_url/$id'), headers: _encabezados()),
    );
    final datos = _procesar(respuesta)['data'];
    if (datos is! Map<String, dynamic>) {
      throw const FormatException('No se recibió el detalle de la reserva.');
    }
    final reserva = Reserva.fromJson(datos);
    if (reserva.id != id) {
      throw const ReservaException(
        'La API devolvió una reserva diferente de la solicitada.',
      );
    }
    return reserva;
  }

  // Solo se envían los campos que cambian: cliente y servicio se conservan.
  Future<void> reagendar(int id, DateTime fecha, int profesionalId) async {
    await _modificar('PUT', id, {
      'fecha': fecha.toIso8601String(),
      'profesionalId': profesionalId,
    });
  }

  Future<void> cancelar(int id, String motivo) async {
    if (motivo.trim().isEmpty) {
      throw const ReservaException('Escribe el motivo de cancelación.');
    }
    await _modificar('DELETE', id, {
      'motivoCancelacionId': null,
      'motivoOtro': motivo.trim(),
    });
  }

  Future<void> _modificar(
    String metodo,
    int id,
    Map<String, dynamic> datos,
  ) async {
    final encabezados = _encabezados();
    final http.Response respuesta;
    try {
      final uri = Uri.parse('$_url/$id');
      respuesta =
          await (metodo == 'PUT'
                  ? _client.put(
                      uri,
                      headers: encabezados,
                      body: jsonEncode(datos),
                    )
                  : _client.delete(
                      uri,
                      headers: encabezados,
                      body: jsonEncode(datos),
                    ))
              .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const ReservaException(
        'No se pudo confirmar el cambio. Consulta la reserva.',
        resultadoIncierto: true,
      );
    } on http.ClientException {
      throw const ReservaException(
        'Se perdió la conexión. Consulta la reserva antes de repetir el cambio.',
        resultadoIncierto: true,
      );
    }
    if (respuesta.statusCode >= 500) {
      throw const ReservaException(
        'Consulta la reserva antes de volver a intentar.',
        resultadoIncierto: true,
      );
    }
    try {
      _procesar(respuesta);
    } on ReservaException catch (error) {
      throw ReservaException(
        error.mensaje,
        resultadoIncierto:
            respuesta.statusCode >= 200 && respuesta.statusCode < 300,
      );
    }
  }

  Future<List<Reserva>> listar({
    int? clienteId,
    int? servicioId,
    int? profesionalId,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    final uri = Uri.parse(_url).replace(
      queryParameters: {
        if (clienteId != null) 'ClienteId': '$clienteId',
        if (servicioId != null) 'ServicioId': '$servicioId',
        if (profesionalId != null) 'ProfesionalId': '$profesionalId',
        if (fechaInicio != null) 'FechaInicio': fechaInicio.toIso8601String(),
        if (fechaFin != null) 'FechaFin': fechaFin.toIso8601String(),
      },
    );
    final respuesta = await _esperar(_client.get(uri, headers: _encabezados()));
    final datos = _procesar(respuesta)['data'];
    if (datos is! List) {
      throw const FormatException('El listado de reservas no es válido.');
    }
    final reservas = datos.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Reserva no válida.');
      }
      return Reserva.fromJson(item);
    }).toList();
    if (clienteId != null && reservas.any((r) => r.clienteId != clienteId)) {
      throw const ReservaException('La API devolvió reservas de otro cliente.');
    }
    reservas.sort((a, b) => a.cita.compareTo(b.cita));
    return reservas;
  }

  Map<String, String> _encabezados() {
    if (!SesionService.activa) {
      throw const ReservaException('Tu sesión venció. Ingresa de nuevo.');
    }
    return SesionService.encabezados();
  }

  Future<http.Response> _esperar(Future<http.Response> peticion) async {
    try {
      return await peticion.timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const ReservaException(
        'La conexión tardó demasiado. Intenta de nuevo.',
      );
    } on http.ClientException {
      throw const ReservaException(
        'No se pudo conectar con la API. Revisa tu conexión.',
      );
    }
  }

  Map<String, dynamic> _procesar(http.Response respuesta) {
    SesionService.revisarRespuesta(respuesta.statusCode);
    if (respuesta.statusCode == 401) {
      throw const ReservaException('Tu sesión venció. Ingresa de nuevo.');
    }
    if (respuesta.statusCode == 403) {
      throw const ReservaException(
        'No tienes permiso para realizar esta operación.',
      );
    }
    if (respuesta.statusCode >= 500) {
      throw const ReservaException(
        'El servidor no está disponible. Intenta más tarde.',
      );
    }
    Map<String, dynamic> datos;
    try {
      final contenido = jsonDecode(utf8.decode(respuesta.bodyBytes));
      if (contenido is! Map<String, dynamic>) throw const FormatException();
      datos = contenido;
    } on FormatException {
      throw const ReservaException('La API devolvió una respuesta no válida.');
    }
    if (respuesta.statusCode < 200 ||
        respuesta.statusCode >= 300 ||
        datos['success'] != true) {
      final mensaje = datos['message'];
      throw ReservaException(
        mensaje is String && mensaje.isNotEmpty
            ? mensaje
            : 'No fue posible completar la operación.',
      );
    }
    return datos;
  }

  void cerrar() => _client.close();
}
