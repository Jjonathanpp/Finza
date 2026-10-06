import 'package:flutter/foundation.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/features/movimientos/data/datasources/movimiento_api.dart';
import 'package:frontend/features/movimientos/data/models/movimiento.dart';

class MovimientosViewModel extends ChangeNotifier {
  MovimientosViewModel(this._api);
  final MovimientoApi _api;

  List<Movimiento> _movimientos = [];
  bool _cargando = false;
  bool _cargandoMas = false;
  String? _error;
  bool _hayMas = true;
  int _pagina = 0;
  bool _cerrado = false;

  List<Movimiento> get movimientos => _movimientos;
  bool get cargando => _cargando;
  bool get cargandoMas => _cargandoMas;
  String? get error => _error;
  bool get hayMas => _hayMas;

  @override
  void notifyListeners() {
    if (!_cerrado) super.notifyListeners();
  }

  @override
  void dispose() {
    _cerrado = true;
    super.dispose();
  }

  Future<void> cargarInicial() async {
    _cargando = true;
    _error = null;
    _pagina = 0;
    _hayMas = true;
    notifyListeners();

    try {
      final nuevos = await _api.listar(pagina: _pagina);
      _movimientos = nuevos;
      _hayMas = nuevos.isNotEmpty;
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> cargarMas() async {
    if (_cargando || _cargandoMas || !_hayMas) return;

    _cargandoMas = true;
    _pagina++;
    notifyListeners();

    try {
      final nuevos = await _api.listar(pagina: _pagina);
      if (nuevos.isEmpty) {
        _hayMas = false;
      } else {
        _movimientos.addAll(nuevos);
      }
    } on ApiException catch (e) {
      _pagina--; // Revertimos la página para poder reintentar
    } finally {
      _cargandoMas = false;
      notifyListeners();
    }
  }
}