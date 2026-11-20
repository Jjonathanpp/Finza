import 'dart:developer' as dev;

import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/session/cuenta_activa.dart';
import 'package:frontend/features/mercadopago/data/datasources/mercadopago_api.dart';

// De Eze en main (b5cb12b): al entrar a la app, si hay Mercado Pago conectado, trae los movimientos
// nuevos en segundo plano, una vez por sesión. Si falla, no se avisa (es solo un adelanto).
bool _yaSincronizoEstaSesion = false;

void reiniciarSincronizacionAlEntrar() {
  _yaSincronizoEstaSesion = false;
}

Future<void> sincronizarMercadoPagoAlEntrar({MercadoPagoApi? api}) async {
  // Solo en la personal: en una compartida importaría todo lo de Mercado Pago a la cuenta de todos.
  if (_yaSincronizoEstaSesion || cuentaActiva.value != null) return;
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
