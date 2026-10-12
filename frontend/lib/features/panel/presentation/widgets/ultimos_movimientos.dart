import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/movimientos/data/models/movimiento.dart';
import 'package:frontend/features/panel/data/datasources/panel_api.dart';
import 'package:frontend/features/panel/data/models/resumen_mes.dart';
import 'package:frontend/shared/utils/color_hex.dart';
import 'package:frontend/shared/utils/pesos.dart';

class UltimosMovimientos extends StatefulWidget {
  const UltimosMovimientos({super.key, this.api});
  final PanelApi? api;

  @override
  State<UltimosMovimientos> createState() => _UltimosMovimientosState();
}

class _UltimosMovimientosState extends State<UltimosMovimientos> {
  late final _resumen = (widget.api ?? PanelApi(ApiClient())).resumen();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ResumenMes>(
      future: _resumen,
      builder: (context, respuesta) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 20, bottom: 9),
              child: Text('Últimos movimientos', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.line),
              ),
              child: _contenido(respuesta),
            ),
          ],
        );
      },
    );
  }

  Widget _contenido(AsyncSnapshot<ResumenMes> respuesta) {
    if (respuesta.connectionState != ConnectionState.done) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5)),
        ),
      );
    }
    final error = respuesta.error;
    if (error != null) {
      return _aviso(error is ApiException ? error.message : 'No se pudieron cargar los movimientos');
    }
    
    final movimientos = respuesta.data!.ultimosMovimientos;
    if (movimientos.isEmpty) return _aviso('Todavía no hay movimientos recientes.');
    
    return Column(
      children: movimientos.map((movimiento) => _FilaMovimiento(movimiento)).toList(),
    );
  }

  Widget _aviso(String texto) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(texto, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
      );
}

class _FilaMovimiento extends StatelessWidget {
  const _FilaMovimiento(this.movimiento);
  final Movimiento movimiento;

  String _formatearFecha(DateTime fecha) {
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colorCategoria = colorDesdeHex(movimiento.categoria.color);
    final colorMonto = movimiento.esIngreso ? AppColors.accent : AppColors.text;
    final signo = movimiento.esIngreso ? '+' : '-';
    final bool estaPendiente = movimiento.estado == 'PENDIENTE';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorCategoria.withValues(alpha: 0.15), 
              borderRadius: BorderRadius.circular(12)
            ),
            child: Text(
              movimiento.categoria.emoji ?? movimiento.categoria.nombre.characters.first.toUpperCase(),
              style: TextStyle(fontSize: 18, color: colorCategoria, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movimiento.categoria.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (estaPendiente) ...[
                      const Icon(Icons.error_outline, size: 12, color: Colors.orange),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        movimiento.descripcion?.isNotEmpty == true ? movimiento.descripcion! : _formatearFecha(movimiento.fecha),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: estaPendiente ? Colors.orange : AppColors.faint),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$signo ${pesos(movimiento.monto)}', 
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colorMonto, fontFeatures: const [FontFeature.tabularFigures()])
          ),
        ],
      ),
    );
  }
}