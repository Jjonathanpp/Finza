import 'package:flutter/material.dart';

import '../../features/login/screens/login_screen.dart';
import '../../features/voice/voice_screen.dart';
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

// Lo primero que se ve al abrir la app: con una sesión que sirve entra directo, si no va al login.
class Portero extends StatefulWidget {
  const Portero({super.key});

  @override
  State<Portero> createState() => _PorteroState();
}

class _PorteroState extends State<Portero> {
  final _haySesion = TokenStorage().obtenerToken().then(tokenVigente);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _haySesion,
      builder: (context, respuesta) {
        if (respuesta.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        // Si no se pudo leer el token (error), data queda vacío y va al login.
        return respuesta.data == true ? const VoiceScreen() : const LoginScreen();
      },
    );
  }
}
