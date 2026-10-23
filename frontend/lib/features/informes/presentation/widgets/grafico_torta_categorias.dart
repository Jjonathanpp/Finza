import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/informes/data/datasources/informe_api.dart';
import 'package:frontend/features/panel/data/models/resumen_gastos.dart';
import 'package:frontend/shared/utils/color_hex.dart';
import 'package:frontend/shared/utils/importe.dart';

class GraficoTortaCategorias extends StatefulWidget {
  const GraficoTortaCategorias({
    super.key,
    this.api,
    this.startDate,
    this.endDate,
  });

  final InformeApi? api;
  final DateTime? startDate;
  final DateTime? endDate;

  @override
  State<GraficoTortaCategorias> createState() => _GraficoTortaCategoriasState();
}

class _GraficoTortaCategoriasState extends State<GraficoTortaCategorias> {
  late final _futuro = (widget.api ?? InformeApi(ApiClient())).porCategoria(
    startDate: widget.startDate,
    endDate: widget.endDate,
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
          const Text(
            'Gastos por categoría',
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          FutureBuilder<ResumenGastos>(
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
                  e is ApiException ? e.message : 'No se pudieron cargar los gastos',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
                );
              }
              final data = snapshot.data!;
              if (data.categorias.isEmpty) {
                return const Text(
                  'Todavía no hay gastos en el período.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12.5),
                );
              }
              return LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 420;
                  final chartSize = isWide ? 160.0 : 140.0;
                  return isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: chartSize,
                              height: chartSize,
                              child: CustomPaint(
                                painter: _PiePainter(categorias: data.categorias),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(child: _Leyenda(categorias: data.categorias)),
                          ],
                        )
                      : Column(
                          children: [
                            SizedBox(
                              width: chartSize,
                              height: chartSize,
                              child: CustomPaint(
                                painter: _PiePainter(categorias: data.categorias),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _Leyenda(categorias: data.categorias),
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
}

class _PiePainter extends CustomPainter {
  _PiePainter({required this.categorias});
  final List<GastoCategoria> categorias;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -math.pi / 2;
    for (final cat in categorias) {
      final sweepAngle = 2 * math.pi * (cat.porcentaje / 100.0);
      if (sweepAngle <= 0) continue;
      final paint = Paint()
        ..color = colorDesdeHex(cat.color)
        ..style = PaintingStyle.fill;
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _Leyenda extends StatelessWidget {
  const _Leyenda({required this.categorias});
  final List<GastoCategoria> categorias;

  String _porcentaje(double valor) {
    final texto = valor.toStringAsFixed(1).replaceAll('.', ',');
    return '${texto.endsWith(',0') ? texto.substring(0, texto.length - 2) : texto}%';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final cat in categorias)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colorDesdeHex(cat.color),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cat.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  importe(cat.total),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 42,
                  child: Text(
                    _porcentaje(cat.porcentaje),
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: AppColors.faint, fontSize: 11.5),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}