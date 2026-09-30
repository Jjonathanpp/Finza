import 'package:flutter/material.dart';

// El backend guarda el color como texto ("#22C55E") y no lo valida: puede venir null o cualquier cosa.
const _gris = Color(0xFF94A3B8);

Color colorDesdeHex(String? hex) {
  if (hex == null || hex.length != 7 || !hex.startsWith('#')) return _gris;
  final valor = int.tryParse(hex.substring(1), radix: 16);
  return valor == null ? _gris : Color(0xFF000000 | valor);
}
