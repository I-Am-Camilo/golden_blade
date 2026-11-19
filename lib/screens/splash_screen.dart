import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/golden_blade_logo.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/fondo_splash.jpeg', fit: BoxFit.cover),

          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x22000000), Color(0xDD000000)],
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Spacer(flex: 4),

                  const GoldenBladeLogo(height: 180),

                  Spacer(flex: 2),

                  SizedBox(
                    width: 300,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(seconds: 3),
                      onEnd: onFinished,
                      builder: (context, progress, child) {
                        return LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          color: AppColors.goldAccent,
                          backgroundColor: AppColors.goldAccent.withAlpha(0x55),
                          borderRadius: BorderRadius.circular(4),
                        );
                      },
                    ),
                  ),

                  SizedBox(height: 24),

                  Text(
                    'Estilo que impulsa\ntu mejor versión',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
