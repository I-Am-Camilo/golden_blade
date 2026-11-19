import 'package:flutter/material.dart';

import '../models/profesional.dart';
import '../models/profesionales_response.dart';
import '../routes/app_routes.dart';
import '../services/profesional_service.dart';
import '../theme/app_colors.dart';

class PantallaProfesionales extends StatefulWidget {
  const PantallaProfesionales({
    super.key,
    this.seleccionarHorario = false,
    this.servicioApi,
  });
  final bool seleccionarHorario;
  final ProfesionalService? servicioApi;

  @override
  State<PantallaProfesionales> createState() => _PantallaProfesionalesState();
}

class _PantallaProfesionalesState extends State<PantallaProfesionales> {
  final _busquedaController = TextEditingController();
  late final ProfesionalService _servicioApi;
  late Future<ProfesionalesResponse> _profesionalesFuture;
  int _especialidadId = 0;
  bool? _estado;

  @override
  void initState() {
    super.initState();
    _servicioApi = widget.servicioApi ?? ProfesionalService();
    _profesionalesFuture = _servicioApi.listar();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    _servicioApi.cerrar();
    super.dispose();
  }

  String _normalizar(String texto) => texto
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ü', 'u');

  void _recargar() {
    setState(() {
      _especialidadId = 0;
      _profesionalesFuture = _servicioApi.listar();
    });
  }

  void _limpiarFiltros() {
    setState(() {
      _busquedaController.clear();
      _especialidadId = 0;
      _estado = null;
    });
  }

  Future<void> _crear() async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final resultado = await Navigator.pushNamed(
      context,
      AppRoutes.newProfessional,
    );
    if (!mounted || resultado is! Profesional) return;
    _busquedaController.clear();
    _estado = null;
    _recargar();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Profesional creado.')));
  }

  Future<void> _abrir(Profesional profesional) async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final resultado = await Navigator.pushNamed(
      context,
      widget.seleccionarHorario
          ? AppRoutes.weeklySchedule
          : AppRoutes.professionalDetail,
      arguments: profesional,
    );
    if (!mounted) return;
    _recargar();
    if (resultado == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profesional eliminado.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final busqueda = _normalizar(_busquedaController.text.trim());
    return Theme(
      data: ThemeData.light(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          centerTitle: true,
          title: Text(
            widget.seleccionarHorario
                ? 'Seleccionar profesional para horario'
                : 'Profesionales',
          ),
          actions: [
            IconButton(
              tooltip: 'Actualizar profesionales',
              onPressed: _recargar,
              icon: const Icon(Icons.refresh, color: AppColors.buttonGoldDark),
            ),
            IconButton(
              tooltip: 'Nuevo profesional',
              onPressed: _crear,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: SizedBox(
              width: 520,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _busquedaController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Buscar nombre o documento...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: AppColors.fieldBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: FutureBuilder<ProfesionalesResponse>(
                        future: _profesionalesFuture,
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
                                    error is ProfesionalException
                                        ? error.mensaje
                                        : 'No se pudieron cargar los profesionales.',
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
                          final profesionales = snapshot.data?.data ?? [];
                          final especialidades = <int, String>{
                            for (final persona in profesionales)
                              persona.especialidadId:
                                  persona.nombreEspecialidad,
                          };
                          final filtrados = profesionales
                              .where(
                                (persona) =>
                                    (_normalizar(persona.nombreCompleto)
                                            .contains(busqueda) ||
                                        persona.documento.contains(busqueda)) &&
                                    (_especialidadId == 0 ||
                                        persona.especialidadId ==
                                            _especialidadId) &&
                                    (_estado == null ||
                                        persona.estado == _estado),
                              )
                              .toList();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              DropdownButton<int>(
                                isExpanded: true,
                                value: _especialidadId,
                                items: [
                                  const DropdownMenuItem(
                                    value: 0,
                                    child: Text('Todas las especialidades'),
                                  ),
                                  for (final item in especialidades.entries)
                                    DropdownMenuItem(
                                      value: item.key,
                                      child: Text(item.value),
                                    ),
                                ],
                                onChanged: (id) =>
                                    setState(() => _especialidadId = id ?? 0),
                              ),
                              Wrap(
                                spacing: 8,
                                children: [
                                  _filtroEstado('Todos', null),
                                  _filtroEstado('Activos', true),
                                  _filtroEstado('Inactivos', false),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: filtrados.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.search_off,
                                              size: 36,
                                            ),
                                            const Text(
                                              'No se encontraron profesionales.',
                                            ),
                                            TextButton(
                                              onPressed: _limpiarFiltros,
                                              child: const Text(
                                                'Limpiar filtros',
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.separated(
                                        keyboardDismissBehavior:
                                            ScrollViewKeyboardDismissBehavior
                                                .onDrag,
                                        itemCount: filtrados.length,
                                        separatorBuilder: (_, index) =>
                                            const SizedBox(height: 8),
                                        itemBuilder: (context, index) {
                                          final persona = filtrados[index];
                                          return ListTile(
                                            tileColor:
                                                AppColors.fieldBackground,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            leading: CircleAvatar(
                                              backgroundColor:
                                                  AppColors.goldAccent,
                                              foregroundColor:
                                                  AppColors.onPrimary,
                                              child: Text(
                                                persona.nombres.isEmpty
                                                    ? '?'
                                                    : persona.nombres[0],
                                              ),
                                            ),
                                            title: Text(
                                              persona.nombreCompleto,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Doc. ${persona.documento} · #${persona.id}',
                                                ),
                                                Text(
                                                  persona.nombreEspecialidad,
                                                ),
                                                Text(
                                                  'Nacimiento: ${persona.nacimientoTexto}',
                                                ),
                                                Text(
                                                  persona.estado
                                                      ? 'Activo'
                                                      : 'Inactivo',
                                                  style: TextStyle(
                                                    color: persona.estado
                                                        ? Colors.green.shade800
                                                        : Colors.black54,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            trailing: const Icon(
                                              Icons.chevron_right,
                                            ),
                                            onTap: () => _abrir(persona),
                                          );
                                        },
                                      ),
                              ),
                            ],
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
    );
  }

  Widget _filtroEstado(String texto, bool? estado) => ChoiceChip(
    label: Text(texto),
    selected: _estado == estado,
    selectedColor: AppColors.goldAccent,
    onSelected: (_) => setState(() => _estado = estado),
  );
}
