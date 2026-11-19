class Comision {
  const Comision({required this.datos});
  final Map<String, dynamic> datos;

  int? get id {
    final valor = datos['id'];
    return valor is int && valor > 0 ? valor : null;
  }
}
