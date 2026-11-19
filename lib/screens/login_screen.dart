import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../models/login_request.dart';
import '../services/login_service.dart';
import '../services/sesion_service.dart';
import '../services/almacenamiento_sesion_service.dart';
import '../theme/app_colors.dart';
import '../widgets/golden_blade_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.loginService});

  final LoginService? loginService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hidePassword = true;
  bool _loading = false;
  bool _recordarSesion = false;
  String? _errorMessage;
  late final LoginService _loginService;

  @override
  void initState() {
    super.initState();
    _loginService = widget.loginService ?? LoginService();
  }

  @override
  void dispose() {
    _loginService.cerrar();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_loading) return;
    final usuario = _usernameController.text.trim();
    final clave = _passwordController.text;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    if (usuario.isEmpty || clave.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            usuario.isEmpty
                ? 'Ingresa tu usuario o correo.'
                : 'Ingresa tu contraseña.',
          ),
        ),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final request = LoginRequest(usuario: usuario, clave: clave);
      final sesion = await _loginService.iniciar(request);
      if (!mounted) return;
      try {
        if (_recordarSesion) {
          await AlmacenamientoSesionService.guardar(sesion);
        } else {
          await AlmacenamientoSesionService.eliminar();
        }
      } catch (_) {
        throw const LoginException(
          'No se pudo actualizar la sesión guardada en este dispositivo. '
          'Reinicia la vista previa e intenta de nuevo.',
        );
      }
      if (!mounted) return;
      SesionService.iniciar(sesion);
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRoutes.welcome, (route) => false);
    } on LoginException catch (error) {
      if (mounted) setState(() => _errorMessage = error.mensaje);
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage =
              'No fue posible iniciar sesión. Intenta de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _clearAuthenticationError(String _) {
    if (_errorMessage != null) setState(() => _errorMessage = null);
  }

  @override
  Widget build(BuildContext context) {
    final fieldDecoration = InputDecoration(
      hintStyle: const TextStyle(color: Colors.black54),
      prefixIconColor: Colors.black54,
      suffixIconColor: Colors.black54,
      filled: true,
      fillColor: const Color(0xFFF7F7F7),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );

    return Scaffold(
      backgroundColor: Color(0xFF17110C),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/fondo_splash.jpeg', fit: BoxFit.cover),

          Container(color: Color(0x88000000)),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(maxWidth: 340),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const GoldenBladeLogo(height: 150),

                      SizedBox(height: 8),

                      TextField(
                        controller: _usernameController,
                        enabled: !_loading,
                        onChanged: _clearAuthenticationError,
                        style: const TextStyle(color: Colors.black87),
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        decoration: fieldDecoration.copyWith(
                          hintText: 'Usuario o correo',
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: _passwordController,
                        enabled: !_loading,
                        onChanged: _clearAuthenticationError,
                        style: const TextStyle(color: Colors.black87),
                        obscureText: _hidePassword,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _login(),
                        decoration: fieldDecoration.copyWith(
                          hintText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: _hidePassword
                                ? 'Mostrar contraseña'
                                : 'Ocultar contraseña',
                            icon: Icon(
                              _hidePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: _loading
                                ? null
                                : () {
                                    setState(() {
                                      _hidePassword = !_hidePassword;
                                    });
                                  },
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      if (_errorMessage != null)
                        Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: AppColors.error,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),

                      Row(
                        children: [
                          Checkbox(
                            value: _recordarSesion,
                            onChanged: _loading
                                ? null
                                : (valor) {
                                    setState(
                                      () => _recordarSesion = valor ?? false,
                                    );
                                  },
                          ),

                          Text(
                            'Recordar sesión',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),

                      SizedBox(height: 8),

                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [Color(0xFFD9A74B), Color(0xFF926020)],
                          ),
                          border: Border.all(color: Color(0xFFE3B85F)),
                        ),

                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 48),
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),

                          onPressed: _loading ? null : _login,
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Ingresar'),
                        ),
                      ),

                      SizedBox(height: 8),

                      TextButton(
                        onPressed: _loading
                            ? null
                            : () {
                                Navigator.of(context)
                                    .pushNamed(AppRoutes.resetPassword);
                              },
                        child: Text(
                          '¿Olvidaste tu contraseña?',
                          style: TextStyle(
                            color: Colors.white70,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
