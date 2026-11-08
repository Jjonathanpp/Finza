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

  Future<InvitacionEnviada> invitar(
    int cuentaCompartidaId,
    String email,
  ) async {
    final data = await _api.post(
      '/api/cuentas-compartidas/$cuentaCompartidaId/invitaciones',
      {'email': email},
    );
    return InvitacionEnviada.fromJson(data);
  }
}
