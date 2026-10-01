import 'package:flutter/services.dart';

// Escribe el monto como se escribe en Argentina mientras el usuario tipea:
// 130000 → 130.000, con coma para los centavos (130.000,50).
// Los puntos los pone la app; el usuario nunca los escribe.
class MontoArgentinoFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue anterior, TextEditingValue nuevo) {
    var texto = nuevo.text;
    // Si toca el punto al final, quiso empezar los centavos (hay teclados que no tienen coma).
    if (texto.endsWith('.') && texto.length > anterior.text.length) {
      texto = '${texto.substring(0, texto.length - 1)},';
    }
    texto = texto.replaceAll('.', '').replaceAll(RegExp(r'[^0-9,]'), '');

    final partes = texto.split(',');
    if (partes.length > 2) return anterior; // una sola coma
    var entero = partes[0].replaceFirst(RegExp(r'^0+(?=\d)'), ''); // sin ceros adelante
    final centavos = partes.length == 2 ? partes[1] : null;
    if (centavos != null && centavos.length > 2) return anterior; // 2 decimales como máximo
    if (entero.isEmpty && centavos != null) entero = '0';

    final conPuntos = entero.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
    final resultado = centavos == null ? conPuntos : '$conPuntos,$centavos';
    // Simplificación: el cursor siempre queda al final; si se edita en el medio del número, salta al final.
    return TextEditingValue(text: resultado, selection: TextSelection.collapsed(offset: resultado.length));
  }
}
