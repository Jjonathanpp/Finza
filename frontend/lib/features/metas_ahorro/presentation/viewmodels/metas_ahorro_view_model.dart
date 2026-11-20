import 'package:flutter/foundation.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/features/metas_ahorro/data/datasources/metas_ahorro_api.dart';
import 'package:frontend/features/metas_ahorro/data/models/meta_ahorro.dart';
import 'package:frontend/l10n/idioma.dart';

class MetasAhorroViewModel extends ChangeNotifier {
  MetasAhorroViewModel(this._api);

  final MetasAhorroApi _api;
  List<MetaAhorro> _metas = [];
  final Map<int, List<AporteMetaAhorro>> _aportesPorMeta = {};
  final Set<int> _cargandoAportes = {};
  bool _cargando = false;
  String? _error;
  bool _cerrado = false;

  List<MetaAhorro> get metas => _metas;
  bool get cargando => _cargando;
  String? get error => _error;

  List<AporteMetaAhorro> aportesDe(MetaAhorro meta) =>
      _aportesPorMeta[meta.id] ?? meta.aportes;

  bool cargandoAportes(int metaId) => _cargandoAportes.contains(metaId);

  @override
  void notifyListeners() {
    if (!_cerrado) super.notifyListeners();
  }

  @override
  void dispose() {
    _cerrado = true;
    super.dispose();
  }

  Future<void> cargarMetas({int? cuentaCompartidaId}) async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _metas = await _api.listar(cuentaCompartidaId: cuentaCompartidaId);
      _aportesPorMeta.clear();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = tr('Error inesperado al cargar las metas: {error}', {
        'error': '$e',
      });
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> cargarAportes(int metaId) async {
    if (_cargandoAportes.contains(metaId)) return;
    _cargandoAportes.add(metaId);
    notifyListeners();
    try {
      final resumen = await _api.obtenerResumenAportes(metaId);
      _aportesPorMeta[metaId] = resumen.aportes;
    } catch (_) {
      // Si falla el detalle puntual, mantiene los aportes básicos que trajo GET /api/metas
    } finally {
      _cargandoAportes.remove(metaId);
      notifyListeners();
    }
  }

  Future<void> crear({
    required String nombre,
    required double montoObjetivo,
    DateTime? fechaLimite,
    int? cuentaCompartidaId,
  }) async {
    await _api.crear(
      nombre: nombre,
      montoObjetivo: montoObjetivo,
      fechaLimite: fechaLimite,
      cuentaCompartidaId: cuentaCompartidaId,
    );
    await cargarMetas(cuentaCompartidaId: cuentaCompartidaId);
  }

  Future<void> editar({
    required MetaAhorro meta,
    required String nombre,
    required double montoObjetivo,
    DateTime? fechaLimite,
    int? cuentaCompartidaId,
  }) async {
    await _api.editar(
      id: meta.id,
      nombre: nombre,
      montoObjetivo: montoObjetivo,
      fechaLimite: fechaLimite,
    );
    await cargarMetas(cuentaCompartidaId: cuentaCompartidaId);
  }

  Future<void> eliminar(MetaAhorro meta, {int? cuentaCompartidaId}) async {
    await _api.eliminar(meta.id);
    await cargarMetas(cuentaCompartidaId: cuentaCompartidaId);
  }

  Future<void> abonar({
    required MetaAhorro meta,
    required double monto,
    int? cuentaCompartidaId,
  }) async {
    final teniaDetalle = _aportesPorMeta.containsKey(meta.id);
    await _api.abonar(id: meta.id, monto: monto);
    await cargarMetas(cuentaCompartidaId: cuentaCompartidaId);
    if (teniaDetalle) {
      await cargarAportes(meta.id);
    }
  }
}
