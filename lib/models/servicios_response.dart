import 'servicio.dart';

class ServiciosResponse {
  const ServiciosResponse({required this.data});
  final List<Servicio> data;

  factory ServiciosResponse.fromJson(Map<String, dynamic> json) {
    final datos = json['data'];
    if (datos is! List) {
      throw const FormatException('El listado de servicios no es válido.');
    }
    return ServiciosResponse(
      data: datos.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('El servicio recibido no es válido.');
        }
        return Servicio.fromJson(item);
      }).toList(),
    );
  }
}
