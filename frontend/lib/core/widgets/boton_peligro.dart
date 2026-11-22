import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';

// .btn.bpel de la maqueta: el botón coral para acciones que borran o sacan algo. Se usa como style de un
// FilledButton: FilledButton(style: estiloBotonPeligro(context), ...). El tamaño y el texto los pone el tema.
ButtonStyle estiloBotonPeligro(BuildContext context) {
  final c = context.colores;
  return FilledButton.styleFrom(
    backgroundColor: c.coralFondo,
    foregroundColor: c.coralTexto,
    disabledBackgroundColor: c.coralFondo.withValues(alpha: .45),
    disabledForegroundColor: c.coralTexto,
  );
}
