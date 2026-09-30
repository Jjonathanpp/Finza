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
}
