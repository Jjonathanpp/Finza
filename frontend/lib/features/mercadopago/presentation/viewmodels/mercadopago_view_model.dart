import 'package:flutter/foundation.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/features/mercadopago/data/datasources/mercadopago_api.dart';
import 'package:frontend/features/mercadopago/data/models/mercadopago_estado.dart';

class MercadoPagoViewModel extends ChangeNotifier {
  MercadoPagoViewModel(this._api);

  final MercadoPagoApi _api;

  bool _cargando = false;
  String? _error;
  MercadoPagoEstado? _estado;
  bool _cerrado = false;

  @override
  void notifyListeners() {
    if (!_cerrado) super.notifyListeners();
  }

  @override
  void dispose() {
    _cerrado = true;
    super.dispose();
  }

  bool get cargando => _cargando;
  String? get error => _error;
  MercadoPagoEstado? get estado => _estado;
  bool get estaConectado => _estado?.conectado ?? false;

  Future<void> cargar() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _estado = await _api.obtenerEstado();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  // Devuelve null si desvinculó con éxito, o el mensaje de error del backend si falló.
  Future<String?> desvincular() async {
    _cargando = true;
    notifyListeners();
    try {
      await _api.desvincular();
      _estado = const MercadoPagoEstado(conectado: false);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }
}