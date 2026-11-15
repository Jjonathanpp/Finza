import 'dart:developer' as dev;

import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/mercadopago/data/datasources/mercadopago_api.dart';

bool _yaSincronizoEstaSesion = false;

void reiniciarSincronizacionAlEntrar() {
  _yaSincronizoEstaSesion = false;
}

Future<void> sincronizarMercadoPagoAlEntrar({MercadoPagoApi? api}) async {
  if (_yaSincronizoEstaSesion) return;
  _yaSincronizoEstaSesion = true;

  try {
    final cliente = api ?? MercadoPagoApi(ApiClient());
    final estado = await cliente.obtenerEstado();
    if (estado.conectado) {
      dev.log('Sincronizando Mercado Pago en segundo plano al entrar...', name: 'MercadoPago');
      await cliente.sincronizar();
      dev.log('Sincronización en segundo plano de Mercado Pago completada con éxito.', name: 'MercadoPago');
    }
  } catch (e) {
    dev.log('Sincronización en segundo plano de Mercado Pago omitida o falló: $e', name: 'MercadoPago');
  }
}
