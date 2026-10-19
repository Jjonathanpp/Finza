import 'package:flutter/foundation.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/features/categorias/data/datasources/categoria_api.dart';
import 'package:frontend/features/categorias/data/models/categoria.dart';

class CategoriasViewModel extends ChangeNotifier {
  CategoriasViewModel(this._api);

  final CategoriaApi _api;

  bool _cargando = false;
  String? _error;
  List<Categoria> _categorias = [];
  bool _cerrado = false;
  // ponytail: no se guarda; al cambiar de pestaña vuelven a verse. Guardarlo si molesta.
  bool _verPredefinidas = true;

  // Si la pantalla se cerró mientras se esperaba al backend, no hay a quién avisar.
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
  List<Categoria> get categorias => _categorias;
  bool get verPredefinidas => _verPredefinidas;

  // Las que se muestran: todas, o solo las propias si se ocultaron las predefinidas.
  Iterable<Categoria> get _visibles =>
      _verPredefinidas ? _categorias : _categorias.where((c) => !c.esPredefinida);

  List<Categoria> get deIngreso =>
      _visibles.where((c) => c.tipo == 'INGRESO').toList();

  List<Categoria> get deEgreso =>
      _visibles.where((c) => c.tipo == 'EGRESO').toList();

  void alternarPredefinidas() {
    _verPredefinidas = !_verPredefinidas;
    notifyListeners();
  }

  Future<void> cargar() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _categorias = await _api.listar();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  // Devuelve null si se borró, o el mensaje del backend si no (por ejemplo, si tiene movimientos).
  Future<String?> eliminar(Categoria categoria) async {
    try {
      await _api.eliminar(categoria);
    } on ApiException catch (e) {
      return e.message;
    }
    _categorias = _categorias.where((c) => c.id != categoria.id).toList();
    notifyListeners();
    return null;
  }
}
