import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/categorias/data/datasources/categoria_api.dart';
import 'package:frontend/features/movimientos/data/datasources/movimiento_api.dart';

// Anota qué se le pide al backend, sin mandar nada. Contesta un movimiento cualquiera.
class _ApiClientQueAnota extends Fake implements ApiClient {
  String? ruta;
  Map<String, dynamic>? cuerpo;

  static const _movimiento = {
    'id': 1,
    'tipo': 'egreso',
    'monto': 500,
    'fecha': '09-10-2026',
    'estado': 'APROBADO',
    'perfilId': 30,
    'categoria': {'id': 6, 'nombre': 'Comida', 'tipo': 'EGRESO', 'esPredefinida': true},
  };

  @override
  Future<dynamic> get(String path) async {
    ruta = path;
    return path.startsWith('/api/categorias') ? [] : {'content': [], 'totalPages': 1};
  }

  @override
  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    ruta = path;
    cuerpo = body;
    return [_movimiento];
  }

  @override
  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    ruta = path;
    cuerpo = body;
    return _movimiento;
  }
}

void main() {
  // Quién es el usuario lo dice el token, que agrega el interceptor: los pedidos no mandan cuenta ni perfil.
  group('los pedidos no mandan cuenta ni perfil, y la fecha va como la espera el backend', () {
    test('crear un movimiento: fecha dd-MM-yyyy y sin perfil', () async {
      final api = _ApiClientQueAnota();
      await MovimientoApi(api).crear(
        esIngreso: false,
        monto: '500',
        categoria: 'Comida',
        fecha: DateTime(2026, 10, 9),
      );

      expect(api.cuerpo!.containsKey('perfilId'), isFalse);
      expect(api.cuerpo!['movimientos'][0]['fecha'], '09-10-2026');
    });

    test('editar un movimiento: fecha dd-MM-yyyy y sin perfil', () async {
      final api = _ApiClientQueAnota();
      await MovimientoApi(api).actualizar(
        id: 1,
        esIngreso: false,
        monto: '500',
        categoria: 'Comida',
        fecha: DateTime(2026, 10, 9),
      );

      expect(api.cuerpo!.containsKey('perfilId'), isFalse);
      expect(api.cuerpo!['fecha'], '09-10-2026');
    });

    test('el historial: filtros con fecha yyyy-MM-dd y sin perfil', () async {
      final api = _ApiClientQueAnota();
      await MovimientoApi(api).listar(fechaInicio: DateTime(2026, 10, 1));

      expect(api.ruta, '/api/movimientos?page=0&size=12&fechaInicio=2026-10-01');
    });

    test('las categorías: sin cuenta', () async {
      final api = _ApiClientQueAnota();
      await CategoriaApi(api).listar();

      expect(api.ruta, '/api/categorias');
    });
  });
}
