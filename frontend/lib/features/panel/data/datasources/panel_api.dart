import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/panel/data/models/resumen_gastos.dart';
import 'package:frontend/features/panel/data/models/resumen_mes.dart';

class PanelApi {
  PanelApi(this._api);

  final ApiClient _api;

  static String _formatearFechaIso(DateTime fecha) {
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${fecha.year}-${dos(fecha.month)}-${dos(fecha.day)}';
  }

  Future<ResumenGastos> gastosPorCategoria({DateTime? startDate, DateTime? endDate}) async {
    final queryParams = <String>[];
    if (startDate != null) queryParams.add('startDate=${_formatearFechaIso(startDate)}');
    if (endDate != null) queryParams.add('endDate=${_formatearFechaIso(endDate)}');
    
    final queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
    final data = await _api.get('/api/panel/gastos-por-categoria$queryString');
    return ResumenGastos.fromJson(data);
  }

  Future<ResumenMes> resumen({DateTime? startDate, DateTime? endDate}) async {
    final queryParams = <String>[];
    if (startDate != null) queryParams.add('startDate=${_formatearFechaIso(startDate)}');
    if (endDate != null) queryParams.add('endDate=${_formatearFechaIso(endDate)}');
    
    final queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
    final data = await _api.get('/api/panel/resumen$queryString');
    return ResumenMes.fromJson(data);
  }
}
