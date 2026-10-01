import 'package:frontend/config/constants/sesion_temporal.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/categorias/data/models/categoria.dart';

class CategoriaApi {
  CategoriaApi(this._api);

  final ApiClient _api;

  Future<List<Categoria>> listar() async {
    final data = await _api.get('/api/categorias?cuentaId=$cuentaIdTemporal');
    return (data as List).map((json) => Categoria.fromJson(json)).toList();
  }

  Future<Categoria> crear({
    required String nombre,
    required bool esIngreso,
    required String color,
  }) async {
    final data = await _api.post('/api/categorias?cuentaId=$cuentaIdTemporal', {
      'nombre': nombre,
      'tipo': esIngreso ? 'INGRESO' : 'EGRESO',
      'color': color,
    });
    return Categoria.fromJson(data);
  }
}
