// Crear y editar utilizan el mismo cuerpo verificado: únicamente nombre.
class EspecialidadRequest {
  const EspecialidadRequest({required this.nombre});

  final String nombre;

  Map<String, dynamic> toJson() => {'nombre': nombre};
}
