import 'package:flutter/material.dart';

import '../models/servicio.dart';
import '../models/cliente.dart';
import '../models/profesional.dart';
import '../routes/app_routes.dart';
import '../services/disponibilidad_service.dart';
import '../theme/app_colors.dart';

class PantallaSeleccionarFechaHora extends StatefulWidget {
  const PantallaSeleccionarFechaHora({
    super.key,
    required this.client,
    required this.service,
    required this.professionals,
    required this.professionalLabel,
    this.servicioApi,
  });
  final Cliente client;
  final Servicio service;
  final List<Profesional> professionals;
  final String professionalLabel;
  final DisponibilidadService? servicioApi;
  @override
  State<PantallaSeleccionarFechaHora> createState() =>
      _PantallaSeleccionarFechaHoraState();
}

class _PantallaSeleccionarFechaHoraState
    extends State<PantallaSeleccionarFechaHora> {
  late final DisponibilidadService _api;
  late Future<List<DateTime>> _consulta;
  DateTime _fecha = DateUtils.dateOnly(DateTime.now());
  DateTime? _seleccion;
  bool _revisando = false;
  int? get _profesionalId =>
      widget.professionalLabel != 'Cualquiera' &&
          widget.professionals.length == 1
      ? widget.professionals.first.id
      : null;
  @override
  void initState() {
    super.initState();
    _api = widget.servicioApi ?? DisponibilidadService();
    _consulta = _consultar();
  }

  @override
  void dispose() {
    _api.cerrar();
    super.dispose();
  }

  Future<List<DateTime>> _consultar() async {
    if (widget.professionals.isEmpty) return [];
    if (widget.professionalLabel != 'Cualquiera' &&
        widget.professionals.length != 1) {
      throw const DisponibilidadException('Selecciona un profesional válido.');
    }
    final horas = await _api.consultar(
      fecha: _fecha,
      servicioId: widget.service.id,
      profesionalId: _profesionalId,
    );
    final ahora = DateTime.now();
    return horas.where((hora) => hora.isAfter(ahora)).toList();
  }

  void _recargar() {
    setState(() {
      _seleccion = null;
      _consulta = _consultar();
    });
  }

  Future<void> _abrirRevision() async {
    final hora = _seleccion;
    if (hora == null || _revisando) return;
    setState(() {
      _revisando = true;
    });
    try {
      final actuales = await _consultar();
      if (!mounted) return;
      setState(() {
        _consulta = Future.value(actuales);
      });
      if (!actuales.contains(hora)) {
        setState(() {
          _seleccion = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ese horario ya no está disponible. Selecciona otro.',
            ),
          ),
        );
        return;
      }
      await Navigator.pushNamed(
        context,
        AppRoutes.reservationReview,
        arguments: (
          widget.client,
          widget.service,
          widget.professionalLabel,
          hora,
          _profesionalId,
        ),
      );
      if (mounted) _recargar();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is DisponibilidadException
                  ? error.mensaje
                  : 'No fue posible confirmar la disponibilidad.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _revisando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hoy = DateUtils.dateOnly(DateTime.now());
    return Theme(
      data: ThemeData.light(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text('Seleccionar fecha y hora'),
          actions: [
            IconButton(
              tooltip: 'Actualizar disponibilidad',
              onPressed: _revisando ? null : _recargar,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: SizedBox(
              width: 520,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Cliente: ${widget.client.nombreCompleto}'),
                  Text('Servicio: ${widget.service.nombre}'),
                  Text(
                    'Profesional: ${widget.professionalLabel == 'Cualquiera' ? 'Asignación automática' : widget.professionalLabel}',
                  ),
                  AbsorbPointer(
                    absorbing: _revisando,
                    child: CalendarDatePicker(
                      initialDate: _fecha.isBefore(hoy) ? hoy : _fecha,
                      firstDate: hoy,
                      lastDate: DateTime(hoy.year + 1, hoy.month, hoy.day),
                      onDateChanged: (fecha) {
                        setState(() {
                          _fecha = fecha;
                          _seleccion = null;
                          _consulta = _consultar();
                        });
                      },
                    ),
                  ),
                  const Text('Horas disponibles'),
                  const SizedBox(height: 8),
                  FutureBuilder<List<DateTime>>(
                    future: _consulta,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        final error = snapshot.error;
                        return Column(
                          children: [
                            Text(
                              error is DisponibilidadException
                                  ? error.mensaje
                                  : 'No se pudo consultar la disponibilidad.',
                            ),
                            TextButton(
                              onPressed: _recargar,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        );
                      }
                      final horas = snapshot.data!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (horas.isEmpty)
                            const Text(
                              'No hay horarios disponibles para esta fecha.',
                            ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final hora in horas)
                                ChoiceChip(
                                  label: Text(
                                    TimeOfDay.fromDateTime(hora)
                                        .format(context),
                                  ),
                                  selected: _seleccion == hora,
                                  selectedColor: AppColors.goldAccent,
                                  onSelected: _revisando
                                      ? null
                                      : (_) {
                                          setState(() {
                                            _seleccion = hora;
                                          });
                                        },
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.onPrimary,
                            ),
                            onPressed: !_revisando && horas.contains(_seleccion)
                                ? _abrirRevision
                                : null,
                            child: Text(
                              _revisando ? 'Comprobando...' : 'Revisar reserva',
                            ),
                          ),
                        ],
                      );
                    },
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
