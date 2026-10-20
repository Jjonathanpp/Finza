import 'package:flutter/material.dart';
import 'package:frontend/features/presupuestos/presentation/viewmodels/presupuestos_view_model.dart';
import 'package:provider/provider.dart';
import 'package:frontend/shared/utils/importe.dart';

class PresupuestosScreen extends StatefulWidget {
  const PresupuestosScreen({super.key});

  @override
  State<PresupuestosScreen> createState() => _PresupuestosScreenState();
}

class _PresupuestosScreenState extends State<PresupuestosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PresupuestosViewModel>().cargarPresupuestos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PresupuestosViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Presupuestos por Categoría'),
      ),
      body: viewModel.cargando
          ? const Center(child: CircularProgressIndicator())
          : viewModel.error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      viewModel.error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : viewModel.presupuestos.isEmpty
                  ? const Center(
                      child: Text('No hay presupuestos para este mes.'),
                    )
                  : ListView.builder(
                      itemCount: viewModel.presupuestos.length,
                      itemBuilder: (context, index) {
                        final item = viewModel.presupuestos[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item.categoriaNombre,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (item.alertaAlcanzada)
                                      const Icon(
                                        Icons.warning,
                                        color: Colors.orange,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: (item.porcentajeConsumo / 100.0) > 1.0
                                      ? 1.0
                                      : (item.porcentajeConsumo / 100.0),
                                  backgroundColor: Colors.grey[200],
                                  color: item.alertaAlcanzada
                                      ? Colors.orange
                                      : Colors.blue,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Gastado: ${importe(item.montoGastado, centavos: true)}',
                                    ),
                                    Text(
                                      'Máximo: ${importe(item.montoTope, centavos: true)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}