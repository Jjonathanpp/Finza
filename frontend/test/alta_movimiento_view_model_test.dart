import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/features/categorias/data/datasources/categoria_api.dart';
import 'package:frontend/features/categorias/data/models/categoria.dart';
import 'package:frontend/features/movimientos/data/datasources/movimiento_api.dart';
import 'package:frontend/features/movimientos/data/models/movimiento.dart';
import 'package:frontend/features/movimientos/presentation/viewmodels/alta_movimiento_view_model.dart';

const _sueldo = Categoria(id: 1, nombre: 'Sueldo', tipo: 'INGRESO', esPredefinida: true);

class CategoriaApiDeMentira extends Fake implements CategoriaApi {
  @override
  Future<List<Categoria>> listar() async => const [
        _sueldo,
        Categoria(id: 6, nombre: 'Comida', tipo: 'EGRESO', esPredefinida: true),
        Categoria(id: 9, nombre: 'Mascotas', tipo: 'EGRESO', esPredefinida: false),
      ];
}

class MovimientoApiDeMentira implements MovimientoApi {
  MovimientoApiDeMentira({this.falla = false});

  final bool falla;
  Map<String, Object?>? recibido;

  @override
  Future<Movimiento> crear({
    required bool esIngreso,
    required String monto,
    required String categoria,
    String? descripcion,
    required DateTime fecha,
  }) async {
    recibido = {'esIngreso': esIngreso, 'monto': monto, 'categoria': categoria};
    if (falla) throw ApiException(400, 'Error: Datos invalidos');
    return Movimiento(
      id: 1,
      tipo: esIngreso ? 'ingreso' : 'egreso',
      monto: double.parse(monto),
      fecha: fecha,
      estado: 'APROBADO',
      categoria: _sueldo,
      perfilId: 1,
    );
  }
}

void main() {
  test('muestra solo las categorías del tipo elegido', () async {
    final vm = AltaMovimientoViewModel(CategoriaApiDeMentira(), MovimientoApiDeMentira());
    await vm.cargarCategorias();

    expect(vm.categoriasDelTipo.map((c) => c.nombre).toList(), ['Sueldo']);
    vm.cambiarTipo(false);
    expect(vm.categoriasDelTipo.map((c) => c.nombre).toList(), ['Comida', 'Mascotas']);
  });

  test('la categoría creada desde el panel aparece entre las opciones y queda elegida', () async {
    final vm = AltaMovimientoViewModel(CategoriaApiDeMentira(), MovimientoApiDeMentira());
    await vm.cargarCategorias();
    vm.cambiarTipo(false);

    vm.agregarCategoria(const Categoria(id: 20, nombre: 'Gimnasio', tipo: 'EGRESO', esPredefinida: false));

    expect(vm.categoriasDelTipo.map((c) => c.nombre).toList(), ['Comida', 'Mascotas', 'Gimnasio']);
    expect(vm.categoria, 'Gimnasio');
  });

  test('si el monto o la categoría están mal, no manda nada', () async {
    final api = MovimientoApiDeMentira();
    final vm = AltaMovimientoViewModel(CategoriaApiDeMentira(), api);

    final creado = await vm.guardar(monto: '');

    expect(creado, isNull);
    expect(vm.errorMonto, 'Ingresá un monto');
    expect(vm.errorCategoria, 'Elegí una categoría');
    expect(api.recibido, isNull);
  });

  test('guarda con el monto en punto y el tipo elegido', () async {
    final api = MovimientoApiDeMentira();
    final vm = AltaMovimientoViewModel(CategoriaApiDeMentira(), api);
    vm.elegirCategoria('Sueldo');

    final creado = await vm.guardar(monto: '1500,50');

    expect(creado, isNotNull);
    expect(api.recibido, {'esIngreso': true, 'monto': '1500.50', 'categoria': 'Sueldo'});
    expect(vm.guardando, isFalse);
  });

  test('si la pantalla se cierra mientras guarda, no se rompe', () async {
    final vm = AltaMovimientoViewModel(CategoriaApiDeMentira(), MovimientoApiDeMentira());
    vm.elegirCategoria('Sueldo');
    final guardado = vm.guardar(monto: '1500');
    vm.dispose();
    await guardado; // sin el arreglo, acá tiraba "A ChangeNotifier was used after being disposed"
  });

  test('si el backend falla, queda su mensaje y deja de guardar', () async {
    final vm = AltaMovimientoViewModel(CategoriaApiDeMentira(), MovimientoApiDeMentira(falla: true));
    vm.elegirCategoria('Sueldo');

    final creado = await vm.guardar(monto: '1500');

    expect(creado, isNull);
    expect(vm.error, 'Error: Datos invalidos');
    expect(vm.guardando, isFalse);
  });
}
