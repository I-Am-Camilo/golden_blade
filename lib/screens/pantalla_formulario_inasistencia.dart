import 'package:flutter/material.dart';

import '../models/inasistencia.dart';
import '../models/crear_inasistencia_request.dart';
import '../models/editar_inasistencia_request.dart';
import '../services/inasistencia_service.dart';
import '../theme/app_colors.dart';

class PantallaFormularioInasistencia extends StatefulWidget {
  const PantallaFormularioInasistencia({
    super.key,
    required this.profesionalId,
    this.inasistencia,
    this.servicioApi,
  });
  final int profesionalId;
  final Inasistencia? inasistencia;
  final InasistenciaService? servicioApi;
  @override
  State<PantallaFormularioInasistencia> createState() =>
      _PantallaFormularioInasistenciaState();
}

class _PantallaFormularioInasistenciaState
    extends State<PantallaFormularioInasistencia> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _observacion;
  late final InasistenciaService _api;
  DateTime? _inicio;
  DateTime? _fin;
  int? _motivo;
  bool _diaCompleto = true;
  bool _guardando = false;
  @override
  void initState() {
    super.initState();
    _api = widget.servicioApi ?? InasistenciaService();
    final registro = widget.inasistencia;
    _observacion = TextEditingController(text: registro?.observacion);
    _inicio = registro?.fechaInicio;
    _fin = registro?.fechaFin;
    _motivo = registro != null && registro.motivo >= 0 && registro.motivo <= 4
        ? registro.motivo
        : null;
    _diaCompleto = registro?.diaCompleto ?? true;
  }

  @override
  void dispose() {
    _observacion.dispose();
    if (widget.servicioApi == null) _api.cerrar();
    super.dispose();
  }

  Future<void> _fechas() async {
    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100, 12, 31),
      initialDateRange: _inicio == null || _fin == null
          ? null
          : DateTimeRange(
              start: DateUtils.dateOnly(_inicio!),
              end: DateUtils.dateOnly(_fin!),
            ),
    );
    if (!mounted || rango == null) return;
    setState(() {
      _inicio = DateTime(
        rango.start.year,
        rango.start.month,
        rango.start.day,
        _inicio?.hour ?? 8,
        _inicio?.minute ?? 0,
      );
      _fin = DateTime(
        rango.end.year,
        rango.end.month,
        rango.end.day,
        _fin?.hour ?? 17,
        _fin?.minute ?? 0,
      );
    });
  }

  Future<void> _hora(bool inicial) async {
    final actual = inicial ? _inicio : _fin;
    if (actual == null) {
      _mensaje('Selecciona primero las fechas.');
      return;
    }
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(actual),
    );
    if (!mounted || hora == null) return;
    setState(() {
      final fecha = DateTime(
        actual.year,
        actual.month,
        actual.day,
        hora.hour,
        hora.minute,
      );
      if (inicial) {
        _inicio = fecha;
      } else {
        _fin = fecha;
      }
    });
  }

  void _mensaje(String texto) {
    final mensajes = ScaffoldMessenger.of(context);
    mensajes.hideCurrentSnackBar();
    mensajes.showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _guardar() async {
    if (_guardando || !_formKey.currentState!.validate()) return;
    if (_inicio == null || _fin == null) {
      _mensaje('Selecciona las fechas de la inasistencia.');
      return;
    }
    final inicio = _diaCompleto ? DateUtils.dateOnly(_inicio!) : _inicio!;
    final fin = _diaCompleto
        ? DateTime(_fin!.year, _fin!.month, _fin!.day, 23, 59, 59)
        : _fin!;
    if (!fin.isAfter(inicio)) {
      _mensaje('El fin debe ser posterior al inicio.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _guardando = true;
    });
    try {
      if (widget.inasistencia == null) {
        final creados = await _api.crear(
          CrearInasistenciaRequest(
            profesionalId: widget.profesionalId,
            fechaInicio: inicio,
            fechaFin: fin,
            motivo: _motivo!,
            observacion: _observacion.text.trim(),
          ),
        );
        if (creados == 0) {
          throw const InasistenciaException(
            'La API omitió el período y no creó una inasistencia. Revisa si ya existe.',
          );
        }
      } else {
        final guardada = await _api.editar(
          widget.inasistencia!.id,
          EditarInasistenciaRequest(
            fechaInicio: inicio,
            fechaFin: fin,
            motivo: _motivo!,
            observacion: _observacion.text.trim(),
          ),
        );
        if (guardada.profesionalId != widget.profesionalId) {
          throw const InasistenciaException(
            'La inasistencia no corresponde al profesional seleccionado.',
          );
        }
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        _mensaje(
          error is InasistenciaException
              ? error.mensaje
              : 'No fue posible guardar la inasistencia.',
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

  @override
  Widget build(BuildContext context) {
    final fechas = MaterialLocalizations.of(context);
    return PopScope(
      canPop: !_guardando,
      child: Theme(
        data: ThemeData.light(),
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: Text(
              widget.inasistencia == null
                  ? 'Nueva inasistencia'
                  : 'Editar inasistencia',
            ),
          ),
          body: SafeArea(
            child: Center(
              child: SizedBox(
                width: 480,
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text('Profesional ID: ${widget.profesionalId}'),
                      const SizedBox(height: 12),
                      ListTile(
                        tileColor: AppColors.fieldBackground,
                        title: const Text('Fechas'),
                        subtitle: Text(
                          _inicio == null || _fin == null
                              ? 'Seleccionar día o rango'
                              : '${fechas.formatCompactDate(_inicio!)} – ${fechas.formatCompactDate(_fin!)}',
                        ),
                        trailing: const Icon(Icons.calendar_today_outlined),
                        onTap: _guardando ? null : _fechas,
                      ),
                      SwitchListTile(
                        title: const Text('Día completo'),
                        value: _diaCompleto,
                        activeTrackColor: AppColors.goldAccent,
                        onChanged: _guardando
                            ? null
                            : (valor) => setState(() {
                                _diaCompleto = valor;
                              }),
                      ),
                      if (!_diaCompleto) ...[
                        const Text(
                          'La disponibilidad de la API bloquea el día completo incluso si se indican solo unas horas.',
                        ),
                        ListTile(
                          title: const Text('Hora de inicio'),
                          subtitle: Text(
                            _inicio == null
                                ? 'Seleccionar hora'
                                : TimeOfDay.fromDateTime(_inicio!)
                                      .format(context),
                          ),
                          onTap: _guardando ? null : () => _hora(true),
                        ),
                        ListTile(
                          title: const Text('Hora de fin'),
                          subtitle: Text(
                            _fin == null
                                ? 'Seleccionar hora'
                                : TimeOfDay.fromDateTime(_fin!).format(context),
                          ),
                          onTap: _guardando ? null : () => _hora(false),
                        ),
                      ],
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: _motivo,
                        decoration: const InputDecoration(labelText: 'Motivo'),
                        items: [
                          for (final codigo in [0, 1, 2, 3, 4])
                            DropdownMenuItem(
                              value: codigo,
                              child: Text('Código $codigo'),
                            ),
                        ],
                        onChanged: _guardando
                            ? null
                            : (valor) {
                                setState(() {
                                  _motivo = valor;
                                });
                              },
                        validator: (valor) =>
                            valor == null ? 'Selecciona un motivo.' : null,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'La API publica los códigos de motivo sin sus nombres.',
                        ),
                      ),
                      TextFormField(
                        enabled: !_guardando,
                        controller: _observacion,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Observación (opcional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
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
      ),
    );
  }
}
