import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';

// Los colores de .chip: ch-m (menta), ch-a (ámbar), ch-c (coral) y ch-h (hundido, neutro).
enum TonoChip { menta, ambar, coral, hundido }

// .chip de la maqueta: una pastilla de 30 px de alto con un texto corto ("Pendiente", "Admin"). Con
// chico = true es .chip.s (22 px, para ir dentro de una fila). Es solo informativo, no se toca.
class ChipEstado extends StatelessWidget {
  const ChipEstado(
    this.texto,
    this.tono, {
    super.key,
    this.chico = false,
    this.icono,
  });

  final String texto;
  final TonoChip tono;
  final bool chico;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final (fondo, color) = switch (tono) {
      TonoChip.menta => (c.menta, c.primario),
      TonoChip.ambar => (c.ambarFondo, c.ambarTexto),
      TonoChip.coral => (c.coralFondo, c.coralTexto),
      TonoChip.hundido => (c.hundido, c.texto),
    };
    final estilo = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: color,
      fontSize: chico ? 11.5 : 13,
    );
    // Con un texto largo (por ejemplo "De {cuenta}") se corta con puntos suspensivos en una línea. Si la
    // fila donde está no le acota el ancho (un Row común), no pasa de la mitad de la pantalla.
    final tope = MediaQuery.sizeOf(context).width / 2;
    return LayoutBuilder(
      builder: (context, restriccion) => Container(
        constraints: BoxConstraints(
          minHeight: chico ? 22 : 30,
          maxWidth: restriccion.hasBoundedWidth ? double.infinity : tope,
        ),
        padding: EdgeInsets.symmetric(horizontal: chico ? 8 : 12),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(Radios.pastilla),
        ),
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [
              if (icono != null) Icon(icono, size: chico ? 14 : 16, color: color),
              Flexible(
                child: Text(
                  texto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: estilo,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
