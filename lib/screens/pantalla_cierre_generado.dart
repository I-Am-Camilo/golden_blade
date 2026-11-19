import 'package:flutter/material.dart';

import '../models/cierre.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';

class PantallaCierreGenerado extends StatelessWidget {
  const PantallaCierreGenerado({super.key, required this.cierre});
  final Cierre cierre;
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Cierre generado'),
          backgroundColor: Colors.white,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 96),
                const SizedBox(height: 24),
                const Text(
                  '¡Cierre generado!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'El cierre #${cierre.id} se guardó correctamente.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Total facturado: ${Cierre.pesos(cierre.totalFacturado)}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                  ),
                  onPressed: () => Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.closingDetail,
                    arguments: cierre,
                  ),
                  child: const Text('Ver detalle'),
                ),
                TextButton(
                  onPressed: () => Navigator.popUntil(
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
    );
  }
}
