import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';

// Una etiqueta arriba (.campo > span), el campo, y abajo el error o una ayuda.
class Campo extends StatelessWidget {
  const Campo({super.key, required this.etiqueta, required this.child, this.error, this.ayuda});

  final String etiqueta;
  final Widget child;
  final String? error;
  final String? ayuda;

  @override
  Widget build(BuildContext context) {
    final abajo = error ?? ayuda;
    final colores = context.colores;
    final chico = Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta, style: chico?.copyWith(fontWeight: FontWeight.w600, color: colores.suave)),
          const SizedBox(height: 6),
          child,
          if (abajo != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                abajo,
                style: error != null
                    ? chico?.copyWith(fontWeight: FontWeight.w600, color: colores.coralTexto)
                    : chico?.copyWith(color: colores.suave),
              ),
            ),
        ],
      ),
    );
  }
}
