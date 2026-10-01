import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/features/categorias/data/datasources/categoria_api.dart';
import 'package:frontend/features/categorias/data/models/categoria.dart';
import 'package:frontend/features/categorias/presentation/viewmodels/categorias_view_model.dart';

class CategoriaApiDeMentira implements CategoriaApi {
  CategoriaApiDeMentira({this.falla = false});

  final bool falla;

  @override
  Future<List<Categoria>> listar() async {
    if (falla) throw ApiException(null, 'No se pudo conectar con el servidor');
    return const [
      Categoria(id: 1, nombre: 'Comida', tipo: 'EGRESO', esPredefinida: true),
      Categoria(id: 2, nombre: 'Sueldo', tipo: 'INGRESO', esPredefinida: true),
      Categoria(id: 3, nombre: 'Mascotas', tipo: 'EGRESO', esPredefinida: false),
    ];
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
}
