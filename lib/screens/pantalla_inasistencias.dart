import 'package:flutter/material.dart';

import '../models/inasistencia.dart';
import '../models/profesional.dart';
import '../services/inasistencia_service.dart';
import '../theme/app_colors.dart';
import 'pantalla_formulario_inasistencia.dart';

class PantallaInasistencias extends StatefulWidget {
  const PantallaInasistencias({
    super.key,
    required this.professional,
    this.servicioApi,
  });
  final Profesional professional;
  final InasistenciaService? servicioApi;
  @override
  State<PantallaInasistencias> createState() => _PantallaInasistenciasState();
}

class _PantallaInasistenciasState extends State<PantallaInasistencias> {
  late final InasistenciaService _api;
  late Future<List<Inasistencia>> _consulta;
  bool _eliminando = false;
  @override
  void initState() {
    super.initState();
    _api = widget.servicioApi ?? InasistenciaService();
    _consulta = _api.listar(widget.professional.id);
  }

  @override
  void dispose() {
    _api.cerrar();
    super.dispose();
  }

  void _recargar() {
    setState(() {
      _consulta = _api.listar(widget.professional.id);
    });
  }

  Future<void> _abrir([Inasistencia? registro]) async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PantallaFormularioInasistencia(
          profesionalId: widget.professional.id,
          inasistencia: registro,
          servicioApi: _api,
        ),
      ),
    );
    if (!mounted || resultado != true) return;
    _recargar();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Inasistencia guardada.')));
  }

  Future<void> _eliminar(Inasistencia registro) async {
    if (_eliminando) return;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('Eliminar inasistencia'),
        content: const Text('¿Quieres eliminar esta inasistencia?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogo, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogo, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (!mounted || confirmado != true || _eliminando) return;
    setState(() {
      _eliminando = true;
    });
    try {
      await _api.eliminar(registro.id);
      if (mounted) {
        _recargar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inasistencia eliminada.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is InasistenciaException
                  ? error.mensaje
                  : 'No fue posible eliminar la inasistencia.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _eliminando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_eliminando,
    child: Theme(
      data: ThemeData.light(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          centerTitle: true,
          title: const Text('Inasistencias'),
          actions: [
            IconButton(
              tooltip: 'Actualizar inasistencias',
              onPressed: _eliminando ? null : _recargar,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: 'Nueva inasistencia',
              onPressed: _eliminando ? null : () => _abrir(),
              icon: const Icon(Icons.add, color: AppColors.buttonGoldDark),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: SizedBox(
              width: 480,
              child: FutureBuilder<List<Inasistencia>>(
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
                              error is InasistenciaException
                                  ? error.mensaje
                                  : 'No se pudieron cargar las inasistencias.',
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
                  final registros = snapshot.data!;
                  final fechas = MaterialLocalizations.of(context);
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.goldAccent,
                          child: Icon(Icons.person_outline),
                        ),
                        title: Text(widget.professional.nombreCompleto),
                        subtitle: Text(
                          '${widget.professional.nombreEspecialidad} · ID ${widget.professional.id}',
                        ),
                      ),
                      if (_eliminando) const LinearProgressIndicator(),
                      if (registros.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'No hay inasistencias registradas.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      for (final registro in registros)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            tileColor: AppColors.fieldBackground,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            title: Text(
                              '${fechas.formatCompactDate(registro.fechaInicio)} – ${fechas.formatCompactDate(registro.fechaFin)}',
                            ),
                            subtitle: Text(
                              '${registro.diaCompleto ? 'Día completo' : '${TimeOfDay.fromDateTime(registro.fechaInicio).format(context)} – ${TimeOfDay.fromDateTime(registro.fechaFin).format(context)}'}\nMotivo: ${registro.motivoTexto}\n${registro.observacion}\nID: ${registro.id}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Editar inasistencia',
                                  onPressed: _eliminando
                                      ? null
                                      : () => _abrir(registro),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip: 'Eliminar inasistencia',
                                  onPressed: _eliminando
                                      ? null
                                      : () => _eliminar(registro),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
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
