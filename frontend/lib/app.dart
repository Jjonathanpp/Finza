import 'package:flutter/material.dart';
import 'config/theme/app_theme.dart';
import 'core/session/deep_link_service.dart';
import 'core/session/portero.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _deepLinks = DeepLinkService();

  @override
  void initState() {
    super.initState();
    // Se espera al primer frame para que el Navigator ya exista
    WidgetsBinding.instance.addPostFrameCallback((_) => _deepLinks.iniciar());
  }

  @override
  void dispose() {
    _deepLinks.dispose();
    super.dispose();
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
