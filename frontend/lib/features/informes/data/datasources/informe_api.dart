import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/informes/data/models/comparacion_periodos.dart';
import 'package:frontend/features/panel/data/models/resumen_gastos.dart';

class InformeApi {
  InformeApi(this._api);

  final ApiClient _api;

  static String _formatearFechaIso(DateTime fecha) {
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${fecha.year}-${dos(fecha.month)}-${dos(fecha.day)}';
  }

    Future<ComparacionPeriodos> comparacion({
    DateTime? startDate,
    DateTime? endDate,
    String? granularidad,
  }) async {
    final queryParams = <String>[];
    if (startDate != null) queryParams.add('startDate=${_formatearFechaIso(startDate)}');
    if (endDate != null) queryParams.add('endDate=${_formatearFechaIso(endDate)}');
    if (granularidad != null && granularidad.isNotEmpty) {
      queryParams.add('granularidad=$granularidad');
    }

    final queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
    final data = await _api.get('/api/informes/comparacion$queryString');
    return ComparacionPeriodos.fromJson(data as Map<String, dynamic>);
  }

  Future<ResumenGastos> porCategoria({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String>[];
    if (startDate != null) queryParams.add('startDate=${_formatearFechaIso(startDate)}');
    if (endDate != null) queryParams.add('endDate=${_formatearFechaIso(endDate)}');

    final queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
    final data = await _api.get('/api/informes/por-categoria$queryString');
    return ResumenGastos.fromJson(data as Map<String, dynamic>);
  }
}