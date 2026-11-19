class Especialidad {
  const Especialidad({
    required this.id,
    required this.nombre,
    required this.activa,
  });

  final int id;
  final String nombre;
  final bool activa;

  factory Especialidad.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final nombre = json['nombre'];
    final activa = json['activa'];
    if (id is! int || nombre is! String || activa is! bool) {
      throw const FormatException('La especialidad recibida no es válida.');
    }
    return Especialidad(id: id, nombre: nombre, activa: activa);
  }
}
