import 'package:flutter/foundation.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/features/categorias/data/datasources/categoria_api.dart';
import 'package:frontend/features/categorias/data/models/categoria.dart';
import 'package:frontend/features/movimientos/data/datasources/movimiento_api.dart';
import 'package:frontend/features/movimientos/data/models/movimiento.dart';

class MovimientosViewModel extends ChangeNotifier {
  MovimientosViewModel(this._api, this._categoriaApi);
  final MovimientoApi _api;
  final CategoriaApi _categoriaApi;

  List<Movimiento> _movimientos = [];
  List<Categoria> categorias = [];
  
  bool _cargando = false;
  String? _error;
  bool _hayMas = true;
  int _pagina = 0;
  final int _limite = 12;
  bool _cerrado = false;
  int _totalPaginas = 1;

  // Filtros
  DateTime? desde;
  DateTime? hasta;
  Categoria? categoriaFiltro;
  bool? esIngresoFiltro;

  int get totalPaginas => _totalPaginas;
  List<Movimiento> get movimientos => _movimientos;
  bool get cargando => _cargando;
  String? get error => _error;
  bool get hayMas => _hayMas;
  bool get hayAnterior => _pagina > 0;
  int get paginaActual => _pagina + 1;
  bool get tieneFiltrosActivos => desde != null || hasta != null || categoriaFiltro != null || esIngresoFiltro != null;

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
    _pagina = 0;
    if (categorias.isEmpty) {
      await _cargarCategorias(); 
    }
    
    await _obtenerDatos();
  }

  Future<void> _cargarCategorias() async {
    try {
      categorias = await _categoriaApi.listar();
      notifyListeners();
    } catch (e) {
      print('🔥 ERROR AL CARGAR CATEGORÍAS EN EL FILTRO: $e');
    } 
  }

  void aplicarFiltros({DateTime? nuevoDesde, DateTime? nuevoHasta, Categoria? nuevaCategoria, bool? nuevoEsIngreso}) {
    desde = nuevoDesde;
    hasta = nuevoHasta;
    categoriaFiltro = nuevaCategoria;
    esIngresoFiltro = nuevoEsIngreso;
    _pagina = 0; // Al filtrar, volvemos a la página 1
    _obtenerDatos();
  }

  void limpiarFiltros() {
    aplicarFiltros();
  }

  Future<void> paginaSiguiente() async {
    if (_cargando || !_hayMas) return;
    _pagina++;
    await _obtenerDatos();
  }

  Future<void> paginaAnterior() async {
    if (_cargando || _pagina == 0) return;
    _pagina--;
    await _obtenerDatos();
  }

  Future<void> irAPagina(int indice) async {
    if (_cargando || indice == _pagina || indice < 0 || indice >= _totalPaginas) return;
    _pagina = indice;
    await _obtenerDatos();
  }

  Future<void> _obtenerDatos() async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      final (nuevos, total) = await _api.listar(
        pagina: _pagina, 
        limite: _limite,
        fechaInicio: desde,
        fechaFin: hasta,
        categoriaId: categoriaFiltro?.id,
        esIngreso: esIngresoFiltro,
      );
      _movimientos = nuevos; 
      _totalPaginas = total;
      _hayMas = _pagina + 1 < _totalPaginas;
    } on ApiException catch (e) {
      _error = e.message;
      if (_pagina > 0) _pagina--; 
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }
}