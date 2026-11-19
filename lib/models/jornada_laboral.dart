class JornadaLaboral {
  const JornadaLaboral({
    required this.id,
    required this.profesionalId,
    required this.diaSemana,
    required this.horaInicio,
    required this.horaFin,
    required this.tieneAlmuerzo,
    this.horaInicioAlmuerzo,
    this.horaFinAlmuerzo,
  });
  final int id;
  final int profesionalId;
  final int diaSemana;
  final String horaInicio;
  final String horaFin;
  final bool tieneAlmuerzo;
  final String? horaInicioAlmuerzo;
  final String? horaFinAlmuerzo;
  // La API utiliza 0 para domingo y 1 para lunes.
  static const dias = [
    'Domingo',
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
  ];
  factory JornadaLaboral.fromJson(Map<String, dynamic> json) {
    if (json['id'] is! int ||
        json['profesionalId'] is! int ||
        json['diaSemana'] is! int ||
        (json['diaSemana'] as int) < 0 ||
        (json['diaSemana'] as int) > 6 ||
        json['horaInicio'] is! String ||
        json['horaFin'] is! String ||
        json['tieneAlmuerzo'] is! bool ||
        (json['horaInicioAlmuerzo'] != null &&
            json['horaInicioAlmuerzo'] is! String) ||
        (json['horaFinAlmuerzo'] != null &&
            json['horaFinAlmuerzo'] is! String)) {
      throw const FormatException('La jornada recibida no es válida.');
    }
    validarHora(json['horaInicio'] as String);
    validarHora(json['horaFin'] as String);
    final inicioAlmuerzo = json['horaInicioAlmuerzo'] as String?;
    final finAlmuerzo = json['horaFinAlmuerzo'] as String?;
    if (inicioAlmuerzo != null) validarHora(inicioAlmuerzo);
    if (finAlmuerzo != null) validarHora(finAlmuerzo);
    if (json['tieneAlmuerzo'] == true &&
        (inicioAlmuerzo == null || finAlmuerzo == null)) {
      throw const FormatException('Almuerzo incompleto.');
    }
    return JornadaLaboral(
      id: json['id'] as int,
      profesionalId: json['profesionalId'] as int,
      diaSemana: json['diaSemana'] as int,
      horaInicio: json['horaInicio'] as String,
      horaFin: json['horaFin'] as String,
      tieneAlmuerzo: json['tieneAlmuerzo'] as bool,
      horaInicioAlmuerzo: inicioAlmuerzo,
      horaFinAlmuerzo: finAlmuerzo,
    );
  }
  static void validarHora(String texto) {
    final partes = texto.split(':');
    if (partes.length != 3) throw const FormatException('Hora no válida.');
    final hora = int.tryParse(partes[0]);
    final minuto = int.tryParse(partes[1]);
    final segundo = double.tryParse(partes[2]);
    if (hora == null ||
        minuto == null ||
        segundo == null ||
        hora < 0 ||
        hora > 23 ||
        minuto < 0 ||
        minuto > 59 ||
        !segundo.isFinite ||
        segundo < 0 ||
        segundo >= 60) {
      throw const FormatException('Hora no válida.');
    }
  }
}
