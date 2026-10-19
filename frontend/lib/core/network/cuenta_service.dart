import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/core/network/api_client.dart';

enum EliminarCuentaResultado {
  exito,
  passwordIncorrecta,
  sesionInvalida,
  error,
}

class CuentaService {
  final ApiClient _api = ApiClient();

  Future<EliminarCuentaResultado> eliminarCuenta(String password) async {
    try {
      await _api.delete('/api/auth/me', {'password': password});
      return EliminarCuentaResultado.exito;
    } on ApiException catch (e) {
      if (e.status == 401 || e.status == 403) {
        // El backend usa 401 para contraseña incorrecta y para token inválido o vencido
        return e.message == 'Credenciales incorrectas'
            ? EliminarCuentaResultado.passwordIncorrecta
            : EliminarCuentaResultado.sesionInvalida;
      }
      return EliminarCuentaResultado.error;
    }
  }
}
