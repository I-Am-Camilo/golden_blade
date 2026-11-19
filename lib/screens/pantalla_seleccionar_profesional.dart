import 'package:flutter/material.dart';

import '../models/servicio.dart';
import '../models/cliente.dart';
import '../models/profesionales_response.dart';
import '../services/profesional_service.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';

class PantallaSeleccionarProfesional extends StatefulWidget {
  const PantallaSeleccionarProfesional({
    super.key,
    required this.client,
    required this.service,
    required this.nombreEspecialidad,
    this.servicioApi,
  });

  final ProfesionalService? servicioApi;
  final Cliente client;
  final Servicio service;
  final String nombreEspecialidad;

  @override
  State<PantallaSeleccionarProfesional> createState() =>
      _PantallaSeleccionarProfesionalState();
}

class _PantallaSeleccionarProfesionalState
    extends State<PantallaSeleccionarProfesional> {
  late final ProfesionalService _api;
  late Future<ProfesionalesResponse> _consulta;
  @override
  void initState() {
    super.initState();
    _api = widget.servicioApi ?? ProfesionalService();
    _consulta = _api.listar(soloActivos: true);
  }

  @override
  void dispose() {
    _api.cerrar();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          centerTitle: true,
          title: const Text('Asignación del profesional'),
        ),
        body: FutureBuilder<ProfesionalesResponse>(
          future: _consulta,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No fue posible consultar los profesionales.'),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _consulta = _api.listar(soloActivos: true);
                        });
                      },
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }
            final professionals = snapshot.data!.data
                .where(
                  (persona) =>
                      persona.estado &&
                      persona.especialidadId == widget.service.especialidadId,
                )
                .toList();
            return SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: 520,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text('Cliente: ${widget.client.nombreCompleto}'),
                      Text('Servicio: ${widget.service.nombre}'),
                      const SizedBox(height: 16),
                      if (professionals.isEmpty)
                        const Text(
                          'No hay profesionales activos para esta especialidad.',
                        ),
                      if (professionals.isNotEmpty) ...[
                        const Text(
                          'Se asignará automáticamente un profesional disponible de esta especialidad.',
                        ),
                        for (final person in professionals)
                          ListTile(
                            leading: const Icon(Icons.person_outline),
                            title: Text(person.nombreCompleto),
                            subtitle: Text(person.nombreEspecialidad),
                          ),
                      ],
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                        ),
                        onPressed: professionals.isEmpty
                            ? null
                            : () {
                                Navigator.of(context).pushNamed(
                                  AppRoutes.reservationTime,
                                  arguments: (
                                    widget.client,
                                    widget.service,
                                    professionals,
                                    'Cualquiera',
                                  ),
                                );
                              },
                        child: const Text('Siguiente'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
