import 'dart:convert';

class LoginResponse {
  const LoginResponse({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.empresaId,
    required this.empresaNombre,
    required this.usuario,
    required this.rol,
    required this.vencimiento,
  });

  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final int empresaId;
  final String empresaNombre;
  final String usuario;
  final String rol;
  final DateTime vencimiento;

  bool get vencida => !DateTime.now().isBefore(vencimiento);

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final token = json['accessToken'];
    final tipo = json['tokenType'];
    final segundos = json['expiresIn'];
    final empresaId = json['empresaId'];
    final empresaNombre = json['empresaNombre'];
    if (token is! String ||
        token.isEmpty ||
        tipo is! String ||
        tipo.isEmpty ||
        segundos is! int ||
        segundos <= 0 ||
        empresaId is! int ||
        empresaNombre is! String) {
      throw const FormatException('Respuesta de sesión incompleta.');
    }

    final partes = token.split('.');
    if (partes.length != 3) {
      throw const FormatException('Token de sesión no válido.');
    }
    final contenido = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(partes[1]))),
    );
    if (contenido is! Map<String, dynamic>) {
      throw const FormatException('Contenido de sesión no válido.');
    }
    final usuario = contenido['usuario'];
    final rol =
        contenido['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'];
    final exp = contenido['exp'];
    if (usuario is! String ||
        usuario.isEmpty ||
        rol is! String ||
        exp is! int) {
      throw const FormatException('Datos de usuario incompletos.');
    }
    final venceToken = DateTime.fromMillisecondsSinceEpoch(
      exp * 1000,
      isUtc: true,
    );
    final venceRespuesta = DateTime.now().toUtc().add(
      Duration(seconds: segundos),
    );
    final vencimiento = venceToken.isBefore(venceRespuesta)
        ? venceToken
        : venceRespuesta;
    if (!vencimiento.isAfter(DateTime.now().toUtc())) {
      throw const FormatException('La sesión recibida ya venció.');
    }
    return LoginResponse(
      accessToken: token,
      tokenType: tipo,
      expiresIn: segundos,
      empresaId: empresaId,
      empresaNombre: empresaNombre,
      usuario: usuario,
      rol: rol,
      vencimiento: vencimiento,
    );
  }
}
