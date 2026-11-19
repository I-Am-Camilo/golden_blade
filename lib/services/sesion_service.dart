import 'dart:async';

import '../models/login_response.dart';
import 'almacenamiento_sesion_service.dart';

class SesionService {
  static LoginResponse? actual;
  static Timer? _temporizador;
  static void Function()? alVencer;

  static bool get activa {
    verificarVencimiento();
    return actual != null;
  }

  static void iniciar(LoginResponse sesion) {
    cerrar();
    actual = sesion;
    verificarVencimiento();
    if (actual != null) {
      _temporizador = Timer(
        sesion.vencimiento.difference(DateTime.now()),
        _vencer,
      );
    }
  }

  static void verificarVencimiento() {
    if (actual?.vencida == true) _vencer();
  }

  static Map<String, String> encabezados() {
    if (!activa) throw StateError('La sesión no está activa.');
    final sesion = actual!;
    return {
      'Content-Type': 'application/json',
      'Authorization': '${sesion.tokenType} ${sesion.accessToken}',
    };
  }

  static void revisarRespuesta(int codigo) {
    if (codigo == 401 && actual != null) _vencer();
  }

  static void _vencer() {
    cerrar();
    unawaited(AlmacenamientoSesionService.eliminar().catchError((Object _) {}));
    alVencer?.call();
  }

  static Future<void> cerrarSesion() async {
    cerrar();
    await AlmacenamientoSesionService.eliminar();
  }

  static void cerrar() {
    _temporizador?.cancel();
    _temporizador = null;
    actual = null;
  }
}
