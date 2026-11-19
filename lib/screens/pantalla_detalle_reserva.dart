import 'package:flutter/material.dart';

import '../models/reserva.dart';
import '../routes/app_routes.dart';
import '../services/reserva_service.dart';
import '../theme/app_colors.dart';

class PantallaDetalleReserva extends StatefulWidget {
  const PantallaDetalleReserva({
    super.key,
    required this.reserva,
    this.servicioApi,
  });
  final Reserva reserva;
  final ReservaService? servicioApi;
  @override
  State<PantallaDetalleReserva> createState() => _PantallaDetalleReservaState();
}

class _PantallaDetalleReservaState extends State<PantallaDetalleReserva> {
  late final ReservaService _api;
  late Future<Reserva> _consulta;
  @override
  void initState() {
    super.initState();
    _api = widget.servicioApi ?? ReservaService();
    _consulta = _api.obtener(widget.reserva.id);
  }

  @override
  void dispose() {
    if (widget.servicioApi == null) _api.cerrar();
    super.dispose();
  }

  void _recargar() {
    setState(() {
      _consulta = _api.obtener(widget.reserva.id);
    });
  }

  Future<void> _abrir(String ruta, Reserva reserva) async {
    await Navigator.pushNamed(context, ruta, arguments: reserva);
    if (mounted) _recargar();
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: ThemeData.light(),
    child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Detalle de reserva'),
        actions: [
          IconButton(
            tooltip: 'Actualizar reserva',
            onPressed: _recargar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: 520,
            child: FutureBuilder<Reserva>(
              future: _consulta,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  final error = snapshot.error;
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            error is ReservaException
                                ? error.mensaje
                                : 'No fue posible consultar la reserva.',
                            textAlign: TextAlign.center,
                          ),
                          TextButton(
                            onPressed: _recargar,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final reserva = snapshot.data!;
                final fecha = MaterialLocalizations.of(context)
                    .formatCompactDate(reserva.fecha);
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _dato(
                      Icons.confirmation_number_outlined,
                      'Reserva',
                      'ID ${reserva.id}',
                    ),
                    _dato(Icons.event_available, 'Estado', reserva.estadoTexto),
                    _dato(
                      Icons.person_outline,
                      'Cliente',
                      '${reserva.cliente} · ID ${reserva.clienteId}',
                    ),
                    _dato(
                      Icons.content_cut,
                      'Servicio',
                      '${reserva.servicio} · ID ${reserva.servicioId}',
                    ),
                    _dato(
                      Icons.badge_outlined,
                      'Profesional asignado',
                      reserva.profesionalId == null
                          ? 'Sin asignar'
                          : '${reserva.profesional} · ID ${reserva.profesionalId}',
                    ),
                    _dato(
                      Icons.schedule,
                      'Fecha y hora',
                      '$fecha · ${reserva.horaInicio} – ${reserva.horaFin}',
                    ),
                    if (reserva.precio != null)
                      _dato(
                        Icons.payments_outlined,
                        'Precio del servicio',
                        '${reserva.precio} COP',
                      ),
                    const SizedBox(height: 16),
                    if (reserva.estado == 0 || reserva.estado == 3) ...[
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                        ),
                        onPressed: () =>
                            _abrir(AppRoutes.rescheduleReservation, reserva),
                        child: const Text('Reagendar reserva'),
                      ),
                      OutlinedButton(
                        onPressed: () =>
                            _abrir(AppRoutes.cancelReservation, reserva),
                        child: const Text(
                          'Cancelar reserva',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
  Widget _dato(IconData icono, String etiqueta, String valor) => ListTile(
    leading: Icon(icono, color: AppColors.buttonGoldDark),
    title: Text(etiqueta),
    subtitle: Text(valor),
  );
}
