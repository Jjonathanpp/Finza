import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/l10n/idioma.dart';

class SelectorMiembros extends StatefulWidget {
  const SelectorMiembros({
    super.key,
    required this.opciones,
    required this.seleccionado,
    required this.alCambiar,
  });

  final List<Map<String, dynamic>?> opciones;
  final Map<String, dynamic>? seleccionado;
  final void Function(Map<String, dynamic>?) alCambiar;

  @override
  State<SelectorMiembros> createState() => _SelectorMiembrosState();
}

class _SelectorMiembrosState extends State<SelectorMiembros> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('Mostrar'),
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.colores.suave),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: Text(context.tr('Todos')),
              selected: widget.seleccionado == null,
              onSelected: (_) => widget.alCambiar(null),
            ),
            FilterChip(
              label: Text(context.tr('Solo míos')),
              selected: widget.seleccionado != null && widget.seleccionado!['esPropio'] == true,
              onSelected: (_) => widget.alCambiar({'esPropio': true}),
            ),
            for (final miembro in widget.opciones)
              FilterChip(
                label: Text(miembro?['nombre'] ?? '?'),
                selected: widget.seleccionado != null &&
                    widget.seleccionado!['esPropio'] != true &&
                    widget.seleccionado!['perfilId'] == miembro?['perfilId'],
                onSelected: (_) => widget.alCambiar(miembro),
              ),
          ],
        ),
      ],
    );
  }
}