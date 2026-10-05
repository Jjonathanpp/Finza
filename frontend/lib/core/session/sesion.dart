import 'dart:convert';

// ¿El token del login sirve todavía? Lee la fecha de vencimiento que trae adentro ("exp").
// La firma no se revisa: eso lo hace el backend, que es el que tiene la clave.
bool tokenVigente(String? token) {
  final partes = token?.split('.');
  if (partes == null || partes.length != 3) return false;
  try {
    final datos = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(partes[1]))));
    final exp = datos['exp'];
    return exp is int && DateTime.fromMillisecondsSinceEpoch(exp * 1000).isAfter(DateTime.now());
  } catch (_) {
    return false;
  }
}
