class Inasistencia {
  const Inasistencia({
    required this.id,
    required this.profesionalId,
    required this.fechaInicio,
    required this.fechaFin,
    required this.motivo,
    this.observacion = '',
  });
  final int id;
  final int profesionalId;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final int motivo;
  final String observacion;
  factory Inasistencia.fromJson(Map<String, dynamic> json) {
    if (json['id'] is! int ||
        json['profesionalId'] is! int ||
        json['fechaInicio'] is! String ||
        json['fechaFin'] is! String ||
        json['motivo'] is! int ||
        (json['observacion'] != null && json['observacion'] is! String)) {
      throw const FormatException('La inasistencia recibida no es válida.');
    }
    final inicio = DateTime.tryParse(json['fechaInicio'] as String);
    final fin = DateTime.tryParse(json['fechaFin'] as String);
    if (inicio == null || fin == null || !fin.isAfter(inicio)) {
      throw const FormatException('Período de inasistencia no válido.');
    }
    return Inasistencia(
      id: json['id'] as int,
      profesionalId: json['profesionalId'] as int,
      fechaInicio: inicio,
      fechaFin: fin,
      motivo: json['motivo'] as int,
      observacion: json['observacion'] as String? ?? '',
    );
  }
  bool get diaCompleto =>
      fechaInicio.hour == 0 &&
      fechaInicio.minute == 0 &&
      fechaInicio.second == 0 &&
      fechaFin.hour == 23 &&
      fechaFin.minute == 59 &&
      fechaFin.second == 59;
  String get motivoTexto => 'Código $motivo';
}
