import 'package:flutter/material.dart';

Future<int?> solicitarId(BuildContext context, String titulo) {
  final formulario = GlobalKey<FormState>();
  String texto = '';
  return showDialog<int>(
    context: context,
    builder: (dialogo) => AlertDialog(
      title: Text(titulo),
      content: Form(
        key: formulario,
        child: TextFormField(
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'ID'),
          onChanged: (valor) => texto = valor,
          validator: (valor) => (int.tryParse(valor?.trim() ?? '') ?? 0) > 0
              ? null
              : 'Ingresa un ID entero mayor que cero.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogo),
          child: const Text('Volver'),
        ),
        TextButton(
          onPressed: () {
            if (formulario.currentState!.validate()) {
              Navigator.pop(dialogo, int.parse(texto.trim()));
            }
          },
          child: const Text('Consultar'),
        ),
      ],
    ),
  );
}
