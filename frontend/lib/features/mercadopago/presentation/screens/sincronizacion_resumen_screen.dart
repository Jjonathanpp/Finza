import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/widgets/barra_con_volver.dart';
import 'package:frontend/features/mercadopago/data/models/sincronizacion_resumen.dart';

class SincronizacionResumenScreen extends StatelessWidget {
  final SincronizacionResumen resumen;

  const SincronizacionResumenScreen({
    super.key,
    required this.resumen,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: barraConVolver(context, 'Resumen de importación'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.check_circle_outline, color: AppColors.accent, size: 30),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Sincronización completada',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Los nuevos movimientos quedaron registrados como pendientes para tu revisión.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _itemMetrica(
            titulo: 'Procesadas',
            subtitulo: 'Total consultado en Mercado Pago',
            valor: resumen.procesadas.toString(),
            color: AppColors.blue,
          ),
          const SizedBox(height: 10),
          _itemMetrica(
            titulo: 'Nuevas creadas',
            subtitulo: 'Movimientos listos para revisar',
            valor: resumen.creadas.toString(),
            color: AppColors.accent,
          ),
          const SizedBox(height: 10),
          _itemMetrica(
            titulo: 'Omitidas',
            subtitulo: 'Transacciones ya existentes',
            valor: resumen.omitidas.toString(),
            color: AppColors.muted,
          ),
          if (resumen.errores > 0) ...[
            const SizedBox(height: 10),
            _itemMetrica(
              titulo: 'Errores',
              subtitulo: 'No se pudieron procesar',
              valor: resumen.errores.toString(),
              color: AppColors.danger,
            ),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.accentInk,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Entendido', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemMetrica({
    required String titulo,
    required String subtitulo,
    required String valor,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text(subtitulo, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
              ],
            ),
          ),
          Text(
            valor,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}