import 'package:flutter/material.dart';

// Colores de la maqueta interna de Finza (tema claro).
// Cada uno es una variable del CSS de la maqueta: --bg, --surface, --line, etc.
abstract final class AppColors {
  static const bg = Color(0xFFEEF1F5);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFF4F7FA);
  static const surface3 = Color(0xFFE9EEF3);
  static const line = Color(0xFFDCE3EA);
  static const text = Color(0xFF121B24);
  static const muted = Color(0xFF5C6E7E);
  static const faint = Color(0xFF8697A6);
  static const accent = Color(0xFF0FA97F);
  static const accentInk = Color(0xFFFFFFFF);
  static const blue = Color(0xFF4361EE);
  static const danger = Color(0xFFDC3545);
}

ThemeData temaFinza() {
  return ThemeData(
    colorScheme: const ColorScheme.light(
      primary: AppColors.accent,
      onPrimary: AppColors.accentInk,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      error: AppColors.danger,
      inverseSurface: AppColors.surface3,
      onInverseSurface: AppColors.text,
    ),
    scaffoldBackgroundColor: AppColors.bg,
    inputDecorationTheme: const InputDecorationThemeData(
      filled: true,
      fillColor: AppColors.surface2,
      contentPadding: EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      hintStyle: TextStyle(color: AppColors.faint),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.accent),
      ),
    ),
    // El botón principal de los formularios ("Registrar movimiento", "Crear categoría").
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
      ),
    ),
    tooltipTheme: const TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.all(Radius.circular(8)),
        border: Border.fromBorderSide(BorderSide(color: AppColors.line)),
      ),
      textStyle: TextStyle(color: AppColors.text, fontSize: 12),
    ),
    appBarTheme: const AppBarThemeData(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.text),
      actionsPadding: EdgeInsets.only(right: 18),
    ),
  );
}
