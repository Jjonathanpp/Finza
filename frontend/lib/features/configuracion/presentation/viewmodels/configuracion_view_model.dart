import 'package:flutter/foundation.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/features/configuracion/data/datasources/preferencias_api.dart';
import 'package:frontend/shared/utils/importe.dart';

class ConfiguracionViewModel extends ChangeNotifier {
  ConfiguracionViewModel(this._api);

  final PreferenciasApi _api;

  bool _guardando = false;
  String? _error;

  bool get guardando => _guardando;
  String? get error => _error;

  // Se guarda en el backend y, con lo que devuelve (la cotización del día), cambia en toda la app.
  // Si falla, queda la que estaba.
  Future<void> elegirMoneda(String moneda) async {
    if (_guardando || moneda == monedaVista.value.moneda) return;
    _guardando = true;
    _error = null;
    notifyListeners();
    try {
      monedaVista.value = await _api.cambiarMoneda(moneda);
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _guardando = false;
      notifyListeners();
    }
  }
}
