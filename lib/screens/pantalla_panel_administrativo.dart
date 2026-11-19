import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../services/sesion_service.dart';
import '../theme/app_colors.dart';
import '../widgets/golden_blade_logo.dart';

class PantallaPanelAdministrativo extends StatelessWidget {
  const PantallaPanelAdministrativo({super.key});

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
                                  value: '—',
                                  label: 'Reservas hoy',
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: _SummaryCard(
                                  icon: Icons.person_add_alt_outlined,
                                  value: '—',
                                  label: 'Clientes nuevos',
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
                                  value: '—',
                                  label: 'Ingresos del día',
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: _SummaryCard(
                                  icon: Icons.content_cut,
                                  value: '—',
                                  label: 'Servicios del día',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Indicadores no disponibles por el momento.',
                      style: TextStyle(color: Colors.black54),
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
                      mainAxisExtent: 80,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _QuickAccess(
                          icon: Icons.calendar_month,
                          label: 'Agenda',
                          onPressed: () =>
                              Navigator.of(context).pushNamed(AppRoutes.agenda),
                        ),
                        _QuickAccess(
                          icon: Icons.event_available,
                          label: 'Nueva reserva',
                          onPressed: () =>
                              Navigator.of(context)
                                  .pushNamed(AppRoutes.reservationClient),
                        ),
                        _QuickAccess(
                          icon: Icons.category_outlined,
                          label: 'Especialidades',
                          onPressed: () {
                            Navigator.of(context)
                                .pushNamed(AppRoutes.specialties);
                          },
                        ),
                        _QuickAccess(
                          icon: Icons.content_cut,
                          label: 'Servicios',
                          onPressed: () {
                            Navigator.of(context).pushNamed(AppRoutes.services);
                          },
                        ),
                        _QuickAccess(
                          icon: Icons.people_outline,
                          label: 'Profesionales',
                          onPressed: () {
                            Navigator.of(context)
                                .pushNamed(AppRoutes.professionals);
                          },
                        ),
                        _QuickAccess(
                          icon: Icons.person_outline,
                          label: 'Clientes',
                          onPressed: () {
                            Navigator.of(context).pushNamed(AppRoutes.clients);
                          },
                        ),
                        _QuickAccess(
                          icon: Icons.schedule,
                          label: 'Horarios',
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRoutes.schedules),
                        ),
                        _QuickAccess(
                          icon: Icons.receipt_long,
                          label: 'Cierres',
                          onPressed: () =>
                              Navigator.of(context)
                                  .pushNamed(AppRoutes.closings),
                        ),
                        _QuickAccess(
                          icon: Icons.payments_outlined,
                          label: 'Comisiones',
                          onPressed: () => Navigator.pushNamed(
                            context,
                            AppRoutes.commissions,
                          ),
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
              Navigator.of(context).pushNamed(AppRoutes.agenda);
            } else if (index == 2) {
              Navigator.of(context).pushNamed(AppRoutes.clients);
            } else if (index != 0) {
              _openMore(context);
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
    Navigator.pushNamed(context, route);
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
