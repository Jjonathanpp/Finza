import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/storage/token_storage.dart';

// Hace de backend: anota los encabezados que le llegan y responde 200.
class _BackendDeMentira implements HttpClientAdapter {
  Map<String, dynamic>? encabezados;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    encabezados = options.headers;
    return ResponseBody.fromString(
      jsonEncode({'status': 200, 'message': 'OK', 'data': null}),
      200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

Future<Map<String, dynamic>?> _encabezadosDeUnPedido() async {
  final backend = _BackendDeMentira();
  final dio = Dio()
    ..httpClientAdapter = backend
    ..interceptors.add(TokenInterceptor(TokenStorage()));
  await dio.get('http://backend/api/categorias');
  return backend.encabezados;
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('con sesión iniciada, cada pedido lleva el token', () async {
    await TokenStorage().guardar(token: 'abc.def.ghi', refreshToken: 'r', email: 'a@b.com');

    final encabezados = await _encabezadosDeUnPedido();

    expect(encabezados?['Authorization'], 'Bearer abc.def.ghi');
  });

  test('sin sesión, el pedido sale sin token', () async {
    final encabezados = await _encabezadosDeUnPedido();

    expect(encabezados?.containsKey('Authorization'), isFalse);
  });

  test('después de cerrar sesión, deja de mandarlo', () async {
    await TokenStorage().guardar(token: 'abc.def.ghi', refreshToken: 'r', email: 'a@b.com');
    await TokenStorage().limpiar();

    final encabezados = await _encabezadosDeUnPedido();

    expect(encabezados?.containsKey('Authorization'), isFalse);
  });
}
