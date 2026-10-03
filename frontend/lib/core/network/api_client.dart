import 'package:dio/dio.dart';
import 'package:frontend/config/constants/api_config.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/core/storage/token_storage.dart';

class ApiClient {
  final Dio _dio = Dio(BaseOptions(baseUrl: apiBaseUrl))
    ..interceptors.add(TokenInterceptor(TokenStorage()));

  Future<dynamic> get(String path) => _enviar(() => _dio.get(path));

  Future<dynamic> post(String path, Map<String, dynamic> body) =>
      _enviar(() => _dio.post(path, data: body));

  Future<dynamic> put(String path, Map<String, dynamic> body) =>
      _enviar(() => _dio.put(path, data: body));

  Future<dynamic> delete(String path) => _enviar(() => _dio.delete(path));

  Future<dynamic> _enviar(Future<Response> Function() pedido) async {
    try {
      final respuesta = await pedido();
      return respuesta.data['data'];
    } on DioException catch (e) {
      final respuestaError = e.response;
      if (respuestaError == null) {
        throw ApiException(null, 'No se pudo conectar con el servidor');
      }
      final cuerpo = respuestaError.data;
      if (cuerpo is Map && cuerpo['message'] != null) {
        throw ApiException(
          respuestaError.statusCode,
          cuerpo['message'],
          cuerpo['data'],
        );
      }
      throw ApiException(respuestaError.statusCode, 'Error inesperado del servidor');
    }
  }
}

// Antes de que salga cada pedido, le agrega el token del login (si hay uno guardado).
class TokenInterceptor extends Interceptor {
  TokenInterceptor(this._tokens);

  final TokenStorage _tokens;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokens.obtenerToken();
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }
}
