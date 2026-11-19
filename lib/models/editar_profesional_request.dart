class EditarProfesionalRequest {
  const EditarProfesionalRequest({
    required this.documento,
    required this.nombres,
    required this.apellidos,
    required this.fechaNacimiento,
    required this.porcentaje,
    required this.estado,
  });
  final String documento;
  final String nombres;
  final String apellidos;
  final DateTime? fechaNacimiento;
  final double porcentaje;
  final bool estado;

  Map<String, dynamic> toJson() => {
    'documento': documento,
    'nombres': nombres,
    'apellidos': apellidos,
    'fechaNacimiento': fechaNacimiento?.toIso8601String().split('T').first,
    'porcentaje': porcentaje,
    'estado': estado,
  };
}
