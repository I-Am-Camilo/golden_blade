import 'package:flutter/material.dart';

import '../models/jornada_laboral.dart';
import '../services/jornada_service.dart';
import '../widgets/solicitar_id.dart';
import 'pantalla_formulario_jornada.dart';
import 'pantalla_profesionales.dart';

class PantallaJornadas extends StatefulWidget {
  const PantallaJornadas({super.key, this.servicio});
  final JornadaService? servicio;
  @override
  State<PantallaJornadas> createState() => _PantallaJornadasState();
}

class _PantallaJornadasState extends State<PantallaJornadas> {
  late final JornadaService _api;
  late Future<List<JornadaLaboral>> _consulta;
  bool _consultando = false;

  @override
  void initState() {
    super.initState();
    _api = widget.servicio ?? JornadaService();
    _consulta = _api.listarTodas();
  }

  @override
  void dispose() {
    if (widget.servicio == null) _api.cerrar();
    super.dispose();
  }

  void _recargar() => setState(() => _consulta = _api.listarTodas());

  Future<void> _editar(JornadaLaboral jornada) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PantallaFormularioJornada(
          profesionalId: jornada.profesionalId,
          diaSemana: jornada.diaSemana,
          jornada: jornada,
          servicioApi: _api,
        ),
      ),
    );
    if (mounted && resultado == true) _recargar();
  }

  Future<void> _porId() async {
    if (_consultando) return;
    final id = await solicitarId(context, 'Consultar jornada por ID');
    if (!mounted || id == null) return;
    setState(() => _consultando = true);
    try {
      final jornada = await _api.obtener(id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogo) => AlertDialog(
          title: Text('Jornada #${jornada.id}'),
          content: Text(
            'Profesional #${jornada.profesionalId}\n${JornadaLaboral.dias[jornada.diaSemana]}\n${jornada.horaInicio} – ${jornada.horaFin}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogo),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is JornadaException
                  ? error.mensaje
                  : 'No se pudo consultar la jornada.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _consultando = false);
    }
  }

  Future<void> _porProfesional() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PantallaProfesionales(seleccionarHorario: true),
      ),
    );
    if (mounted) _recargar();
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: ThemeData.light(),
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Jornadas laborales'),
        actions: [
          IconButton(
            tooltip: 'Consultar jornada por ID',
            onPressed: _consultando ? null : _porId,
            icon: const Icon(Icons.manage_search),
          ),
          IconButton(
            tooltip: 'Actualizar jornadas',
            onPressed: _recargar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            TextButton.icon(
              onPressed: _porProfesional,
              icon: const Icon(Icons.people_outline),
              label: const Text('Consultar y gestionar por profesional'),
            ),
            if (_consultando) const LinearProgressIndicator(),
            Expanded(
              child: FutureBuilder<List<JornadaLaboral>>(
                future: _consulta,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('No se pudieron consultar las jornadas.'),
                          TextButton(
                            onPressed: _recargar,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    );
                  }
                  final jornadas = snapshot.data!;
                  if (jornadas.isEmpty) {
                    return const Center(
                      child: Text('No hay jornadas registradas.'),
                    );
                  }
                  return ListView.builder(
                    itemCount: jornadas.length,
                    itemBuilder: (context, index) {
                      final jornada = jornadas[index];
                      return ListTile(
                        title: Text(
                          '${JornadaLaboral.dias[jornada.diaSemana]} · Profesional #${jornada.profesionalId}',
                        ),
                        subtitle: Text(
                          'Jornada #${jornada.id}\n${jornada.horaInicio} – ${jornada.horaFin}',
                        ),
                        trailing: IconButton(
                          tooltip: 'Editar jornada #${jornada.id}',
                          onPressed: () => _editar(jornada),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
