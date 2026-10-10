import 'package:frontend/config/constants/sesion_temporal.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/mercadopago/data/models/mercadopago_estado.dart';
import 'package:frontend/features/mercadopago/data/models/sincronizacion_resumen.dart';

class MercadoPagoApi {
  MercadoPagoApi(this._api);

  final ApiClient _api;

  Future<MercadoPagoEstado> obtenerEstado() async {
    final data = await _api.get('/api/mercadopago/estado?usuarioId=$cuentaIdTemporal');
    return MercadoPagoEstado.fromJson(data as Map<String, dynamic>);
  }

  Future<void> desvincular() async {
    await _api.delete('/api/mercadopago/desvincular?usuarioId=$cuentaIdTemporal');
  }

  Future<SincronizacionResumen> sincronizar({int perfilId = 1}) async {
    final data = await _api.post(
      '/api/mercadopago/sincronizar?usuarioId=$cuentaIdTemporal&perfilId=$perfilId',
      {},
    );
    return SincronizacionResumen.fromJson(data as Map<String, dynamic>);
  }
}