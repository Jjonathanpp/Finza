import 'package:frontend/core/network/api_client.dart';

class CuentaCompartidaApi {
  CuentaCompartidaApi(this._api);

  final ApiClient _api;

  // Las cuentas compartidas en las que está el usuario, con su rol y su perfil ahí:
  // [{id, nombre, rol, perfilId}] (t-13.1.2). El perfilId es el que va en X-Perfil-Id.
  Future<List<Map<String, dynamic>>> listarMias() async =>
      (await _api.get('/api/cuentas-compartidas') as List).cast<Map<String, dynamic>>();

  // Crea una cuenta compartida en la que quien la crea es el administrador (t-11.1.4).
  // Devuelve {id, nombre, perfilId}, sin el rol.
  Future<Map<String, dynamic>> crear(String nombre) async =>
      (await _api.post('/api/cuentas-compartidas', {'nombre': nombre}) as Map).cast<String, dynamic>();
}
