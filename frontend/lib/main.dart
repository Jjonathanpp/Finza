import 'package:flutter/material.dart';
import 'app.dart';
import 'l10n/idioma.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await leerIdioma();
  runApp(const App());
}
