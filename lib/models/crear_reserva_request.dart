// Variante de creación con cliente ya registrado. No admite profesional ni pago.
class CrearReservaRequest {
  const CrearReservaRequest({
    required this.fecha,
    required this.servicioId,
    required this.clienteId,
  });
  final DateTime fecha;
  final int servicioId;
  final int clienteId;
  Map<String, dynamic> toJson() => {
    'fecha': fecha.toIso8601String(),
    'servicioId': servicioId,
    'clienteId': clienteId,
  };
}
