import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/app_drawer.dart';
import 'package:frontend/features/home/presentation/widgets/acciones_rapidas.dart';
import 'package:frontend/features/panel/presentation/widgets/gastos_por_categoria.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Finza')),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              height: 240,
              alignment: Alignment.center,
              child: const Text('Gráfico (próximamente)'),
            ),
            const SizedBox(height: 16),

            const AccionesRapidas(),

            const SizedBox(height: 16),
            // Espacio para la lista de últimos movimientos
            Container(
              height: 240,
              alignment: Alignment.center,
              child: const Text('Últimos movimientos (próximamente)'),
            ),

            const GastosPorCategoria(),
          ],
        ),
      ),
    );
  }
}
