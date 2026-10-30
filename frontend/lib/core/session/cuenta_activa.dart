import 'package:flutter/foundation.dart';

// La cuenta en la que está la app (selector de cuenta, t-13.1.2): null es la personal; si no, una
// cuenta compartida como la devuelve GET /api/cuentas-compartidas: {id, nombre, rol, perfilId}.
// La guarda TokenStorage (se vuelve a la personal al iniciar o cerrar sesión) y el ApiClient la
// manda en el header X-Perfil-Id: con eso el backend devuelve los datos de esa cuenta.
final cuentaActiva = ValueNotifier<Map<String, dynamic>?>(null);

// En la personal todo es tuyo; en una compartida, crear o cambiar presupuestos y categorías es del admin.
bool get esAdminDeCuentaActiva => cuentaActiva.value == null || cuentaActiva.value!['rol'] == 'ADMIN';

// El título de una pantalla con la cuenta compartida al lado ("Finza · Casa"), para no cargar algo
// en la cuenta equivocada. En la personal, el título solo.
String conCuentaActiva(String titulo) =>
    cuentaActiva.value == null ? titulo : '$titulo · ${cuentaActiva.value!['nombre']}';
