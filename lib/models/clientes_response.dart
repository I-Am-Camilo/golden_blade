import 'cliente.dart';

class ClientesResponse {
  const ClientesResponse({required this.data});
  final List<Cliente> data;

  factory ClientesResponse.fromJson(Map<String, dynamic> json) {
    final datos = json['data'];
    if (datos is! List) {
      throw const FormatException('El listado de clientes no es válido.');
    }
    return ClientesResponse(
      data: datos.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('El cliente recibido no es válido.');
        }
        return Cliente.fromJson(item);
      }).toList(),
    );
  }
}
