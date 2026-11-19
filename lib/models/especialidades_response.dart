import 'especialidad.dart';

class EspecialidadesResponse {
  const EspecialidadesResponse({required this.data});

  final List<Especialidad> data;

  factory EspecialidadesResponse.fromJson(Map<String, dynamic> json) {
    final datos = json['data'];
    if (datos is! List) {
      throw const FormatException('El listado de especialidades no es válido.');
    }
    return EspecialidadesResponse(
      data: datos.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('La especialidad recibida no es válida.');
        }
        return Especialidad.fromJson(item);
      }).toList(),
    );
  }
}
