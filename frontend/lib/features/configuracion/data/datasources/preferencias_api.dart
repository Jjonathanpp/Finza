import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/shared/utils/importe.dart';

class PreferenciasApi {
  PreferenciasApi(this._api);

  final ApiClient _api;

  Future<MonedaVista> moneda() async =>
      monedaDesdeJson(await _api.get('/api/preferencias/moneda'));

  // Devuelve la moneda guardada con la cotización del día.
  Future<MonedaVista> cambiarMoneda(String moneda) async => monedaDesdeJson(
    await _api.put('/api/preferencias/moneda', {'moneda': moneda}),
  );

  // Cambia la contraseña de la cuenta autenticada. Si la actual es incorrecta, el backend responde 400.
  Future<void> cambiarPassword(
    String contrasenaActual,
    String nuevaContrasena,
  ) async {
    await _api.post('/api/auth/cambio-contrasena', {
      'contraseña_actual': contrasenaActual,
      'nueva_contraseña': nuevaContrasena,
    });
  }
}
