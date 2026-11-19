import 'package:flutter/material.dart';

import '../models/profesional.dart';
import '../models/especialidad.dart';
import '../models/crear_profesional_request.dart';
import '../models/editar_profesional_request.dart';
import '../services/profesional_service.dart';
import '../services/especialidad_service.dart';
import '../theme/app_colors.dart';

class PantallaFormularioProfesional extends StatefulWidget {
  const PantallaFormularioProfesional({
    super.key,
    this.profesional,
    this.servicioApi,
    this.especialidadApi,
  });

  final ProfesionalService? servicioApi;
  final EspecialidadService? especialidadApi;
  final Profesional? profesional;

  @override
  State<PantallaFormularioProfesional> createState() =>
      _PantallaFormularioProfesionalState();
}

class _PantallaFormularioProfesionalState
    extends State<PantallaFormularioProfesional> {
  final _formKey = GlobalKey<FormState>();
  final _documento = TextEditingController();
  final _nombres = TextEditingController();
  final _apellidos = TextEditingController();
  final _porcentaje = TextEditingController();
  int? _especialidadId;
  late final ProfesionalService _api;
  late final EspecialidadService _especialidadApi;
  late Future<List<Especialidad>> _catalogo;
  List<Profesional> _registrados = [];
  bool _guardando = false;
  bool _datosListos = false;
  DateTime? _fechaNacimiento;
  bool _estado = true;

  @override
  void initState() {
    super.initState();
    _api = widget.servicioApi ?? ProfesionalService();
    _especialidadApi = widget.especialidadApi ?? EspecialidadService();
    _catalogo = _cargar();
    final profesional = widget.profesional;
    if (profesional != null) {
      _documento.text = profesional.documento;
      _nombres.text = profesional.nombres;
      _apellidos.text = profesional.apellidos;
      _porcentaje.text = profesional.porcentaje?.toString() ?? '';
      _especialidadId = profesional.especialidadId;
      _fechaNacimiento = profesional.fechaNacimiento;
      _estado = profesional.estado;
    }
  }

  @override
  void dispose() {
    _documento.dispose();
    _nombres.dispose();
    _apellidos.dispose();
    _porcentaje.dispose();
    _api.cerrar();
    _especialidadApi.cerrar();
    super.dispose();
  }

  Future<void> _elegirFechaNacimiento() async {
    final hoy = DateUtils.dateOnly(DateTime.now());
    final fecha = await showDatePicker(
      context: context,
      initialDate:
          _fechaNacimiento != null &&
              !_fechaNacimiento!.isAfter(hoy) &&
              !_fechaNacimiento!.isBefore(DateTime(1900))
          ? _fechaNacimiento!
          : DateTime(hoy.year - 25),
      firstDate: DateTime(1900),
      lastDate: hoy,
    );
    if (mounted && fecha != null) {
      setState(() => _fechaNacimiento = fecha);
    }
  }

  double? _leerPorcentaje(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  Future<List<Especialidad>> _cargar() async {
    _datosListos = false;
    _registrados = (await _api.listar()).data;
    final especialidades = widget.profesional == null
        ? (await _especialidadApi.listar()).data
        : <Especialidad>[];
    _datosListos = true;
    return especialidades;
  }

  Future<void> _guardar() async {
    if (_guardando || !_datosListos || !_formKey.currentState!.validate()) {
      return;
    }
    if (_fechaNacimiento != null && _fechaNacimiento!.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La fecha no puede ser futura.')),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _guardando = true;
    });
    try {
      final Profesional guardado;
      if (widget.profesional == null) {
        guardado = await _api.crear(
          CrearProfesionalRequest(
            documento: _documento.text.trim(),
            nombres: _nombres.text.trim(),
            apellidos: _apellidos.text.trim(),
            fechaNacimiento: _fechaNacimiento,
            porcentaje: _leerPorcentaje(_porcentaje.text)!,
            estado: _estado,
            especialidad: _especialidadId!,
          ),
        );
      } else {
        guardado = await _api.editar(
          widget.profesional!.id,
          EditarProfesionalRequest(
            documento: _documento.text.trim(),
            nombres: _nombres.text.trim(),
            apellidos: _apellidos.text.trim(),
            fechaNacimiento: _fechaNacimiento,
            porcentaje: _leerPorcentaje(_porcentaje.text)!,
            estado: _estado,
          ),
        );
      }
      if (mounted) Navigator.pop(context, guardado);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is ProfesionalException
                  ? error.mensaje
                  : 'No fue posible guardar el profesional.',
            ),
          ),
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

  InputDecoration _decoracion(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.fieldBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fechaNacimiento = _fechaNacimiento;
    final editando = widget.profesional != null;
    return PopScope(
      canPop: !_guardando,
      child: Theme(
        data: ThemeData.light(),
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            centerTitle: true,
            title: Text(editando ? 'Editar profesional' : 'Nuevo profesional'),
          ),
          body: FutureBuilder<List<Especialidad>>(
            future: _catalogo,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('No fue posible cargar los datos.'),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _catalogo = _cargar();
                          });
                        },
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }
              return SafeArea(
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
                              enabled: !_guardando,
                              controller: _documento,
                              keyboardType: TextInputType.number,
                              decoration: _decoracion('Documento *'),
                              validator: (value) {
                                final documento = value?.trim() ?? '';
                                if (documento.isEmpty) {
                                  return 'Ingresa el documento.';
                                }
                                if (_registrados.any(
                                  (persona) =>
                                      persona.id != widget.profesional?.id &&
                                      persona.documento == documento,
                                )) {
                                  return 'Este documento ya está registrado.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              enabled: !_guardando,
                              controller: _nombres,
                              textCapitalization: TextCapitalization.words,
                              decoration: _decoracion('Nombres *'),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Ingresa los nombres.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              enabled: !_guardando,
                              controller: _apellidos,
                              textCapitalization: TextCapitalization.words,
                              decoration: _decoracion('Apellidos (opcional)'),
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              tileColor: AppColors.fieldBackground,
                              title: const Text(
                                'Fecha de nacimiento (opcional)',
                              ),
                              subtitle: Text(
                                fechaNacimiento == null
                                    ? 'Seleccionar fecha'
                                    : '${fechaNacimiento.day}/${fechaNacimiento.month}/${fechaNacimiento.year}',
                              ),
                              trailing: fechaNacimiento == null || editando
                                  ? const Icon(Icons.calendar_today_outlined)
                                  : IconButton(
                                      tooltip: 'Quitar fecha de nacimiento',
                                      onPressed: _guardando
                                          ? null
                                          : () => setState(
                                              () => _fechaNacimiento = null,
                                            ),
                                      icon: const Icon(Icons.close),
                                    ),
                              onTap: _guardando ? null : _elegirFechaNacimiento,
                            ),
                            const SizedBox(height: 16),
                            if (editando)
                              TextFormField(
                                enabled: !_guardando,
                                initialValue:
                                    widget.profesional?.nombreEspecialidad,
                                readOnly: true,
                                decoration: _decoracion('Especialidad'),
                              )
                            else
                              DropdownButtonFormField<int>(
                                isExpanded: true,
                                initialValue: _especialidadId,
                                decoration: _decoracion(
                                  editando ? 'Especialidad' : 'Especialidad *',
                                ),
                                items: [
                                  for (final especialidad in snapshot.data!)
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
                                    : (value) => setState(
                                        () => _especialidadId = value,
                                      ),
                                validator: (value) => value == null
                                    ? 'Selecciona una especialidad.'
                                    : null,
                              ),
                            const SizedBox(height: 16),
                            TextFormField(
                              enabled: !_guardando,
                              controller: _porcentaje,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: _decoracion('Comisión (%) *'),
                              validator: (value) {
                                final porcentaje = _leerPorcentaje(value ?? '');
                                if (porcentaje == null ||
                                    !porcentaje.isFinite ||
                                    porcentaje < 0 ||
                                    porcentaje > 100) {
                                  return 'Ingresa un porcentaje entre 0 y 100.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Estado'),
                              subtitle: Text(_estado ? 'Activo' : 'Inactivo'),
                              value: _estado,
                              activeTrackColor: AppColors.goldAccent,
                              onChanged: _guardando
                                  ? null
                                  : (value) => setState(() => _estado = value),
                            ),
                            const SizedBox(height: 16),
                            if (_guardando) const LinearProgressIndicator(),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.onPrimary,
                                minimumSize: const Size(0, 48),
                              ),
                              onPressed: _guardando ? null : _guardar,
                              child: Text(
                                _guardando
                                    ? 'Guardando...'
                                    : editando
                                    ? 'Guardar cambios'
                                    : 'Guardar',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
