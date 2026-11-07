import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/cuentas_compartidas/data/models/miembro.dart';
 
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
 
  // Los integrantes de la cuenta compartida en la que está la app (la del header X-Perfil-Id),
  // en el orden en que entraron (t-11.3.2).
  Future<List<Miembro>> listarMiembros() async =>
      (await _api.get('/api/cuentas-compartidas/miembros') as List)
          .map((json) => Miembro.fromJson((json as Map).cast<String, dynamic>()))
          .toList();
 
  // Solo un ADMIN, y no sobre sí mismo ni sobre quien creó la cuenta: si no, el backend
  // responde 400/403 con el motivo (llega como ApiException).
  Future<void> cambiarRol(int perfilId, String rol) async {
    await _api.put('/api/cuentas-compartidas/perfiles/$perfilId/rol', {'rol': rol});
  }
}