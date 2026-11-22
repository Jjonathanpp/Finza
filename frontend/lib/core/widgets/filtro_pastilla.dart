import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/widgets/tocable.dart';

// .fb de la maqueta: un filtro en forma de pastilla de 40 px (el área táctil llega a 44). activo es .on
// (fondo del color del texto); ambar pinta el filtro de ámbar mientras no esté activo (.fa, por ejemplo
// "Por revisar"). Se arma una fila con FilaFiltros.
class FiltroPastilla extends StatelessWidget {
  const FiltroPastilla({
    super.key,
    required this.texto,
    required this.activo,
    required this.alTocar,
    this.ambar = false,
  });

  final String texto;
  final bool activo;
  final VoidCallback alTocar;
  final bool ambar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final (fondo, color) = activo
        ? (c.texto, c.fondo)
        : ambar
        ? (c.ambarFondo, c.ambarTexto)
        : (c.hundido, c.texto);
    final sinAnimacion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      selected: activo,
      child: Tocable(
        alTocar: alTocar,
        child: SizedBox(
          height: 44,
          child: Center(
            child: AnimatedContainer(
              duration: sinAnimacion ? Duration.zero : Duraciones.toque,
              curve: Curvas.toque,
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: fondo,
                borderRadius: BorderRadius.circular(Radios.pastilla),
              ),
              child: Text(
                texto,
                maxLines: 1,
                softWrap: false,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontSize: 14, color: color),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// .filtros de la maqueta: los FiltroPastilla en una fila que se desliza para el costado, con 8 px entre
// uno y otro. etiqueta es lo que lee el lector de pantalla para el grupo ("Qué ver").
class FilaFiltros extends StatelessWidget {
  const FilaFiltros({super.key, required this.children, this.etiqueta});

  final List<Widget> children;
  final String? etiqueta;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: etiqueta,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(spacing: 8, children: children),
      ),
    );
  }
}
