import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/storage/token_storage.dart';

import 'tokens_de_prueba.dart';

// Hace de backend: anota los encabezados que le llegan y responde con [estado] (200 si no se dice).
class _BackendDeMentira implements HttpClientAdapter {
  _BackendDeMentira({this.estado = 200});

  final int estado;
  Map<String, dynamic>? encabezados;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    encabezados = options.headers;
    return ResponseBody.fromString(
      jsonEncode({'status': estado, 'message': 'OK', 'data': null}),
      estado,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dioConInterceptor(_BackendDeMentira backend, {void Function()? alTerminarSesion}) => Dio()
  ..httpClientAdapter = backend
  ..interceptors.add(TokenInterceptor(TokenStorage(), alTerminarSesion: alTerminarSesion ?? () {}));

Future<Map<String, dynamic>?> _encabezadosDeUnPedido() async {
  final backend = _BackendDeMentira();
  await _dioConInterceptor(backend).get('http://backend/api/categorias');
  return backend.encabezados;
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('con sesión iniciada, cada pedido lleva el token', () async {
    final token = tokenVigenteDePrueba();
    await TokenStorage().guardar(token: token, refreshToken: 'r', email: 'a@b.com');

    final encabezados = await _encabezadosDeUnPedido();

    expect(encabezados?['Authorization'], 'Bearer $token');
  });

  test('sin sesión, el pedido sale sin token', () async {
    final encabezados = await _encabezadosDeUnPedido();

    expect(encabezados?.containsKey('Authorization'), isFalse);
  });

  test('después de cerrar sesión, deja de mandarlo', () async {
    await TokenStorage().guardar(token: tokenVigenteDePrueba(), refreshToken: 'r', email: 'a@b.com');
    await TokenStorage().limpiar();

    final encabezados = await _encabezadosDeUnPedido();

    expect(encabezados?.containsKey('Authorization'), isFalse);
  });

  test('con el token vencido, el pedido no sale, se borra la sesión y vuelve al login', () async {
    await TokenStorage().guardar(token: tokenVencidoDePrueba(), refreshToken: 'r', email: 'a@b.com');
    final backend = _BackendDeMentira();
    var fueAlLogin = false;

    final pedido = _dioConInterceptor(backend, alTerminarSesion: () => fueAlLogin = true)
        .get('http://backend/api/categorias');

    await expectLater(pedido, throwsA(isA<DioException>()));
    expect(backend.encabezados, isNull, reason: 'al backend no le tiene que llegar nada');
    expect(await TokenStorage().obtenerToken(), isNull);
    expect(fueAlLogin, isTrue);
  });

  test('el login sale aunque haya un token vencido guardado', () async {
    await TokenStorage().guardar(token: tokenVencidoDePrueba(), refreshToken: 'r', email: 'a@b.com');
    final backend = _BackendDeMentira();
    var fueAlLogin = false;

    await _dioConInterceptor(backend, alTerminarSesion: () => fueAlLogin = true)
        .post('http://backend/api/auth/login');

    expect(backend.encabezados, isNotNull);
    expect(fueAlLogin, isFalse);
  });

  test('si el backend responde 401, se borra la sesión y vuelve al login', () async {
    await TokenStorage().guardar(token: tokenVigenteDePrueba(), refreshToken: 'r', email: 'a@b.com');
    var fueAlLogin = false;

    final pedido = _dioConInterceptor(_BackendDeMentira(estado: 401), alTerminarSesion: () => fueAlLogin = true)
        .get('http://backend/api/categorias');

    await expectLater(
      pedido,
      throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'estado', 401)),
    );
    expect(await TokenStorage().obtenerToken(), isNull);
    expect(fueAlLogin, isTrue);
  });

  test('un 401 del login (contraseña equivocada) no cierra nada', () async {
    var fueAlLogin = false;

    final pedido = _dioConInterceptor(_BackendDeMentira(estado: 401), alTerminarSesion: () => fueAlLogin = true)
        .post('http://backend/api/auth/login');

    await expectLater(pedido, throwsA(isA<DioException>()));
    expect(fueAlLogin, isFalse);
  });

  test('un 403 (no es tuyo) no cierra la sesión', () async {
    final token = tokenVigenteDePrueba();
    await TokenStorage().guardar(token: token, refreshToken: 'r', email: 'a@b.com');
    var fueAlLogin = false;

    final pedido = _dioConInterceptor(_BackendDeMentira(estado: 403), alTerminarSesion: () => fueAlLogin = true)
        .get('http://backend/api/categorias');

    await expectLater(pedido, throwsA(isA<DioException>()));
    expect(await TokenStorage().obtenerToken(), token);
    expect(fueAlLogin, isFalse);
  });
}
