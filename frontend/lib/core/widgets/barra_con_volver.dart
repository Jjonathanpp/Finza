import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/widgets/boton_icono.dart';

// El encabezado de las pantallas empujadas (.cab): el botón redondo para volver y el título,
// con un subtítulo chico opcional abajo y, a la derecha, las acciones (por ejemplo un BotonIcono con el +).
AppBar barraConVolver(
  BuildContext context,
  String titulo, {
  String? subtitulo,
  List<Widget> acciones = const [],
}) {
  final textos = Theme.of(context).textTheme;
  return AppBar(
    automaticallyImplyLeading: false,
    titleSpacing: 20,
    title: Row(
      children: [
        BotonIcono(
          icono: Icons.arrow_back,
          ayuda: 'Volver',
          alTocar: () => Navigator.maybePop(context),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(titulo, maxLines: 1, overflow: TextOverflow.ellipsis, style: textos.titleSmall),
              if (subtitulo != null)
                Text(
                  subtitulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textos.bodySmall?.copyWith(color: context.colores.suave),
                ),
            ],
          ),
        ),
      ],
    ),
    actions: [if (acciones.isNotEmpty) ...[...acciones, const SizedBox(width: 20)]],
  );
}
