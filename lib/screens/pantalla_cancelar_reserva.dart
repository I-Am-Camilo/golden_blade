import 'package:flutter/material.dart';

import '../models/reserva.dart';
import '../services/reserva_service.dart';

class PantallaCancelarReserva extends StatefulWidget {
  const PantallaCancelarReserva({
    super.key,
    required this.reserva,
    this.servicioApi,
  });
  final Reserva reserva;
  final ReservaService? servicioApi;

  @override
  State<PantallaCancelarReserva> createState() =>
      _PantallaCancelarReservaState();
}

class _PantallaCancelarReservaState extends State<PantallaCancelarReserva> {
  final _formulario = GlobalKey<FormState>();
  final _motivo = TextEditingController();
  late final ReservaService _api;
  bool _guardando = false;
  bool _consultarAntesDeRepetir = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = widget.servicioApi ?? ReservaService();
  }

  @override
  void dispose() {
    _motivo.dispose();
    if (widget.servicioApi == null) _api.cerrar();
    super.dispose();
  }

  Future<void> _cancelar() async {
    if (_guardando || !_formulario.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final actual = await _api.obtener(widget.reserva.id);
      if (actual.estado != 0 && actual.estado != 3) {
        throw const ReservaException(
          'Esta reserva ya no admite cancelación. Vuelve al detalle.',
        );
      }
      await _api.cancelar(actual.id, _motivo.text);
      _consultarAntesDeRepetir = true;
      final guardada = await _api.obtener(actual.id);
      if (guardada.estado != 1) {
        throw const ReservaException(
          'La cancelación todavía no se confirma. Consulta el detalle.',
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
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'No se pudo verificar la cancelación. Consulta el detalle antes de repetirla.';
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
        appBar: AppBar(title: const Text('Cancelar reserva')),
        body: SafeArea(
          child: Center(
            child: SizedBox(
              width: 520,
              child: Form(
                key: _formulario,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 72,
                    ),
                    const Text(
                      '¿Cancelar esta reserva?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Reserva #${widget.reserva.id}'),
                    Text(widget.reserva.cliente),
                    Text(widget.reserva.servicio),
                    const Text(
                      'Esta acción no se puede deshacer. Puedes volver sin cancelar.',
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _motivo,
                      minLines: 2,
                      maxLines: 4,
                      enabled: !_guardando && !_consultarAntesDeRepetir,
                      decoration: const InputDecoration(
                        labelText: 'Motivo de cancelación',
                        border: OutlineInputBorder(),
                      ),
                      validator: (valor) =>
                          valor == null || valor.trim().isEmpty
                          ? 'Escribe el motivo de cancelación.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    if (_error != null)
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    if (_guardando) const LinearProgressIndicator(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _guardando || _consultarAntesDeRepetir
                          ? null
                          : _cancelar,
                      child: const Text('Confirmar cancelación'),
                    ),
                    TextButton(
                      onPressed: _guardando
                          ? null
                          : () => Navigator.pop(context, true),
                      child: Text(
                        _consultarAntesDeRepetir
                            ? 'Volver y consultar reserva'
                            : 'Volver sin cancelar',
                      ),
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
