import 'package:flutter/material.dart';

import '../models/servicio.dart';
import '../models/especialidades_response.dart';
import '../models/crear_servicio_request.dart';
import '../models/editar_servicio_request.dart';
import '../services/servicio_service.dart';
import '../services/especialidad_service.dart';
import '../theme/app_colors.dart';

class PantallaFormularioServicio extends StatefulWidget {
  const PantallaFormularioServicio({
    super.key,
    this.servicio,
    this.servicioApi,
    this.especialidadApi,
  });

  final Servicio? servicio;
  final ServicioService? servicioApi;
  final EspecialidadService? especialidadApi;

  @override
  State<PantallaFormularioServicio> createState() =>
      _PantallaFormularioServicioState();
}

class _PantallaFormularioServicioState
    extends State<PantallaFormularioServicio> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _precioController = TextEditingController();
  final _duracionController = TextEditingController();
  final _descripcionController = TextEditingController();
  late final ServicioService _servicioApi;
  late final EspecialidadService _especialidadApi;
  late Future<EspecialidadesResponse> _especialidadesFuture;
  int? _especialidadId;
  bool _activo = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _servicioApi = widget.servicioApi ?? ServicioService();
    _especialidadApi = widget.especialidadApi ?? EspecialidadService();
    _especialidadesFuture = _especialidadApi.listar();
    final servicio = widget.servicio;
    if (servicio != null) {
      _nombreController.text = servicio.nombre;
      _precioController.text = servicio.precio.toString();
      _duracionController.text = servicio.duracion.toString();
      _descripcionController.text = servicio.descripcion;
      _especialidadId = servicio.especialidadId;
      _activo = servicio.activo;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _precioController.dispose();
    _duracionController.dispose();
    _descripcionController.dispose();
    _servicioApi.cerrar();
    _especialidadApi.cerrar();
    super.dispose();
  }

  InputDecoration _decoracion(String etiqueta) => InputDecoration(
    labelText: etiqueta,
    filled: true,
    fillColor: AppColors.fieldBackground,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
  );

  Future<void> _guardar() async {
    if (_guardando || !_formKey.currentState!.validate()) return;
    if (widget.servicio == null && _especialidadId == null) {
      _mensaje('Carga y selecciona una especialidad antes de guardar.');
      return;
    }
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    FocusScope.of(context).unfocus();
    setState(() => _guardando = true);
    try {
      final servicio = widget.servicio;
      final guardado = servicio == null
          ? await _servicioApi.crear(
              CrearServicioRequest(
                nombre: _nombreController.text.trim(),
                precio: int.parse(_precioController.text.trim()),
                duracion: int.parse(_duracionController.text.trim()),
                especialidad: _especialidadId!,
                descripcion: _descripcionController.text.trim(),
              ),
            )
          : await _servicioApi.editar(
              servicio.id,
              EditarServicioRequest(
                nombre: _nombreController.text.trim(),
                precio: int.parse(_precioController.text.trim()),
                duracion: int.parse(_duracionController.text.trim()),
                activo: _activo,
              ),
            );
      if (mounted) Navigator.pop(context, guardado);
    } catch (error) {
      if (mounted) {
        _mensaje(
          error is ServicioException
              ? error.mensaje
              : 'No se pudo guardar el servicio.',
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _mensaje(String mensaje) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.servicio != null;
    return PopScope(
      canPop: !_guardando,
      child: Theme(
        data: ThemeData.light(),
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            centerTitle: true,
            title: Text(editando ? 'Editar servicio' : 'Nuevo servicio'),
          ),
          body: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: 480,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _nombreController,
                          enabled: !_guardando,
                          maxLength: 50,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.next,
                          decoration: _decoracion('Nombre *'),
                          validator: (valor) => (valor ?? '').trim().isEmpty
                              ? 'Ingresa el nombre del servicio.'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        FutureBuilder<EspecialidadesResponse>(
                          future: _especialidadesFuture,
                          builder: (context, snapshot) {
                            if (editando) {
                              var nombre =
                                  'Especialidad #${widget.servicio!.especialidadId}';
                              for (final especialidad
                                  in snapshot.data?.data ?? []) {
                                if (especialidad.id ==
                                    widget.servicio!.especialidadId) {
                                  nombre = especialidad.nombre;
                                }
                              }
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                tileColor: AppColors.fieldBackground,
                                title: const Text('Especialidad'),
                                subtitle: Text(nombre),
                                trailing: const Icon(Icons.lock_outline),
                              );
                            }
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
                              return Column(
                                children: [
                                  Text(
                                    error is EspecialidadException
                                        ? error.mensaje
                                        : 'No se pudieron cargar las especialidades.',
                                  ),
                                  TextButton(
                                    onPressed: _guardando
                                        ? null
                                        : () {
                                            setState(() {
                                              _especialidadId = null;
                                              _especialidadesFuture =
                                                  _especialidadApi.listar();
                                            });
                                          },
                                    child: const Text(
                                      'Reintentar especialidades',
                                    ),
                                  ),
                                ],
                              );
                            }
                            final especialidades = snapshot.data?.data ?? [];
                            if (especialidades.isEmpty) {
                              return const Text(
                                'Primero registra una especialidad activa.',
                              );
                            }
                            return DropdownButtonFormField<int>(
                              initialValue: _especialidadId,
                              isExpanded: true,
                              decoration: _decoracion('Especialidad *'),
                              items: [
                                for (final especialidad in especialidades)
                                  DropdownMenuItem(
                                    value: especialidad.id,
                                    child: Text(
                                      especialidad.nombre,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: _guardando
                                  ? null
                                  : (id) =>
                                        setState(() => _especialidadId = id),
                              validator: (valor) => valor == null
                                  ? 'Selecciona una especialidad.'
                                  : null,
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _precioController,
                          enabled: !_guardando,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          decoration: _decoracion('Precio (COP) *'),
                          validator: (valor) {
                            final precio = int.tryParse(valor?.trim() ?? '');
                            return precio == null ||
                                    precio < 0 ||
                                    precio > 2147483647
                                ? 'Ingresa un precio entero entre 0 y 2147483647.'
                                : null;
                          },
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _duracionController,
                          enabled: !_guardando,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          decoration: _decoracion('Duración en minutos *'),
                          validator: (valor) {
                            final duracion = int.tryParse(valor?.trim() ?? '');
                            return duracion == null ||
                                    duracion <= 0 ||
                                    duracion > 2147483647
                                ? 'Ingresa una duración entera entre 1 y 2147483647.'
                                : null;
                          },
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _descripcionController,
                          enabled: !_guardando,
                          readOnly: editando,
                          minLines: 2,
                          maxLines: 4,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _decoracion(
                            editando
                                ? 'Descripción (solo lectura)'
                                : 'Descripción (opcional)',
                          ),
                        ),
                        if (editando) ...[
                          const SizedBox(height: 18),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Estado'),
                            subtitle: Text(_activo ? 'Activo' : 'Inactivo'),
                            activeTrackColor: AppColors.goldAccent,
                            value: _activo,
                            onChanged: _guardando
                                ? null
                                : (valor) => setState(() => _activo = valor),
                          ),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            minimumSize: const Size(0, 48),
                          ),
                          onPressed: _guardando ? null : _guardar,
                          child: _guardando
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(editando ? 'Guardar cambios' : 'Guardar'),
                        ),
                      ],
                    ),
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
