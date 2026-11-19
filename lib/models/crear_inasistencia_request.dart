class CrearInasistenciaRequest {
  const CrearInasistenciaRequest({
    required this.profesionalId,
    required this.fechaInicio,
    required this.fechaFin,
    required this.motivo,
    required this.observacion,
  });
  final int profesionalId;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final int motivo;
  final String observacion;
  Map<String, dynamic> toJson() => {
    'profesionalId': profesionalId,
    'motivo': motivo,
    'observacion': observacion,
    'periodos': [
      {
        'fechaInicio': fechaInicio.toIso8601String(),
        'fechaFin': fechaFin.toIso8601String(),
      },
    ],
  };
}
