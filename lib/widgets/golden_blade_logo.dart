import 'package:flutter/material.dart';

class GoldenBladeLogo extends StatelessWidget {
  const GoldenBladeLogo({super.key, required this.height});

  final double height;

  // Disimula el fondo blanco del logo al colocarlo sobre la foto.
  static const _filter = ColorFilter.matrix(<double>[
    1, 0, 0, 0, 0, // Rojo.
    0, 1, 0, 0, 0, // Verde.
    0, 0, 1, 0, 0, // Azul.
    0, 0, -8, 0, 1936, // Transparencia.
  ]);

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: _filter,
      child: Image.asset(
        'assets/images/logo.jpeg',
        width: 310,
        height: height,
        fit: BoxFit.contain,
        semanticLabel: 'Golden Blade Barber Shop',
      ),
    );
  }
}
