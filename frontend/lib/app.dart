import 'package:flutter/material.dart';
import 'config/theme/app_theme.dart';
import 'core/session/portero.dart';

class App extends StatelessWidget {
  const App({super.key});

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
