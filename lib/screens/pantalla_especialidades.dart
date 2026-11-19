import 'package:flutter/material.dart';

import '../models/especialidad.dart';
import '../models/especialidades_response.dart';
import '../routes/app_routes.dart';
import '../services/especialidad_service.dart';
import '../theme/app_colors.dart';
import '../widgets/iconos_especialidad.dart';

class PantallaEspecialidades extends StatefulWidget {
  const PantallaEspecialidades({super.key, this.servicio});

  final EspecialidadService? servicio;

  @override
  State<PantallaEspecialidades> createState() => _PantallaEspecialidadesState();
}

class _PantallaEspecialidadesState extends State<PantallaEspecialidades> {
  final _busquedaController = TextEditingController();
  late final EspecialidadService _servicio;
  late Future<EspecialidadesResponse> _especialidadesFuture;
  bool _inactivando = false;

  @override
  void initState() {
    super.initState();
    _servicio = widget.servicio ?? EspecialidadService();
    _especialidadesFuture = _servicio.listar();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    _servicio.cerrar();
    super.dispose();
  }

  void _recargar() {
    setState(() {
      _especialidadesFuture = _servicio.listar();
    });
  }

  Future<void> _abrirFormulario([Especialidad? especialidad]) async {
    final resultado = await Navigator.pushNamed(
      context,
      especialidad == null ? AppRoutes.newSpecialty : AppRoutes.editSpecialty,
      arguments: especialidad,
    );
    if (!mounted || resultado != true) return;
    _busquedaController.clear();
    _recargar();
    _mostrarMensaje(
      especialidad == null
          ? 'Especialidad creada.'
          : 'Especialidad actualizada.',
    );
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _inactivar(Especialidad especialidad) async {
    if (_inactivando) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Inactivar especialidad'),
        content: Text(
          '¿Quieres inactivar ${especialidad.nombre}? Dejará de aparecer en el listado. La API no publica una operación para reactivarla.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Inactivar'),
          ),
        ],
      ),
    );
    if (!mounted || confirmar != true) return;
    setState(() => _inactivando = true);
    try {
      await _servicio.inactivar(especialidad.id);
      if (!mounted) return;
      _recargar();
      _mostrarMensaje('Especialidad inactivada.');
    } catch (error) {
      if (mounted) {
        _mostrarMensaje(
          error is EspecialidadException
              ? error.mensaje
              : 'No se pudo inactivar la especialidad.',
        );
      }
    } finally {
      if (mounted) setState(() => _inactivando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busqueda = _busquedaController.text.trim().toLowerCase();
    return PopScope(
      canPop: !_inactivando,
      child: Theme(
        data: ThemeData.light(),
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            centerTitle: true,
            title: const Text('Especialidades'),
            actions: [
              IconButton(
                tooltip: 'Actualizar especialidades',
                onPressed: _inactivando ? null : _recargar,
                icon: const Icon(
                  Icons.refresh,
                  color: AppColors.buttonGoldDark,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: IconButton(
                  tooltip: 'Nueva especialidad',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _inactivando ? null : () => _abrirFormulario(),
                  icon: const Icon(Icons.add),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Center(
              child: SizedBox(
                width: 520,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _busquedaController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Buscar especialidad...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: AppColors.fieldBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_inactivando)
                        const LinearProgressIndicator(
                          color: AppColors.buttonGoldDark,
                        ),
                      Expanded(
                        child: FutureBuilder<EspecialidadesResponse>(
                          future: _especialidadesFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.buttonGoldDark,
                                ),
                              );
                            }
                            if (snapshot.hasError) {
                              final error = snapshot.error;
                              return Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      error is EspecialidadException
                                          ? error.mensaje
                                          : 'No se pudieron cargar las especialidades.',
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
                            final especialidades = snapshot.data?.data ?? [];
                            final filtradas = especialidades
                                .where(
                                  (item) => item.nombre.toLowerCase().contains(
                                    busqueda,
                                  ),
                                )
                                .toList();
                            if (filtradas.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.search_off, size: 36),
                                    const SizedBox(height: 8),
                                    Text(
                                      especialidades.isEmpty
                                          ? 'No hay especialidades registradas.'
                                          : 'No se encontraron especialidades.',
                                    ),
                                    if (busqueda.isNotEmpty)
                                      TextButton(
                                        onPressed: () =>
                                            setState(_busquedaController.clear),
                                        child: const Text('Limpiar búsqueda'),
                                      ),
                                  ],
                                ),
                              );
                            }
                            return ListView.separated(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              itemCount: filtradas.length,
                              separatorBuilder: (_, index) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final especialidad = filtradas[index];
                                return ListTile(
                                  tileColor: AppColors.fieldBackground,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.goldAccent,
                                    foregroundColor: AppColors.onPrimary,
                                    child: Icon(
                                      IconosEspecialidad.obtener(
                                        especialidad.id,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    especialidad.nombre,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '#${especialidad.id} · ${especialidad.activa ? 'Activa' : 'Inactiva'}',
                                    style: TextStyle(
                                      color: especialidad.activa
                                          ? Colors.green.shade800
                                          : Colors.black54,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip:
                                            'Editar ${especialidad.nombre}',
                                        onPressed: _inactivando
                                            ? null
                                            : () => _abrirFormulario(
                                                especialidad,
                                              ),
                                        icon: const Icon(Icons.edit_outlined),
                                      ),
                                      IconButton(
                                        tooltip:
                                            'Inactivar ${especialidad.nombre}',
                                        onPressed:
                                            _inactivando || !especialidad.activa
                                            ? null
                                            : () => _inactivar(especialidad),
                                        icon: const Icon(Icons.block_outlined),
                                      ),
                                    ],
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
            ),
          ),
        ),
      ),
    );
  }
}
