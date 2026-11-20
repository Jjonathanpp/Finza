import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app.dart';
import 'package:frontend/l10n/idioma.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  tearDown(() => cambiarIdioma('es'));

  // Si alguien agrega un tr('...') y se olvida de traducirlo en algún archivo de assets/idiomas/,
  // esta prueba dice qué texto falta y en qué archivo. Un texto igual en los dos idiomas ("Email")
  // va igual en el archivo: "Email": "Email".
  test(
    'cada texto de la app con tr() está en todos los archivos de idioma',
    () {
      final textos = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((archivo) => !archivo.path.contains('l10n'))
          .expand(
            (archivo) => RegExp(
              r'''tr\(\s*(['"])((?:(?!\1)[^\\]|\\.)*)\1''',
            ).allMatches(archivo.readAsStringSync()),
          )
          .map((m) => m[2]!.replaceAll(r"\'", "'").replaceAll(r'\$', r'$'))
          .toSet();
      expect(textos, isNotEmpty);

      for (final archivo in Directory(
        'assets/idiomas',
      ).listSync().whereType<File>()) {
        final traducciones = jsonDecode(archivo.readAsStringSync()) as Map;
        expect(
          textos.where((t) => !traducciones.containsKey(t)),
          isEmpty,
          reason: 'Faltan en ${archivo.path}',
        );
      }
    },
  );

  test(
    'tr: en español queda igual, en inglés se traduce, y los datos van en su lugar',
    () async {
      await leerIdioma();
      expect(idiomas, containsPair('en', 'English'));
      expect(tr('Gastado: {monto}', {'monto': r'$ 10'}), r'Gastado: $ 10');

      await cambiarIdioma('en');
      expect(tr('Gastado: {monto}', {'monto': r'$ 10'}), r'Spent: $ 10');
      expect(tr('Comida'), 'Food'); // una categoría predefinida
      // Una categoría propia: queda como la escribió el usuario
      expect(tr('Mascotas'), 'Mascotas');
    },
  );

  testWidgets(
    'cambiar a inglés cambia la app al instante y queda guardado para la próxima vez',
    (tester) async {
      await tester.runAsync(leerIdioma);
      await tester.pumpWidget(const App()); // sin sesión: el login
      await tester.pumpAndSettle();
      expect(find.text('Ingresar'), findsOneWidget);

      await tester.runAsync(() => cambiarIdioma('en'));
      await tester.pumpAndSettle();
      expect(find.text('Log in'), findsOneWidget);

      // Como si se cerrara y se volviera a abrir la app
      idioma.value = const Locale('es');
      await tester.runAsync(leerIdioma);
      expect(idioma.value, const Locale('en'));
    },
  );
}
