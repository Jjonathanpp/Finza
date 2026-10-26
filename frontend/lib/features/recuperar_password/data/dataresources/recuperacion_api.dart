import 'package:frontend/core/network/api_client.dart';

class RecuperacionApi {
  RecuperacionApi(this._api);

  final ApiClient _api;

  Future<void> solicitarCodigo(String email) async {
    await _api.post('/api/auth/olvide-contrasena', {'email': email});
  }

  Future<void> restablecer({
    required String email,
    required String codigo,
    required String nuevaContrasena,
  }) async {
    await _api.post('/api/auth/restablecer-contrasena', {
      'email': email,
      'codigo': codigo,
      'nuevaContrasena': nuevaContrasena,
    });
  }
}
