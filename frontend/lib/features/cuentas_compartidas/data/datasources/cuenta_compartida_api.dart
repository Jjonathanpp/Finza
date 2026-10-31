import 'package:frontend/core/network/api_client.dart';

class CuentaCompartidaApi {
  CuentaCompartidaApi(this._api);

  final ApiClient _api;

  // Las cuentas compartidas en las que está el usuario, con su rol y su perfil ahí:
  // [{id, nombre, rol, perfilId}] (t-13.1.2). El perfilId es el que va en X-Perfil-Id.
  Future<List<Map<String, dynamic>>> listarMias() async =>
      (await _api.get('/api/cuentas-compartidas') as List).cast<Map<String, dynamic>>();
}
