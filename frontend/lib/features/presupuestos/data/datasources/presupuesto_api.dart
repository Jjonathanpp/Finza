import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/presupuestos/data/models/presupuesto.dart';

class PresupuestoApi {
  PresupuestoApi(this._client);
  final ApiClient _client;

  Future<List<Presupuesto>> listarPorMes(int mes, int anio) async {
    try {
      final data = await _client.get('/api/presupuestos/mes?mes=$mes&anio=$anio');
      final List<dynamic> lista = data['categorias'] as List<dynamic>;
      return lista.map((json) => Presupuesto.fromJson(json)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(500, 'Error al obtener los presupuestos: $e');
    }
  }
}