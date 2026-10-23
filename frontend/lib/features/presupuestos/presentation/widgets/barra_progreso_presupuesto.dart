import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';

class BarraProgresoPresupuesto extends StatelessWidget {
  const BarraProgresoPresupuesto({
    super.key,
    required this.porcentaje,
    this.altura = 8,
  });

  final double porcentaje;
  final double altura;

  Color _colorPorUmbral(double p) {
    if (p >= 100) return AppColors.danger;
    if (p >= 80) return Colors.amber;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final valor = (porcentaje / 100).clamp(0.0, 1.0);
    final color = _colorPorUmbral(porcentaje);

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: valor,
        backgroundColor: AppColors.surface3,
        valueColor: AlwaysStoppedAnimation(color),
        minHeight: altura,
      ),
    );
  }
}