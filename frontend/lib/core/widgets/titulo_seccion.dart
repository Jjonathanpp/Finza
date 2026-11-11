import 'package:flutter/material.dart';

// Título de una sección. Chico (.h2: 13/700 en suave, con margen 8 arriba y 4 a los costados) o grande
// (.sec: 18/800 con el link opcional a la derecha, .link). El link mide 44 px de alto como mínimo.
class TituloSeccion extends StatelessWidget {
  const TituloSeccion(
    this.texto, {
    super.key,
    this.grande = false,
    this.link,
    this.alLink,
  });

  final String texto;
  final bool grande;

  // Texto del link de la derecha ("Ver todos"). Solo se muestra en el título grande, y con alLink.
  final String? link;
  final VoidCallback? alLink;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    if (!grande) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
        child: Semantics(
          header: true,
          child: Text(
            texto,
            style: textos.labelMedium?.copyWith(color: textos.bodySmall?.color),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(texto, style: textos.titleMedium),
            ),
          ),
          if (link != null && alLink != null)
            TextButton(
              onPressed: alLink,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(44, 44),
              ),
              child: Text(link!),
            ),
        ],
      ),
    );
  }
}
