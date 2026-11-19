class Servicio {
  const Servicio({
    required this.id,
    required this.nombre,
    required this.especialidadId,
    required this.precio,
    required this.duracion,
    required this.activo,
    this.descripcion = '',
  });

  final int id;
  final String nombre;
  final int especialidadId;
  final int precio;
  final int duracion;
  final bool activo;
  final String descripcion;

  factory Servicio.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final nombre = json['nombre'];
    final especialidadId = json['especialidadId'];
    final precio = json['precio'];
    final duracion = json['duracion'];
    final activo = json['activo'];
    final descripcion = json['descripcion'];
    if (id is! int ||
        nombre is! String ||
        especialidadId is! int ||
        precio is! int ||
        duracion is! int ||
        activo is! bool ||
        (descripcion != null && descripcion is! String)) {
      throw const FormatException('El servicio recibido no es válido.');
    }
    return Servicio(
      id: id,
      nombre: nombre,
      especialidadId: especialidadId,
      precio: precio,
      duracion: duracion,
      activo: activo,
      descripcion: descripcion as String? ?? '',
    );
  }

  String get precioTexto {
    var monto = precio.toString();
    for (var i = monto.length - 3; i > 0; i -= 3) {
      monto = '${monto.substring(0, i)}.${monto.substring(i)}';
    }
    return '\$$monto';
  }
}
