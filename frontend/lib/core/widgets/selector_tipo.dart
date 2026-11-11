import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';

// Gasto e Ingreso juntos (.seg de la maqueta). Lo usan el alta de movimientos y la de categorías.
// esIngreso en false es Gasto.
class SelectorTipo extends StatelessWidget {
  const SelectorTipo({super.key, required this.esIngreso, required this.alCambiar});

  final bool esIngreso;
  final ValueChanged<bool> alCambiar;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colores.hundido,
        borderRadius: BorderRadius.circular(Radios.segmento),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Row(
          children: [
            Expanded(
              child: _Segmento(
                texto: 'Gasto',
                activo: !esIngreso,
                alTocar: () => alCambiar(false),
              ),
            ),
            Expanded(
              child: _Segmento(
                texto: 'Ingreso',
                activo: esIngreso,
                alTocar: () => alCambiar(true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Un botón del .seg: 40 de alto y 12 de radio. El área para tocar incluye el borde del segmento (48 de alto).
class _Segmento extends StatelessWidget {
  const _Segmento({required this.texto, required this.activo, required this.alTocar});

  final String texto;
  final bool activo;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Semantics(
      button: true,
      selected: activo,
      excludeSemantics: true,
      label: texto,
      onTap: alTocar,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: alTocar,
        child: Padding(
          padding: const EdgeInsets.all(2).copyWith(top: 4, bottom: 4),
          child: AnimatedContainer(
            duration: Duraciones.toque,
            curve: Curvas.toque,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: activo ? colores.tarjeta : Colors.transparent,
              borderRadius: BorderRadius.circular(Radios.botonSegmento),
              boxShadow: activo ? colores.sombra : null,
            ),
            child: AnimatedDefaultTextStyle(
              duration: Duraciones.toque,
              curve: Curvas.toque,
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                fontSize: 14,
                color: activo ? colores.texto : colores.suave,
              ),
              child: Text(texto),
            ),
          ),
        ),
      ),
    );
  }
}
