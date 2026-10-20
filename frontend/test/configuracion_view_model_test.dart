import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/features/configuracion/data/datasources/preferencias_api.dart';
import 'package:frontend/features/configuracion/presentation/viewmodels/configuracion_view_model.dart';
import 'package:frontend/shared/utils/importe.dart';

// Contesta como el PUT de /api/preferencias/moneda y anota qué se le pidió.
class PreferenciasApiDeMentira extends Fake implements PreferenciasApi {
  PreferenciasApiDeMentira({this.falla = false});

  final bool falla;
  final pedidas = <String>[];

  @override
  Future<MonedaVista> cambiarMoneda(String moneda) async {
    pedidas.add(moneda);
    if (falla) throw ApiException(null, 'No se pudo conectar con el servidor');
    return (moneda: moneda, cotizacion: 1540.0, actualizada: null);
  }
}

void main() {
  tearDown(() => monedaVista.value = enPesos);

  test('elegir dólares lo guarda en el backend y cambia la moneda de toda la app', () async {
    final api = PreferenciasApiDeMentira();
    final vm = ConfiguracionViewModel(api);

    await vm.elegirMoneda('DOLAR');

    expect(api.pedidas, ['DOLAR']);
    expect(monedaVista.value.moneda, 'DOLAR');
    expect(monedaVista.value.cotizacion, 1540.0);
    expect(vm.guardando, isFalse);
    expect(vm.error, isNull);
  });

  test('si el backend falla, queda la moneda que estaba y se avisa', () async {
    final vm = ConfiguracionViewModel(PreferenciasApiDeMentira(falla: true));

    await vm.elegirMoneda('EURO');

    expect(monedaVista.value, enPesos);
    expect(vm.error, 'No se pudo conectar con el servidor');
    expect(vm.guardando, isFalse);
  });

  test('elegir la que ya está no pide nada', () async {
    final api = PreferenciasApiDeMentira();

    await ConfiguracionViewModel(api).elegirMoneda('PESO');

    expect(api.pedidas, isEmpty);
  });
}
