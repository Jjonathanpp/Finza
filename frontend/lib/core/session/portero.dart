import 'package:flutter/material.dart';

import '../../features/login/screens/login_screen.dart';
import '../../features/home/presentation/screens/pantalla_principal.dart';
import '../storage/token_storage.dart';
import 'sesion.dart';

// La llave del navegador de la app (va en app.dart): deja cambiar de pantalla desde lugares
// que no son pantallas, como el interceptor del ApiClient.
final navegador = GlobalKey<NavigatorState>();

// Se terminó la sesión: deja solo el login, sin poder volver atrás.
void irAlLogin() {
  navegador.currentState?.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (_) => false,
  );
}

// Se cambió de cuenta en el selector (t-13.1.2): arma la pantalla principal de cero, así todas las
// pestañas vuelven a pedir sus datos, ahora de la cuenta elegida.
void irAlInicio() {
  navegador.currentState?.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const PantallaPrincipal()),
    (_) => false,
  );
}

// Lo primero que se ve al abrir la app: con una sesión que sirve entra directo, si no va al login.
class Portero extends StatefulWidget {
  const Portero({super.key});

  @override
  State<Portero> createState() => _PorteroState();
}

class _PorteroState extends State<Portero> {
  final _haySesion = _arrancar();

  // Antes de mostrar nada, la cuenta en la que se estaba: así los primeros pedidos ya van con ella.
  static Future<bool> _arrancar() async {
    final tokens = TokenStorage();
    await tokens.cargarCuentaActiva();
    return tokenVigente(await tokens.obtenerToken());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _haySesion,
      builder: (context, respuesta) {
        if (respuesta.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // Si no se pudo leer el token (error), data queda vacío y va al login.
        return respuesta.data == true
            ? const PantallaPrincipal()
            : const LoginScreen();
      },
    );
  }
}
