import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';

class LoginException implements Exception {
  const LoginException(this.mensaje);
  final String mensaje;
}

class LoginService {
  LoginService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<LoginResponse> iniciar(LoginRequest request) async {
    try {
      final respuesta = await _client
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/Sesion'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 20));

      if (respuesta.statusCode == 400 || respuesta.statusCode == 401) {
        throw const LoginException('Usuario o contraseña incorrectos.');
      }
      if (respuesta.statusCode == 403) {
        throw const LoginException('No tienes permiso para ingresar.');
      }
      if (respuesta.statusCode >= 500) {
        throw const LoginException(
          'El servidor no está disponible. Intenta más tarde.',
        );
      }
      if (respuesta.statusCode != 200) {
        throw const LoginException(
          'No fue posible iniciar sesión. Intenta de nuevo.',
        );
      }
      final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
      if (datos is! Map<String, dynamic>) {
        throw const FormatException('Respuesta de sesión no válida.');
      }
      return LoginResponse.fromJson(datos);
    } on TimeoutException {
      throw const LoginException(
        'La conexión tardó demasiado. Intenta de nuevo.',
      );
    } on http.ClientException {
      throw const LoginException(
        'No se pudo conectar con la API. Revisa tu conexión.',
      );
    } on FormatException {
      throw const LoginException(
        'La API devolvió una sesión no válida. Intenta de nuevo.',
      );
    }
  }

  void cerrar() => _client.close();
}
