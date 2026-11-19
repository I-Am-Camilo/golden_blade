import 'package:flutter/material.dart';

import '../models/cliente.dart';
import '../models/reserva.dart';
import '../routes/app_routes.dart';
import '../services/cliente_service.dart';
import '../theme/app_colors.dart';

class PantallaDetalleCliente extends StatefulWidget {
  const PantallaDetalleCliente({
    super.key,
    required this.cliente,
    this.servicioApi,
  });
  final Cliente cliente;
  final ClienteService? servicioApi;
  @override
  State<PantallaDetalleCliente> createState() => _PantallaDetalleClienteState();
}

class _PantallaDetalleClienteState extends State<PantallaDetalleCliente> {
  late final ClienteService _api;
  late String _documento;
  late Future<Cliente> _consulta;
  Future<List<Reserva>>? _historial;
  @override
  void initState() {
    super.initState();
    _api = widget.servicioApi ?? ClienteService();
    _documento = widget.cliente.documento;
    _consulta = _cargarCliente();
  }

  @override
  void dispose() {
    _api.cerrar();
    super.dispose();
  }

  Future<Cliente> _cargarCliente() async {
    final cliente = await _api.buscarPorDocumento(_documento);
    if (cliente.id != widget.cliente.id) {
      throw const ClienteException(
        'El documento ya no corresponde al cliente seleccionado. Actualiza el listado.',
      );
    }
    return cliente;
  }

  void _recargar() {
    setState(() {
      _consulta = _cargarCliente();
      _historial = null;
    });
  }

  Future<void> _editar(Cliente cliente) async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final resultado = await Navigator.pushNamed(
      context,
      AppRoutes.editClient,
      arguments: cliente,
    );
    if (!mounted || resultado is! Cliente) return;
    _documento = resultado.documento;
    _recargar();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Cliente actualizado.')));
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: ThemeData.light(),
    child: DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Detalle del cliente'),
          centerTitle: true,
          backgroundColor: Colors.white,
          actions: [
            IconButton(
              tooltip: 'Actualizar cliente',
              onPressed: _recargar,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: SizedBox(
              width: 480,
              child: FutureBuilder<Cliente>(
                future: _consulta,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.buttonGoldDark,
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return _error(snapshot.error, _recargar);
                  }
                  final cliente = snapshot.data!;
                  return Column(
                    children: [
                      const SizedBox(height: 12),
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.goldAccent,
                        foregroundColor: AppColors.onPrimary,
                        child: Text(
                          cliente.nombres.isEmpty ? '?' : cliente.nombres[0],
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cliente.nombreCompleto,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const TabBar(
                        labelColor: AppColors.buttonGoldDark,
                        indicatorColor: AppColors.buttonGoldDark,
                        tabs: [
                          Tab(text: 'Información'),
                          Tab(text: 'Historial'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                _dato('ID', '${cliente.id}'),
                                _dato('Documento', cliente.documento),
                                _dato('Nombres', cliente.nombres),
                                _dato('Apellidos', cliente.apellidos),
                                _dato(
                                  'Fecha de nacimiento',
                                  cliente.nacimientoTexto,
                                ),
                                _dato('Celular', cliente.celular),
                                _dato('Correo', cliente.correo),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.onPrimary,
                                    minimumSize: const Size(0, 48),
                                  ),
                                  onPressed: () => _editar(cliente),
                                  child: const Text('Editar cliente'),
                                ),
                              ],
                            ),
                            FutureBuilder<List<Reserva>>(
                              future: _historial ??= _api.historial(cliente.id),
                              builder: (context, historial) {
                                if (historial.connectionState !=
                                    ConnectionState.done) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                if (historial.hasError) {
                                  return _error(historial.error, () {
                                    setState(() {
                                      _historial = _api.historial(cliente.id);
                                    });
                                  });
                                }
                                final reservas = historial.data!;
                                if (reservas.isEmpty) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Text(
                                        'Este cliente no tiene reservas registradas.',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  );
                                }
                                return ListView.separated(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: reservas.length,
                                  separatorBuilder: (_, index) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final reserva = reservas[index];
                                    final fecha = MaterialLocalizations.of(
                                      context,
                                    ).formatMediumDate(reserva.fecha);
                                    return ListTile(
                                      tileColor: AppColors.fieldBackground,
                                      leading: const Icon(
                                        Icons.event_note,
                                        color: AppColors.buttonGoldDark,
                                      ),
                                      title: Text(reserva.servicio),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Reserva #${reserva.id} · ${reserva.estadoTexto}',
                                          ),
                                          Text(
                                            '$fecha · ${_hora(reserva.horaInicio)} - ${_hora(reserva.horaFin)}',
                                          ),
                                          Text(
                                            reserva.profesional.isEmpty
                                                ? 'Profesional sin asignar'
                                                : reserva.profesional,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    ),
  );
  String _hora(String hora) => hora.length >= 5 ? hora.substring(0, 5) : hora;
  Widget _dato(String titulo, String valor) => ListTile(
    title: Text(titulo),
    subtitle: Text(valor.isEmpty ? 'Sin registrar' : valor),
  );
  Widget _error(Object? error, VoidCallback reintentar) => Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            error is ClienteException
                ? error.mensaje
                : 'No fue posible consultar los datos.',
            textAlign: TextAlign.center,
          ),
          TextButton(onPressed: reintentar, child: const Text('Reintentar')),
        ],
      ),
    ),
  );
}
