import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/metas_ahorro/data/models/meta_ahorro.dart';
import 'package:frontend/l10n/idioma.dart';

class MetasAhorroApi {
  MetasAhorroApi(this._client);

  final ApiClient _client;

  Future<List<MetaAhorro>> listar({int? cuentaCompartidaId}) async {
    try {
      final query = cuentaCompartidaId == null
          ? ''
          : '?cuentaCompartidaId=$cuentaCompartidaId';
      final response = await _client.get('/api/metas$query');
      if (response is! List) {
        throw ApiException(
          500,
          tr('El servidor devolvió una lista de metas inválida'),
        );
      }
      return response
          .map((item) => MetaAhorro.fromJson(item as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        500,
        tr('Error al obtener las metas de ahorro: {error}', {'error': '$e'}),
      );
    }
  }

  Future<void> crear({
    required String nombre,
    required double montoObjetivo,
    DateTime? fechaLimite,
    int? cuentaCompartidaId,
  }) async {
    try {
      await _client.post('/api/metas', {
        'nombre': nombre,
        'montoObjetivo': montoObjetivo,
        'fechaLimite': _fecha(fechaLimite),
        'cuentaCompartidaId': cuentaCompartidaId,
      });
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        500,
        tr('Error al crear la meta de ahorro: {error}', {'error': '$e'}),
      );
    }
  }

  Future<void> editar({
    required int id,
    required String nombre,
    required double montoObjetivo,
    DateTime? fechaLimite,
  }) async {
    try {
      await _client.put('/api/metas/$id', {
        'nombre': nombre,
        'montoObjetivo': montoObjetivo,
        'fechaLimite': _fecha(fechaLimite),
      });
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        500,
        tr('Error al editar la meta de ahorro: {error}', {'error': '$e'}),
      );
    }
  }

  Future<void> eliminar(int id) async {
    try {
      await _client.delete('/api/metas/$id');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        500,
        tr('Error al eliminar la meta de ahorro: {error}', {'error': '$e'}),
      );
    }
  }

  Future<void> abonar({required int id, required double monto}) async {
    try {
      await _client.post('/api/metas/$id/abonar', {'monto': monto});
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        500,
        tr('Error al ingresar dinero a la meta: {error}', {'error': '$e'}),
      );
    }
  }

  Future<void> retirar({required int id, required double monto}) async {
    try {
      await _client.post('/api/metas/$id/retirar', {'monto': monto});
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        500,
        tr('Error al retirar dinero de la meta: {error}', {'error': '$e'}),
      );
    }
  }

  // El desglose de aportes de una meta: todos los integrantes (también los que todavía no pusieron
  // nada y los que ya se fueron), con cuánto puso cada uno y qué parte del objetivo es.
  Future<List<AporteMetaAhorro>> aportes(int id) async {
    final response = await _client.get('/api/metas/$id/aportes');
    final lista = response is Map ? response['aportes'] : null;
    if (lista is! List) return const [];
    return lista
        .map((item) => AporteMetaAhorro.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  String? _fecha(DateTime? fecha) => fecha == null
      ? null
      : '${fecha.year.toString().padLeft(4, '0')}-'
            '${fecha.month.toString().padLeft(2, '0')}-'
            '${fecha.day.toString().padLeft(2, '0')}';
}
