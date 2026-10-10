import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/panel/data/models/resumen_gastos.dart';
import 'package:frontend/features/panel/data/models/resumen_mes.dart';

class PanelApi {
  PanelApi(this._api);

  final ApiClient _api;

  // De quién son los gastos lo dice el token, que agrega el interceptor.
  Future<ResumenGastos> gastosPorCategoria() async {
    final data = await _api.get('/api/panel/gastos-por-categoria');
    return ResumenGastos.fromJson(data);
  }

  Future<ResumenMes> resumen() async {
    final data = await _api.get('/api/panel/resumen');
    return ResumenMes.fromJson(data);
  }
}
