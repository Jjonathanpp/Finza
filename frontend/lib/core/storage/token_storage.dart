import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _keyToken = 'auth_token';
  static const _keyRefreshToken = 'auth_refresh_token';
  static const _keyEmail = 'auth_email';

  Future<void> guardar({
    required String token,
    required String refreshToken,
    required String email,
  }) async {
    await _storage.write(key: _keyToken, value: token);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
    await _storage.write(key: _keyEmail, value: email);
  }

  Future<String?> obtenerToken() => _storage.read(key: _keyToken);

  Future<String?> obtenerRefreshToken() => _storage.read(key: _keyRefreshToken);

  Future<String?> obtenerEmail() => _storage.read(key: _keyEmail);

  Future<void> limpiar() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyEmail);
  }
}
