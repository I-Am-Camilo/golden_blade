import 'package:flutter/material.dart';

class IconosEspecialidad {
  static final _iconos = <int, IconData>{};

  static IconData obtener(int id) => _iconos[id] ?? Icons.category_outlined;

  static void guardar(int id, IconData icono) {
    _iconos[id] = icono;
  }
}
