import 'package:flutter/material.dart';

import '../models/cierre.dart';
import '../models/comision.dart';
import '../routes/app_routes.dart';
import '../widgets/datos_comision.dart';
import '../models/profesional.dart';
import '../services/cierre_service.dart';
import '../services/comision_service.dart';
import '../services/profesional_service.dart';
import '../services/sesion_service.dart';
import '../theme/app_colors.dart';

class PantallaComisiones extends StatefulWidget {
  const PantallaComisiones({
    super.key,
    this.cierre,
    this.profesional,
    this.servicioApi,
    this.cierresApi,
    this.profesionalesApi,
  });
  final Cierre? cierre;
  final Profesional? profesional;
  final ComisionService? servicioApi;
  final CierreService? cierresApi;
  final ProfesionalService? profesionalesApi;

  @override
  State<PantallaComisiones> createState() => _PantallaComisionesState();
}

class _PantallaComisionesState extends State<PantallaComisiones> {
  late final ComisionService _api;
  late final CierreService _cierresApi;
  late final ProfesionalService _profesionalesApi;
  late Future<List<Map<String, dynamic>>> _consulta;
  List<Cierre> _cierres = [];
  List<Profesional> _profesionales = [];
  int? _cierreId;
  int? _profesionalId;
  DateTimeRange? _periodo;
  String? _avisoCatalogos;

  @override
  void initState() {
    super.initState();
    _api = widget.servicioApi ?? ComisionService();
    _cierresApi = widget.cierresApi ?? CierreService();
    _profesionalesApi = widget.profesionalesApi ?? ProfesionalService();
    _cierreId = widget.cierre?.id;
    _profesionalId = widget.profesional?.id;
    _consulta = _cargar();
  }

  Future<List<Map<String, dynamic>>> _cargar() async {
    final datos = await _consultar();
    final avisos = <String>[];
    try {
      _cierres = await _cierresApi.listar();
    } catch (error) {
      avisos.add(
        error is CierreException
            ? error.mensaje
            : 'No se pudo cargar el catálogo de cierres.',
      );
    }
    try {
      _profesionales = (await _profesionalesApi.listar()).data;
    } catch (error) {
      avisos.add(
        error is ProfesionalException
            ? error.mensaje
            : 'No se pudo cargar el catálogo de profesionales.',
      );
    }
    if (!SesionService.activa) {
      throw const ComisionException('Tu sesión venció. Ingresa de nuevo.');
    }
    // Los objetos recibidos desde una ficha son datos reales ya consultados.
    if (widget.cierre != null &&
        !_cierres.any((c) => c.id == widget.cierre!.id)) {
      _cierres.add(widget.cierre!);
    }
    if (widget.profesional != null &&
        !_profesionales.any((p) => p.id == widget.profesional!.id)) {
      _profesionales.add(widget.profesional!);
    }
    _avisoCatalogos = avisos.isEmpty ? null : avisos.join(' ');
    return datos;
  }

  Future<List<Map<String, dynamic>>> _consultar() => _api.listar(
    profesionalId: _profesionalId,
    liquidacionComisionId: _cierreId,
    fechaInicio: _periodo?.start,
    fechaFin: _periodo?.end,
  );

  @override
  void dispose() {
    if (widget.servicioApi == null) _api.cerrar();
    if (widget.cierresApi == null) _cierresApi.cerrar();
    if (widget.profesionalesApi == null) _profesionalesApi.cerrar();
    super.dispose();
  }

  void _recargar() {
    setState(() {
      _consulta = _cargar();
    });
  }

  Future<void> _elegirPeriodo() async {
    final periodo = await showDateRangePicker(
      context: context,
      initialDateRange: _periodo,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100, 12, 31),
    );
    if (mounted && periodo != null) {
      setState(() {
        _periodo = periodo;
        _consulta = _consultar();
      });
    }
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: ThemeData.light(),
    child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.profesional != null
              ? 'Servicios y comisiones'
              : widget.cierre != null
              ? 'Comisiones del cierre'
              : 'Comisiones',
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Actualizar comisiones',
            onPressed: _recargar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: 520,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _consulta,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  final error = snapshot.error;
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          error is ComisionException
                              ? error.mensaje
                              : 'No fue posible consultar las comisiones.',
                        ),
                        TextButton(
                          onPressed: _recargar,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }
                final fechas = MaterialLocalizations.of(context);
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (widget.cierre != null)
                      Text('Cierre #${widget.cierre!.id}'),
                    if (widget.profesional != null)
                      Text(widget.profesional!.nombreCompleto),
                    DropdownButtonFormField<int>(
                      key: ValueKey('cierre-$_cierreId'),
                      initialValue: _cierreId ?? 0,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Cierre'),
                      items: [
                        const DropdownMenuItem(
                          value: 0,
                          child: Text('Todos los cierres'),
                        ),
                        for (final c in _cierres)
                          DropdownMenuItem(
                            value: c.id,
                            child: Text(
                              'Cierre #${c.id} · ${fechas.formatCompactDate(c.inicio)} – ${fechas.formatCompactDate(c.fin)}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: widget.cierre != null
                          ? null
                          : (id) {
                              setState(() {
                                _cierreId = id == 0 ? null : id;
                                _consulta = _consultar();
                              });
                            },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      key: ValueKey('profesional-$_profesionalId'),
                      initialValue: _profesionalId ?? 0,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Profesional',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: 0,
                          child: Text('Todos los profesionales'),
                        ),
                        for (final p in _profesionales)
                          DropdownMenuItem(
                            value: p.id,
                            child: Text(
                              '${p.nombreCompleto} · ID ${p.id}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: widget.profesional != null
                          ? null
                          : (id) {
                              setState(() {
                                _profesionalId = id == 0 ? null : id;
                                _consulta = _consultar();
                              });
                            },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.date_range),
                      title: const Text('Período'),
                      subtitle: Text(
                        _periodo == null
                            ? 'Todas las fechas'
                            : '${fechas.formatCompactDate(_periodo!.start)} – ${fechas.formatCompactDate(_periodo!.end)}',
                      ),
                      onTap: _elegirPeriodo,
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _cierreId = widget.cierre?.id;
                          _profesionalId = widget.profesional?.id;
                          _periodo = null;
                          _consulta = _consultar();
                        });
                      },
                      child: const Text('Limpiar filtros'),
                    ),
                    if (_avisoCatalogos != null) Text(_avisoCatalogos!),
                    const SizedBox(height: 20),
                    const Icon(
                      Icons.payments_outlined,
                      size: 48,
                      color: AppColors.buttonGoldDark,
                    ),
                    const SizedBox(height: 12),
                    Text('Comisiones registradas: ${snapshot.data!.length}'),
                    const SizedBox(height: 12),
                    if (snapshot.data!.isEmpty)
                      const Text(
                        'No hay comisiones para estos filtros.',
                        textAlign: TextAlign.center,
                      ),
                    if (widget.cierre != null)
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Volver al cierre'),
                      ),
                    for (final datos in snapshot.data!)
                      Card(
                        color: AppColors.fieldBackground,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              DatosComision(datos: datos),
                              TextButton(
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.commissionDetail,
                                  arguments: Comision(datos: datos),
                                ),
                                child: const Text('Ver servicios asociados'),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}
