class EditarJornadaRequest {
  const EditarJornadaRequest({
    required this.horaInicio,
    required this.horaFin,
    required this.tieneAlmuerzo,
    this.horaInicioAlmuerzo,
    this.horaFinAlmuerzo,
  });
  final String horaInicio;
  final String horaFin;
  final bool tieneAlmuerzo;
  final String? horaInicioAlmuerzo;
  final String? horaFinAlmuerzo;
  Map<String, dynamic> toJson() => {
    'horaInicio': horaInicio,
    'horaFin': horaFin,
    'tieneAlmuerzo': tieneAlmuerzo,
    'horaInicioAlmuerzo': horaInicioAlmuerzo,
    'horaFinAlmuerzo': horaFinAlmuerzo,
  };
}
