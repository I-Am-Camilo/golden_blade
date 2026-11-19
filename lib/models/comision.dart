// Conserva los campos recibidos; no completa importes ni porcentajes ausentes.
class Comision {
  const Comision({required this.datos});
  final Map<String, dynamic> datos;

  // Solo permite abrir servicios cuando el propio registro identifica su ID.
  int? get id {
    final valor = datos['id'];
    return valor is int && valor > 0 ? valor : null;
  }
}
