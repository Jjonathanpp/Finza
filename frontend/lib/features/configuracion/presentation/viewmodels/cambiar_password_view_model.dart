import 'package:flutter/foundation.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/features/configuracion/data/datasources/preferencias_api.dart';

class CambiarPasswordViewModel extends ChangeNotifier {
  CambiarPasswordViewModel(this._api);

  final PreferenciasApi _api;

  bool _guardando = false;
  String? _error;

  bool get guardando => _guardando;
  String? get error => _error;

  // Devuelve true si el cambio fue exitoso. Si falla, deja el mensaje del backend en `error`.
  Future<bool> cambiarPassword(
    String contrasenaActual,
    String nuevaContrasena,
  ) async {
    if (_guardando) return false;
    _guardando = true;
    _error = null;
    notifyListeners();
    try {
      await _api.cambiarPassword(contrasenaActual, nuevaContrasena);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _guardando = false;
      notifyListeners();
    }
  }
}
