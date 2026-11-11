import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/circulo_categoria.dart';
import 'package:frontend/core/widgets/tocable.dart';

// .fila de la maqueta con el círculo de la categoría (leading, por ejemplo CirculoCategoria.de; o, sin
// leading, uno de ícono con icono, color y fondo), título (.t1), subtítulo (.t2) y monto. No conoce
// los modelos: todo llega ya resuelto. monto es el texto formateado (Monto.texto) y colorMonto el color
// (Monto.color; si es null, el del texto). chip va al lado del subtítulo (el "Por revisar") y pie
// abajo del monto (el autor). Con alTocar la fila se achica al apretarla. Va dentro de una TarjetaLista,
// que pone las líneas entre filas.
class FilaMovimiento extends StatelessWidget {
  const FilaMovimiento({
    super.key,
    this.leading,
    this.icono,
    this.color,
    this.fondo,
    required this.titulo,
    required this.subtitulo,
    required this.monto,
    this.colorMonto,
    this.chip,
    this.pie,
    this.alTocar,
  }) : assert(leading != null || (icono != null && color != null && fondo != null));

  final Widget? leading; // si está, reemplaza al círculo de ícono
  final IconData? icono;
  final Color? color; // del ícono
  final Color? fondo; // del círculo
  final String titulo;
  final String subtitulo;
  final String monto;
  final Color? colorMonto;
  final Widget? chip;
  final Widget? pie;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final fila = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          leading ?? CirculoCategoria(icono: icono!, color: color!, fondo: fondo!),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textos.bodyMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  spacing: 6,
                  children: [
                    Flexible(
                      child: Text(
                        subtitulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textos.bodySmall,
                      ),
                    ),
                    ?chip,
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: 4,
            children: [
              Text(
                monto,
                maxLines: 1,
                softWrap: false,
                style: textos.labelLarge?.copyWith(color: colorMonto),
              ),
              ?pie,
            ],
          ),
        ],
      ),
    );
    return alTocar == null ? fila : Tocable(alTocar: alTocar, child: fila);
  }
}
