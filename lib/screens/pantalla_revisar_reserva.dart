import 'package:flutter/material.dart';

import '../models/servicio.dart';
import '../models/cliente.dart';
import '../models/crear_reserva_request.dart';
import '../services/reserva_service.dart';
import '../services/disponibilidad_service.dart';
import '../services/cliente_service.dart';
import '../services/servicio_service.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';

class PantallaRevisarReserva extends StatefulWidget {
  const PantallaRevisarReserva({
    super.key,
    required this.client,
    required this.service,
    required this.professionalLabel,
    required this.appointment,
    this.profesionalId,
    this.reservaApi,
    this.disponibilidadApi,
    this.clienteApi,
    this.servicioApi,
  });

  final Cliente client;
  final Servicio service;
  final String professionalLabel;
  final DateTime appointment;
  final int? profesionalId;
  final ReservaService? reservaApi;
  final DisponibilidadService? disponibilidadApi;
  final ClienteService? clienteApi;
  final ServicioService? servicioApi;

  @override
  State<PantallaRevisarReserva> createState() => _PantallaRevisarReservaState();
}

class _PantallaRevisarReservaState extends State<PantallaRevisarReserva> {
  late final ReservaService _reservas;
  late final DisponibilidadService _disponibilidad;
  late final ClienteService _clientes;
  late final ServicioService _servicios;
  bool _enviando = false;
  bool _terminada = false;
  bool _resultadoIncierto = false;
  bool _horaOcupada = false;
  int? _idCreada;
  String? _error;
  @override
  void initState() {
    super.initState();
    _reservas = widget.reservaApi ?? ReservaService();
    _disponibilidad = widget.disponibilidadApi ?? DisponibilidadService();
    _clientes = widget.clienteApi ?? ClienteService();
    _servicios = widget.servicioApi ?? ServicioService();
  }

  @override
  void dispose() {
    _reservas.cerrar();
    _disponibilidad.cerrar();
    _clientes.cerrar();
    _servicios.cerrar();
    super.dispose();
  }

  Future<void> _confirmar() async {
    if (_enviando || _terminada || _resultadoIncierto || _horaOcupada) return;
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      if (_idCreada == null) {
        if (widget.client.id <= 0 ||
            widget.service.id <= 0 ||
            widget.appointment.isBefore(DateTime.now())) {
          throw const ReservaException(
            'Selecciona un cliente, servicio y una hora futura.',
          );
        }
        if (widget.profesionalId != null) {
          throw const ReservaException(
            'Esta operación utiliza asignación automática. Vuelve a seleccionar el horario.',
          );
        }
        final cliente = await _clientes.buscarPorDocumento(
          widget.client.documento,
        );
        if (cliente.id != widget.client.id ||
            cliente.nombreCompleto != widget.client.nombreCompleto) {
          throw const ReservaException(
            'Los datos del cliente cambiaron. Vuelve a seleccionarlo.',
          );
        }
        final servicio = await _servicios.obtener(widget.service.id);
        if (!servicio.activo ||
            servicio.especialidadId != widget.service.especialidadId ||
            servicio.precio != widget.service.precio ||
            servicio.duracion != widget.service.duracion ||
            servicio.nombre != widget.service.nombre) {
          throw const ReservaException(
            'El servicio cambió o está inactivo. Vuelve a seleccionarlo.',
          );
        }
        final horas = await _disponibilidad.consultar(
          fecha: widget.appointment,
          servicioId: servicio.id,
        );
        if (!horas.contains(widget.appointment)) {
          _horaOcupada = true;
          throw const ReservaException(
            'Ese horario ya no está disponible. Vuelve a elegir fecha y hora.',
          );
        }
        _idCreada = await _reservas.crear(
          CrearReservaRequest(
            fecha: widget.appointment,
            servicioId: servicio.id,
            clienteId: cliente.id,
          ),
        );
      }
      final reserva = await _reservas.obtener(_idCreada!);
      if (reserva.clienteId != widget.client.id ||
          reserva.servicioId != widget.service.id ||
          reserva.cita != widget.appointment) {
        throw const ReservaException(
          'Los datos devueltos no corresponden a la reserva solicitada. Revisa la agenda.',
        );
      }
      if (!mounted) return;
      _terminada = true;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.reservationCreated,
        ModalRoute.withName(AppRoutes.adminPanel),
        arguments: reserva,
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          if (error is ReservaException && error.resultadoIncierto) {
            _resultadoIncierto = true;
          }
          final mensaje = error is ReservaException
              ? error.mensaje
              : error is ClienteException
              ? error.mensaje
              : error is ServicioException
              ? error.mensaje
              : error is DisponibilidadException
              ? error.mensaje
              : 'No fue posible completar la operación.';
          if (_idCreada != null) {
            _error =
                'La reserva #$_idCreada fue registrada, pero no se pudo consultar su detalle. $mensaje';
          } else if (_resultadoIncierto) {
            _error =
                'No pudimos confirmar si la reserva se guardó. Consulta la agenda antes de volver a intentarlo. $mensaje';
          } else {
            _error = mensaje;
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _enviando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final date = MaterialLocalizations.of(context)
        .formatCompactDate(widget.appointment);
    final time = TimeOfDay.fromDateTime(widget.appointment).format(context);

    return Theme(
      data: ThemeData.light(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text('Revisar la reserva'),
        ),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 520,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _detail(
                    Icons.person_outline,
                    'Cliente',
                    widget.client.nombreCompleto,
                  ),
                  _detail(Icons.content_cut, 'Servicio', service.nombre),
                  _detail(
                    Icons.payments_outlined,
                    'Precio',
                    service.precioTexto,
                  ),
                  _detail(
                    Icons.timer_outlined,
                    'Duración',
                    '${service.duracion} min',
                  ),
                  _detail(
                    Icons.badge_outlined,
                    'Profesional',
                    'Asignación automática del profesional',
                  ),
                  _detail(
                    Icons.event_outlined,
                    'Fecha y hora',
                    '$date · $time',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Esta operación no registra medios de pago ni realiza cobros.',
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  if (_idCreada != null || _resultadoIncierto)
                    OutlinedButton(
                      onPressed: _enviando
                          ? null
                          : () => Navigator.pushReplacementNamed(
                              context,
                              AppRoutes.agenda,
                              arguments: widget.appointment,
                            ),
                      child: const Text('Consultar la agenda'),
                    ),
                  if (_horaOcupada)
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Volver a elegir horario'),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                    ),
                    onPressed:
                        _enviando ||
                            _terminada ||
                            _resultadoIncierto ||
                            _horaOcupada
                        ? null
                        : _confirmar,
                    child: Text(
                      _enviando
                          ? 'Confirmando...'
                          : _idCreada != null
                          ? 'Consultar reserva creada'
                          : 'Confirmar reserva',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detail(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: AppColors.buttonGoldDark),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}
