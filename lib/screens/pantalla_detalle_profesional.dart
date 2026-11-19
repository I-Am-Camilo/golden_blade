import 'package:flutter/material.dart';

import '../models/profesional.dart';
import '../routes/app_routes.dart';
import '../services/profesional_service.dart';
import '../theme/app_colors.dart';

class PantallaDetalleProfesional extends StatefulWidget {
  const PantallaDetalleProfesional({
    super.key,
    required this.profesional,
    this.servicioApi,
  });
  final Profesional profesional;
  final ProfesionalService? servicioApi;

  @override
  State<PantallaDetalleProfesional> createState() =>
      _PantallaDetalleProfesionalState();
}

class _PantallaDetalleProfesionalState
    extends State<PantallaDetalleProfesional> {
  late final ProfesionalService _servicioApi;
  late Future<Profesional> _profesionalFuture;
  bool _eliminando = false;

  @override
  void initState() {
    super.initState();
    _servicioApi = widget.servicioApi ?? ProfesionalService();
    _profesionalFuture = _servicioApi.obtener(widget.profesional.id);
  }

  @override
  void dispose() {
    _servicioApi.cerrar();
    super.dispose();
  }

  void _recargar() {
    setState(() {
      _profesionalFuture = _servicioApi.obtener(widget.profesional.id);
    });
  }

  Future<void> _editar(Profesional profesional) async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final resultado = await Navigator.pushNamed(
      context,
      AppRoutes.editProfessional,
      arguments: profesional,
    );
    if (!mounted || resultado is! Profesional) return;
    _recargar();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profesional actualizado.')));
  }

  Future<void> _eliminar(Profesional profesional) async {
    if (_eliminando) return;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('Eliminar profesional'),
        content: Text('¿Quieres eliminar a ${profesional.nombreCompleto}?'),
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
    setState(() => _eliminando = true);
    try {
      await _servicioApi.eliminar(profesional.id);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is ProfesionalException
                  ? error.mensaje
                  : 'No fue posible eliminar el profesional.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _eliminando = false);
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
          title: const Text('Detalle del profesional'),
          actions: [
            IconButton(
              tooltip: 'Actualizar profesional',
              onPressed: _eliminando ? null : _recargar,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: AbsorbPointer(
          absorbing: _eliminando,
          child: SafeArea(
            child: FutureBuilder<Profesional>(
              future: _profesionalFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.buttonGoldDark,
                    ),
                  );
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  final error = snapshot.error;
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          error is ProfesionalException
                              ? error.mensaje
                              : 'No se pudo consultar el profesional.',
                          textAlign: TextAlign.center,
                        ),
                        TextButton(
                          onPressed: _recargar,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }
                final profesional = snapshot.data!;
                return Align(
                  alignment: Alignment.topCenter,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: 480,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: CircleAvatar(
                              radius: 36,
                              backgroundColor: AppColors.goldAccent,
                              foregroundColor: AppColors.onPrimary,
                              child: Text(
                                profesional.nombres.isEmpty
                                    ? '?'
                                    : profesional.nombres[0],
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            profesional.nombreCompleto,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            profesional.nombreEspecialidad,
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            profesional.estado ? 'Activo' : 'Inactivo',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: profesional.estado
                                  ? Colors.green.shade800
                                  : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Información',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          _dato('ID', '${profesional.id}'),
                          _dato('Documento', profesional.documento),
                          _dato('Nombres', profesional.nombres),
                          _dato('Apellidos', profesional.apellidos),
                          _dato(
                            'Fecha de nacimiento',
                            profesional.nacimientoTexto,
                          ),
                          _dato(
                            'Especialidad',
                            '${profesional.nombreEspecialidad} · #${profesional.especialidadId}',
                          ),
                          _dato(
                            'Comisión',
                            profesional.porcentaje == null
                                ? ''
                                : '${profesional.porcentaje} %',
                          ),
                          const SizedBox(height: 16),
                          if (_eliminando) const LinearProgressIndicator(),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.onPrimary,
                            ),
                            onPressed: () => _editar(profesional),
                            child: const Text('Editar profesional'),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              AppRoutes.weeklySchedule,
                              arguments: profesional,
                            ),
                            child: const Text('Ver horario'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              AppRoutes.absences,
                              arguments: profesional,
                            ),
                            child: const Text('Ver inasistencias'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              AppRoutes.commissions,
                              arguments: profesional,
                            ),
                            icon: const Icon(Icons.payments_outlined),
                            label: const Text('Ver servicios y comisiones'),
                          ),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: _eliminando
                                ? null
                                : () => _eliminar(profesional),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Eliminar profesional'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );

  Widget _dato(String etiqueta, String valor) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    title: Text(etiqueta),
    subtitle: Text(valor.isEmpty ? 'Sin registrar' : valor),
  );
}
