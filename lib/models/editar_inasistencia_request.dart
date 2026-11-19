class EditarInasistenciaRequest {
  const EditarInasistenciaRequest({
    required this.fechaInicio,
    required this.fechaFin,
    required this.motivo,
    required this.observacion,
  });
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final int motivo;
  final String observacion;
  Map<String, dynamic> toJson() => {
    'fechaInicio': fechaInicio.toIso8601String(),
    'fechaFin': fechaFin.toIso8601String(),
    'motivo': motivo,
    'observacion': observacion,
  };
}
