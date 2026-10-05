import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/session/sesion.dart';

import 'tokens_de_prueba.dart';

void main() {
  group('tokenVigente', () {
    test('sin token no hay sesión', () {
      expect(tokenVigente(null), isFalse);
    });

    test('un texto que no es un token no sirve', () {
      expect(tokenVigente(''), isFalse);
      expect(tokenVigente('cualquier-cosa'), isFalse);
      expect(tokenVigente('a.b.c'), isFalse);
    });

    test('un token que vence en media hora sirve', () {
      expect(tokenVigente(tokenVigenteDePrueba()), isTrue);
    });

    test('un token que venció hace un minuto no sirve', () {
      expect(tokenVigente(tokenVencidoDePrueba()), isFalse);
    });

    test('un token sin fecha de vencimiento no sirve', () {
      expect(tokenVigente(tokenCon({'sub': '29'})), isFalse);
    });
  });
}
