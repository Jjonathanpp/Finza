import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/widgets/tocable.dart';

// .card de la maqueta: fondo tarjeta, radio 20 y sombra. Con destacada = true es .dest: fondo oscuro
// (destacado), radio 28, padding 16 y sin sombra; el texto y los íconos de adentro salen con el color de
// destacadoTexto. Si tiene alTocar se achica al apretarla (Tocable).
// Sin padding usa el de .pad (14 vertical, 16 horizontal); para una lista de filas, Tarjeta.paddingLista.
class Tarjeta extends StatelessWidget {
  const Tarjeta({
    super.key,
    required this.child,
    this.padding,
    this.alTocar,
    this.destacada = false,
    this.etiqueta,
  });

  static const paddingNormal = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 14,
  );
  static const paddingLista = EdgeInsets.symmetric(horizontal: 16); // .lista

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? alTocar;
  final bool destacada;

  // Lo que lee el lector de pantalla cuando la tarjeta es tocable (si es null, el texto de adentro).
  final String? etiqueta;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    Widget contenido = Padding(
      padding:
          padding ?? (destacada ? const EdgeInsets.all(16) : paddingNormal),
      child: child,
    );
    if (destacada) {
      contenido = DefaultTextStyle.merge(
        style: TextStyle(color: c.destacadoTexto),
        child: IconTheme.merge(
          data: IconThemeData(color: c.destacadoTexto),
          child: contenido,
        ),
      );
    }
    final tarjeta = DecoratedBox(
      decoration: BoxDecoration(
        color: destacada ? c.destacado : c.tarjeta,
        borderRadius: BorderRadius.circular(
          destacada ? Radios.destacada : Radios.tarjeta,
        ),
        boxShadow: destacada ? null : c.sombra,
      ),
      child: contenido,
    );
    return alTocar == null
        ? tarjeta
        : Tocable(alTocar: alTocar, etiqueta: etiqueta, child: tarjeta);
  }
}

// .card.lista: una tarjeta con filas una abajo de la otra, separadas por una línea (.lista>li+li).
class TarjetaLista extends StatelessWidget {
  const TarjetaLista({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Tarjeta(
      padding: Tarjeta.paddingLista,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(),
            children[i],
          ],
        ],
      ),
    );
  }
}
