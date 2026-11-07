import 'package:flutter/material.dart';
import 'config/theme/app_theme.dart';
import 'core/actualizacion/aviso_de_version.dart';
import 'core/avisos/aviso_de_presupuestos.dart';
import 'core/session/deep_link_service.dart';
import 'core/session/portero.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  final _deepLinks = DeepLinkService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Se espera al primer frame para que el Navigator ya exista
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deepLinks.iniciar();
      avisarSiHayVersionNueva();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _deepLinks.dispose();
    super.dispose();
  }

  // Al volver a la app (estaba en segundo plano): pudo entrar un gasto por voz o por Mercado
  // Pago mientras tanto. Sin sesión, la revisión no hace nada.
  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (estado == AppLifecycleState.resumed) revisarAvisosDePresupuesto();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navegador,
      debugShowCheckedModeBanner: false,
      theme: temaFinza(),
      home: const Portero(),
    );
  }
}
