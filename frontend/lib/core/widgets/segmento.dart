import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';

// .seg de la maqueta: un control segmentado (por ejemplo Gasto / Ingreso). Las opciones son pares
// (valor, texto) y todas miden lo mismo. La elegida es valor. deshabilitadas son opciones que se ven
// apagadas (opacidad .45) y no responden.
class Segmento<T> extends StatelessWidget {
  const Segmento({
    super.key,
    required this.opciones,
    required this.valor,
    required this.alCambiar,
    this.deshabilitadas = const {},
  });

  final List<(T, String)> opciones;
  final T valor;
  final ValueChanged<T> alCambiar;
  final Set<T> deshabilitadas;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final sinAnimacion = MediaQuery.disableAnimationsOf(context);
    final estilo = Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(fontSize: 14);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: c.hundido,
          borderRadius: BorderRadius.circular(Radios.segmento),
        ),
        child: Row(
          spacing: 4,
          children: [
            for (final (v, texto) in opciones)
              Expanded(
                child: _Opcion(
                  elegida: v == valor,
                  habilitada: !deshabilitadas.contains(v),
                  alTocar: () => alCambiar(v),
                  duracion: sinAnimacion ? Duration.zero : Duraciones.toque,
                  child: Text(
                    texto,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: estilo?.copyWith(
                      color: v == valor ? c.texto : c.suave,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Opcion extends StatelessWidget {
  const _Opcion({
    required this.elegida,
    required this.habilitada,
    required this.alTocar,
    required this.duracion,
    required this.child,
  });

  final bool elegida;
  final bool habilitada;
  final VoidCallback alTocar;
  final Duration duracion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Semantics(
      button: true,
      selected: elegida,
      enabled: habilitada,
      onTap: habilitada ? alTocar : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: habilitada ? alTocar : null,
        child: Opacity(
          opacity: habilitada ? 1 : .45,
          child: AnimatedContainer(
            duration: duracion,
            curve: Curvas.toque,
            height: 40,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: elegida ? c.tarjeta : Colors.transparent,
              borderRadius: BorderRadius.circular(Radios.botonSegmento),
              boxShadow: elegida ? c.sombra : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
