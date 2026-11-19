import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'routes/app_routes.dart';
import 'services/sesion_service.dart';
import 'theme/app_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GoldenBladeApp());
}

// Abre la aplicación completa desde Flutter Widget Preview en VS Code.
@Preview(name: 'Golden Blade', size: Size(393, 852))
Widget vistaPreviaGoldenBlade() => const GoldenBladeApp();

class GoldenBladeApp extends StatefulWidget {
  const GoldenBladeApp({super.key});

  @override
  State<GoldenBladeApp> createState() => _GoldenBladeAppState();
}

class _GoldenBladeAppState extends State<GoldenBladeApp>
    with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SesionService.alVencer = _volverAlLogin;
  }

  void _volverAlLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );
      _messengerKey.currentState?.hideCurrentSnackBar();
      _messengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Tu sesión venció. Ingresa de nuevo.')),
      );
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SesionService.verificarVencimiento();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SesionService.alVencer = null;
    SesionService.cerrar();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
    );
    return MaterialApp(
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: _messengerKey,
      title: 'Golden Blade',
      theme: ThemeData(colorScheme: colorScheme),
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.generarRuta,
    );
  }
}
