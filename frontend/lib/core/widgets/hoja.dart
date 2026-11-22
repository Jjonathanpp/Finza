import 'package:flutter/material.dart';

// Abre una hoja inferior como .hoja de la maqueta. El tema ya pone el fondo, el radio y el agarre; acá van
// el padding (10 20 24), los 12 px entre elementos, el título (19/800), el texto (14, en suave), el
// contenido que se pase y que la hoja suba con el teclado. Si el contenido es largo, se desliza.
// Devuelve lo que se pase a Navigator.pop (null si se cierra tocando afuera o arrastrando).
Future<T?> mostrarHoja<T>(
  BuildContext context, {
  required String titulo,
  String? texto,
  Widget? contenido,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (contexto) {
      final textos = Theme.of(contexto).textTheme;
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(contexto).bottom,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                Semantics(
                  header: true,
                  child: Text(titulo, style: textos.titleLarge),
                ),
                if (texto != null)
                  Text(
                    texto,
                    style: textos.bodyMedium?.copyWith(
                      color: textos.bodySmall?.color,
                    ),
                  ),
                ?contenido,
              ],
            ),
          ),
        ),
      );
    },
  );
}
