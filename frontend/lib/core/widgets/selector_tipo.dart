import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';

// Ingreso y Egreso juntos, como en la maqueta. Lo usan el alta de movimientos y la de categorías.
class SelectorTipo extends StatelessWidget {
  const SelectorTipo({super.key, required this.esIngreso, required this.alCambiar});

  final bool esIngreso;
  final ValueChanged<bool> alCambiar;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment(value: true, label: Text('Ingreso')),
        ButtonSegment(value: false, label: Text('Egreso')),
      ],
      selected: {esIngreso},
      onSelectionChanged: (seleccion) => alCambiar(seleccion.first),
      showSelectedIcon: false,
      expandedInsets: EdgeInsets.zero,
      style: SegmentedButton.styleFrom(
        backgroundColor: AppColors.surface2,
        foregroundColor: AppColors.muted,
        selectedBackgroundColor: AppColors.surface,
        selectedForegroundColor: esIngreso ? AppColors.accent : AppColors.danger,
        side: const BorderSide(color: AppColors.line),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
