import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/shared/utils/importe.dart';

void main() {
  tearDown(() => monedaVista.value = enPesos);

  test('en pesos, como en la maqueta: sin centavos, con punto de miles y el menos adelante', () {
    expect(importe(200000), '\$ 200.000');
    expect(importe(-5000), '−\$ 5.000');
    expect(importe(1234.5, centavos: true), '\$ 1.234,50');
  });

  test('en dólares se divide por la cotización y va con centavos', () {
    monedaVista.value = (moneda: 'DOLAR', cotizacion: 1540.0, actualizada: null);

    expect(importe(15400), 'US\$ 10,00');
    expect(importe(-1000), '−US\$ 0,65');
    expect(importe(1540000), 'US\$ 1.000,00');
  });

  test('en euros, con la cotización del euro', () {
    monedaVista.value = (moneda: 'EURO', cotizacion: 1712.166, actualizada: null);

    expect(importe(15400), '€ 8,99');
  });

  test('con dólares elegidos pero sin cotización, se ve en pesos', () {
    monedaVista.value = (moneda: 'DOLAR', cotizacion: null, actualizada: null);

    expect(importe(15400), '\$ 15.400');
    expect(nombreMoneda, 'Pesos');
    expect(aclaracionCotizacion, isNull);
  });

  test('lee lo que devuelve /api/preferencias/moneda', () {
    final moneda = monedaDesdeJson({'moneda': 'DOLAR', 'cotizacion': 1540, 'actualizada': '2026-10-20T10:00:00Z'});

    expect(moneda.moneda, 'DOLAR');
    expect(moneda.cotizacion, 1540.0);
    expect(moneda.actualizada, DateTime.utc(2026, 10, 20, 10).toLocal());
    expect(monedaDesdeJson({'moneda': 'PESO', 'cotizacion': null, 'actualizada': null}), enPesos);
  });
}
