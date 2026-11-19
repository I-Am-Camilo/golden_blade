class CrearCierreRequest {
  const CrearCierreRequest({required this.fechaInicio, required this.fechaFin});

  final DateTime fechaInicio;
  final DateTime fechaFin;

  Map<String, dynamic> toJson() => {
    'fechaInicio': fechaInicio.toIso8601String().split('T').first,
    'fechaFin': fechaFin.toIso8601String().split('T').first,
  };
}
