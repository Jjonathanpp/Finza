import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/informes/data/datasources/informe_api.dart';
import 'package:frontend/features/informes/data/models/comparacion_periodos.dart';
import 'package:frontend/shared/utils/importe.dart';

class GraficoBarrasComparacion extends StatefulWidget {
  const GraficoBarrasComparacion({
    super.key,
    this.api,
    this.startDate,
    this.endDate,
    this.granularidad = 'MES',
  });

  final InformeApi? api;
  final DateTime? startDate;
  final DateTime? endDate;
  final String granularidad;

  @override
  State<GraficoBarrasComparacion> createState() => _GraficoBarrasComparacionState();
}

class _GraficoBarrasComparacionState extends State<GraficoBarrasComparacion> {
  late final _futuro = (widget.api ?? InformeApi(ApiClient())).comparacion(
    startDate: widget.startDate,
    endDate: widget.endDate,
    granularidad: widget.granularidad,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ingresos y egresos por período',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _leyenda(),
          const SizedBox(height: 12),
          FutureBuilder<ComparacionPeriodos>(
            future: _futuro,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(
                  child: SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                );
              }
              if (snapshot.hasError) {
                final e = snapshot.error;
                return Text(
                  e is ApiException ? e.message : 'No se pudieron cargar los datos',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
                );
              }
              final data = snapshot.data!;
              if (data.periodos.isEmpty) {
                return const Text('Todavía no hay datos en el período.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12.5));
              }
              double maxValor = 0;
              for (final p in data.periodos) {
                if (p.ingresos.abs() > maxValor) maxValor = p.ingresos.abs();
                if (p.egresos.abs() > maxValor) maxValor = p.egresos.abs();
              }
              return LayoutBuilder(
                builder: (context, constraints) {
                  final anchoEtiqueta = constraints.maxWidth < 420 ? 70.0 : 110.0;
                  return Column(
                    children: [
                      for (final p in data.periodos)
                        _filaPeriodo(p, maxValor, anchoEtiqueta),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _leyenda() {
    return Row(
      children: [
        _punto(AppColors.accent, 'Ingresos'),
        const SizedBox(width: 16),
        _punto(const Color(0xFF7C9CFF), 'Egresos'),
      ],
    );
  }

  Widget _punto(Color color, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(texto, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
      ],
    );
  }

  Widget _filaPeriodo(PeriodoComparacion p, double maxValor, double anchoEtiqueta) {
    final fIng = maxValor > 0 ? (p.ingresos.abs() / maxValor) : 0.0;
    final fEgr = maxValor > 0 ? (p.egresos.abs() / maxValor) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(p.etiqueta,
              style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Row(
            children: [
              SizedBox(
                width: anchoEtiqueta,
                child: const Text('Ingresos',
                    style: TextStyle(color: AppColors.muted, fontSize: 11.5)),
              ),
              Expanded(child: _barra(fIng, AppColors.accent)),
              const SizedBox(width: 8),
              SizedBox(
                width: 70,
                child: Text(importe(p.ingresos),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              SizedBox(
                width: anchoEtiqueta,
                child: const Text('Egresos',
                    style: TextStyle(color: AppColors.muted, fontSize: 11.5)),
              ),
              Expanded(child: _barra(fEgr, const Color(0xFF7C9CFF))),
              const SizedBox(width: 8),
              SizedBox(
                width: 70,
                child: Text(importe(p.egresos),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _barra(double factor, Color color) {
    return Container(
      height: 14,
      decoration: BoxDecoration(color: AppColors.surface3, borderRadius: BorderRadius.circular(6)),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: factor.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }
}