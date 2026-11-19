import 'package:flutter/material.dart';

import '../models/comision.dart';
import '../services/comision_service.dart';
import '../widgets/datos_comision.dart';

class PantallaDetalleComision extends StatefulWidget {
  const PantallaDetalleComision({
    super.key,
    required this.comision,
    this.servicioApi,
  });
  final Comision comision;
  final ComisionService? servicioApi;

  @override
  State<PantallaDetalleComision> createState() =>
      _PantallaDetalleComisionState();
}

class _PantallaDetalleComisionState extends State<PantallaDetalleComision> {
  late final ComisionService _api;
  Future<Object?>? _consulta;

  @override
  void initState() {
    super.initState();
    _api = widget.servicioApi ?? ComisionService();
    final id = widget.comision.id;
    if (id != null) _consulta = _api.servicios(id);
  }

  @override
  void dispose() {
    if (widget.servicioApi == null) _api.cerrar();
    super.dispose();
  }

  void _recargar() {
    final id = widget.comision.id;
    if (id != null) {
      setState(() {
        _consulta = _api.servicios(id);
      });
    }
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: ThemeData.light(),
    child: Scaffold(
      appBar: AppBar(title: const Text('Detalle de comisión')),
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: 520,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                DatosComision(datos: widget.comision.datos),
                const Divider(),
                const Text(
                  'Servicios asociados',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 16),
                if (_consulta == null)
                  const Text(
                    'El registro no incluye un identificador válido para consultar sus servicios.',
                  )
                else
                  FutureBuilder<Object?>(
                    future: _consulta,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const LinearProgressIndicator();
                      }
                      if (snapshot.hasError) {
                        final error = snapshot.error;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              error is ComisionException
                                  ? error.mensaje
                                  : 'No fue posible consultar los servicios.',
                            ),
                            TextButton(
                              onPressed: _recargar,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        );
                      }
                      final datos = snapshot.data;
                      if (datos is List && datos.isEmpty) {
                        return const Text(
                          'No hay servicios asociados a esta comisión.',
                        );
                      }
                      if (datos == null) {
                        return const Text(
                          'El servidor no devolvió información de servicios.',
                        );
                      }
                      return DatosComision(datos: datos);
                    },
                  ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Volver a comisiones'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
