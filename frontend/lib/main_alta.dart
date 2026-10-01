import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/features/movimientos/presentation/screens/alta_movimiento_screen.dart';

// Solo para ver el alta de movimientos sin tocar app.dart:
// flutter run -d linux -t lib/main_alta.dart
void main() => runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: temaFinza(),
        home: const AltaMovimientoScreen(),
      ),
    );
