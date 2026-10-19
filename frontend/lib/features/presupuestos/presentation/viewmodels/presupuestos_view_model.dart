import 'package:flutter/foundation.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/features/presupuestos/data/datasources/presupuesto_api.dart';
import 'package:frontend/features/presupuestos/data/models/presupuesto.dart';

class PresupuestosViewModel extends ChangeNotifier {
  PresupuestosViewModel(this._api);
  final PresupuestoApi _api;

  List<Presupuesto> _presupuestos = [];
  bool _cargando = false;
  String? _error;
  bool _cerrado = false;

  int _mesActual = DateTime.now().month;
  int _anioActual = DateTime.now().year;

  List<Presupuesto> get presupuestos => _presupuestos;
  bool get cargando => _cargando;
  String? get error => _error;
  int get mesActual => _mesActual;
  int get anioActual => _anioActual;

  @override
  void notifyListeners() {
    if (!_cerrado) super.notifyListeners();
  }

  @override
  void dispose() {
    _cerrado = true;
    super.dispose();
  }

  Future<void> cargarPresupuestos({int? mes, int? anio}) async {
    if (mes != null) _mesActual = mes;
    if (anio != null) _anioActual = anio;

    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      _presupuestos = await _api.listarPorMes(_mesActual, _anioActual);
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Error inesperado al cargar presupuestos: $e';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }
}