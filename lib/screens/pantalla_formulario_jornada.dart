import 'package:flutter/material.dart';

import '../models/jornada_laboral.dart';
import '../models/crear_jornada_request.dart';
import '../models/editar_jornada_request.dart';
import '../services/jornada_service.dart';
import '../theme/app_colors.dart';

class PantallaFormularioJornada extends StatefulWidget {
  const PantallaFormularioJornada({
    super.key,
    required this.profesionalId,
    required this.diaSemana,
    this.jornada,
    this.servicioApi,
  });

  final int profesionalId;
  final int diaSemana;
  final JornadaLaboral? jornada;
  final JornadaService? servicioApi;

  @override
  State<PantallaFormularioJornada> createState() =>
      _PantallaFormularioJornadaState();
}

class _PantallaFormularioJornadaState extends State<PantallaFormularioJornada> {
  late TimeOfDay _inicio;
  late TimeOfDay _fin;
  late TimeOfDay _inicioAlmuerzo;
  late TimeOfDay _finAlmuerzo;
  late bool _tieneAlmuerzo;
  late final JornadaService _api;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _api = widget.servicioApi ?? JornadaService();
    final jornada = widget.jornada;
    _inicio = jornada == null
        ? const TimeOfDay(hour: 8, minute: 0)
        : _leerHora(jornada.horaInicio);
    _fin = jornada == null
        ? const TimeOfDay(hour: 17, minute: 0)
        : _leerHora(jornada.horaFin);
    _inicioAlmuerzo = jornada?.horaInicioAlmuerzo == null
        ? const TimeOfDay(hour: 12, minute: 0)
        : _leerHora(jornada!.horaInicioAlmuerzo!);
    _finAlmuerzo = jornada?.horaFinAlmuerzo == null
        ? const TimeOfDay(hour: 13, minute: 0)
        : _leerHora(jornada!.horaFinAlmuerzo!);
    _tieneAlmuerzo = jornada?.tieneAlmuerzo ?? false;
  }

  TimeOfDay _leerHora(String texto) {
    final partes = texto.split(':');
    return TimeOfDay(hour: int.parse(partes[0]), minute: int.parse(partes[1]));
  }

  String _horaApi(TimeOfDay hora) =>
      '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}:00';
  int _minutos(TimeOfDay time) => time.hour * 60 + time.minute;

  @override
  void dispose() {
    if (widget.servicioApi == null) _api.cerrar();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_guardando) return;
    final start = _minutos(_inicio);
    final end = _minutos(_fin);
    final lunchStart = _minutos(_inicioAlmuerzo);
    final lunchEnd = _minutos(_finAlmuerzo);
    String? error;

    if (start >= end) {
      error = 'La hora de fin debe ser posterior al inicio.';
    } else if (_tieneAlmuerzo &&
        (lunchStart < start || lunchEnd > end || lunchStart >= lunchEnd)) {
      error = 'El almuerzo debe tener una duración válida y quedar dentro de la jornada.';
    }

    if (error != null) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _guardando = true;
    });
    try {
      final inicio = _horaApi(_inicio);
      final fin = _horaApi(_fin);
      final almuerzoInicio = _tieneAlmuerzo ? _horaApi(_inicioAlmuerzo) : null;
      final almuerzoFin = _tieneAlmuerzo ? _horaApi(_finAlmuerzo) : null;
      final JornadaLaboral guardada;
      if (widget.jornada == null) {
        guardada = await _api.crear(
          CrearJornadaRequest(
            profesionalId: widget.profesionalId,
            diaSemana: widget.diaSemana,
            horaInicio: inicio,
            horaFin: fin,
            tieneAlmuerzo: _tieneAlmuerzo,
            horaInicioAlmuerzo: almuerzoInicio,
            horaFinAlmuerzo: almuerzoFin,
          ),
        );
      } else {
        guardada = await _api.editar(
          widget.jornada!.id,
          EditarJornadaRequest(
            horaInicio: inicio,
            horaFin: fin,
            tieneAlmuerzo: _tieneAlmuerzo,
            horaInicioAlmuerzo: almuerzoInicio,
            horaFinAlmuerzo: almuerzoFin,
          ),
        );
      }
      if (guardada.profesionalId != widget.profesionalId ||
          guardada.diaSemana != widget.diaSemana) {
        throw const JornadaException(
          'La jornada recibida no corresponde al profesional y día seleccionados.',
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is JornadaException
                  ? error.mensaje
                  : 'No fue posible guardar la jornada.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  Widget _campoHora(
    String label,
    TimeOfDay time,
    ValueChanged<TimeOfDay> change,
  ) {
    return ListTile(
      title: Text(label),
      subtitle: Text(time.format(context)),
      trailing: const Icon(Icons.schedule),
      onTap: _guardando
          ? null
          : () async {
              final selected = await showTimePicker(
                context: context,
                initialTime: time,
              );
              if (mounted && selected != null) {
                setState(() => change(selected));
              }
            },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_guardando,
      child: Theme(
        data: ThemeData.light(),
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: Text(
              widget.jornada == null ? 'Agregar jornada' : 'Editar jornada',
            ),
          ),
          body: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 480,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      JornadaLaboral.dias[widget.diaSemana],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _campoHora(
                      'Hora de inicio',
                      _inicio,
                      (time) => _inicio = time,
                    ),
                    _campoHora('Hora de fin', _fin, (time) => _fin = time),
                    SwitchListTile(
                      title: const Text('Pausa de almuerzo'),
                      value: _tieneAlmuerzo,
                      activeTrackColor: AppColors.goldAccent,
                      onChanged: _guardando
                          ? null
                          : (value) => setState(() => _tieneAlmuerzo = value),
                    ),
                    if (_tieneAlmuerzo) ...[
                      _campoHora(
                        'Inicio del almuerzo',
                        _inicioAlmuerzo,
                        (time) => _inicioAlmuerzo = time,
                      ),
                      _campoHora(
                        'Fin del almuerzo',
                        _finAlmuerzo,
                        (time) => _finAlmuerzo = time,
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (_guardando) const LinearProgressIndicator(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        minimumSize: const Size(0, 48),
                      ),
                      onPressed: _guardando ? null : _guardar,
                      child: Text(_guardando ? 'Guardando...' : 'Guardar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
