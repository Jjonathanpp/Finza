import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/features/categorias/data/datasources/categoria_api.dart';
import 'package:frontend/features/categorias/data/models/categoria.dart';
import 'package:frontend/features/categorias/presentation/viewmodels/categorias_view_model.dart';

class CategoriaApiDeMentira extends Fake implements CategoriaApi {
  CategoriaApiDeMentira({this.falla = false, this.fallaAlEliminar});

  final bool falla;
  final ApiException? fallaAlEliminar;

  @override
  Future<List<Categoria>> listar() async {
    if (falla) throw ApiException(null, 'No se pudo conectar con el servidor');
    return const [
      Categoria(id: 1, nombre: 'Comida', tipo: 'EGRESO', esPredefinida: true),
      Categoria(id: 2, nombre: 'Sueldo', tipo: 'INGRESO', esPredefinida: true),
      Categoria(id: 3, nombre: 'Mascotas', tipo: 'EGRESO', esPredefinida: false),
    ];
  }

  @override
  Future<void> eliminar(Categoria categoria) async {
    if (fallaAlEliminar != null) throw fallaAlEliminar!;
  }
}

void main() {
  test('cargar trae las categorías y las separa por tipo', () async {
    final vm = CategoriasViewModel(CategoriaApiDeMentira());

    await vm.cargar();

    expect(vm.cargando, isFalse);
    expect(vm.error, isNull);
    expect(vm.deIngreso.map((c) => c.nombre).toList(), ['Sueldo']);
    expect(vm.deEgreso.map((c) => c.nombre).toList(), ['Comida', 'Mascotas']);
  });

  test('si la pantalla se cierra mientras carga, no se rompe', () async {
    final vm = CategoriasViewModel(CategoriaApiDeMentira());
    final carga = vm.cargar();
    vm.dispose();
    await carga; // sin el arreglo, acá tiraba "A ChangeNotifier was used after being disposed"
  });

  test('si el backend falla, guarda el mensaje y deja de cargar', () async {
    final vm = CategoriasViewModel(CategoriaApiDeMentira(falla: true));

    await vm.cargar();

    expect(vm.cargando, isFalse);
    expect(vm.error, 'No se pudo conectar con el servidor');
    expect(vm.categorias, isEmpty);
  });

  test('eliminar la saca de la lista', () async {
    final vm = CategoriasViewModel(CategoriaApiDeMentira());
    await vm.cargar();

    final error = await vm.eliminar(vm.deEgreso.last);

    expect(error, isNull);
    expect(vm.deEgreso.map((c) => c.nombre).toList(), ['Comida']);
  });

  test('si tiene movimientos, devuelve el mensaje y la deja en la lista', () async {
    const mensaje = 'No se puede eliminar la categoría porque tiene movimientos asociados';
    final vm = CategoriasViewModel(CategoriaApiDeMentira(fallaAlEliminar: ApiException(409, mensaje)));
    await vm.cargar();

    final error = await vm.eliminar(vm.deEgreso.last);

    expect(error, mensaje);
    expect(vm.deEgreso.map((c) => c.nombre).toList(), ['Comida', 'Mascotas']);
  });
}
