import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/app_drawer.dart';
import 'package:frontend/features/panel/presentation/widgets/gastos_por_categoria.dart';

// El panel principal (EP-005). Por ahora tiene un solo bloque: las otras partes del panel
// (el resumen del mes, los últimos movimientos, el gráfico) se suman a esta lista con sus tareas.
class PanelScreen extends StatelessWidget {
  const PanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel')),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        children: const [GastosPorCategoria()],
      ),
    );
  }
}
