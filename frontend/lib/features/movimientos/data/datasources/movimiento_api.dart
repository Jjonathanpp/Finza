import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/movimientos/data/models/movimiento.dart';
import 'package:frontend/features/movimientos/data/models/perfil_cuenta.dart';
 
class MovimientoApi {
  MovimientoApi(this._api);
 
  final ApiClient _api;
 
  Future<Movimiento> crear({
    required bool esIngreso,
    required String monto,
    required String categoria,
    String? descripcion,
    required DateTime fecha,
  }) async {
    final data = await _api.post('/api/movimientos', {
      'movimientos': [
        {
          'tipo': esIngreso ? 'ingreso' : 'egreso',
          'monto': monto,
          'categoria': categoria,
          'descripcion': descripcion,
          'fecha': _formatearFecha(fecha),
        },
      ],
    });
    return Movimiento.fromJson((data as List).first);
  }
 
  Future<void> eliminar(int id) async {
    await _api.delete('/api/movimientos/$id');
  }
 
  Future<Movimiento> actualizar({
    required int id,
    required bool esIngreso,
    required String monto,
    required String categoria,
    String? descripcion,
    required DateTime fecha,
    String origen = 'MANUAL',
  }) async {
    final data = await _api.put('/api/movimientos/$id', {
      'tipo': esIngreso ? 'ingreso' : 'egreso',
      'monto': monto,
      'categoria': categoria,
      'descripcion': descripcion,
      'fecha': _formatearFecha(fecha),
      'origen': origen.toUpperCase(),
    });
    return Movimiento.fromJson(data);
  }
 
  Future<(List<Movimiento>, int)> listar({
    int pagina = 0,
    int limite = 12,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    int? categoriaId,
    bool? esIngreso,
    String? estado,
    int? perfilId,
    int? usuarioId,
  }) async {
    // Agregamos sort=fecha,desc&sort=id,desc para que los más recientes queden arriba
    String url =
        '/api/movimientos?page=$pagina&size=$limite&sort=fecha,desc&sort=id,desc';
 
    if (fechaInicio != null) {
      url += '&fechaInicio=${_formatearFechaIso(fechaInicio)}';
    }
    if (fechaFin != null) url += '&fechaFin=${_formatearFechaIso(fechaFin)}';
    if (categoriaId != null) url += '&categoriaId=$categoriaId';
    if (esIngreso != null) url += '&esIngreso=$esIngreso';
    if (estado != null) url += '&estado=$estado';
    if (perfilId != null) url += '&perfilId=$perfilId';
    if (usuarioId != null) url += '&usuarioId=$usuarioId';
 
    return _leerPagina(await _api.get(url));
  }
 
  // Vista consolidada (t-12.1.2): los movimientos de todos los perfiles de la
  // cuenta (el personal y los de cada cuenta compartida). El backend toma la cuenta
  // del token y ordena siempre por fecha e id descendente, así que no se manda
  // perfilId ni sort.
  Future<(List<Movimiento>, int)> listarConsolidado({
    int pagina = 0,
    int limite = 12,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    int? categoriaId,
    bool? esIngreso,
    String? estado,
  }) async {
    String url = '/api/movimientos/consolidado?page=$pagina&size=$limite';
 
    if (fechaInicio != null) {
      url += '&fechaInicio=${_formatearFechaIso(fechaInicio)}';
    }
    if (fechaFin != null) url += '&fechaFin=${_formatearFechaIso(fechaFin)}';
    if (categoriaId != null) url += '&categoriaId=$categoriaId';
    if (esIngreso != null) url += '&esIngreso=$esIngreso';
    if (estado != null) url += '&estado=$estado';
 
    return _leerPagina(await _api.get(url));
  }
 
  // La página de Spring: los movimientos en "content" y el total de páginas en
  // "totalPages" (o dentro de "page", según cómo la serialice el backend).
  static (List<Movimiento>, int) _leerPagina(dynamic data) {
    if (data == null) return (<Movimiento>[], 1);
 
    final listaJson = data is List ? data : (data['content'] as List? ?? []);
    final totalPaginas = data is Map
        ? (data['totalPages'] as int? ??
              (data['page'] is Map ? data['page']['totalPages'] as int? : null) ??
              1)
        : 1;
 
    final movimientos = listaJson
        .map((json) => Movimiento.fromJson(json))
        .toList();
 
    // Sin resultados Spring manda 0 páginas: la paginación siempre muestra al menos una.
    return (movimientos, totalPaginas < 1 ? 1 : totalPaginas);
  }
 
  // Crear y editar: el backend espera la fecha como dd-MM-yyyy (ej. 01-10-2026).
  static String _formatearFecha(DateTime fecha) {
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(fecha.day)}-${dos(fecha.month)}-${fecha.year}';
  }
 
  // Los filtros del listado, en cambio, van como yyyy-MM-dd (ej. 2026-10-01).
  static String _formatearFechaIso(DateTime fecha) {
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${fecha.year}-${dos(fecha.month)}-${dos(fecha.day)}';
  }
 
  /// Cambia el estado de un movimiento
  Future<Movimiento> cambiarEstado(int id, String nuevoEstado) async {
    final data = await _api.put(
      '/api/movimientos/$id/estado?nuevoEstado=${nuevoEstado.toUpperCase()}',
      {}, // El body va vacío porque no lo necesita
    );
    return Movimiento.fromJson(data);
  }
 
  Future<List<PerfilCuenta>> listarPerfilesDeCuentaCompartida(
    int cuentaCompartidaId,
  ) async {
    final data = await _api.get(
      '/api/cuentas-compartidas/$cuentaCompartidaId/perfiles',
    );
    return (data as List).map((j) => PerfilCuenta.fromJson(j)).toList();
  }
}