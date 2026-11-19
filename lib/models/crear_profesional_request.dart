class CrearProfesionalRequest {
  const CrearProfesionalRequest({
    required this.documento,
    required this.nombres,
    required this.apellidos,
    required this.fechaNacimiento,
    required this.porcentaje,
    required this.estado,
    required this.especialidad,
  });
  final String documento;
  final String nombres;
  final String apellidos;
  final DateTime? fechaNacimiento;
  final double porcentaje;
  final bool estado;
  final int especialidad;

  Map<String, dynamic> toJson() => {
    'documento': documento,
    'nombres': nombres,
    'apellidos': apellidos,
    'fechaNacimiento': fechaNacimiento?.toIso8601String().split('T').first,
    'porcentaje': porcentaje,
    'estado': estado,
    'especialidad': especialidad,
  };
}
