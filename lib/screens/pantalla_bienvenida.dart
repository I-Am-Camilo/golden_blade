import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../services/sesion_service.dart';
import '../theme/app_colors.dart';
import '../widgets/golden_blade_logo.dart';

class PantallaBienvenida extends StatelessWidget {
  const PantallaBienvenida({super.key});

  @override
  Widget build(BuildContext context) {
    final sesion = SesionService.actual;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/fondo_splash.jpeg',
            fit: BoxFit.cover,
            excludeFromSemantics: true,
          ),
          Container(color: const Color(0x88000000)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: 320,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const GoldenBladeLogo(height: 130),
                      const SizedBox(height: 28),
                      const Center(
                        child: CircleAvatar(
                          radius: 34,
                          backgroundColor: AppColors.goldAccent,
                          foregroundColor: AppColors.onPrimary,
                          child: Icon(Icons.person_outline, size: 38),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        '¡Bienvenido!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        sesion?.usuario ?? 'Usuario',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sesion?.rol ?? 'Sin sesión',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context)
                              .pushReplacementNamed(AppRoutes.adminPanel);
                        },
                        child: const Text('Continuar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
