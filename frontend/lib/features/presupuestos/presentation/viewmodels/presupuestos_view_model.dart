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

  // ---- Resumen del mes (lo calcula el front a partir de las categorías) ----

  // Los más comprometidos primero: lo que pide atención queda arriba.
  List<Presupuesto> get presupuestosOrdenados =>
      [..._presupuestos]..sort((a, b) => b.porcentajeConsumo.compareTo(a.porcentajeConsumo));

  double get totalTope => _presupuestos.fold(0.0, (suma, p) => suma + p.montoTope);
  double get totalGastado => _presupuestos.fold(0.0, (suma, p) => suma + p.montoGastado);
  double get porcentajeTotal => totalTope == 0 ? 0 : totalGastado / totalTope * 100;

  // Mismos cortes que la alerta del backend (80%) y el tope (100%).
  int get cantidadEnOrden => _presupuestos.where((p) => p.porcentajeConsumo < 80).length;
  int get cantidadCercaDelTope =>
      _presupuestos.where((p) => p.porcentajeConsumo >= 80 && p.porcentajeConsumo < 100).length;
  int get cantidadExcedidos => _presupuestos.where((p) => p.porcentajeConsumo >= 100).length;

  // Para el "podés gastar $X por día": los días que le quedan al mes que se está
  // viendo, contando hoy. Un mes futuro, todos sus días; uno pasado, null.
  int? get diasRestantes {
    final hoy = DateTime.now();
    final diasDelMes = DateTime(_anioActual, _mesActual + 1, 0).day;
    final esPasado = _anioActual < hoy.year || (_anioActual == hoy.year && _mesActual < hoy.month);
    if (esPasado) return null;
    if (_anioActual == hoy.year && _mesActual == hoy.month) return diasDelMes - hoy.day + 1;
    return diasDelMes;
  }

  bool get esMesPasado => diasRestantes == null;

  @override
  void notifyListeners() {
    if (!_cerrado) super.notifyListeners();
  }

  @override
  void dispose() {
    _cerrado = true;
    super.dispose();
  }

  // Para los de una cuenta compartida (solo el admin, t-13.1.2). Si el backend dice que no, la
  // ApiException sigue de largo para que la muestre el panel; si sale bien, recarga el mes.
  Future<void> editarTope(Presupuesto presupuesto, double tope) async {
    await _api.editarPresupuesto(
      id: presupuesto.presupuestoId,
      categoriaId: presupuesto.categoriaId,
      montoTope: tope,
      mes: _mesActual,
      anio: _anioActual,
    );
    await cargarPresupuestos();
  }

  Future<void> desactivar(Presupuesto presupuesto) async {
    await _api.desactivarPresupuesto(presupuesto.presupuestoId);
    await cargarPresupuestos();
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