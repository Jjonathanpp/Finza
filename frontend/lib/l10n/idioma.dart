import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Idioma de la app (US-8.3). El español está escrito en el código: cada texto que ve el usuario va
// dentro de tr('...'). Cada otro idioma es un archivo en assets/idiomas/ (en.json, it.json...) con el
// texto en español como clave y "_nombre" con el nombre del idioma. Para sumar un idioma alcanza con
// agregar su archivo: aparece solo en Configuración. Si a un archivo le falta un texto, sale en español.
// La elección se guarda en el celular, no en la cuenta: no se borra al cerrar sesión.

const _carpeta = 'assets/idiomas/';
const _storage = FlutterSecureStorage();

final idioma = ValueNotifier(const Locale('es'));

/// Los idiomas que se pueden elegir: código → nombre en su idioma ({'es': 'Español', 'en': 'English'}).
var idiomas = {'es': 'Español'};

var _textos = <String, String>{};

/// Antes de arrancar la app: busca los archivos de idioma y carga el que estaba elegido.
Future<void> leerIdioma() async {
  final manifiesto = await AssetManifest.loadFromAssetBundle(rootBundle);
  for (final archivo in manifiesto.listAssets()) {
    if (!archivo.startsWith(_carpeta) || !archivo.endsWith('.json')) continue;
    final codigo = archivo.substring(_carpeta.length).replaceAll('.json', '');
    idiomas[codigo] = (await _leer(codigo))['_nombre'] ?? codigo;
  }
  final guardado = await _storage.read(key: 'idioma');
  if (guardado != null && idiomas.containsKey(guardado)) {
    await cambiarIdioma(guardado);
  }
}

Future<void> cambiarIdioma(String codigo) async {
  _textos = codigo == 'es' ? {} : await _leer(codigo);
  idioma.value = Locale(codigo);
  await _storage.write(key: 'idioma', value: codigo);
}

Future<Map<String, String>> _leer(String codigo) async =>
    Map<String, String>.from(
      jsonDecode(await rootBundle.loadString('$_carpeta$codigo.json')),
    );

/// Fuera de una pantalla (validaciones, view models). Los datos van entre llaves: tr('Gastado: {monto}', {'monto': x}).
String tr(String texto, [Map<String, String> datos = const {}]) =>
    _traducir(texto, datos);

extension Traducir on BuildContext {
  /// En las pantallas: así se redibujan cuando cambia el idioma.
  String tr(String texto, [Map<String, String> datos = const {}]) {
    Localizations.localeOf(this);
    return _traducir(texto, datos);
  }
}

String _traducir(String texto, Map<String, String> datos) {
  var traducido = _textos[texto] ?? texto;
  datos.forEach(
    (clave, valor) => traducido = traducido.replaceAll('{$clave}', valor),
  );
  return traducido;
}
