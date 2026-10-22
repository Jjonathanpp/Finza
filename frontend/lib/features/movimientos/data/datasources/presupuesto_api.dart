import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/presupuestos/data/models/presupuesto.dart';

class PresupuestoApi {
  PresupuestoApi(this._client);
  final ApiClient _client;

  Future<List<Presupuesto>> listarPorMes(int mes, int anio) async {
    try {
      final response = await _client.get('/presupuestos?mes=$mes&anio=$anio');
      final List<dynamic> data = response.data;
      return data.map((json) => Presupuesto.fromJson(json)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error al obtener los presupuestos: $e');
    }
  }
}