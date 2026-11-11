import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _storage = FlutterSecureStorage();
const _keyApariencia = 'apariencia';

// El modo elegido por la persona. Arranca en claro; cargarApariencia() pone el que se guardó.
final apariencia = ValueNotifier<ThemeMode>(ThemeMode.light);

// Al abrir la app. Si no hay nada guardado o falla la lectura, queda en claro.
Future<void> cargarApariencia() async {
  try {
    final guardada = await _storage.read(key: _keyApariencia);
    apariencia.value = guardada == 'oscuro' ? ThemeMode.dark : ThemeMode.light;
  } catch (_) {
    apariencia.value = ThemeMode.light;
  }
}

Future<void> guardarApariencia(ThemeMode modo) async {
  apariencia.value = modo;
  await _storage.write(
    key: _keyApariencia,
    value: modo == ThemeMode.dark ? 'oscuro' : 'claro',
  );
}
