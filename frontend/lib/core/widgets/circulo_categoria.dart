import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/features/categorias/data/models/categoria.dart';
import 'package:frontend/shared/utils/color_hex.dart';

// .cat de la maqueta: un círculo de 40 px con un ícono de 20 adentro. color es el del ícono y fondo el
// del círculo (por ejemplo serie[i] y serieFondo[i], o primario y menta, o coralTexto y coralFondo).
// Con CirculoCategoria.texto lleva un texto (un emoji o una inicial) en lugar del ícono, y con
// CirculoCategoria.de se arma el de una categoría. Es decorativo: el lector de pantalla no lo lee.
class CirculoCategoria extends StatelessWidget {
  const CirculoCategoria({
    super.key,
    required IconData this.icono,
    required this.color,
    required this.fondo,
    this.tamano = 40,
    this.tamanoIcono,
  }) : texto = null,
       esEmoji = false;

  // El círculo con un texto adentro. color es el de las letras (un emoji lo ignora, porque se dibuja con
  // sus colores); si no se lee bien sobre el fondo, en claro o en oscuro, se usa el color del texto del tema.
  const CirculoCategoria.texto({
    super.key,
    required String this.texto,
    required this.color,
    required this.fondo,
    this.tamano = 40,
    this.esEmoji = false,
  }) : icono = null,
       tamanoIcono = null;

  // El de una categoría: su emoji si es una predefinida que lo tiene; si no, la inicial del nombre. El
  // círculo va con el color que se guardó para la categoría, suave.
  factory CirculoCategoria.de(Categoria categoria, {double tamano = 40}) {
    final color = colorDesdeHex(categoria.color);
    // characters, no [0]: un emoji ocupa dos lugares del texto, y medio emoji no se puede dibujar.
    final nombre = categoria.nombre;
    final emoji = categoria.emoji;
    return CirculoCategoria.texto(
      texto: emoji ?? (nombre.isEmpty ? '?' : nombre.characters.first.toUpperCase()),
      esEmoji: emoji != null,
      color: color,
      fondo: color.withValues(alpha: .16),
      tamano: tamano,
    );
  }

  final IconData? icono;
  final String? texto;
  final bool esEmoji;
  final Color color;
  final Color fondo;
  final double tamano;

  // Si no se pasa, la mitad del círculo (20 para 40).
  final double? tamanoIcono;

  // El color de las letras: el de la categoría si contrasta (3:1, que alcanza para letra grande y en
  // negrita) con el fondo, y si no el del texto del tema.
  Color _colorLetra(BuildContext context) {
    final c = context.colores;
    final base = Color.alphaBlend(fondo, c.tarjeta);
    final claro = color.computeLuminance();
    final fondoLuz = base.computeLuminance();
    final contraste = (claro > fondoLuz ? claro + .05 : fondoLuz + .05) / (claro > fondoLuz ? fondoLuz + .05 : claro + .05);
    return contraste >= 3 ? color : c.texto;
  }

  @override
  Widget build(BuildContext context) {
    final letras = texto;
    final Widget contenido;
    if (letras == null) {
      contenido = Icon(icono, size: tamanoIcono ?? tamano / 2, color: color);
    } else {
      contenido = Text(
        letras,
        maxLines: 1,
        textScaler: TextScaler.noScaling,
        style: TextStyle(
          fontSize: tamano * (esEmoji ? .45 : .4),
          fontWeight: FontWeight.w800,
          height: 1,
          color: esEmoji ? null : _colorLetra(context),
        ),
      );
    }
    return ExcludeSemantics(
      child: Container(
        width: tamano,
        height: tamano,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: fondo, shape: BoxShape.circle),
        child: contenido,
      ),
    );
  }
}
