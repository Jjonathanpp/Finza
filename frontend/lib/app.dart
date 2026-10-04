import 'package:flutter/material.dart';
import 'config/theme/app_theme.dart';
import 'features/login/screens/login_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: temaFinza(),
      home: const LoginScreen(),
    );
  }
}
