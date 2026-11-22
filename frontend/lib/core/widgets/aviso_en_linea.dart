import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';

// .aviso de la maqueta: un recuadro con una aclaración (13 px, en suave) y un ícono opcional. Con
// verde = true es .aviso.v (menta, texto verde y en semibold: para avisos buenos o de confirmación).
class AvisoEnLinea extends StatelessWidget {
  const AvisoEnLinea(this.texto, {super.key, this.icono, this.verde = false});

  final String texto;
  final IconData? icono;
  final bool verde;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final color = verde ? c.primario : c.suave;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: verde ? c.menta : c.hundido,
        borderRadius: BorderRadius.circular(Radios.aviso),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          if (icono != null) Icon(icono, size: 18, color: color),
          Expanded(
            child: Text(
              texto,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: verde ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
