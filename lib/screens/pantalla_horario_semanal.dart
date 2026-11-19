import 'package:flutter/material.dart';

import '../models/profesional.dart';
import '../models/jornada_laboral.dart';
import '../services/jornada_service.dart';
import '../theme/app_colors.dart';
import 'pantalla_formulario_jornada.dart';

class PantallaHorarioSemanal extends StatefulWidget {
  const PantallaHorarioSemanal({
    super.key,
    required this.professional,
    this.servicioApi,
  });
  final Profesional professional;
  final JornadaService? servicioApi;
  @override
  State<PantallaHorarioSemanal> createState() => _PantallaHorarioSemanalState();
}

class _PantallaHorarioSemanalState extends State<PantallaHorarioSemanal> {
  late final JornadaService _api;
  late Future<List<JornadaLaboral>> _consulta;
  @override
  void initState() {
    super.initState();
    _api = widget.servicioApi ?? JornadaService();
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

  Future<void> _abrir(int dia, [JornadaLaboral? jornada]) async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PantallaFormularioJornada(
          profesionalId: widget.professional.id,
          diaSemana: dia,
          jornada: jornada,
          servicioApi: _api,
        ),
      ),
    );
    if (!mounted || guardado != true) return;
    _recargar();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Jornada guardada.')));
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: ThemeData.light(),
    child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Horario semanal'),
        actions: [
          IconButton(
            tooltip: 'Actualizar jornadas',
            onPressed: _recargar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: 480,
            child: FutureBuilder<List<JornadaLaboral>>(
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
                            error is JornadaException
                                ? error.mensaje
                                : 'No se pudieron cargar las jornadas.',
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
                final jornadas = snapshot.data!;
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
                    if (!widget.professional.estado)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Text(
                          'El profesional está inactivo. Actívalo desde su ficha para configurar jornadas.',
                        ),
                      ),
                    for (final dia in [1, 2, 3, 4, 5, 6, 0]) ...[
                      if (!jornadas.any((j) => j.diaSemana == dia))
                        _fila(dia, null),
                      for (final jornada in jornadas.where(
                        (j) => j.diaSemana == dia,
                      ))
                        _fila(dia, jornada),
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
  String _hora(String texto) {
    final partes = texto.split(':');
    return TimeOfDay(
      hour: int.parse(partes[0]),
      minute: int.parse(partes[1]),
    ).format(context);
  }

  Widget _fila(int dia, JornadaLaboral? jornada) {
    var texto = 'Sin jornada';
    if (jornada != null) {
      texto = '${_hora(jornada.horaInicio)} – ${_hora(jornada.horaFin)}';
      if (jornada.tieneAlmuerzo) {
        texto +=
            '\nAlmuerzo ${_hora(jornada.horaInicioAlmuerzo!)} – ${_hora(jornada.horaFinAlmuerzo!)}';
      }
      texto += '\nID: ${jornada.id}';
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        tileColor: AppColors.fieldBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: const Icon(Icons.schedule, color: AppColors.buttonGoldDark),
        title: Text(JornadaLaboral.dias[dia]),
        subtitle: Text(texto),
        trailing: IconButton(
          tooltip:
              '${jornada == null ? 'Agregar' : 'Editar'} jornada de ${JornadaLaboral.dias[dia]}',
          onPressed: widget.professional.estado
              ? () => _abrir(dia, jornada)
              : null,
          icon: Icon(jornada == null ? Icons.add : Icons.edit_outlined),
        ),
      ),
    );
  }
}
