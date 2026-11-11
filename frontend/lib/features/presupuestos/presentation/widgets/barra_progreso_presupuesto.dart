import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/widgets/barra_progreso.dart';
import 'package:frontend/core/widgets/chip_estado.dart';
import 'package:frontend/core/widgets/monto.dart';

// Cómo va un presupuesto según cuánto se usó. Los cortes de 80 % y 100 % son los de la alerta del backend:
// hasta 79,9 % está en regla (barra verde), desde 80 % está cerca del tope (ámbar), al 100 % llegó al
// tope y pasado el 100 % se excedió (coral). De acá salen el tono de la barra, el del chip y el color del
// texto, para que la lista, el resumen y el detalle digan lo mismo.
enum EstadoConsumo {
  enRegla,
  cerca,
  tope,
  excedido;

  static EstadoConsumo de(double porcentaje) {
    if (porcentaje.isNaN) return enRegla;
    if (porcentaje > 100) return excedido;
    if (porcentaje >= 100) return tope;
    if (porcentaje >= 80) return cerca;
    return enRegla;
  }

  TonoBarra get tonoBarra => switch (this) {
    enRegla => TonoBarra.barra,
    cerca => TonoBarra.ambar,
    tope || excedido => TonoBarra.coral,
  };

  TonoChip get tonoChip => switch (this) {
    enRegla => TonoChip.menta,
    cerca => TonoChip.ambar,
    tope || excedido => TonoChip.coral,
  };

  String get texto => switch (this) {
    enRegla => 'Vas bien',
    cerca => 'Cerca del tope',
    tope => 'Llegaste al tope',
    excedido => 'Excedido',
  };

  // El color del porcentaje y del "Quedan $ X".
  Color colorTexto(BuildContext context) {
    final c = context.colores;
    return switch (this) {
      enRegla => c.primario,
      cerca => c.ambarTexto,
      tope || excedido => c.coralTexto,
    };
  }

  // El mismo, para el texto secundario de la derecha: en regla va en suave.
  Color colorSecundario(BuildContext context) =>
      this == enRegla ? context.colores.suave : colorTexto(context);
}

// Sin decimales si es entero (50 %), con uno si no (79,6 % no es lo mismo que 80 %).
String textoPorcentaje(double porcentaje) {
  final p = porcentaje.isNaN ? 0.0 : porcentaje;
  final texto = p == p.roundToDouble() ? p.toStringAsFixed(0) : p.toStringAsFixed(1);
  return '${texto.replaceAll('.', ',')}%';
}

// Lo que falta (o sobra) del tope: "Quedan $ 8.000", "Llegaste al tope" o "Te pasaste $ 2.000".
String textoRestante(double gastado, double tope) {
  final diferencia = tope - gastado;
  if (diferencia.abs() < 0.005) return 'Llegaste al tope';
  if (diferencia < 0) return 'Te pasaste ${Monto.texto(-diferencia)}';
  return 'Quedan ${Monto.texto(diferencia)}';
}
