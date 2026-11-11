import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';

// .av de la maqueta: un círculo con la inicial de una persona. Sin serie es el de "Vos" (menta con letra
// verde); con serie (0 a 4) usa el par serieFondo / serie de esa persona. Mide 36 por defecto; con
// AvatarInicial.yo es .yo: 44 px, el de la cabecera que abre el menú.
class AvatarInicial extends StatelessWidget {
  const AvatarInicial(this.inicial, {super.key, this.serie, this.tamano = 36});

  const AvatarInicial.yo(this.inicial, {super.key}) : serie = null, tamano = 44;

  final String inicial;
  final int? serie;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final fondo = serie == null
        ? c.menta
        : c.serieFondo[serie! % c.serieFondo.length];
    final color = serie == null ? c.primario : c.serie[serie! % c.serie.length];
    final tamanoTexto = tamano >= 60 ? 24.0 : (tamano >= 44 ? 17.0 : 14.0);
    return ExcludeSemantics(
      child: Container(
        width: tamano,
        height: tamano,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: fondo, shape: BoxShape.circle),
        child: Text(
          inicial.isEmpty ? '' : inicial.substring(0, 1).toUpperCase(),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontSize: tamanoTexto, color: color),
        ),
      ),
    );
  }
}
