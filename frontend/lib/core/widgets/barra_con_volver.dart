import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/boton_icono.dart';

// La barra de arriba de las pantallas de alta: el botón cuadrado para volver y el título.
AppBar barraConVolver(BuildContext context, String titulo) {
  return AppBar(
    automaticallyImplyLeading: false,
    titleSpacing: 18,
    title: Row(
      children: [
        BotonIcono(
          icono: Icons.arrow_back,
          tamanio: 34,
          ayuda: 'Volver',
          alTocar: () => Navigator.maybePop(context),
        ),
        const SizedBox(width: 12),
        Text(titulo),
      ],
    ),
  );
}
