import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/lista-invitaciones/data/models/invitacion_enviada.dart';
import 'package:frontend/features/lista-invitaciones/data/models/invitacion_recibida.dart';

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

  // ---- Para quien abre el enlace de la invitación (t-11.2.2): solo con el token ----

  Future<InvitacionRecibida> detalle(String token) async {
    final data = await _api.post('/api/invitaciones/detalle', {'token': token});
    return InvitacionRecibida.fromJson((data as Map).cast<String, dynamic>());
  }

  // Devuelve la cuenta compartida a la que se entró, con el formato del selector de cuenta
  // ({id, nombre, rol, perfilId}): se guarda tal cual como cuenta activa.
  Future<Map<String, dynamic>> aceptar(String token) async {
    final data = await _api.post('/api/invitaciones/aceptar', {'token': token});
    return (data as Map).cast<String, dynamic>();
  }

  Future<void> rechazar(String token) async {
    await _api.post('/api/invitaciones/rechazar', {'token': token});
  }
}


