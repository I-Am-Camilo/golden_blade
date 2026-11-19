import 'package:flutter/material.dart';

import '../models/cliente.dart';
import '../models/clientes_response.dart';
import '../routes/app_routes.dart';
import '../services/cliente_service.dart';
import '../theme/app_colors.dart';

class PantallaClientes extends StatefulWidget {
  const PantallaClientes({super.key, this.selecting = false, this.servicioApi});
  final bool selecting;
  final ClienteService? servicioApi;
  @override
  State<PantallaClientes> createState() => _PantallaClientesState();
}

class _PantallaClientesState extends State<PantallaClientes> {
  final _busqueda = TextEditingController();
  late final ClienteService _api;
  late Future<ClientesResponse> _consulta;
  int? _seleccionadoId;
  @override
  void initState() {
    super.initState();
    _api = widget.servicioApi ?? ClienteService();
    _consulta = _api.listar();
  }

  @override
  void dispose() {
    _busqueda.dispose();
    _api.cerrar();
    super.dispose();
  }

  String _normalizar(String texto) => texto
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ü', 'u');
  void _recargar() {
    setState(() {
      _seleccionadoId = null;
      _consulta = _api.listar();
    });
  }

  Future<void> _nuevo() async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final resultado = await Navigator.pushNamed(context, AppRoutes.newClient);
    if (!mounted || resultado is! Cliente) return;
    setState(() {
      _busqueda.clear();
      _seleccionadoId = widget.selecting ? resultado.id : null;
      _consulta = _api.listar();
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Cliente creado.')));
  }

  Future<void> _abrir(Cliente cliente) async {
    FocusScope.of(context).unfocus();
    if (widget.selecting) {
      setState(() {
        _seleccionadoId = cliente.id;
      });
      return;
    }
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    await Navigator.pushNamed(
      context,
      AppRoutes.clientDetail,
      arguments: cliente,
    );
    if (mounted) _recargar();
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: ThemeData.light(),
    child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(widget.selecting ? 'Seleccionar cliente' : 'Clientes'),
        actions: [
          IconButton(
            tooltip: 'Actualizar clientes',
            onPressed: _recargar,
            icon: const Icon(Icons.refresh, color: AppColors.buttonGoldDark),
          ),
          IconButton(
            tooltip: 'Nuevo cliente',
            onPressed: _nuevo,
            icon: const Icon(Icons.add, color: AppColors.buttonGoldDark),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: 520,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _busqueda,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Nombre, documento o celular',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: AppColors.fieldBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: FutureBuilder<ClientesResponse>(
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
                          final error = snapshot.error;
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  error is ClienteException
                                      ? error.mensaje
                                      : 'No se pudieron cargar los clientes.',
                                  textAlign: TextAlign.center,
                                ),
                                TextButton(
                                  onPressed: _recargar,
                                  child: const Text('Reintentar'),
                                ),
                              ],
                            ),
                          );
                        }
                        final clientes = snapshot.data!.data;
                        final texto = _normalizar(_busqueda.text.trim());
                        final visibles = clientes
                            .where(
                              (cliente) =>
                                  _normalizar(cliente.nombreCompleto)
                                      .contains(texto) ||
                                  cliente.documento.contains(texto) ||
                                  cliente.celular.contains(texto),
                            )
                            .toList();
                        final seleccionados = clientes
                            .where((cliente) => cliente.id == _seleccionadoId)
                            .toList();
                        return Column(
                          children: [
                            Expanded(
                              child: visibles.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.search_off,
                                            size: 36,
                                          ),
                                          const Text(
                                            'No se encontraron clientes.',
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              setState(() {
                                                _busqueda.clear();
                                              });
                                            },
                                            child: const Text(
                                              'Limpiar búsqueda',
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.separated(
                                      keyboardDismissBehavior:
                                          ScrollViewKeyboardDismissBehavior
                                              .onDrag,
                                      itemCount: visibles.length,
                                      separatorBuilder: (_, index) =>
                                          const SizedBox(height: 8),
                                      itemBuilder: (context, index) {
                                        final cliente = visibles[index];
                                        final seleccionado =
                                            _seleccionadoId == cliente.id;
                                        return ListTile(
                                          tileColor: AppColors.fieldBackground,
                                          selectedTileColor:
                                              AppColors.goldAccent,
                                          selected: seleccionado,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          leading: CircleAvatar(
                                            backgroundColor:
                                                AppColors.goldAccent,
                                            foregroundColor:
                                                AppColors.onPrimary,
                                            child: Text(
                                              cliente.nombres.isEmpty
                                                  ? '?'
                                                  : cliente.nombres[0],
                                            ),
                                          ),
                                          title: Text(cliente.nombreCompleto),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('Doc. ${cliente.documento}'),
                                              if (cliente.celular.isNotEmpty)
                                                Text(cliente.celular),
                                              if (cliente.correo.isNotEmpty)
                                                Text(cliente.correo),
                                            ],
                                          ),
                                          trailing: Icon(
                                            widget.selecting
                                                ? seleccionado
                                                      ? Icons.check_circle
                                                      : Icons
                                                            .radio_button_unchecked
                                                : Icons.chevron_right,
                                          ),
                                          onTap: () => _abrir(cliente),
                                        );
                                      },
                                    ),
                            ),
                            if (widget.selecting)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.onPrimary,
                                ),
                                onPressed: seleccionados.length != 1
                                    ? null
                                    : () => Navigator.pushNamed(
                                        context,
                                        AppRoutes.reservationService,
                                        arguments: seleccionados.single,
                                      ),
                                child: const Text('Siguiente'),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
