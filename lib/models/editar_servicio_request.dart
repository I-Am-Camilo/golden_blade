class EditarServicioRequest {
  const EditarServicioRequest({
    required this.nombre,
    required this.precio,
    required this.duracion,
    required this.activo,
  });

  final String nombre;
  final int precio;
  final int duracion;
  final bool activo;

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'precio': precio,
    'duracion': duracion,
    'activo': activo,
  };
}
