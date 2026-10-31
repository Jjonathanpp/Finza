import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/core/session/cuenta_activa.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _keyToken = 'auth_token';
  static const _keyRefreshToken = 'auth_refresh_token';
  static const _keyEmail = 'auth_email';
  static const _keyCuenta = 'cuenta_activa';

  Future<void> guardar({
    required String token,
    required String refreshToken,
    required String email,
  }) async {
    await _storage.write(key: _keyToken, value: token);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
    await _storage.write(key: _keyEmail, value: email);
    await guardarCuentaActiva(null); // al iniciar sesión, la cuenta personal
  }

  // La cuenta elegida en el selector (ver cuenta_activa.dart): null es la personal.
  Future<void> guardarCuentaActiva(Map<String, dynamic>? cuenta) async {
    cuentaActiva.value = cuenta;
    if (cuenta == null) {
      await _storage.delete(key: _keyCuenta);
    } else {
      await _storage.write(key: _keyCuenta, value: jsonEncode(cuenta));
    }
  }

  // Al abrir la app, para seguir en la cuenta en la que se estaba.
  Future<void> cargarCuentaActiva() async {
    final guardada = await _storage.read(key: _keyCuenta);
    cuentaActiva.value = guardada == null ? null : jsonDecode(guardada) as Map<String, dynamic>;
  }

  Future<String?> obtenerToken() => _storage.read(key: _keyToken);

  Future<String?> obtenerRefreshToken() => _storage.read(key: _keyRefreshToken);

  Future<String?> obtenerEmail() => _storage.read(key: _keyEmail);

  Future<void> limpiar() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyEmail);
    await guardarCuentaActiva(null);
  }
}
