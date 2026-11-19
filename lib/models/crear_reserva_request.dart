import 'cliente.dart';

class CrearReservaRequest {
  const CrearReservaRequest({
    required this.fecha,
    required this.servicioId,
    this.clienteId,
    this.clienteNuevo,
  });
  final DateTime fecha;
  final int servicioId;
  final int? clienteId;
  final Cliente? clienteNuevo;
  Map<String, dynamic> toJson() {
    if (servicioId <= 0 ||
        (clienteNuevo == null && (clienteId == null || clienteId! <= 0)) ||
        (clienteNuevo != null && clienteId != null) ||
        (clienteNuevo != null &&
            (clienteNuevo!.documento.trim().isEmpty ||
                clienteNuevo!.nombres.trim().isEmpty ||
                clienteNuevo!.apellidos.trim().isEmpty))) {
      throw const FormatException(
        'Completa los datos del cliente y del servicio.',
      );
    }
    return {
      'fecha': fecha.toIso8601String(),
      'servicioId': servicioId,
      if (clienteNuevo == null) 'clienteId': clienteId,
      if (clienteNuevo != null) ...{
        'documento': clienteNuevo!.documento,
        'nombres': clienteNuevo!.nombres,
        'apellidos': clienteNuevo!.apellidos,
        'celular': clienteNuevo!.celular,
        if (clienteNuevo!.correo.isNotEmpty) 'correo': clienteNuevo!.correo,
        if (clienteNuevo!.fechaNacimiento != null)
          'fechaNacimiento': clienteNuevo!.fechaNacimiento!
              .toIso8601String()
              .split('T')
              .first,
      },
    };
  }
}
