import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/core/session/portero.dart';
import 'package:url_launcher/url_launcher.dart';

// Aviso de versión nueva (t-1.8.5): al abrir la app, si en GitHub Releases hay una más nueva que la
// instalada, un cuadro para bajarla. La versión instalada la pasa el workflow "Publicar APK" al armar
// la APK (--dart-define=APP_VERSION, la siguiente a la última release); en la compu queda vacía y no
// se consulta nada.
const versionInstalada = String.fromEnvironment('APP_VERSION');

const _ultimaRelease = 'https://api.github.com/repos/Jjonathanpp/Finza/releases/latest';

// La última release, si tiene una APK: su versión sin la v (los tags viejos mezclan v y V) y el link.
Future<({String version, String apk})?> ultimaPublicada(Dio dio) async {
  final respuesta = await dio.get(_ultimaRelease);
  final release = respuesta.data as Map<String, dynamic>;
  final version = (release['tag_name'] as String? ?? '').replaceFirst(RegExp('^[vV]'), '');
  final apk = (release['assets'] as List<dynamic>? ?? [])
      .map((archivo) => (archivo as Map<String, dynamic>)['browser_download_url'] as String? ?? '')
      .where((link) => link.endsWith('.apk'))
      .firstOrNull;
  return version.isEmpty || apk == null ? null : (version: version, apk: apk);
}

// Si la versión a es mayor que la b, número por número (1.10.0 es mayor que 1.9.0). Si alguna tiene algo
// que no es un número, no se toma como más nueva: mejor no avisar que mandar a bajar algo raro.
bool esMasNueva(String a, String b) {
  final x = a.split('.').map(int.tryParse).toList();
  final y = b.split('.').map(int.tryParse).toList();
  if (x.contains(null) || y.contains(null)) return false;
  for (var i = 0; i < 3; i++) {
    final parteA = i < x.length ? x[i]! : 0;
    final parteB = i < y.length ? y[i]! : 0;
    if (parteA != parteB) return parteA > parteB;
  }
  return false;
}

// Desde app.dart, al primer cuadro. Sin internet o si GitHub no contesta, no muestra nada.
Future<void> avisarSiHayVersionNueva({
  String instalada = versionInstalada,
  Dio? dio,
  Future<bool> Function(Uri link) abrir = _abrirEnElNavegador,
}) async {
  if (instalada.isEmpty) return;
  final ({String version, String apk})? nueva;
  try {
    nueva = await ultimaPublicada(dio ??
        Dio(BaseOptions(connectTimeout: const Duration(seconds: 5), receiveTimeout: const Duration(seconds: 5))));
  } catch (_) {
    return;
  }
  final contexto = navegador.currentContext;
  if (nueva == null || !esMasNueva(nueva.version, instalada) || contexto == null || !contexto.mounted) return;
  final (:version, :apk) = nueva;

  final actualizar = await showDialog<bool>(
    context: contexto,
    builder: (contexto) => AlertDialog(
      title: const Text('Hay una versión nueva de Finza'),
      content: Text('Tenés la $instalada y ya salió la $version. Se instala encima, sin perder nada.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(contexto, false), child: const Text('Más tarde')),
        FilledButton(onPressed: () => Navigator.pop(contexto, true), child: const Text('Actualizar')),
      ],
    ),
  );
  if (actualizar == true) await abrir(Uri.parse(apk));
}

// Baja la APK con el navegador, como se instaló la primera vez: después se toca el archivo y Android la
// instala encima (con la misma firma, la clave de release).
Future<bool> _abrirEnElNavegador(Uri link) => launchUrl(link, mode: LaunchMode.externalApplication);
