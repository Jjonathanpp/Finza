import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';

// El botón cuadrado con ícono de la maqueta (volver, +, editar, borrar).
class BotonIcono extends StatelessWidget {
  const BotonIcono({
    super.key,
    required this.icono,
    required this.tamanio,
    required this.ayuda,
    required this.alTocar,
  });

  final IconData icono;
  final double tamanio;
  final String ayuda;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(tamanio / 3),
      side: const BorderSide(color: AppColors.line),
    );
    return Tooltip(
      message: ayuda,
      child: Material(
        color: AppColors.surface2,
        shape: forma,
        child: InkWell(
          customBorder: forma,
          onTap: alTocar,
          child: SizedBox(
            width: tamanio,
            height: tamanio,
            child: Icon(icono, size: tamanio / 2, color: AppColors.muted),
          ),
        ),
      ),
    );
  }
}
