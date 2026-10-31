import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/mercadopago/data/models/mercadopago_estado.dart';
import 'package:frontend/features/mercadopago/data/models/sincronizacion_resumen.dart';
import 'package:frontend/features/movimientos/data/models/movimiento.dart';

class MercadoPagoApi {
  MercadoPagoApi(this._api);

  final ApiClient _api;

  Future<String> obtenerUrlAutorizacion() async {
    final res = await _api.get('/api/mercadopago/autorizar');
    if (res is Map<String, dynamic>) {
      if (res['data'] is Map<String, dynamic> && res['data']['url'] != null) {
        return res['data']['url'] as String;
      }
      if (res['url'] != null) {
        return res['url'] as String;
      }
    }
    throw Exception('No se pudo obtener la URL de autorización');
  }

  Future<MercadoPagoEstado> obtenerEstado() async {
    final data = await _api.get('/api/mercadopago/estado');
    return MercadoPagoEstado.fromJson(data as Map<String, dynamic>);
  }

  Future<void> desvincular() async {
    await _api.delete('/api/mercadopago/desvincular');
  }

  Future<SincronizacionResumen> sincronizar() async {
    final data = await _api.post('/api/mercadopago/sincronizar', {});
    return SincronizacionResumen.fromJson(data as Map<String, dynamic>);
  }

  Future<List<Movimiento>> obtenerPendientesMercadoPago() async {
    final data = await _api.get('/api/movimientos/pendientes-mercadopago');
    if (data is List) {
      return (data as List)
          .map((json) => Movimiento.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}