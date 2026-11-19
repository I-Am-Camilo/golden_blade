import 'reserva.dart';

class ResumenPanel {
  const ResumenPanel({
    required this.reservasHoy,
    required this.totalClientes,
    required this.completadasHoy,
    required this.valorCompletadas,
  });

  final int reservasHoy;
  final int totalClientes;
  final int completadasHoy;
  // null significa que falta algún precio, no que el valor sea cero.
  final int? valorCompletadas;

  factory ResumenPanel.calcular(
    List<Reserva> reservas,
    int totalClientes,
    DateTime hoy,
  ) {
    final delDia = reservas
        .where(
          (r) =>
              r.fecha.year == hoy.year &&
              r.fecha.month == hoy.month &&
              r.fecha.day == hoy.day,
        )
        .toList();
    final completadas = delDia.where((r) => r.estado == 2).toList();
    int? valor = 0;
    for (final reserva in completadas) {
      if (reserva.precio == null || reserva.precio! < 0) {
        valor = null;
        break;
      }
      valor = valor! + reserva.precio!;
    }
    return ResumenPanel(
      reservasHoy: delDia.length,
      totalClientes: totalClientes,
      completadasHoy: completadas.length,
      valorCompletadas: valor,
    );
  }
}
