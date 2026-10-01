import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/features/categorias/data/datasources/categoria_api.dart';
import 'package:frontend/features/categorias/data/models/categoria.dart';
import 'package:frontend/features/categorias/presentation/viewmodels/nueva_categoria_view_model.dart';

class CategoriaApiDeMentira extends Fake implements CategoriaApi {
  CategoriaApiDeMentira({this.falla});

  final ApiException? falla;
  Map<String, Object?>? recibido;

  @override
  Future<Categoria> crear({
    required String nombre,
    required bool esIngreso,
    required String color,
  }) async {
    recibido = {'nombre': nombre, 'esIngreso': esIngreso, 'color': color};
    if (falla != null) throw falla!;
    return Categoria(
      id: 20,
      nombre: nombre,
      color: color,
      tipo: esIngreso ? 'INGRESO' : 'EGRESO',
      esPredefinida: false,
    );
  }
}

void main() {
  test('si el nombre está vacío, no manda nada', () async {
    final api = CategoriaApiDeMentira();
    final vm = NuevaCategoriaViewModel(api);

    final creada = await vm.guardar('   ');

    expect(creada, isNull);
    expect(vm.errorNombre, 'Ingresá un nombre');
    expect(api.recibido, isNull);
  });

  test('guarda con el tipo que le pasaron y el color elegido', () async {
    final api = CategoriaApiDeMentira();
    final vm = NuevaCategoriaViewModel(api, esIngreso: true);
    vm.elegirColor('#2DD4A7');

    final creada = await vm.guardar('Aguinaldo');

    expect(creada?.id, 20);
    expect(api.recibido, {'nombre': 'Aguinaldo', 'esIngreso': true, 'color': '#2DD4A7'});
    expect(vm.guardando, isFalse);
  });

  test('si el nombre ya existe, el error del backend va abajo del nombre', () async {
    const mensaje = 'Ya existe una categoría con ese nombre para el tipo indicado';
    final vm = NuevaCategoriaViewModel(CategoriaApiDeMentira(falla: ApiException(409, mensaje)));

    final creada = await vm.guardar('Comida');

    expect(creada, isNull);
    expect(vm.errorNombre, mensaje);
    expect(vm.error, isNull);
    expect(vm.guardando, isFalse);
  });

  test('si el backend falla por otra cosa, queda como error general', () async {
    const mensaje = 'No se pudo conectar con el servidor';
    final vm = NuevaCategoriaViewModel(CategoriaApiDeMentira(falla: ApiException(null, mensaje)));

    await vm.guardar('Mascotas');

    expect(vm.error, mensaje);
    expect(vm.errorNombre, isNull);
  });

  test('si la pantalla se cierra mientras guarda, no se rompe', () async {
    final vm = NuevaCategoriaViewModel(CategoriaApiDeMentira());
    final guardado = vm.guardar('Mascotas');
    vm.dispose();
    await guardado;
  });
}
