class ClienteRequest {
  const ClienteRequest({
    required this.documento,
    required this.nombres,
    required this.apellidos,
    required this.fechaNacimiento,
    required this.celular,
    required this.correo,
  });
  final String documento;
  final String nombres;
  final String apellidos;
  final DateTime? fechaNacimiento;
  final String celular;
  final String correo;
  Map<String, dynamic> toJson() => {
    'documento': documento,
    'nombres': nombres,
    'apellidos': apellidos,
    'fechaNacimiento': fechaNacimiento?.toIso8601String().split('T').first,
    'celular': celular,
    'correo': correo,
  };
}
