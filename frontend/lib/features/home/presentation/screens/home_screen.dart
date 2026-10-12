import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/app_drawer.dart';
import 'package:frontend/features/home/presentation/widgets/acciones_rapidas.dart';
import 'package:frontend/features/panel/presentation/widgets/gastos_por_categoria.dart';
import 'package:frontend/features/panel/presentation/widgets/tarjeta_saldo.dart';
import 'package:frontend/features/panel/presentation/widgets/grafico_balance_mes.dart';
import 'package:frontend/features/panel/presentation/widgets/ultimos_movimientos.dart';

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
          children: const [
            TarjetaSaldo(),
            SizedBox(height: 16),
            GraficoBalanceMes(),
            SizedBox(height: 16),
            
            AccionesRapidas(),
            SizedBox(height: 16),
            
            UltimosMovimientos(),
            SizedBox(height: 16),
            
            GastosPorCategoria(),
          ],
        ),
      ),
    );
  }
}
