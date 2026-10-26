import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';

class ContadorExpiracion extends StatelessWidget {
  final int segundosRestantes;

  const ContadorExpiracion({super.key, required this.segundosRestantes});

  bool get _expirado => segundosRestantes <= 0;

  String get _tiempoTexto {
    final m = (segundosRestantes ~/ 60).toString().padLeft(2, '0');
    final s = (segundosRestantes % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _expirado
          ? 'El código expiró. Pedí uno nuevo.'
          : 'El código expira en $_tiempoTexto',
      style: TextStyle(
        color: _expirado || segundosRestantes <= 60
            ? AppColors.danger
            : AppColors.muted,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
