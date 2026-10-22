import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/features/presupuestos/presentation/screens/alta_presupuestos_screen.dart'; // Nombre con "s" como lo guardaste
import 'package:frontend/features/presupuestos/presentation/viewmodels/presupuestos_view_model.dart';
import 'package:frontend/shared/utils/color_hex.dart';
import 'package:provider/provider.dart';

class PresupuestosScreen extends StatefulWidget {
  const PresupuestosScreen({super.key});

  @override
  State<PresupuestosScreen> createState() => _PresupuestosScreenState();
}

class _PresupuestosScreenState extends State<PresupuestosScreen> {
  final List<String> _meses = [
    '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PresupuestosViewModel>().cargarPresupuestos();
    });
  }

  String _formatoMonto(double monto) {
    return monto.toStringAsFixed(2);
  }

  void _cambiarMes(PresupuestosViewModel vm, int delta) {
    int m = vm.mesActual + delta;
    int a = vm.anioActual;
    if (m < 1) {
      m = 12;
      a--;
    } else if (m > 12) {
      m = 1;
      a++;
    }
    vm.cargarPresupuestos(mes: m, anio: a);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Presupuestos'),
        elevation: 0,
      ),
      body: Consumer<PresupuestosViewModel>(
        builder: (context, vm, child) {
          return Column(
            children: [
              // 1. Selector de Mes y Año
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 28),
                      onPressed: () => _cambiarMes(vm, -1),
                    ),
                    Text(
                      '${_meses[vm.mesActual]} ${vm.anioActual}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 28),
                      onPressed: () => _cambiarMes(vm, 1),
                    ),
                  ],
                ),
              ),

              // 2. Botón Grande "Agregar presupuesto"
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_circle_outline, size: 22),
                    label: const Text('Agregar presupuesto', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      final creado = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AltaPresupuestoScreen()),
                      );
                      // Si se creó uno, recargamos la vista del mes actual
                      if (creado == true && mounted) {
                        vm.cargarPresupuestos();
                      }
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 12),

              // 3. Lista de presupuestos (o estado de carga/vacio)
              Expanded(
                child: _construirContenido(vm),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _construirContenido(PresupuestosViewModel vm) {
    if (vm.cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(vm.error!, style: const TextStyle(color: AppColors.danger)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => vm.cargarPresupuestos(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (vm.presupuestos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pie_chart_outline, size: 64, color: AppColors.faint),
            const SizedBox(height: 16),
            Text(
              'No hay presupuestos en ${_meses[vm.mesActual]}',
              style: const TextStyle(color: AppColors.muted, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      itemCount: vm.presupuestos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final p = vm.presupuestos[index];
        final colorCat = colorDesdeHex(p.categoriaColor);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(color: colorCat, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(p.categoriaNombre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    ],
                  ),
                  Text(
                    '${p.porcentajeConsumo.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: p.alertaAlcanzada ? AppColors.danger : AppColors.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (p.porcentajeConsumo / 100).clamp(0.0, 1.0),
                  backgroundColor: AppColors.surface3,
                  valueColor: AlwaysStoppedAnimation(p.alertaAlcanzada ? AppColors.danger : colorCat),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Gastado: \$${_formatoMonto(p.montoGastado)}', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                  Text('Tope: \$${_formatoMonto(p.montoTope)}', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}