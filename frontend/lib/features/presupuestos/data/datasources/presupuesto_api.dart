import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/presupuestos/data/models/presupuesto.dart';

class PresupuestoApi {
  PresupuestoApi(this._client);
  final ApiClient _client;

  Future<List<Presupuesto>> listarPorMes(int mes, int anio) async {
    try {
      final response = await _client.get('/api/presupuestos/mes?mes=$mes&anio=$anio');
      // Extraemos los datos por si el backend los envuelve en un objeto "data"
      final data = response is Map && response.containsKey('data') ? response['data'] : response;
      
      if (data == null || !data.containsKey('categorias')) return [];

      final List<dynamic> lista = data['categorias'] as List<dynamic>;
      return lista.map((json) => Presupuesto.fromJson(json)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(500, 'Error al obtener los presupuestos: $e');
    }
  }

  Future<void> crearPresupuesto({
    required int categoriaId,
    required double montoTope,
    required int mes,
    required int anio,
  }) async {
    try {
      await _client.post('/api/presupuestos', {
        'categoriaId': categoriaId,
        'montoTope': montoTope,
        'mes': mes,
        'anio': anio,
      });
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(500, 'Error al crear el presupuesto: $e');
    }
  }

  Future<List<Map<String, dynamic>>> obtenerCategoriasEgreso() async {
    try {
      final response = await _client.get('/api/categorias');
      final List datos = response is Map && response.containsKey('data') ? response['data'] : response;
      
      return datos
          .cast<Map<String, dynamic>>()
          .where((c) => c['tipo'] == 'EGRESO')
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(500, 'Error al obtener categorías: $e');
    }
  }
}