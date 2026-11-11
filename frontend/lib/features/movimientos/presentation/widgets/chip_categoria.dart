import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/widgets/circulo_categoria.dart';
import 'package:frontend/core/widgets/tocable.dart';
import 'package:frontend/features/categorias/data/models/categoria.dart';

// .cchip de la maqueta: una pastilla de 40 de alto con el círculo de la categoría adelante (30) y el nombre.
// La elegida (.on) va en menta, con el borde de 2 px en verde. El círculo lleva el emoji de la
// categoría o, si no tiene, su inicial.
class ChipCategoria extends StatelessWidget {
  const ChipCategoria({super.key, required this.categoria, required this.elegida, required this.alTocar});

  final Categoria categoria;
  final bool elegida;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    return _Pastilla(
      elegida: elegida,
      alTocar: alTocar,
      etiqueta: categoria.nombre,
      adelante: CirculoCategoria.de(categoria, tamano: 30),
      texto: categoria.nombre,
    );
  }
}

// El "+ Nueva" del final: la misma pastilla, sin círculo y con un más.
class ChipNuevaCategoria extends StatelessWidget {
  const ChipNuevaCategoria({super.key, required this.alTocar});

  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    return _Pastilla(
      elegida: false,
      alTocar: alTocar,
      etiqueta: 'Nueva categoría',
      adelante: const Padding(
        padding: EdgeInsets.only(left: 9),
        child: Icon(Icons.add, size: 16),
      ),
      texto: 'Nueva',
    );
  }
}

class _Pastilla extends StatelessWidget {
  const _Pastilla({
    required this.elegida,
    required this.alTocar,
    required this.etiqueta,
    required this.adelante,
    required this.texto,
  });

  final bool elegida;
  final VoidCallback alTocar;
  final String etiqueta;
  final Widget adelante;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final color = elegida ? colores.primario : colores.texto;
    return Semantics(
      selected: elegida,
      child: Tocable(
        alTocar: alTocar,
        etiqueta: etiqueta,
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : Duraciones.toque,
          curve: Curvas.toque,
          height: 40,
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width - 40),
          padding: const EdgeInsets.only(left: 3, right: 14),
          decoration: BoxDecoration(
            color: elegida ? colores.menta : colores.hundido,
            borderRadius: BorderRadius.circular(Radios.pastilla),
            border: Border.all(color: elegida ? colores.primario : Colors.transparent, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              adelante,
              Flexible(
                child: Text(
                  texto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 14, color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
