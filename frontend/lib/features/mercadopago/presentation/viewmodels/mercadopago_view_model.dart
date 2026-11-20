import 'package:flutter/foundation.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/features/mercadopago/data/datasources/mercadopago_api.dart';
import 'package:frontend/features/mercadopago/data/models/mercadopago_estado.dart';
import 'package:frontend/features/mercadopago/data/models/sincronizacion_resumen.dart';
import 'package:frontend/features/movimientos/data/models/movimiento.dart';

class MercadoPagoViewModel extends ChangeNotifier {
  MercadoPagoViewModel(this._api);

  final MercadoPagoApi _api;

  bool _cargando = false;
  String? _error;
  MercadoPagoEstado? _estado;
  bool _cerrado = false;
  List<Movimiento> _pendientes = [];

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
  List<Movimiento> get pendientes => _pendientes;

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

  Future<SincronizacionResumen?> sincronizar() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      final resumen = await _api.sincronizar();
      return resumen;
    } on ApiException catch (e) {
      _error = e.message;
      return null;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> cargarPendientes() async {
    _pendientes = await _api.obtenerPendientesMercadoPago();
    notifyListeners();
  }

  Future<String> obtenerUrlAutorizacion() async {
    return await _api.obtenerUrlAutorizacion();
  }

  // ── Elegir qué importar (Eze en main) ──
  List<Map<String, dynamic>> _disponibles = [];
  final Set<String> _seleccionados = {};
  bool _cargandoDisponibles = false;

  List<Map<String, dynamic>> get disponibles => _disponibles;
  Set<String> get seleccionados => _seleccionados;
  bool get cargandoDisponibles => _cargandoDisponibles;

  Future<void> cargarDisponibles() async {
    _cargandoDisponibles = true;
    _error = null;
    _seleccionados.clear();
    notifyListeners();
    try {
      _disponibles = await _api.obtenerDisponibles();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _cargandoDisponibles = false;
      notifyListeners();
    }
  }

  void alternarSeleccion(String id) {
    if (!_seleccionados.remove(id)) _seleccionados.add(id);
    notifyListeners();
  }

  Future<SincronizacionResumen?> importarSeleccionados() async {
    if (_seleccionados.isEmpty) return null;
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      final resumen = await _api.importarSeleccionados(_seleccionados.toList());
      _seleccionados.clear();
      return resumen;
    } on ApiException catch (e) {
      _error = e.message;
      return null;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }
}
