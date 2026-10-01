import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';

// Una etiqueta arriba, el campo, y abajo el error o una ayuda.
class Campo extends StatelessWidget {
  const Campo({super.key, required this.etiqueta, required this.child, this.error, this.ayuda});

  final String etiqueta;
  final Widget child;
  final String? error;
  final String? ayuda;

  @override
  Widget build(BuildContext context) {
    final abajo = error ?? ayuda;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted)),
          const SizedBox(height: 6),
          child,
          if (abajo != null)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                abajo,
                style: TextStyle(fontSize: 11.5, color: error != null ? AppColors.danger : AppColors.faint),
              ),
            ),
        ],
      ),
    );
  }
}
