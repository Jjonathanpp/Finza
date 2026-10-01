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
          'fecha': _formatearFecha(fecha),
        },
      ],
    });
    return Movimiento.fromJson((data as List).first);
  }

  // El backend espera la fecha como dd-MM-yyyy (ej. 01-10-2026).
  static String _formatearFecha(DateTime fecha) {
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(fecha.day)}-${dos(fecha.month)}-${fecha.year}';
  }
}
