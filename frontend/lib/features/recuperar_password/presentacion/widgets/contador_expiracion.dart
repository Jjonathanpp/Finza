import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';

class ContadorExpiracion extends StatelessWidget {
  final int segundosRestantes;

  const ContadorExpiracion({super.key, required this.segundosRestantes});

  bool get _expirado => segundosRestantes <= 0;

  String get _tiempoTexto {
    final m = (segundosRestantes ~/ 60).toString();
    final s = (segundosRestantes % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final color = _expirado || segundosRestantes <= 60
        ? colores.coralTexto
        : colores.suave;
    return Row(
      spacing: 6,
      children: [
        ExcludeSemantics(
          child: Icon(Icons.schedule_outlined, size: 16, color: color),
        ),
        Flexible(
          child: Text(
            _expirado
                ? 'El código expiró. Pedí uno nuevo.'
                : 'Vence en $_tiempoTexto',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
