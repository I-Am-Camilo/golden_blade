import 'package:flutter/material.dart';

import '../models/servicio.dart';
import '../models/servicios_response.dart';
import '../models/cliente.dart';
import '../models/especialidad.dart';
import '../routes/app_routes.dart';
import '../services/servicio_service.dart';
import '../services/especialidad_service.dart';
import '../theme/app_colors.dart';

class PantallaServicios extends StatefulWidget {
  const PantallaServicios({
    super.key,
    this.cliente,
    this.servicioApi,
    this.especialidadApi,
  });

  final Cliente? cliente;
  final ServicioService? servicioApi;
  final EspecialidadService? especialidadApi;

  @override
  State<PantallaServicios> createState() => _PantallaServiciosState();
}

class _PantallaServiciosState extends State<PantallaServicios> {
  final _busquedaController = TextEditingController();
  final _idController = TextEditingController();
  final _idsConsultados = <int>{};
  late final ServicioService _servicioApi;
  late final EspecialidadService _especialidadApi;
  late Future<ServiciosResponse> _serviciosFuture;
  List<Especialidad> _especialidades = [];
  int _especialidadId = 0;
  bool? _activo;
  bool _consultandoId = false;
  Servicio? _seleccionado;

  @override
  void initState() {
    super.initState();
    _servicioApi = widget.servicioApi ?? ServicioService();
    _especialidadApi = widget.especialidadApi ?? EspecialidadService();
    _serviciosFuture = _cargar();
  }

  Future<ServiciosResponse> _cargar() async {
    final respuesta = await _servicioApi.listar();
    final especialidades = await _especialidadApi.listar();
    final servicios = respuesta.data.toList();
    // El listado de la API omite inactivos. Solo recuperamos IDs ya conocidos, sin enumerarlos.
    for (final id in _idsConsultados.toList()) {
      if (!servicios.any((item) => item.id == id)) {
        servicios.add(await _servicioApi.obtener(id));
      }
    }
    _especialidades = especialidades.data;
    return ServiciosResponse(data: servicios);
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    _idController.dispose();
    _servicioApi.cerrar();
    _especialidadApi.cerrar();
    super.dispose();
  }

  String _nombreEspecialidad(int id) {
    for (final especialidad in _especialidades) {
      if (especialidad.id == id) return especialidad.nombre;
    }
    return 'Especialidad #$id';
  }

  void _recargar() {
    setState(() {
      _seleccionado = null;
      _especialidadId = 0;
      _serviciosFuture = _cargar();
    });
  }

  void _limpiarFiltros() {
    setState(() {
      _busquedaController.clear();
      _especialidadId = 0;
      _activo = null;
      _seleccionado = null;
    });
  }

