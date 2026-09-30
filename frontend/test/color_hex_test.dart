import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/shared/utils/color_hex.dart';

void main() {
  test('convierte el color que manda el backend y usa gris si no sirve', () {
    expect(colorDesdeHex('#22C55E'), const Color(0xFF22C55E));
    expect(colorDesdeHex(null), const Color(0xFF94A3B8));
    expect(colorDesdeHex('rojo'), const Color(0xFF94A3B8));
    expect(colorDesdeHex('#XYZXYZ'), const Color(0xFF94A3B8));
  });
}
