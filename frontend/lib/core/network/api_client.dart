import 'package:dio/dio.dart';
import 'package:frontend/config/constants/api_config.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/core/session/portero.dart';
import 'package:frontend/core/session/sesion.dart';
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
// Si el token venció (el pedido no sale) o el backend responde 401, termina la sesión.
// Menos en login y registro: ahí no hay sesión, y una contraseña equivocada también da 401.
class TokenInterceptor extends Interceptor {
  TokenInterceptor(this._tokens, {this.alTerminarSesion = irAlLogin});

  final TokenStorage _tokens;
  final void Function() alTerminarSesion;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokens.obtenerToken();
    if (token != null && !tokenVigente(token) && !_esDeLogin(options)) {
      await _terminarSesion();
      handler.reject(DioException(requestOptions: options, message: 'La sesión venció'));
      return;
    }
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_esDeLogin(err.requestOptions)) {
      await _terminarSesion();
    }
    handler.next(err);
  }

  Future<void> _terminarSesion() async {
    await _tokens.limpiar();
    alTerminarSesion();
  }
}

bool _esDeLogin(RequestOptions pedido) => pedido.uri.path.startsWith('/api/auth/');
