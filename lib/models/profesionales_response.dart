import 'profesional.dart';

class ProfesionalesResponse {
  const ProfesionalesResponse({required this.data});
  final List<Profesional> data;

  factory ProfesionalesResponse.fromJson(Map<String, dynamic> json) {
    final datos = json['data'];
    if (datos is! List) {
      throw const FormatException('El listado de profesionales no es válido.');
    }
    return ProfesionalesResponse(
      data: datos.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('El profesional recibido no es válido.');
        }
        return Profesional.fromJson(item);
      }).toList(),
    );
  }
}
