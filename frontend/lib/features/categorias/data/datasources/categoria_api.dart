import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/categorias/data/models/categoria.dart';

class CategoriaApi {
  CategoriaApi(this._api);

  final ApiClient _api;

  Future<List<Categoria>> listar() async {
    final data = await _api.get('/api/categorias');
    return (data as List).map((json) => Categoria.fromJson(json)).toList();
  }

  Future<Categoria> crear({
    required String nombre,
    required bool esIngreso,
    required String color,
  }) async {
    final data = await _api.post('/api/categorias', {
      'nombre': nombre,
      'tipo': esIngreso ? 'INGRESO' : 'EGRESO',
      'color': color,
    });
    return Categoria.fromJson(data);
  }

  // La respuesta no se lee: el PUT devuelve la entidad entera, con otros nombres de campos.
  Future<void> editar(
    Categoria categoria, {
    required String nombre,
    required String color,
    int? cuentaCompartidaId,
  }) async {
    await _api.put(_ruta(categoria.id, cuentaCompartidaId), {
      'nombre': nombre,
      'color': color,
      // Hoy el PUT no lo usa, pero es el mismo pedido del alta, donde es obligatorio.
      'tipo': categoria.tipo,
    });
  }

  Future<void> eliminar(Categoria categoria, {int? cuentaCompartidaId}) async {
    await _api.delete(_ruta(categoria.id, cuentaCompartidaId));
  }

  String _ruta(int id, int? cuentaCompartidaId) => cuentaCompartidaId == null
      ? '/api/categorias/$id'
      : '/api/categorias/$id?cuentaCompartidaId=$cuentaCompartidaId';
}
