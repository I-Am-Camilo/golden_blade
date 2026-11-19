import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/login_response.dart';

class AlmacenamientoSesionService {
  static const _seguro = FlutterSecureStorage();
  static const _claveSesion = 'golden_blade_sesion';
  static const _claveRecordar = 'golden_blade_recordar_sesion';

  static Future<void> guardar(LoginResponse sesion) async {
    final preferencias = await SharedPreferences.getInstance();
    // Primero desactivamos la restauración por si falla la escritura segura.
    await preferencias.setBool(_claveRecordar, false);
    await _seguro.write(
      key: _claveSesion,
      value: jsonEncode({
        'accessToken': sesion.accessToken,
        'tokenType': sesion.tokenType,
        'expiresIn': sesion.expiresIn,
        'empresaId': sesion.empresaId,
        'empresaNombre': sesion.empresaNombre,
        'vencimiento': sesion.vencimiento.toUtc().toIso8601String(),
      }),
    );
    await preferencias.setBool(_claveRecordar, true);
  }

  static Future<LoginResponse?> recuperar() async {
    final preferencias = await SharedPreferences.getInstance();
    if (preferencias.getBool(_claveRecordar) != true) return null;
    final texto = await _seguro.read(key: _claveSesion);
    try {
      if (texto == null) throw const FormatException();
      final datos = jsonDecode(texto) as Map<String, dynamic>;
      final vencimiento = DateTime.parse(datos['vencimiento'] as String);
      if (!DateTime.now().isBefore(vencimiento)) {
        throw const FormatException();
      }
      // También comprueba el vencimiento original del JWT; no renueva el token.
      final sesion = LoginResponse.fromJson(datos);
      return LoginResponse(
        accessToken: sesion.accessToken,
        tokenType: sesion.tokenType,
        expiresIn: sesion.expiresIn,
        empresaId: sesion.empresaId,
        empresaNombre: sesion.empresaNombre,
        usuario: sesion.usuario,
        rol: sesion.rol,
        vencimiento: vencimiento.isBefore(sesion.vencimiento)
            ? vencimiento
            : sesion.vencimiento,
      );
    } on FormatException {
      await eliminar();
      return null;
    } on TypeError {
      await eliminar();
      return null;
    }
  }

  static Future<void> eliminar() async {
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.setBool(_claveRecordar, false);
    await _seguro.delete(key: _claveSesion);
  }
}
