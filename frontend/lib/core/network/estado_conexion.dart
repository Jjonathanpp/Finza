import 'package:flutter/foundation.dart';

// Si un pedido al backend falla por falta de conexión, toda la app muestra el aviso "No pudimos conectarnos".
final sinConexion = ValueNotifier<bool>(false);

// Sube cada vez que se toca "Reintentar" en ese aviso: la pantalla principal lo escucha y vuelve a pedir lo suyo.
final reintentos = ValueNotifier<int>(0);
