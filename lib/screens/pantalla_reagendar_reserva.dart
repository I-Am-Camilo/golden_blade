import 'package:flutter/material.dart';

import '../models/profesional.dart';
import '../models/reserva.dart';
import '../services/disponibilidad_service.dart';
import '../services/profesional_service.dart';
import '../services/reserva_service.dart';
import '../services/servicio_service.dart';
import '../theme/app_colors.dart';

class PantallaReagendarReserva extends StatefulWidget {
  const PantallaReagendarReserva({
    super.key,
    required this.reserva,
    this.servicioApi,
    this.profesionalApi,
    this.catalogoApi,
    this.disponibilidadApi,
  });
  final Reserva reserva;
  final ReservaService? servicioApi;
  final ProfesionalService? profesionalApi;
  final ServicioService? catalogoApi;
  final DisponibilidadService? disponibilidadApi;

  @override
  State<PantallaReagendarReserva> createState() =>
      _PantallaReagendarReservaState();
}

class _PantallaReagendarReservaState extends State<PantallaReagendarReserva> {
  late final ReservaService _api;
  late final ProfesionalService _profesionales;
  late final ServicioService _servicios;
  late final DisponibilidadService _disponibilidad;
  late Future<List<Profesional>> _consulta;
  late DateTime _fecha;
  int? _profesionalId;
  Future<List<DateTime>>? _horas;
  DateTime? _hora;
  bool _guardando = false;
  bool _consultarAntesDeRepetir = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = widget.servicioApi ?? ReservaService();
    _profesionales = widget.profesionalApi ?? ProfesionalService();
    _servicios = widget.catalogoApi ?? ServicioService();
    _disponibilidad = widget.disponibilidadApi ?? DisponibilidadService();
    _fecha = DateUtils.dateOnly(widget.reserva.cita);
    final hoy = DateUtils.dateOnly(DateTime.now());
    if (_fecha.isBefore(hoy)) _fecha = hoy;
    _consulta = _cargarProfesionales();
  }

  Future<List<Profesional>> _cargarProfesionales() async {
    final servicio = await _servicios.obtener(widget.reserva.servicioId);
    final respuesta = await _profesionales.listar(soloActivos: true);
    return respuesta.data
        .where((p) => p.estado && p.especialidadId == servicio.especialidadId)
        .toList();
  }

  @override
  void dispose() {
    if (widget.servicioApi == null) _api.cerrar();
    if (widget.profesionalApi == null) _profesionales.cerrar();
    if (widget.catalogoApi == null) _servicios.cerrar();
    if (widget.disponibilidadApi == null) _disponibilidad.cerrar();
    super.dispose();
  }

  void _consultarHoras() {
    setState(() {
      _hora = null;
      _error = null;
      final id = _profesionalId;
      _horas = id == null
          ? null
          : _disponibilidad.consultar(
              fecha: _fecha,
              servicioId: widget.reserva.servicioId,
              profesionalId: id,
            );
    });
  }

  Future<void> _elegirFecha() async {
    final hoy = DateUtils.dateOnly(DateTime.now());
    final limite = DateTime(hoy.year + 2, hoy.month, hoy.day);
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: hoy,
      lastDate: _fecha.isAfter(limite) ? _fecha : limite,
    );
    if (!mounted || fecha == null) return;
    _fecha = fecha;
    _consultarHoras();
  }

  Future<void> _guardar() async {
    if (_guardando) return;
    final hora = _hora;
    final profesional = _profesionalId;
    if (hora == null || profesional == null) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      if (!hora.isAfter(DateTime.now())) {
        throw const ReservaException('Elige una fecha y hora futuras.');
      }
      if (hora == widget.reserva.cita &&
          profesional == widget.reserva.profesionalId) {
        throw const ReservaException('Elige otra hora o profesional.');
      }
      final actual = await _api.obtener(widget.reserva.id);
      if (actual.estado != 0 && actual.estado != 3) {
        throw const ReservaException(
          'Esta reserva ya no admite cambios. Vuelve al detalle.',
        );
      }
      if (actual.clienteId != widget.reserva.clienteId ||
          actual.servicioId != widget.reserva.servicioId) {
        throw const ReservaException(
          'La reserva cambió. Vuelve al detalle para actualizarla.',
        );
      }
      final profesionales = await _cargarProfesionales();
      if (!profesionales.any((p) => p.id == profesional)) {
        throw const ReservaException(
          'El profesional ya no está disponible en esta especialidad.',
        );
      }
      final disponibles = await _disponibilidad.consultar(
        fecha: hora,
        servicioId: actual.servicioId,
        profesionalId: profesional,
      );
      if (!disponibles.contains(hora)) {
        throw const ReservaException(
          'La hora ya no está disponible. Actualiza las horas.',
        );
      }
      await _api.reagendar(actual.id, hora, profesional);

      _consultarAntesDeRepetir = true;
      final guardada = await _api.obtener(actual.id);
      if (guardada.clienteId != actual.clienteId ||
          guardada.servicioId != actual.servicioId ||
          guardada.profesionalId != profesional ||
          guardada.cita != hora ||
          guardada.estado != 3) {
        throw const ReservaException(
          'Revisa el detalle: los datos devueltos no coinciden con el cambio solicitado.',
        );
      }
      if (mounted) Navigator.pop(context, true);
    } on ReservaException catch (error) {
      if (error.resultadoIncierto) _consultarAntesDeRepetir = true;
      if (mounted) {
        setState(() {
          _error = error.mensaje;
        });
      }
    } on DisponibilidadException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.mensaje;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'No fue posible verificar el cambio. Revisa el detalle antes de repetirlo.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: ThemeData.light(),
    child: PopScope(
      canPop: !_guardando,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('Reagendar reserva')),
        body: SafeArea(
          child: Center(
            child: SizedBox(
              width: 520,
              child: FutureBuilder<List<Profesional>>(
                future: _consulta,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'No se pudieron consultar los profesionales.',
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _consulta = _cargarProfesionales();
                            });
                          },
                          child: const Text('Reintentar'),
                        ),
                      ],
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(widget.reserva.cliente),
                      Text(widget.reserva.servicio),
                      const Text(
                        'Se conservan el cliente y el servicio de la reserva.',
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        initialValue: _profesionalId,
                        decoration: const InputDecoration(
                          labelText: 'Profesional',
                        ),
                        isExpanded: true,
                        items: [
                          for (final p in snapshot.data!)
                            DropdownMenuItem(
                              value: p.id,
                              child: Text(
                                p.nombreCompleto,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: _guardando || _consultarAntesDeRepetir
                            ? null
                            : (id) {
                                _profesionalId = id;
                                _consultarHoras();
                              },
                      ),
                      if (snapshot.data!.isEmpty)
                        const Text(
                          'No hay profesionales activos para esta especialidad.',
                        ),
                      ListTile(
                        title: const Text('Nueva fecha'),
                        subtitle: Text(
                          MaterialLocalizations.of(context)
                              .formatCompactDate(_fecha),
                        ),
                        trailing: const Icon(Icons.calendar_today_outlined),
                        onTap: _guardando || _consultarAntesDeRepetir
                            ? null
                            : _elegirFecha,
                      ),
                      if (_horas != null)
                        FutureBuilder<List<DateTime>>(
                          future: _horas,
                          builder: (context, horas) {
                            if (horas.connectionState != ConnectionState.done) {
                              return const LinearProgressIndicator();
                            }
                            if (horas.hasError) {
                              return const Text(
                                'No fue posible consultar la disponibilidad.',
                              );
                            }
                            final disponibles = horas.data!
                                .where((h) => h.isAfter(DateTime.now()))
                                .toList();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Horas disponibles'),
                                if (disponibles.isEmpty)
                                  const Text(
                                    'No hay horas disponibles en esta fecha.',
                                  ),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    for (final h in disponibles)
                                      ChoiceChip(
                                        label: Text(
                                          TimeOfDay.fromDateTime(h)
                                              .format(context),
                                        ),
                                        selected: _hora == h,
                                        selectedColor: AppColors.goldAccent,
                                        onSelected:
                                            _guardando ||
                                                _consultarAntesDeRepetir
                                            ? null
                                            : (_) {
                                                setState(() {
                                                  _hora = h;
                                                });
                                              },
                                      ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      TextButton(
                        onPressed: _guardando || _consultarAntesDeRepetir
                            ? null
                            : _consultarHoras,
                        child: const Text('Actualizar horas'),
                      ),
                      if (_error != null)
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      if (_guardando) const LinearProgressIndicator(),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                        ),
                        onPressed:
                            _guardando ||
                                _consultarAntesDeRepetir ||
                                _hora == null
                            ? null
                            : _guardar,
                        child: const Text('Guardar cambios'),
                      ),
                      TextButton(
                        onPressed: _guardando
                            ? null
                            : () => Navigator.pop(context, true),
                        child: Text(
                          _consultarAntesDeRepetir
                              ? 'Volver y consultar reserva'
                              : 'Volver sin guardar',
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
