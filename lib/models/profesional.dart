class Profesional {
  const Profesional({
    required this.id,
    required this.documento,
    required this.nombres,
    required this.apellidos,
    required this.especialidadId,
    required this.nombreEspecialidad,
    required this.estado,
    this.fechaNacimiento,
    this.porcentaje,
  });

  final int id;
  final String documento;
  final String nombres;
  final String apellidos;
  final int especialidadId;
  final String nombreEspecialidad;
  final bool estado;
  final DateTime? fechaNacimiento;
  final double? porcentaje;

  factory Profesional.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final documento = json['documento'];
    final nombres = json['nombres'];
    final apellidos = json['apellidos'];
    final especialidadId = json['especialidadId'];
    final relacion = json['especialidad'];
    final estado = json['estado'];
    final porcentaje = json['porcentaje'];
    final fecha = json['fechaNacimiento'];
    if (id is! int ||
        documento is! String ||
        nombres is! String ||
        (apellidos != null && apellidos is! String) ||
        especialidadId is! int ||
        estado is! bool ||
        (porcentaje != null && porcentaje is! num) ||
        (fecha != null && fecha is! String)) {
      throw const FormatException('El profesional recibido no es válido.');
    }
    final nacimiento = fecha is String ? DateTime.tryParse(fecha) : null;
    if (fecha != null && nacimiento == null) {
      throw const FormatException('Fecha de nacimiento no válida.');
    }
    var nombreEspecialidad = 'Especialidad #$especialidadId';
    if (relacion is Map<String, dynamic> && relacion['nombre'] is String) {
      if (relacion['id'] != especialidadId) {
        throw const FormatException('Relación de especialidad no válida.');
      }
      nombreEspecialidad = relacion['nombre'] as String;
    }
    return Profesional(
      id: id,
      documento: documento,
      nombres: nombres,
      apellidos: apellidos as String? ?? '',
      especialidadId: especialidadId,
      nombreEspecialidad: nombreEspecialidad,
      estado: estado,
      fechaNacimiento: nacimiento,
      porcentaje: porcentaje == null ? null : (porcentaje as num).toDouble(),
    );
  }

  String get nombreCompleto => '$nombres $apellidos'.trim();

  String get nacimientoTexto {
    final fecha = fechaNacimiento;
    if (fecha == null) return 'Sin registrar';
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }
}
