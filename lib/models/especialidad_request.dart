class EspecialidadRequest {
  const EspecialidadRequest({required this.nombre});

  final String nombre;

  Map<String, dynamic> toJson() => {'nombre': nombre};
}
