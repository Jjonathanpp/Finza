import 'package:flutter/material.dart';
import 'app.dart';
import 'l10n/idioma.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await leerIdioma(); // el idioma guardado en el celular, antes de dibujar nada (US-8.3)
  runApp(const App());
}
