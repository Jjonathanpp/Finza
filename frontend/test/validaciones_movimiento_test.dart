import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/movimientos/presentation/validaciones_movimiento.dart';

void main() {
  test('el monto se escribe como en Argentina y se frena lo que el backend no valida', () {
    expect(validarMonto('1500'), isNull);
    expect(validarMonto('130.000'), isNull);
    expect(validarMonto('1.500,50'), isNull);
    expect(validarMonto(''), 'Ingresá un monto');
    expect(validarMonto('abc'), 'El monto no es válido');
    expect(validarMonto('10,999'), 'Máximo 2 decimales');
    expect(validarMonto('0'), 'El monto tiene que ser mayor a cero');
    expect(validarMonto('99.999.999.999'), 'El monto es demasiado grande');
  });

  test('el monto sale sin puntos de miles y con punto decimal para el backend', () {
    expect(normalizarMonto(' 130.000,50 '), '130000.50');
    expect(normalizarMonto('130.000'), '130000');
  });

  test('la categoría es obligatoria', () {
    expect(validarCategoria(null), 'Elegí una categoría');
    expect(validarCategoria('Sueldo'), isNull);
  });
}
