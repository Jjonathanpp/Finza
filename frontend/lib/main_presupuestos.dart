import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/presupuestos/data/datasources/presupuesto_api.dart';
import 'package:frontend/features/presupuestos/presentation/screens/presupuestos_screen.dart';
import 'package:frontend/features/presupuestos/presentation/viewmodels/presupuestos_view_model.dart';
import 'package:provider/provider.dart';

void main() {
  final apiClient = ApiClient();
  final presupuestoApi = PresupuestoApi(apiClient);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => PresupuestosViewModel(presupuestoApi),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: temaFinza(),
        home: const PresupuestosScreen(),
      ),
    ),
  );
}