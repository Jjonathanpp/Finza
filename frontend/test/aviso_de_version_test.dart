import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/actualizacion/aviso_de_version.dart';
import 'package:frontend/core/session/portero.dart';

// Aviso de versión nueva (t-1.8.5): la comparación de versiones, cómo se lee la release de GitHub y el
// cuadro para actualizar.

// Un Dio que no sale a internet: contesta lo que se le pase (o falla, si no hay nada).
Dio _github(Map<String, dynamic>? release) {
  final dio = Dio();
  dio.interceptors.add(InterceptorsWrapper(onRequest: (pedido, handler) {
    if (release == null) {
      handler.reject(DioException(requestOptions: pedido, message: 'sin internet'));
    } else {
      handler.resolve(Response(requestOptions: pedido, statusCode: 200, data: release));
    }
  }));
  return dio;
}

Map<String, dynamic> _release(String tag, List<String> archivos) => {
      'tag_name': tag,
      'assets': [for (final nombre in archivos) {'browser_download_url': 'https://github.com/descargas/$tag/$nombre'}],
    };

Future<void> _pantalla(WidgetTester tester) async {
  await tester.pumpWidget(MaterialApp(navigatorKey: navegador, home: const Scaffold(body: Text('Inicio'))));
}

void main() {
  group('esMasNueva', () {
    test('compara número por número, no como texto', () {
      expect(esMasNueva('1.1.1', '1.1.0'), isTrue);
      expect(esMasNueva('1.10.0', '1.9.0'), isTrue);
      expect(esMasNueva('2.0.0', '1.9.9'), isTrue);
      expect(esMasNueva('1.1.0', '1.1.0'), isFalse);
      expect(esMasNueva('1.0.2', '1.1.0'), isFalse);
    });

    test('una versión rara no se toma como más nueva', () {
      expect(esMasNueva('1.2.0-beta', '1.1.0'), isFalse);
      expect(esMasNueva('', '1.1.0'), isFalse);
    });
  });

  group('ultimaPublicada', () {
    test('saca la v o la V del tag y elige el archivo que termina en .apk', () async {
      final nueva = await ultimaPublicada(_github(_release('V1.0.2', ['notas.txt', 'finza-1.0.2.apk'])));
      expect(nueva?.version, '1.0.2');
      expect(nueva?.apk, 'https://github.com/descargas/V1.0.2/finza-1.0.2.apk');

      expect((await ultimaPublicada(_github(_release('v1.1.0', ['finza-1.1.0.apk']))))?.version, '1.1.0');
    });

    test('una release sin APK no sirve para actualizar', () async {
      expect(await ultimaPublicada(_github(_release('v1.1.1', ['notas.txt']))), isNull);
    });
  });

  group('el cuadro', () {
    testWidgets('si hay una más nueva aparece, y "Actualizar" abre el link de la APK', (tester) async {
      await _pantalla(tester);
      Uri? abierto;
      unawaited(avisarSiHayVersionNueva(
        instalada: '1.1.0',
        dio: _github(_release('v1.1.1', ['finza-1.1.1.apk'])),
        abrir: (link) async {
          abierto = link;
          return true;
        },
      ));
      await tester.pumpAndSettle();

      expect(find.text('Hay una versión nueva de Finza'), findsOneWidget);
      expect(find.text('Tenés la 1.1.0 y ya salió la 1.1.1. Se instala encima, sin perder nada.'), findsOneWidget);
      await tester.tap(find.text('Actualizar'));
      await tester.pumpAndSettle();

      expect(abierto, Uri.parse('https://github.com/descargas/v1.1.1/finza-1.1.1.apk'));
      expect(find.text('Hay una versión nueva de Finza'), findsNothing);
    });

    testWidgets('"Más tarde" lo cierra sin abrir nada', (tester) async {
      await _pantalla(tester);
      var abrio = false;
      unawaited(avisarSiHayVersionNueva(
        instalada: '1.1.0',
        dio: _github(_release('v1.2.0', ['finza-1.2.0.apk'])),
        abrir: (_) async => abrio = true,
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Más tarde'));
      await tester.pumpAndSettle();

      expect(find.text('Hay una versión nueva de Finza'), findsNothing);
      expect(abrio, isFalse);
    });

    testWidgets('no aparece si es la misma versión, si GitHub falla o si no se sabe la instalada', (tester) async {
      await _pantalla(tester);
      Future<bool> nuncaAbre(Uri _) async => fail('no tenía que abrir nada');

      for (final (instalada, release) in [
        ('1.1.0', _release('v1.1.0', ['finza-1.1.0.apk'])), // la misma
        ('1.1.0', null), // GitHub no contesta
        ('', _release('v9.0.0', ['finza-9.0.0.apk'])), // armada en la compu
      ]) {
        unawaited(avisarSiHayVersionNueva(instalada: instalada, dio: _github(release), abrir: nuncaAbre));
        await tester.pumpAndSettle();
        expect(find.text('Hay una versión nueva de Finza'), findsNothing);
      }
    });
  });
}
