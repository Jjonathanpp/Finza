import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/lista-invitaciones/data/models/invitacion_enviada.dart';

class InvitacionApi {
  InvitacionApi(this._api);

  final ApiClient _api;

  Future<List<InvitacionEnviada>> listar(int cuentaCompartidaId) async {
    final data = await _api.get(
      '/api/cuentas-compartidas/$cuentaCompartidaId/invitaciones',
    );
    return (data as List)
        .map((json) => InvitacionEnviada.fromJson(json))
        .toList();
  }
}
