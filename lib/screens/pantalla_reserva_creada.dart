import 'package:flutter/material.dart';

import '../models/reserva.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';

class PantallaReservaCreada extends StatefulWidget {
  const PantallaReservaCreada({super.key, required this.reserva});

  final Reserva reserva;

  @override
  State<PantallaReservaCreada> createState() => _PantallaReservaCreadaState();
}

class _PantallaReservaCreadaState extends State<PantallaReservaCreada> {
  Future<void> _openDetail() async {
    await Navigator.of(context)
        .pushNamed(AppRoutes.reservationDetail, arguments: widget.reserva);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final reservation = widget.reserva;
    final date = MaterialLocalizations.of(context)
        .formatCompactDate(reservation.cita);
    final time = TimeOfDay.fromDateTime(reservation.cita).format(context);
    return Theme(
      data: ThemeData.light(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Reserva creada'),
          backgroundColor: Colors.white,
        ),
        body: SafeArea(
          child: Center(
            child: SizedBox(
              width: 480,
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(24),
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: AppColors.buttonGoldDark,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    reservation.cliente,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Reserva #${reservation.id}',
                    textAlign: TextAlign.center,
                  ),
                  Text(reservation.servicio, textAlign: TextAlign.center),
                  Text(
                    reservation.profesionalId == null
                        ? 'Profesional sin asignar'
                        : 'Profesional: ${reservation.profesional}',
                    textAlign: TextAlign.center,
                  ),
                  Text('$date · $time', textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                    ),
                    onPressed: () => Navigator.of(context).pushReplacementNamed(
                      AppRoutes.agenda,
                      arguments: reservation.cita,
                    ),
                    child: const Text('Ver agenda'),
                  ),
                  OutlinedButton(
                    onPressed: _openDetail,
                    child: const Text('Ver detalle'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
