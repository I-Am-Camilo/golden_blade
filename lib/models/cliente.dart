class Cliente {
  const Cliente({
    required this.id,
    required this.documento,
    required this.nombres,
    required this.apellidos,
    this.fechaNacimiento,
    this.celular = '',
    this.correo = '',
  });
  final int id;
  final String documento;
  final String nombres;
  final String apellidos;
  final DateTime? fechaNacimiento;
  final String celular;
  final String correo;

  factory Cliente.fromJson(Map<String, dynamic> json) {
    if (json['id'] is! int ||
        json['documento'] is! String ||
        json['nombres'] is! String ||
        (json['apellidos'] != null && json['apellidos'] is! String) ||
        (json['celular'] != null && json['celular'] is! String) ||
        (json['correo'] != null && json['correo'] is! String) ||
        (json['fechaNacimiento'] != null &&
            json['fechaNacimiento'] is! String)) {
      throw const FormatException('El cliente recibido no es válido.');
    }
    final fechaTexto = json['fechaNacimiento'] as String?;
    final fecha = fechaTexto == null ? null : DateTime.tryParse(fechaTexto);
    if (fechaTexto != null && fecha == null) {
      throw const FormatException('Fecha no válida.');
    }
    return Cliente(
      id: json['id'] as int,
      documento: json['documento'] as String,
      nombres: json['nombres'] as String,
      apellidos: json['apellidos'] as String? ?? '',
      fechaNacimiento: fecha,
      celular: json['celular'] as String? ?? '',
      correo: json['correo'] as String? ?? '',
    );
  }
  String get nombreCompleto => '$nombres $apellidos'.trim();
  String get nacimientoTexto {
    final fecha = fechaNacimiento;
    if (fecha == null) return 'Sin registrar';
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }
}
