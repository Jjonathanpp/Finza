import 'dart:convert';

// Arma un token de mentira con lo que se quiera adentro. La firma da igual: la app no la revisa.
String tokenCon(Map<String, dynamic> datos) {
  String parte(Map<String, dynamic> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  return '${parte({'alg': 'HS256'})}.${parte(datos)}.firma';
}

String tokenQueVence(DateTime cuando) =>
    tokenCon({'sub': '29', 'type': 'access', 'exp': cuando.millisecondsSinceEpoch ~/ 1000});

String tokenVigenteDePrueba() => tokenQueVence(DateTime.now().add(const Duration(minutes: 30)));

String tokenVencidoDePrueba() => tokenQueVence(DateTime.now().subtract(const Duration(minutes: 1)));
