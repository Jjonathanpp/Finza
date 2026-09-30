import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/features/categorias/presentation/screens/categorias_screen.dart';

// Solo para ver la pantalla de categorías sin tocar app.dart:
// flutter run -d linux -t lib/main_categorias.dart
void main() => runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: temaFinza(),
        home: const CategoriasScreen(),
      ),
    );