  Future<void> _abrirFormulario([Servicio? servicio]) async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final resultado = await Navigator.pushNamed(
      context,
      servicio == null ? AppRoutes.newService : AppRoutes.editService,
      arguments: servicio,
    );
    if (!mounted || resultado is! Servicio) return;
    _idsConsultados.add(resultado.id);
    _busquedaController.clear();
    _activo = null;
    _recargar();
    _mensaje(servicio == null ? 'Servicio creado.' : 'Servicio actualizado.');
  }

  void _mensaje(String mensaje) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _consultarPorId() async {
    if (_consultandoId) return;
    final controlador = _idController;
    controlador.clear();
    final formKey = GlobalKey<FormState>();
    final id = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Consultar servicio por ID'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controlador,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'ID del servicio'),
            validator: (valor) {
              final numero = int.tryParse(valor?.trim() ?? '');
              return numero == null || numero <= 0
                  ? 'Ingresa un ID entero mayor que cero.'
                  : null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(
                  dialogContext,
                  int.parse(controlador.text.trim()),
                );
              }
            },
            child: const Text('Consultar'),
          ),
        ],
      ),
    );
    if (!mounted || id == null) return;
    setState(() => _consultandoId = true);
    try {
      final servicio = await _servicioApi.obtener(id);
      if (!mounted) return;
      _idsConsultados.add(id);
      _busquedaController.clear();
      _activo = servicio.activo ? null : false;
      _recargar();
    } catch (error) {
      if (mounted) {
        _mensaje(
          error is ServicioException
              ? error.mensaje
              : 'No se pudo consultar el servicio.',
        );
      }
    } finally {
      if (mounted) setState(() => _consultandoId = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cliente = widget.cliente;
    return Theme(
      data: ThemeData.light(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          centerTitle: true,
          title: Text(cliente == null ? 'Servicios' : 'Seleccionar servicio'),
          actions: [
            IconButton(
              tooltip: 'Actualizar servicios',
              onPressed: _consultandoId ? null : _recargar,
              icon: const Icon(Icons.refresh, color: AppColors.buttonGoldDark),
            ),
            if (cliente == null) ...[
              IconButton(
                tooltip: 'Consultar servicio por ID',
                onPressed: _consultandoId ? null : _consultarPorId,
                icon: const Icon(
                  Icons.manage_search,
                  color: AppColors.buttonGoldDark,
                ),
              ),
              IconButton(
                tooltip: 'Nuevo servicio',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                ),
                onPressed: _consultandoId ? null : () => _abrirFormulario(),
                icon: const Icon(Icons.add),
              ),
            ],
          ],
        ),
        body: SafeArea(
          child: Center(
            child: SizedBox(
              width: 520,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (cliente != null) ...[
                      Text('Cliente: ${cliente.nombreCompleto}'),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: _busquedaController,
                      onChanged: (_) => setState(() => _seleccionado = null),
                      decoration: InputDecoration(
                        hintText: 'Buscar servicio...',
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
                    if (_consultandoId)
                      const LinearProgressIndicator(
                        color: AppColors.buttonGoldDark,
                      ),
                    Expanded(
                      child: FutureBuilder<ServiciosResponse>(
                        future: _serviciosFuture,
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
                                    error is ServicioException
                                        ? error.mensaje
                                        : error is EspecialidadException
                                        ? error.mensaje
                                        : 'No se pudieron cargar los servicios.',
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
                          final servicios = snapshot.data?.data ?? [];
                          final opciones = <int, String>{
                            for (final item in _especialidades)
                              item.id: item.nombre,
                          };
                          for (final servicio in servicios) {
                            opciones.putIfAbsent(
                              servicio.especialidadId,
                              () =>
                                  _nombreEspecialidad(servicio.especialidadId),
                            );
                          }
                          final busqueda = _busquedaController.text
                              .trim()
                              .toLowerCase();
                          final filtrados = servicios
                              .where(
                                (item) =>
                                    item.nombre.toLowerCase().contains(
                                      busqueda,
                                    ) &&
                                    (_especialidadId == 0 ||
                                        item.especialidadId ==
                                            _especialidadId) &&
                                    (_activo == null ||
                                        item.activo == _activo) &&
                                    (cliente == null || item.activo),
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
                                  for (final opcion in opciones.entries)
                                    DropdownMenuItem(
                                      value: opcion.key,
                                      child: Text(opcion.value),
                                    ),
                                ],
                                onChanged: (id) => setState(() {
                                  _especialidadId = id ?? 0;
                                  _seleccionado = null;
                                }),
                              ),
                              if (cliente == null)
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    _estado('Todos', null),
                                    _estado('Activos', true),
                                    _estado('Inactivos', false),
                                  ],
                                ),
                              if (_activo == false)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    'Se muestran los inactivos consultados en esta vista. Puedes recuperar otro con su ID.',
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                ),
                              const SizedBox(height: 8),
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
                                              'No se encontraron servicios.',
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
                                          final servicio = filtrados[index];
                                          return ListTile(
                                            tileColor:
                                                AppColors.fieldBackground,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            leading: const CircleAvatar(
                                              backgroundColor:
                                                  AppColors.goldAccent,
                                              foregroundColor:
                                                  AppColors.onPrimary,
                                              child: Icon(Icons.content_cut),
                                            ),
                                            title: Text(
                                              servicio.nombre,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${servicio.precioTexto} · ${servicio.duracion} min',
                                                ),
                                                Text(
                                                  '${_nombreEspecialidad(servicio.especialidadId)} · #${servicio.id}',
                                                ),
                                                Text(
                                                  servicio.activo
                                                      ? 'Activo'
                                                      : 'Inactivo',
                                                  style: TextStyle(
                                                    color: servicio.activo
                                                        ? Colors.green.shade800
                                                        : Colors.black54,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            selected:
                                                _seleccionado?.id ==
                                                servicio.id,
                                            selectedTileColor:
                                                AppColors.goldAccent,
                                            onTap: cliente == null
                                                ? null
                                                : () {
                                                    FocusScope.of(context)
                                                        .unfocus();
                                                    setState(
                                                      () => _seleccionado =
                                                          servicio,
                                                    );
                                                  },
                                            trailing: cliente == null
                                                ? IconButton(
                                                    tooltip:
                                                        'Editar ${servicio.nombre}',
                                                    onPressed: () =>
                                                        _abrirFormulario(
                                                          servicio,
                                                        ),
                                                    icon: const Icon(
                                                      Icons.edit_outlined,
                                                    ),
                                                  )
                                                : Icon(
                                                    _seleccionado?.id ==
                                                            servicio.id
                                                        ? Icons.check_circle
                                                        : Icons
                                                              .radio_button_unchecked,
                                                  ),
                                          );
                                        },
                                      ),
                              ),
                              if (cliente != null)
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.onPrimary,
                                  ),
                                  onPressed:
                                      _seleccionado == null ||
                                          !filtrados.any(
                                            (item) =>
                                                item.id == _seleccionado!.id,
                                          )
                                      ? null
                                      : () => Navigator.pushNamed(
                                          context,
                                          AppRoutes.reservationProfessional,
                                          arguments: (
                                            cliente,
                                            _seleccionado!,
                                            _nombreEspecialidad(
                                              _seleccionado!.especialidadId,
                                            ),
                                          ),
                                        ),
                                  child: const Text('Siguiente'),
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

  Widget _estado(String texto, bool? activo) => ChoiceChip(
    label: Text(texto),
    selected: _activo == activo,
    selectedColor: AppColors.goldAccent,
    onSelected: (_) => setState(() {
      _activo = activo;
      _seleccionado = null;
    }),
  );
}
