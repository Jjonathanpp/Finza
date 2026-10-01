import 'package:flutter/foundation.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/features/categorias/data/datasources/categoria_api.dart';
import 'package:frontend/features/categorias/data/models/categoria.dart';
import 'package:frontend/features/movimientos/data/datasources/movimiento_api.dart';
import 'package:frontend/features/movimientos/data/models/movimiento.dart';
import 'package:frontend/features/movimientos/presentation/validaciones_movimiento.dart';

class AltaMovimientoViewModel extends ChangeNotifier {
  AltaMovimientoViewModel(this._categoriaApi, this._movimientoApi);

  final CategoriaApi _categoriaApi;
  final MovimientoApi _movimientoApi;

  bool _esIngreso = true;
  String? _categoria;
  DateTime _fecha = DateTime.now();
  bool _cerrado = false;
  List<Categoria> _categorias = [];
  bool _guardando = false;
  String? _error;
  String? _errorMonto;
  String? _errorCategoria;

  bool get esIngreso => _esIngreso;
  String? get categoria => _categoria;
  DateTime get fecha => _fecha;
  bool get guardando => _guardando;
  String? get error => _error;
  String? get errorMonto => _errorMonto;
  String? get errorCategoria => _errorCategoria;

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

  List<Categoria> get categoriasDelTipo =>
      _categorias.where((c) => c.tipo == (_esIngreso ? 'INGRESO' : 'EGRESO')).toList();

  Future<void> cargarCategorias() async {
    try {
      _categorias = await _categoriaApi.listar();
    } on ApiException catch (e) {
      _error = e.message;
    }
    notifyListeners();
  }

  void cambiarTipo(bool esIngreso) {
    _esIngreso = esIngreso;
    _categoria = null;
    notifyListeners();
  }

  void elegirCategoria(String nombre) {
    _categoria = nombre;
    _errorCategoria = null;
    notifyListeners();
  }

  // La categoría recién creada desde el panel: se suma a las opciones y queda elegida.
  void agregarCategoria(Categoria categoria) {
    _categorias = [..._categorias, categoria];
    elegirCategoria(categoria.nombre);
  }

  void cambiarFecha(DateTime fecha) {
    _fecha = fecha;
    notifyListeners();
  }

  // Deja el formulario listo para el próximo movimiento (el tipo se mantiene).
  void limpiar() {
    _categoria = null;
    _fecha = DateTime.now();
    _error = null;
    _errorMonto = null;
    _errorCategoria = null;
    notifyListeners();
  }

  // Valida y guarda. Devuelve el movimiento creado, o null si algo falló.
  Future<Movimiento?> guardar({required String monto, String? descripcion}) async {
    _errorMonto = validarMonto(monto);
    _errorCategoria = validarCategoria(_categoria);
    _error = null;
    if (_errorMonto != null || _errorCategoria != null) {
      notifyListeners();
      return null;
    }
    _guardando = true;
    notifyListeners();
    try {
      return await _movimientoApi.crear(
        esIngreso: _esIngreso,
        monto: normalizarMonto(monto),
        categoria: _categoria!,
        descripcion: descripcion,
        fecha: _fecha,
      );
    } on ApiException catch (e) {
      _error = e.message;
      return null;
    } finally {
      _guardando = false;
      notifyListeners();
    }
  }
}
