import 'package:flutter/foundation.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/features/categorias/data/datasources/categoria_api.dart';
import 'package:frontend/features/categorias/data/models/categoria.dart';
import 'package:frontend/features/movimientos/data/datasources/movimiento_api.dart';
import 'package:frontend/features/movimientos/data/models/movimiento.dart';
import 'package:frontend/core/session/cuenta_activa.dart';
import 'package:frontend/features/movimientos/data/models/perfil_cuenta.dart';
import 'package:frontend/core/network/api_client.dart';

class MovimientosViewModel extends ChangeNotifier {
  MovimientosViewModel(this._api, this._categoriaApi, this._apiClient) {
    cuentaActiva.addListener(_alCambiarCuenta);
  }
  final MovimientoApi _api;
  final CategoriaApi _categoriaApi;
  final ApiClient _apiClient;

  List<Movimiento> _movimientos = [];
  List<Categoria> categorias = [];

  bool _cargando = false;
  String? _error;
  bool _hayMas = true;
  int _pagina = 0;
  final int _limite = 12;
  bool _cerrado = false;
  int _totalPaginas = 1;
  String? estadoFiltro;

  // Filtros
  DateTime? desde;
  DateTime? hasta;
  Categoria? categoriaFiltro;
  bool? esIngresoFiltro;
  int? perfilFiltroId;
  List<PerfilCuenta> perfilesDisponibles = [];

  int get totalPaginas => _totalPaginas;
  List<Movimiento> get movimientos => _movimientos;
  bool get cargando => _cargando;
  String? get error => _error;
  bool get hayMas => _hayMas;
  bool get hayAnterior => _pagina > 0;
  int get paginaActual => _pagina + 1;
  bool get tieneFiltrosActivos =>
      desde != null ||
      hasta != null ||
      categoriaFiltro != null ||
      esIngresoFiltro != null ||
      estadoFiltro != null ||
      perfilFiltroId != null;

  // Vista consolidada (t-12.1.4): los movimientos de TODOS los perfiles de la
  // cuenta (el personal y los de cada cuenta compartida) en un solo listado, con
  // un badge que dice de dónde es cada uno. Apagada, se ve solo el perfil activo.
  bool _consolidado = false;
  bool get consolidado => _consolidado;

  bool get enCuentaCompartida => cuentaActiva.value != null;

  Future<void> cambiarModoConsolidado(bool valor) async {
    if (valor == _consolidado || _cargando) return;
    _consolidado = valor;
    // El consolidado no filtra por integrante: ese filtro se descarta.
    if (valor) perfilFiltroId = null;
    _pagina = 0;
    await _obtenerDatos();
  }

  // Si el movimiento es del perfil en el que está parada la app (selector de
  // cuenta). El backend solo deja editarlo o verificarlo desde ese perfil.
  bool esDelPerfilActivo(Movimiento movimiento) {
    final cuenta = cuentaActiva.value;
    if (cuenta == null) return movimiento.esPersonal;
    return movimiento.perfilId == cuenta['perfilId'];
  }

  // En el consolidado todos los movimientos son de la cuenta del usuario, así
  // que se pueden borrar aunque sean de otro perfil. En una cuenta compartida
  // (vista normal), los de otros integrantes no.
  bool puedeEliminar(Movimiento movimiento) =>
      _consolidado || esDelPerfilActivo(movimiento);

  @override
  void notifyListeners() {
    if (!_cerrado) super.notifyListeners();
  }

  @override
  void dispose() {
    cuentaActiva.removeListener(_alCambiarCuenta);
    _cerrado = true;
    super.dispose();
  }

  void _alCambiarCuenta() {
    perfilFiltroId = null;
    // Sin esto, mientras carga se verían los movimientos de la cuenta anterior.
    // (El modo consolidado se mantiene: su lista no depende del perfil activo,
    // pero sí qué movimientos se pueden editar.)
    _movimientos = [];
    notifyListeners();
    cargarInicial();
  }

