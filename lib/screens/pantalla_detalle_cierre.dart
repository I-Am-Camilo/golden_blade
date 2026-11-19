import 'package:flutter/material.dart';

import '../models/cierre.dart';
import '../routes/app_routes.dart';
import '../services/cierre_service.dart';
import '../theme/app_colors.dart';

class PantallaDetalleCierre extends StatefulWidget {
  const PantallaDetalleCierre({
    super.key,
    required this.cierre,
    this.servicioApi,
  });
  final Cierre cierre;
  final CierreService? servicioApi;

  @override
  State<PantallaDetalleCierre> createState() => _PantallaDetalleCierreState();
}

class _PantallaDetalleCierreState extends State<PantallaDetalleCierre> {
  late final CierreService _api;
  late Future<Cierre> _consulta;

  @override
  void initState() {
    super.initState();
    _api = widget.servicioApi ?? CierreService();
    _consulta = _api.obtener(widget.cierre.id);
  }

  @override
  void dispose() {
    if (widget.servicioApi == null) _api.cerrar();
    super.dispose();
  }

  void _recargar() {
    setState(() {
      _consulta = _api.obtener(widget.cierre.id);
    });
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: ThemeData.light(),
    child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Detalle del cierre'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Actualizar cierre',
            onPressed: _recargar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: 520,
            child: FutureBuilder<Cierre>(
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
                          error is CierreException
                              ? error.mensaje
                              : 'No fue posible consultar el cierre.',
                        ),
                        TextButton(
                          onPressed: _recargar,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }
                final cierre = snapshot.data!;
                final fechas = MaterialLocalizations.of(context);
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.fieldBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.receipt_long,
                            size: 48,
                            color: AppColors.buttonGoldDark,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Cierre #${cierre.id}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text('Liquidación de comisiones'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: const Text('Fecha inicial'),
                      subtitle: Text(fechas.formatCompactDate(cierre.inicio)),
                    ),
                    ListTile(
                      leading: const Icon(Icons.event_outlined),
                      title: const Text('Fecha final'),
                      subtitle: Text(fechas.formatCompactDate(cierre.fin)),
                    ),
                    const Divider(),
                    _importe('Total facturado', cierre.totalFacturado),
                    _importe(
                      'Comisión del negocio',
                      cierre.subtotalComisionNegocio,
                    ),
                    _importe(
                      'Comisión de los profesionales',
                      cierre.subtotalComisionProfesionales,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                      ),
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.commissions,
                        arguments: cierre,
                      ),
                      icon: const Icon(Icons.payments_outlined),
                      label: const Text('Ver comisiones'),
                    ),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Volver al listado'),
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

  Widget _importe(String titulo, num valor) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo),
        Text(
          Cierre.pesos(valor),
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
            color: AppColors.buttonGoldDark,
          ),
        ),
      ],
    ),
  );
}
