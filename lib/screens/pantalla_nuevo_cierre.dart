import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../theme/app_colors.dart';

class PantallaNuevoCierre extends StatefulWidget {
  const PantallaNuevoCierre({super.key});

  @override
  State<PantallaNuevoCierre> createState() => _PantallaNuevoCierreState();
}

class _PantallaNuevoCierreState extends State<PantallaNuevoCierre> {
  DateTime? _inicio;
  DateTime? _fin;

  Future<void> _elegirFecha({required bool inicio}) async {
    final hoy = DateUtils.dateOnly(DateTime.now());
    final fecha = await showDatePicker(
      context: context,
      initialDate: (inicio ? _inicio : _fin) ?? hoy,
      firstDate: DateTime(1900),
      lastDate: hoy,
    );
    if (mounted && fecha != null) {
      setState(() {
        if (inicio) {
          _inicio = fecha;
        } else {
          _fin = fecha;
        }
      });
    }
  }

  void _revisar() {
    final inicio = _inicio;
    final fin = _fin;
    if (inicio == null || fin == null) {
      return;
    }
    if (fin.isBefore(inicio)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La fecha final debe ser igual o posterior a la inicial.',
          ),
        ),
      );
      return;
    }
    Navigator.of(context).pushNamed(
      AppRoutes.closingSummary,
      arguments: DateTimeRange(start: inicio, end: fin),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fechas = MaterialLocalizations.of(context);
    final inicio = _inicio;
    final fin = _fin;
    return Theme(
      data: ThemeData.light(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Nuevo cierre'),
          backgroundColor: Colors.white,
        ),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 520,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ListTile(
                    title: const Text('Fecha inicial'),
                    subtitle: Text(
                      inicio == null
                          ? 'Seleccionar fecha'
                          : fechas.formatCompactDate(inicio),
                    ),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: () => _elegirFecha(inicio: true),
                  ),
                  ListTile(
                    title: const Text('Fecha final'),
                    subtitle: Text(
                      fin == null
                          ? 'Seleccionar fecha'
                          : fechas.formatCompactDate(fin),
                    ),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: () => _elegirFecha(inicio: false),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                    ),
                    onPressed: inicio == null || fin == null ? null : _revisar,
                    child: const Text('Revisar período'),
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
