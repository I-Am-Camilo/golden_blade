import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../models/cierre.dart';
import '../services/cierre_service.dart';
import '../theme/app_colors.dart';

class PantallaCierres extends StatefulWidget {
  const PantallaCierres({super.key, this.servicioApi});
  final CierreService? servicioApi;

  @override
  State<PantallaCierres> createState() => _PantallaCierresState();
}

class _PantallaCierresState extends State<PantallaCierres> {
  static const _months = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  int _year = 0;
  int _month = 0;
  late final CierreService _api;
  late Future<List<Cierre>> _consulta;

  @override
  void initState() {
    super.initState();
    _api = widget.servicioApi ?? CierreService();
    _consulta = _api.listar();
  }

  @override
  void dispose() {
    if (widget.servicioApi == null) _api.cerrar();
    super.dispose();
  }

  void _recargar() {
    setState(() {
      _consulta = _api.listar();
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Cierre>>(
    future: _consulta,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.hasError) {
        final error = snapshot.error;
        return Scaffold(
          appBar: AppBar(title: const Text('Cierres')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    error is CierreException
                        ? error.mensaje
                        : 'No se pudieron consultar los cierres.',
                  ),
                  TextButton(
                    onPressed: _recargar,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      return _contenido(snapshot.data!);
    },
  );

  Widget _contenido(List<Cierre> cierres) {
    final dates = MaterialLocalizations.of(context);
    final years = cierres.map((closing) => closing.inicio.year).toSet();
    final visible = cierres.where((closing) {
      return (_year == 0 || closing.inicio.year == _year) &&
          (_month == 0 || closing.inicio.month == _month);
    });

    return Theme(
      data: ThemeData.light(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          centerTitle: true,
          title: const Text('Cierres'),
          actions: [
            IconButton(
              tooltip: 'Actualizar cierres',
              onPressed: _recargar,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: 'Nuevo cierre',
              icon: const Icon(Icons.add, color: AppColors.buttonGoldDark),
              onPressed: () async {
                await Navigator.of(context).pushNamed(AppRoutes.newClosing);
                if (!mounted) return;
                setState(() {
                  _year = 0;
                  _month = 0;
                  _consulta = _api.listar();
                });
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 520,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: years.contains(_year) ? _year : 0,
                          items: [
                            const DropdownMenuItem(
                              value: 0,
                              child: Text('Todos los años'),
                            ),
                            for (final year in years)
                              DropdownMenuItem(
                                value: year,
                                child: Text('$year'),
                              ),
                          ],
                          onChanged: (value) =>
                              setState(() => _year = value ?? 0),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: _month,
                          items: [
                            const DropdownMenuItem(
                              value: 0,
                              child: Text('Todos los meses'),
                            ),
                            for (var index = 0; index < _months.length; index++)
                              DropdownMenuItem(
                                value: index + 1,
                                child: Text(_months[index]),
                              ),
                          ],
                          onChanged: (value) =>
                              setState(() => _month = value ?? 0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _year = 0;
                        _month = 0;
                      });
                    },
                    child: const Text('Limpiar filtros'),
                  ),
                  if (visible.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No hay cierres para este período.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  for (final closing in visible)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        tileColor: AppColors.fieldBackground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        leading: const Icon(
                          Icons.receipt_long,
                          color: AppColors.buttonGoldDark,
                        ),
                        title: Text('Cierre #${closing.id}'),
                        onTap: () async {
                          await Navigator.pushNamed(
                            context,
                            AppRoutes.closingDetail,
                            arguments: closing,
                          );
                          if (mounted) _recargar();
                        },
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${dates.formatCompactDate(closing.inicio)} – ${dates.formatCompactDate(closing.fin)}',
                            ),
                            Text(
                              'Facturado: ${Cierre.pesos(closing.totalFacturado)}',
                            ),
                            Text(
                              'Comisiones profesionales: ${Cierre.pesos(closing.subtotalComisionProfesionales)}',
                            ),
                          ],
                        ),
                      ),
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
