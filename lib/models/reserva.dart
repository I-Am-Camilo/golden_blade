// Reserva real recibida por GET /Reservas y GET /Reservas/{id}.
class Reserva {
  const Reserva({
    required this.id,
    required this.clienteId,
    required this.servicioId,
    required this.fecha,
    required this.estado,
    required this.servicio,
    required this.profesional,
    required this.horaInicio,
    required this.horaFin,
    this.profesionalId,
    this.cliente = '',
    this.precio,
  });
  final String cliente;
  final int? precio;
  final int id;
  final int clienteId;
  final int servicioId;
  final int? profesionalId;
  final DateTime fecha;
  final int estado;
  final String servicio;
  final String profesional;
  final String horaInicio;
  final String horaFin;
  factory Reserva.fromJson(Map<String, dynamic> json) {
    if (json['id'] is! int ||
        json['clienteId'] is! int ||
        json['servicioId'] is! int ||
        (json['profesionalId'] != null && json['profesionalId'] is! int) ||
        json['fecha'] is! String ||
        json['estado'] is! int ||
        json['horaInicio'] is! String ||
        json['horaFin'] is! String) {
      throw const FormatException('La reserva del historial no es válida.');
    }
    final fecha = DateTime.tryParse(json['fecha'] as String);
    if (fecha == null) {
      throw const FormatException('Fecha de reserva no válida.');
    }
    final cliente = json['cliente'];
    final servicio = json['servicio'];
    _hora(json['horaInicio'] as String);
    _hora(json['horaFin'] as String);
    final profesional = json['profesional'];
    return Reserva(
      cliente: cliente is Map<String, dynamic>
          ? '${cliente['nombres'] ?? ''} ${cliente['apellidos'] ?? ''}'.trim()
          : 'Cliente #${json['clienteId']}',
      precio: servicio is Map<String, dynamic> && servicio['precio'] is int
          ? servicio['precio'] as int
          : null,
      id: json['id'] as int,
      clienteId: json['clienteId'] as int,
      servicioId: json['servicioId'] as int,
      profesionalId: json['profesionalId'] as int?,
      fecha: fecha,
      estado: json['estado'] as int,
      servicio: servicio is Map<String, dynamic> && servicio['nombre'] is String
          ? servicio['nombre'] as String
          : 'Servicio #${json['servicioId']}',
      profesional: profesional is Map<String, dynamic>
          ? '${profesional['nombres'] ?? ''} ${profesional['apellidos'] ?? ''}'
                .trim()
          : '',
      horaInicio: json['horaInicio'] as String,
      horaFin: json['horaFin'] as String,
    );
  }
  static List<int> _hora(String texto) {
    final partes = texto.split(':');
    if (partes.length != 3) {
      throw const FormatException('Hora de reserva no válida.');
    }
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
      throw const FormatException('Hora de reserva no válida.');
    }
    return [hora, minuto, segundo.toInt()];
  }

  DateTime get cita {
    final hora = _hora(horaInicio);
    return DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
      hora[0],
      hora[1],
      hora[2],
    );
  }

  static const estados = ['Agendada', 'Cancelada', 'Completada', 'Reagendada'];
  String get estadoTexto {
    return estado >= 0 && estado < estados.length
        ? estados[estado]
        : 'Estado $estado';
  }
}
