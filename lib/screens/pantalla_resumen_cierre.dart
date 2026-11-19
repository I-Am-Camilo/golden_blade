import 'package:flutter/material.dart';

import '../models/cierre.dart';
import '../models/crear_cierre_request.dart';
import '../services/cierre_service.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';

class PantallaResumenCierre extends StatefulWidget {
  const PantallaResumenCierre({
    super.key,
    required this.periodo,
    this.servicioApi,
  });
  final DateTimeRange periodo;
  final CierreService? servicioApi;
  @override
  State<PantallaResumenCierre> createState() => _PantallaResumenCierreState();
}

class _PantallaResumenCierreState extends State<PantallaResumenCierre> {
  bool _generado = false;
  bool _enviando = false;
  bool _resultadoIncierto = false;
  Cierre? _creado;
  String? _error;
  late final CierreService _api;

  @override
  void initState() {
    super.initState();
    _api = widget.servicioApi ?? CierreService();
  }

  @override
  void dispose() {
    if (widget.servicioApi == null) _api.cerrar();
    super.dispose();
  }

  Future<void> _generar() async {
    if (_generado || _enviando || _resultadoIncierto) return;
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      _creado ??= await _api.crear(
        CrearCierreRequest(
          fechaInicio: widget.periodo.start,
          fechaFin: widget.periodo.end,
        ),
      );
      // Si falla esta consulta, se conserva el ID y el botón solo reintenta leer.
      final cierre = await _api.obtener(_creado!.id);
      if (cierre.inicio != _creado!.inicio ||
          cierre.fin != _creado!.fin ||
          cierre.totalFacturado != _creado!.totalFacturado ||
          cierre.subtotalComisionNegocio != _creado!.subtotalComisionNegocio ||
          cierre.subtotalComisionProfesionales !=
              _creado!.subtotalComisionProfesionales) {
        throw const CierreException(
          'El detalle consultado no coincide con el cierre generado. Revisa el listado.',
        );
      }
      if (!mounted) return;
      _generado = true;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.closingCreated,
        (route) =>
            route.settings.name == AppRoutes.closings ||
            route.settings.name == AppRoutes.adminPanel ||
            route.isFirst,
        arguments: cierre,
      );
    } on CierreException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.mensaje;
          _resultadoIncierto = error.resultadoIncierto;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _resultadoIncierto = _creado == null;
          _error = 'No fue posible verificar el cierre. Consulta el listado antes de generar otro.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _enviando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fechas = MaterialLocalizations.of(context);
    return PopScope(
      canPop: !_enviando,
      child: Theme(
        data: ThemeData.light(),
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('Resumen del período'),
            backgroundColor: Colors.white,
          ),
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 520,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.date_range,
                      color: AppColors.buttonGoldDark,
                    ),
                    title: const Text('Período del cierre'),
                    subtitle: Text(
                      '${fechas.formatCompactDate(widget.periodo.start)} – ${fechas.formatCompactDate(widget.periodo.end)}',
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Revisa las fechas antes de generar. Los importes se mostrarán al finalizar la liquidación.',
                    ),
                  ),
                  if (_error != null)
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  if (_enviando) const LinearProgressIndicator(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                    ),
                    onPressed: _generado || _enviando || _resultadoIncierto
                        ? null
                        : _generar,
                    child: Text(
                      _creado == null
                          ? 'Generar cierre'
                          : 'Consultar cierre generado',
                    ),
                  ),
                  TextButton(
                    onPressed: _enviando
                        ? null
                        : () => Navigator.popUntil(
                            context,
                            (route) =>
                                route.settings.name == AppRoutes.closings ||
                                route.isFirst,
                          ),
                    child: const Text('Volver a cierres'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
