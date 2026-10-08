import 'package:frontend/config/constants/sesion_temporal.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/movimientos/data/models/movimiento.dart';

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
      'perfilId': perfilIdTemporal,
      'movimientos': [
        {
          'tipo': esIngreso ? 'ingreso' : 'egreso',
          'monto': monto,
          'categoria': categoria,
          'descripcion': descripcion,
          'fecha': _formatearFechaIso(fecha),
        },
      ],
    });
    return Movimiento.fromJson((data as List).first);
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
      'perfilId': perfilIdTemporal,
      'tipo': esIngreso ? 'ingreso' : 'egreso',
      'monto': monto,
      'categoria': categoria,
      'descripcion': descripcion,
      'fecha': _formatearFechaIso(fecha),
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
  }) async {
    String url = '/api/movimientos?perfilId=$perfilIdTemporal&page=$pagina&size=$limite';
    
    if (fechaInicio != null) url += '&fechaInicio=${_formatearFechaIso(fechaInicio)}';
    if (fechaFin != null) url += '&fechaFin=${_formatearFechaIso(fechaFin)}';
    if (categoriaId != null) url += '&categoriaId=$categoriaId';
    if (esIngreso != null) url += '&esIngreso=$esIngreso';

    final data = await _api.get(url);
    
    if (data == null) return (<Movimiento>[], 1);

    final listaJson = data is List ? data : (data['content'] as List? ?? []);
    final totalPaginas = data is Map ? (data['totalPages'] as int? ?? 1) : 1;
    
    final movimientos = listaJson.map((json) => Movimiento.fromJson(json)).toList();
    
    return (movimientos, totalPaginas);
  }

  static String _formatearFechaIso(DateTime fecha) {
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${fecha.year}-${dos(fecha.month)}-${dos(fecha.day)}';
  }
}