  Future<String?> eliminar(Movimiento movimiento) async {
    try {
      await _api.eliminar(movimiento.id);
    } on ApiException catch (e) {
      return e.message;
    }

    // Si era el único movimiento de la última página, retrocedemos una
    if (_movimientos.length == 1 && _pagina > 0) _pagina--;

    await _obtenerDatos();
    return null;
  }

  Future<void> cargarInicial() async {
    _pagina = 0;
    if (categorias.isEmpty) {
      await _cargarCategorias();
    }
    await cargarPerfilesDisponibles();
    await _obtenerDatos();
  }

  Future<void> _cargarCategorias() async {
    try {
      categorias = await _categoriaApi.listar();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error al cargar categorías en filtro: $e');
      }
    }
  }

  void aplicarFiltros({
    DateTime? nuevoDesde,
    DateTime? nuevoHasta,
    Categoria? nuevaCategoria,
    bool? nuevoEsIngreso,
    String? nuevoEstado,
    int? nuevoPerfilId,
  }) {
    desde = nuevoDesde;
    hasta = nuevoHasta;
    categoriaFiltro = nuevaCategoria;
    esIngresoFiltro = nuevoEsIngreso;
    estadoFiltro = nuevoEstado;
    perfilFiltroId = _consolidado ? null : nuevoPerfilId;
    _pagina = 0;
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
    if (_cargando ||
        indice == _pagina ||
        indice < 0 ||
        indice >= _totalPaginas) {
      return;
    }
    _pagina = indice;
    await _obtenerDatos();
  }

  Future<void> _obtenerDatos() async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      final (nuevos, total) = _consolidado
          ? await _api.listarConsolidado(
              pagina: _pagina,
              limite: _limite,
              fechaInicio: desde,
              fechaFin: hasta,
              categoriaId: categoriaFiltro?.id,
              esIngreso: esIngresoFiltro,
              estado: estadoFiltro,
            )
          : await _api.listar(
              pagina: _pagina,
              limite: _limite,
              fechaInicio: desde,
              fechaFin: hasta,
              categoriaId: categoriaFiltro?.id,
              esIngreso: esIngresoFiltro,
              estado: estadoFiltro,
              perfilId: perfilFiltroId,
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

  Future<String?> editar(
    Movimiento movimiento, {
    required bool esIngreso,
    required String monto,
    required String categoria,
    String? descripcion,
    required DateTime fecha,
    String origen = 'MANUAL',
  }) async {
    try {
      final actualizado = await _api.actualizar(
        id: movimiento.id,
        esIngreso: esIngreso,
        monto: monto,
        categoria: categoria,
        descripcion: descripcion,
        fecha: fecha,
        origen: origen,
      );
      final index = _movimientos.indexWhere((m) => m.id == actualizado.id);
      if (index != -1) {
        _movimientos[index] = actualizado;
        notifyListeners();
      }
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  // Lista vacía = el selector no se muestra (perfil personal o MIEMBRO).
  void actualizarPerfilesDisponibles(List<PerfilCuenta> perfiles) {
    perfilesDisponibles = perfiles;
    // Si el perfil filtrado ya no está disponible (cambió de cuenta, por ejemplo), vuelve a "Todos".
    if (perfilFiltroId != null &&
        !perfiles.any((p) => p.id == perfilFiltroId)) {
      perfilFiltroId = null;
    }
    notifyListeners();
  }

  Future<void> cargarPerfilesDisponibles() async {
    final cuenta = cuentaActiva.value;

    // Perfil personal: no hay selector
    if (cuenta == null) {
      actualizarPerfilesDisponibles([]);
      return;
    }

    try {
      final perfiles = await _api.listarPerfilesDeCuentaCompartida(
        cuenta['id'] as int,
      );
      actualizarPerfilesDisponibles(perfiles);
    } catch (_) {
      actualizarPerfilesDisponibles([]);
    }
  }
}