import 'package:flutter/material.dart';

import '../models/especialidad.dart';
import '../models/especialidad_request.dart';
import '../services/especialidad_service.dart';
import '../widgets/iconos_especialidad.dart';
import '../theme/app_colors.dart';

class PantallaFormularioEspecialidad extends StatefulWidget {
  const PantallaFormularioEspecialidad({
    super.key,
    this.especialidad,
    this.servicio,
  });

  final Especialidad? especialidad;
  final EspecialidadService? servicio;

  @override
  State<PantallaFormularioEspecialidad> createState() =>
      _PantallaFormularioEspecialidadState();
}

class _PantallaFormularioEspecialidadState
    extends State<PantallaFormularioEspecialidad> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  IconData? _iconoSeleccionado;
  bool _guardando = false;
  late final EspecialidadService _servicio;

  static const _iconos = {
    'Tijeras': Icons.content_cut,
    'Rostro': Icons.face_outlined,
    'Tinte': Icons.format_paint_outlined,
    'Pincel': Icons.brush_outlined,
    'Spa': Icons.spa_outlined,
    'Paleta': Icons.color_lens_outlined,
    'Estrella': Icons.star_outline,
    'Corazón': Icons.favorite_border,
    'Categoría': Icons.category_outlined,
  };

  @override
  void initState() {
    super.initState();
    _servicio = widget.servicio ?? EspecialidadService();
    final especialidad = widget.especialidad;
    if (especialidad != null) {
      _nombreController.text = especialidad.nombre;
      _iconoSeleccionado = IconosEspecialidad.obtener(especialidad.id);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _servicio.cerrar();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_guardando || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _guardando = true);
    try {
      final request = EspecialidadRequest(
        nombre: _nombreController.text.trim(),
      );
      final especialidad = widget.especialidad;
      final guardada = especialidad == null
          ? await _servicio.crear(request)
          : await _servicio.editar(especialidad.id, request);
      if (!mounted) return;
      IconosEspecialidad.guardar(
        guardada.id,
        _iconoSeleccionado ?? Icons.category_outlined,
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is EspecialidadException
                ? error.mensaje
                : 'No se pudo guardar la especialidad.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.especialidad != null;

    return PopScope(
      canPop: !_guardando,
      child: Theme(
        data: ThemeData.light(),
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            centerTitle: true,
            title: Text(
              editando ? 'Editar especialidad' : 'Nueva especialidad',
            ),
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
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _guardar(),
                          decoration: InputDecoration(
                            labelText: 'Nombre *',
                            hintText: 'Ej. Corte de cabello',
                            filled: true,
                            fillColor: AppColors.fieldBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ingresa el nombre de la especialidad.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Ícono (opcional)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'El ícono es visual y se conserva mientras la app esté abierta.',
                          style: TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final opcion in _iconos.entries)
                              IconButton(
                                tooltip: opcion.key,
                                isSelected: _iconoSeleccionado == opcion.value,
                                style: IconButton.styleFrom(
                                  backgroundColor:
                                      _iconoSeleccionado == opcion.value
                                      ? AppColors.goldAccent
                                      : AppColors.fieldBackground,
                                  foregroundColor: AppColors.onPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: _guardando
                                    ? null
                                    : () {
                                        setState(() {
                                          _iconoSeleccionado =
                                              _iconoSeleccionado == opcion.value
                                              ? null
                                              : opcion.value;
                                        });
                                      },
                                icon: Icon(opcion.value),
                              ),
                          ],
                        ),
                        if (editando) ...[
                          const SizedBox(height: 20),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Estado informado por la API'),
                            subtitle: Text(
                              widget.especialidad!.activa
                                  ? 'Activa'
                                  : 'Inactiva',
                            ),
                          ),
                          const Text(
                            'Puedes inactivar desde el listado. La API no publica una operación para reactivar.',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                        const SizedBox(height: 28),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
