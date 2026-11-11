import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/widgets/boton_peligro.dart';

export 'package:frontend/core/widgets/boton_peligro.dart';

// Un diálogo de confirmación como .dialogo de la maqueta: título, texto y dos botones iguales (.acciones),
// "Cancelar" y textoAccion. Con peligro = true la acción es coral (.btn.bpel), para borrar o salir.
// Devuelve true si se confirma y false si se cancela o se toca afuera.
Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String texto,
  required String textoAccion,
  bool peligro = false,
}) async {
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (contexto) {
      final textos = Theme.of(contexto).textTheme;
      return Dialog(
        child: Semantics(
          scopesRoute: true,
          namesRoute: true,
          explicitChildNodes: true,
          label: titulo,
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 14,
                children: [
                  Text(titulo, style: textos.titleLarge),
                  Text(
                    texto,
                    style: textos.bodyMedium?.copyWith(
                      color: contexto.colores.suave,
                    ),
                  ),
                  Row(
                    spacing: 8,
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(contexto).pop(false),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      Expanded(
                        child: FilledButton(
                          style: peligro ? estiloBotonPeligro(contexto) : null,
                          onPressed: () => Navigator.of(contexto).pop(true),
                          child: Text(textoAccion),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
  return confirmado ?? false;
}
