import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/panel/data/datasources/panel_api.dart';
import 'package:frontend/features/panel/data/models/resumen_mes.dart';
import 'package:frontend/shared/utils/pesos.dart';

class GraficoBalanceMes extends StatefulWidget {
  const GraficoBalanceMes({super.key, this.api, this.startDate, this.endDate});

  final PanelApi? api;
  final DateTime? startDate;
  final DateTime? endDate;

  @override
  State<GraficoBalanceMes> createState() => _GraficoBalanceMesState();
}

class _GraficoBalanceMesState extends State<GraficoBalanceMes> {
  late final _resumen = (widget.api ?? PanelApi(ApiClient())).resumen(
    startDate: widget.startDate,
    endDate: widget.endDate,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ingresos y egresos del mes',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          FutureBuilder<ResumenMes>(
            future: _resumen,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const SizedBox(
                  height: 60,
                  child: Center(
                    child: SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }

              final data = snapshot.data;
              final ingresos = (data?.totalIngresos ?? 0.0).abs();
              final egresos = (data?.totalEgresos ?? 0.0).abs();
              final mayor = ingresos > egresos ? ingresos : egresos;

              final factorIngresos = mayor > 0 ? (ingresos / mayor) : 0.0;
              final factorEgresos = mayor > 0 ? (egresos / mayor) : 0.0;

              return Column(
                children: [
                  _FilaBarra(
                    etiqueta: 'Ingresos',
                    monto: data?.totalIngresos ?? 0.0,
                    factor: factorIngresos,
                    colorBarra: AppColors.accent,
                  ),
                  const SizedBox(height: 12),
                  _FilaBarra(
                    etiqueta: 'Egresos',
                    monto: data?.totalEgresos ?? 0.0,
                    factor: factorEgresos,
                    colorBarra: const Color(0xFF7C9CFF),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FilaBarra extends StatelessWidget {
  const _FilaBarra({
    required this.etiqueta,
    required this.monto,
    required this.factor,
    required this.colorBarra,
  });

  final String etiqueta;
  final double monto;
  final double factor;
  final Color colorBarra;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 65,
          child: Text(
            etiqueta,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.surface3,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: factor.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: colorBarra,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          pesos(monto),
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}