import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/widgets/app_drawer.dart';
import 'package:frontend/features/movimientos/data/datasources/movimiento_api.dart';
import 'package:frontend/features/movimientos/data/models/movimiento.dart';
import 'package:frontend/features/movimientos/presentation/viewmodels/movimientos_view_model.dart';
import 'package:frontend/shared/utils/color_hex.dart';

class MovimientosScreen extends StatefulWidget {
  const MovimientosScreen({super.key});

  @override
  State<MovimientosScreen> createState() => _MovimientosScreenState();
}

class _MovimientosScreenState extends State<MovimientosScreen> {
  late final _vm = MovimientosViewModel(MovimientoApi(ApiClient()));
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _vm.cargarInicial();
    _scrollController.addListener(_alScrollear);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_alScrollear);
    _scrollController.dispose();
    _vm.dispose();
    super.dispose();
  }

  void _alScrollear() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _vm.cargarMas();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Movimientos')),
      drawer: const AppDrawer(),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          if (_vm.cargando && _vm.movimientos.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_vm.error != null && _vm.movimientos.isEmpty) {
            return _VistaError(mensaje: _vm.error!, alReintentar: _vm.cargarInicial);
          }

          if (_vm.movimientos.isEmpty) {
            return const Center(
              child: Text('No tenés movimientos registrados', style: TextStyle(color: AppColors.muted)),
            );
          }

          return RefreshIndicator(
            onRefresh: _vm.cargarInicial,
            color: AppColors.accent,
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.all(18),
              itemCount: _vm.movimientos.length + (_vm.hayMas ? 1 : 0),
              separatorBuilder: (_, __) => const Divider(color: AppColors.line, height: 24),
              itemBuilder: (context, i) {
                if (i == _vm.movimientos.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }
                return _FilaMovimiento(_vm.movimientos[i]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _FilaMovimiento extends StatelessWidget {
  const _FilaMovimiento(this.movimiento);
  final Movimiento movimiento;

  String _formatearMonto(double monto) {
    final partes = monto.toStringAsFixed(2).split('.');
    final entero = partes[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');
    return '\$ $entero,${partes[1]}';
  }

  String _formatearFecha(DateTime fecha) {
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colorCategoria = colorDesdeHex(movimiento.categoria.color);
    final colorMonto = movimiento.esIngreso ? AppColors.accent : AppColors.text;
    final signo = movimiento.esIngreso ? '+' : '-';

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colorCategoria.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            movimiento.categoria.emoji ?? movimiento.categoria.nombre.characters.first.toUpperCase(),
            style: TextStyle(fontSize: 20, color: colorCategoria, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                movimiento.categoria.nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text),
              ),
              const SizedBox(height: 2),
              Text(
                movimiento.descripcion?.isNotEmpty == true ? movimiento.descripcion! : _formatearFecha(movimiento.fecha),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: AppColors.faint),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$signo ${_formatearMonto(movimiento.monto)}',
          style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: colorMonto),
        ),
      ],
    );
  }
}

class _VistaError extends StatelessWidget {
  const _VistaError({required this.mensaje, required this.alReintentar});
  final String mensaje;
  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
          const SizedBox(height: 16),
          Text(mensaje, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: alReintentar,
            child: const Text('Reintentar'),
          )
        ],
      ),
    );
  }
}