import 'package:flutter/material.dart';

class DatosComision extends StatelessWidget {
  const DatosComision({super.key, required this.datos});
  final Object? datos;

  String _etiqueta(String nombre) {
    final texto = nombre
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll('_', ' ');
    return texto.isEmpty
        ? 'Dato'
        : '${texto[0].toUpperCase()}${texto.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final valor = datos;
    if (valor is Map<String, dynamic>) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final campo in valor.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _etiqueta(campo.key),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  DatosComision(datos: campo.value),
                ],
              ),
            ),
        ],
      );
    }
    if (valor is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final registro in valor)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: DatosComision(datos: registro),
              ),
            ),
          if (valor.isEmpty) const Text('Sin registros.'),
        ],
      );
    }
    return Text(valor == null ? 'No disponible' : '$valor');
  }
}
