import 'package:flutter/material.dart';

import '../models/cliente.dart';
import '../models/cliente_request.dart';
import '../services/cliente_service.dart';
import '../theme/app_colors.dart';

class PantallaFormularioCliente extends StatefulWidget {
  const PantallaFormularioCliente({
    super.key,
    this.cliente,
    this.servicioApi,
    this.soloDatosReserva = false,
  });

  final bool soloDatosReserva;
  final Cliente? cliente;
  final ClienteService? servicioApi;

  @override
  State<PantallaFormularioCliente> createState() =>
      _PantallaFormularioClienteState();
}

class _PantallaFormularioClienteState extends State<PantallaFormularioCliente> {
  final _formKey = GlobalKey<FormState>();
  final _documento = TextEditingController();
  final _nombres = TextEditingController();
  final _apellidos = TextEditingController();
  final _celular = TextEditingController();
  final _correo = TextEditingController();
  DateTime? _fechaNacimiento;
  late final ClienteService _api;
  late Future<void> _carga;
  List<Cliente> _registrados = [];
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _api = widget.servicioApi ?? ClienteService();
    _carga = _cargar();
    final cliente = widget.cliente;
    if (cliente != null) {
      _documento.text = cliente.documento;
      _nombres.text = cliente.nombres;
      _apellidos.text = cliente.apellidos;
      _celular.text = cliente.celular;
      _correo.text = cliente.correo;
      _fechaNacimiento = cliente.fechaNacimiento;
    }
  }

  @override
  void dispose() {
    _documento.dispose();
    _nombres.dispose();
    _apellidos.dispose();
    _celular.dispose();
    _correo.dispose();
    _api.cerrar();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
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

  Future<void> _cargar() async {
    _registrados = (await _api.listar()).data;
  }

  Future<void> _guardar() async {
    if (_guardando || !_formKey.currentState!.validate()) return;
    if (_fechaNacimiento != null && _fechaNacimiento!.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La fecha no puede ser futura.')),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() {
      _guardando = true;
    });
    try {
      final request = ClienteRequest(
        documento: _documento.text.trim(),
        nombres: _nombres.text.trim(),
        apellidos: _apellidos.text.trim(),
        fechaNacimiento: _fechaNacimiento,
        celular: _celular.text.trim(),
        correo: _correo.text.trim(),
      );
      if (widget.soloDatosReserva) {
        final borrador = Cliente(
          id: 0,
          documento: request.documento,
          nombres: request.nombres,
          apellidos: request.apellidos,
          fechaNacimiento: request.fechaNacimiento,
          celular: request.celular,
          correo: request.correo,
        );
        if (mounted) Navigator.pop(context, borrador);
        return;
      }
      final guardado = widget.cliente == null
          ? await _api.crear(request)
          : await _api.editar(widget.cliente!.id, request);
      if (mounted) Navigator.pop(context, guardado);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is ClienteException
                  ? error.mensaje
                  : 'No fue posible guardar el cliente.',
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
              widget.soloDatosReserva
                  ? 'Cliente de primera vez'
                  : widget.cliente == null
                  ? 'Nuevo cliente'
                  : 'Editar cliente',
            ),
          ),
          body: FutureBuilder<void>(
            future: _carga,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'No fue posible cargar los clientes para validar el documento.',
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _carga = _cargar();
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
                  child: SizedBox(
                    width: 480,
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          TextFormField(
                            enabled: !_guardando,
                            controller: _documento,
                            decoration: _decoracion('Documento *'),
                            validator: (value) {
                              final documento = value?.trim() ?? '';
                              if (documento.isEmpty) {
                                return 'Ingresa el documento.';
                              }
                              if (_registrados.any(
                                (cliente) =>
                                    cliente.id != widget.cliente?.id &&
                                    cliente.documento == documento,
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
                            validator: (value) => (value ?? '').trim().isEmpty
                                ? 'Ingresa los nombres.'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            enabled: !_guardando,
                            controller: _apellidos,
                            textCapitalization: TextCapitalization.words,
                            decoration: _decoracion('Apellidos *'),
                            validator: (value) => (value ?? '').trim().isEmpty
                                ? 'Ingresa los apellidos.'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            tileColor: AppColors.fieldBackground,
                            title: const Text('Fecha de nacimiento (opcional)'),
                            subtitle: Text(
                              fechaNacimiento == null
                                  ? 'Seleccionar fecha'
                                  : '${fechaNacimiento.day}/${fechaNacimiento.month}/${fechaNacimiento.year}',
                            ),
                            trailing:
                                fechaNacimiento == null ||
                                    widget.cliente != null
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
                            onTap: _guardando ? null : _elegirFecha,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            enabled: !_guardando,
                            controller: _celular,
                            keyboardType: TextInputType.phone,
                            decoration: _decoracion('Celular (opcional)'),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            enabled: !_guardando,
                            controller: _correo,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _decoracion('Correo (opcional)'),
                            validator: (value) {
                              final correo = value?.trim() ?? '';
                              if (correo.isNotEmpty &&
                                  !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                      .hasMatch(correo)) {
                                return 'Ingresa un correo válido.';
                              }
                              return null;
                            },
                          ),
                          if (widget.soloDatosReserva)
                            const Text(
                              'El cliente se registrará al confirmar la reserva.',
                            ),
                          const SizedBox(height: 24),
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
                                  : widget.soloDatosReserva
                                  ? 'Continuar con la reserva'
                                  : widget.cliente == null
                                  ? 'Guardar'
                                  : 'Guardar cambios',
                            ),
                          ),
                        ],
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
