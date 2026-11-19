class CrearServicioRequest {
  const CrearServicioRequest({
    required this.nombre,
    required this.precio,
    required this.duracion,
    required this.especialidad,
    required this.descripcion,
  });

  final String nombre;
  final int precio;
  final int duracion;
  final int especialidad;
  final String descripcion;

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'precio': precio,
    'duracion': duracion,
    'especialidad': especialidad,
    'descripcion': descripcion,
  };
}
