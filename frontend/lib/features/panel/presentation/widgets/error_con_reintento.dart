import 'package:flutter/material.dart';

// Cuando falla la carga de un bloque del Inicio: el mensaje corto y el botón para volver a pedirlo.
class ErrorConReintento extends StatelessWidget {
  const ErrorConReintento({super.key, required this.mensaje, required this.alReintentar});

  final String mensaje;
  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      children: [
        Expanded(child: Text(mensaje, style: Theme.of(context).textTheme.bodySmall)),
        TextButton(onPressed: alReintentar, child: const Text('Reintentar')),
      ],
    );
  }
}
