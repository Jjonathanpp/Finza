import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';

// El botón redondo con ícono de la maqueta (.bi): volver, +, editar, borrar.
// Por defecto es el de tarjeta (.bi.t); con principal es el verde (.bi.p).
// El área para tocar nunca baja de 44 px, aunque el círculo se pida más chico.
class BotonIcono extends StatelessWidget {
  const BotonIcono({
    super.key,
    required this.icono,
    this.tamanio = 44,
    required this.ayuda,
    required this.alTocar,
    this.principal = false,
  });

  final IconData icono;
  final double tamanio;
  final String ayuda;
  final VoidCallback alTocar;
  final bool principal;

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final fondo = principal ? colores.primario : colores.tarjeta;
    final tinta = principal ? colores.sobrePrimario : colores.texto;
    const forma = CircleBorder();
    final area = math.max(tamanio, 44.0);

    return Tooltip(
      message: ayuda,
      child: SizedBox(
        width: area,
        height: area,
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: fondo,
              shape: BoxShape.circle,
              boxShadow: principal ? null : colores.sombra,
            ),
            child: Material(
              type: MaterialType.transparency,
              shape: forma,
              child: InkWell(
                customBorder: forma,
                onTap: alTocar,
                child: SizedBox(
                  width: tamanio,
                  height: tamanio,
                  child: Icon(icono, size: tamanio * 0.48, color: tinta),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
