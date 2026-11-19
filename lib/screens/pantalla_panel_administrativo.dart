import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../services/sesion_service.dart';
import '../services/reserva_service.dart';
import '../services/cliente_service.dart';
import '../models/resumen_panel.dart';
import '../models/cierre.dart';
import '../theme/app_colors.dart';
import '../widgets/golden_blade_logo.dart';

class PantallaPanelAdministrativo extends StatefulWidget {
  const PantallaPanelAdministrativo({
    super.key,
    this.reservaService,
    this.clienteService,
  });
  final ReservaService? reservaService;
  final ClienteService? clienteService;

  @override
  State<PantallaPanelAdministrativo> createState() =>
      _PantallaPanelAdministrativoState();
}

class _PantallaPanelAdministrativoState
    extends State<PantallaPanelAdministrativo>
    with WidgetsBindingObserver {
  late final ReservaService _reservas;
  late final ClienteService _clientes;
  ResumenPanel? _resumen;
  bool _cargando = false;
  String? _error;
  DateTime? _fechaConsulta;

  @override
  void initState() {
    super.initState();
    _reservas = widget.reservaService ?? ReservaService();
    _clientes = widget.clienteService ?? ClienteService();
    WidgetsBinding.instance.addObserver(this);
    _cargar();
  }

  Future<void> _cargar() async {
    if (_cargando) return;
    setState(() {
      _cargando = true;
      _error = null;
      _resumen = null;
    });
    try {
      final reservas = await _reservas.listar();
      final clientes = await _clientes.listar();
      final hoy = DateTime.now();
      final resumen = ResumenPanel.calcular(
        reservas,
        clientes.data.length,
        hoy,
      );
      if (!mounted) return;
      setState(() {
        _resumen = resumen;
        _fechaConsulta = hoy;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is ReservaException
            ? error.mensaje
            : error is ClienteException
            ? error.mensaje
            : 'No fue posible consultar los indicadores.';
      });
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _abrir(String ruta) async {
    await Navigator.of(context).pushNamed(ruta);
    if (mounted && SesionService.activa) await _cargar();
  }

  Future<void> _mas() async {
    await _openMore(context);
    if (mounted && SesionService.activa) await _cargar();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && SesionService.activa) _cargar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _reservas.cerrar();
    _clientes.cerrar();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sesion = SesionService.actual;
    return Theme(
      data: ThemeData.light(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: SizedBox(
                width: 520,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/fondo_splash.jpeg'),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Color(0xB8000000),
                            BlendMode.darken,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(child: GoldenBladeLogo(height: 64)),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.goldAccent,
                                foregroundColor: AppColors.onPrimary,
                                child: Icon(Icons.person_outline),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sesion?.usuario ?? 'Usuario',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      sesion?.rol ?? 'Sin sesión',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8),
                              IconButton(
                                tooltip: 'Cerrar sesión',
                                icon: const Icon(
                                  Icons.logout,
                                  color: Colors.white,
                                ),
                                onPressed: () async {
                                  try {
                                    await SesionService.cerrarSesion();
                                  } catch (_) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'No se pudo borrar la sesión guardada. Intenta cerrar sesión de nuevo.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  if (!context.mounted) return;
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    AppRoutes.login,
                                    (route) => false,
                                  );
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _SummaryCard(
                                  icon: Icons.calendar_today_outlined,
                                  value:
                                      _resumen?.reservasHoy.toString() ?? '—',
                                  label: 'Reservas hoy',
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: _SummaryCard(
                                  icon: Icons.person_add_alt_outlined,
                                  value:
                                      _resumen?.totalClientes.toString() ?? '—',
                                  label: 'Total clientes',
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _SummaryCard(
                                  icon: Icons.attach_money,
                                  value: _resumen == null
                                      ? '—'
                                      : _resumen!.valorCompletadas == null
                                      ? 'Sin precio'
                                      : Cierre.pesos(
                                          _resumen!.valorCompletadas!,
                                        ),
                                  label: 'Valor servicios completados hoy',
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: _SummaryCard(
                                  icon: Icons.content_cut,
                                  value:
                                      _resumen?.completadasHoy.toString() ??
                                      '—',
                                  label: 'Servicios completados hoy',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_cargando) const LinearProgressIndicator(),
                    if (_error != null)
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    if (_fechaConsulta != null && _resumen != null)
                      Text(
                        'Datos del ${MaterialLocalizations.of(context).formatCompactDate(_fechaConsulta!)}',
                      ),
                    TextButton.icon(
                      onPressed: _cargando ? null : _cargar,
                      icon: const Icon(Icons.refresh),
                      label: Text(
                        _error == null
                            ? 'Actualizar indicadores'
                            : 'Reintentar indicadores',
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Accesos rápidos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      padding: EdgeInsets.zero,
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      mainAxisExtent:
                          80 * MediaQuery.textScalerOf(context).scale(1),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _QuickAccess(
                          icon: Icons.calendar_month,
                          label: 'Agenda',
                          onPressed: () => _abrir(AppRoutes.agenda),
                        ),
                        _QuickAccess(
                          icon: Icons.event_available,
                          label: 'Nueva reserva',
                          onPressed: () => _abrir(AppRoutes.reservationClient),
                        ),
                        _QuickAccess(
                          icon: Icons.category_outlined,
                          label: 'Especialidades',
                          onPressed: () {
                            _abrir(AppRoutes.specialties);
                          },
                        ),
                        _QuickAccess(
                          icon: Icons.content_cut,
                          label: 'Servicios',
                          onPressed: () {
                            _abrir(AppRoutes.services);
                          },
                        ),
                        _QuickAccess(
                          icon: Icons.people_outline,
                          label: 'Profesionales',
                          onPressed: () {
                            _abrir(AppRoutes.professionals);
                          },
                        ),
                        _QuickAccess(
                          icon: Icons.person_outline,
                          label: 'Clientes',
                          onPressed: () {
                            _abrir(AppRoutes.clients);
                          },
                        ),
                        _QuickAccess(
                          icon: Icons.schedule,
                          label: 'Horarios',
                          onPressed: () => _abrir(AppRoutes.schedules),
                        ),
                        _QuickAccess(
                          icon: Icons.receipt_long,
                          label: 'Cierres',
                          onPressed: () => _abrir(AppRoutes.closings),
                        ),
                        _QuickAccess(
                          icon: Icons.payments_outlined,
                          label: 'Comisiones',
                          onPressed: () => _abrir(AppRoutes.commissions),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.buttonGoldDark,
          onTap: (index) {
            if (index == 1) {
              _abrir(AppRoutes.agenda);
            } else if (index == 2) {
              _abrir(AppRoutes.clients);
            } else if (index != 0) {
              _mas();
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month),
              label: 'Agenda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Clientes',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Más'),
          ],
        ),
      ),
    );
  }
}

Future<void> _openMore(BuildContext context) async {
  final route = await showModalBottomSheet<String>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          const ListTile(
            title: Text(
              'Más opciones',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          for (final option in {
            'Especialidades': AppRoutes.specialties,
            'Servicios': AppRoutes.services,
            'Profesionales': AppRoutes.professionals,
            'Horarios': AppRoutes.schedules,
            'Cierres': AppRoutes.closings,
            'Comisiones': AppRoutes.commissions,
          }.entries)
            ListTile(
              title: Text(option.key),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(sheetContext, option.value),
            ),
        ],
      ),
    ),
  );
  if (context.mounted && route != null) {
    await Navigator.pushNamed(context, route);
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: AppColors.fieldBackground,
            foregroundColor: AppColors.buttonGoldDark,
            child: Icon(icon, size: 17),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(label, style: const TextStyle(fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAccess extends StatelessWidget {
  const _QuickAccess({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.onPrimary,
        backgroundColor: AppColors.fieldBackground,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: onPressed,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: AppColors.buttonGoldDark),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
