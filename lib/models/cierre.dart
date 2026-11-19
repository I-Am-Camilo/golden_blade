class Cierre {
  const Cierre({
    required this.id,
    required this.inicio,
    required this.fin,
    required this.totalFacturado,
    required this.subtotalComisionNegocio,
    required this.subtotalComisionProfesionales,
  });

  final int id;
  final DateTime inicio;
  final DateTime fin;
  final num totalFacturado;
  final num subtotalComisionNegocio;
  final num subtotalComisionProfesionales;

  factory Cierre.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final inicio = json['fechaInicio'];
    final fin = json['fechaFin'];
    final total = json['totalFacturado'];
    final negocio = json['subtotalComisionNegocio'];
    final profesionales = json['subtotalComisionProfesionales'];
    if (id is! int ||
        id <= 0 ||
        inicio is! String ||
        fin is! String ||
        total is! num ||
        !total.isFinite ||
        negocio is! num ||
        !negocio.isFinite ||
        profesionales is! num ||
        !profesionales.isFinite) {
      throw const FormatException('El cierre recibido no es válido.');
    }
    final fechaInicio = DateTime.tryParse(inicio);
    final fechaFin = DateTime.tryParse(fin);
    if (fechaInicio == null ||
        fechaFin == null ||
        fechaFin.isBefore(fechaInicio)) {
      throw const FormatException('El período del cierre no es válido.');
    }
    return Cierre(
      id: id,
      inicio: fechaInicio,
      fin: fechaFin,
      totalFacturado: total,
      subtotalComisionNegocio: negocio,
      subtotalComisionProfesionales: profesionales,
    );
  }

  static String pesos(num valor) {
    final partes = valor.toStringAsFixed(2).split('.');
    final entero = partes.first.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (coincidencia) => '${coincidencia[1]}.',
    );
    return '$entero,${partes.last} COP';
  }
}
