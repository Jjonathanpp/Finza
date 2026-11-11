import 'dart:io';

import 'package:dio/dio.dart';
import 'package:frontend/config/constants/api_config.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/core/network/estado_conexion.dart';
import 'package:frontend/core/session/cuenta_activa.dart';
import 'package:frontend/core/session/portero.dart';
import 'package:frontend/core/session/sesion.dart';
import 'package:frontend/core/storage/token_storage.dart';

class ApiClient {
  final Dio _dio = Dio(BaseOptions(baseUrl: apiBaseUrl))
    ..interceptors.add(TokenInterceptor(TokenStorage()));

  Future<dynamic> get(String path) => _enviar(() => _dio.get(path));

  Future<dynamic> post(String path, Map<String, dynamic> body) =>
      _enviar(() => _dio.post(path, data: body));

  Future<dynamic> postMultipart(String path, FormData body) =>
      _enviar(() => _dio.post(path, data: body));

  Future<dynamic> put(String path, Map<String, dynamic> body) =>
      _enviar(() => _dio.put(path, data: body));

  Future<dynamic> delete(String path, [Map<String, dynamic>? body]) =>
      _enviar(() => _dio.delete(path, data: body));

  Future<dynamic> _enviar(Future<Response> Function() pedido) async {
    try {
      final respuesta = await pedido();
      sinConexion.value = false;
      return respuesta.data['data'];
    } on DioException catch (e) {
      final respuestaError = e.response;
      if (respuestaError == null) throw _errorSinRespuesta(e);
      sinConexion.value = false;
      final cuerpo = respuestaError.data;
      if (cuerpo is Map && cuerpo['message'] != null) {
        throw ApiException(
          respuestaError.statusCode,
          cuerpo['message'],
          cuerpo['data'],
        );
      }
      throw ApiException(respuestaError.statusCode, _errorInesperado);
    }
  }

  Future<List<int>> getBytes(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final respuesta = await _dio.get<List<int>>(
        path,
        queryParameters: queryParameters,
        options: Options(responseType: ResponseType.bytes),
      );
      sinConexion.value = false;
      return respuesta.data ?? <int>[];
    } on DioException catch (e) {
      final respuestaError = e.response;
      if (respuestaError == null) throw _errorSinRespuesta(e);
      sinConexion.value = false;
      throw ApiException(respuestaError.statusCode, _errorInesperado);
    }
  }
}

const _errorSinConexion =
    'No pudimos conectarnos. Revisá tu conexión a internet y probá de nuevo.';
const _errorInesperado =
    'Algo salió mal de nuestro lado. Probá de nuevo en un rato.';

// Un pedido que no tuvo respuesta: si fue por falta de conexión (sin red, backend que no contesta o
// demora de más) se prende el aviso global de la app; si fue por otra cosa, un mensaje genérico.
ApiException _errorSinRespuesta(DioException e) {
  final porConexion = switch (e.type) {
    DioExceptionType.connectionError ||
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => true,
    DioExceptionType.unknown => e.error is SocketException,
    _ => false,
  };
  if (porConexion) {
    sinConexion.value = true;
    return ApiException(null, _errorSinConexion);
  }
  return ApiException(null, 'No pudimos completar la acción. Probá de nuevo.');
}

// Antes de que salga cada pedido, le agrega el token del login (si hay uno guardado) y, si se eligió
// una cuenta compartida en el selector, su perfil en X-Perfil-Id (t-13.1.2).
// Si el token venció (el pedido no sale) o el backend responde 401, termina la sesión.
// Menos en login y registro: ahí no hay sesión, y una contraseña equivocada también da 401.
class TokenInterceptor extends Interceptor {
  TokenInterceptor(this._tokens, {this.alTerminarSesion = irAlLogin});

  final TokenStorage _tokens;
  final void Function() alTerminarSesion;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokens.obtenerToken();
    if (token != null && !tokenVigente(token) && !_esDeLogin(options)) {
      await _terminarSesion();
      handler.reject(
        DioException(requestOptions: options, message: 'La sesión venció'),
      );
      return;
    }
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    final cuenta = cuentaActiva.value;
    if (cuenta != null) {
      options.headers['X-Perfil-Id'] = '${cuenta['perfilId']}';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
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

/* bool _esDeLogin(RequestOptions pedido) =>
    pedido.uri.path.startsWith('/api/auth/'); */

bool _esDeLogin(RequestOptions pedido) => const [
  '/api/auth/login',
  '/api/auth/registro',
  '/api/auth/olvide-contrasena',
  '/api/auth/restablecer-contrasena',
].contains(pedido.uri.path);
