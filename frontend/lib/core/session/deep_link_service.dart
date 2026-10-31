import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../../features/invitacion/presentation/screens/invitacion_screen.dart';
import '../storage/token_storage.dart';
import 'portero.dart';
import 'sesion.dart';

// Guarda el token de la invitación hasta que haya sesión para abrirla.
class InvitacionPendiente {
  static String? token;
}

class DeepLinkService {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;

  Future<void> iniciar() async {
    // App cerrada y abierta desde el link
    final inicial = await _appLinks.getInitialLink();
    if (inicial != null) await _manejar(inicial);

    // App ya abierta
    _subscription = _appLinks.uriLinkStream.listen(_manejar);
  }

  Future<void> _manejar(Uri uri) async {
    if (uri.scheme != 'finza' || uri.host != 'invitacion') return;

    final token = uri.queryParameters['token'];
    if (token == null || token.isEmpty) return;

    InvitacionPendiente.token = token;

    // Con sesión se abre ya; sin sesión queda guardado hasta que el usuario inicie sesión
    final haySesion = tokenVigente(await TokenStorage().obtenerToken());
    if (haySesion) abrirInvitacionPendiente();
  }

  void dispose() => _subscription?.cancel();
}

// Abre la pantalla de la invitación guardada, si hay una. Se llama también después del login.
void abrirInvitacionPendiente() {
  final token = InvitacionPendiente.token;
  if (token == null) return;

  InvitacionPendiente.token = null;
  navegador.currentState?.push(
    MaterialPageRoute(builder: (_) => InvitacionScreen(token: token)),
  );
}
