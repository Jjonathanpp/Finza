import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/movimientos/presentation/monto_formatter.dart';

// Simula que el campo tenía `antes` y el usuario lo dejó en `despues`.
String tipear(String despues, {String antes = ''}) => MontoArgentinoFormatter()
    .formatEditUpdate(TextEditingValue(text: antes), TextEditingValue(text: despues))
    .text;

void main() {
  test('pone los puntos de miles solo', () {
    expect(tipear('130000'), '130.000');
    expect(tipear('1000000'), '1.000.000');
    expect(tipear('999'), '999');
  });

  test('la coma es de centavos, con 2 como máximo', () {
    expect(tipear('130000,5'), '130.000,5');
    expect(tipear(',5'), '0,5');
    expect(tipear('10,999', antes: '10,99'), '10,99');
    expect(tipear('1,2,3', antes: '1,2'), '1,2');
  });

  test('tocar el punto al final empieza los centavos', () {
    expect(tipear('130.000.', antes: '130.000'), '130.000,');
  });
}
