import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/widgets/chip_estado.dart';
import 'package:frontend/core/widgets/esqueleto.dart';
import 'package:frontend/core/widgets/tarjeta.dart';
import 'package:frontend/features/informes/data/datasources/informe_api.dart';
import 'package:frontend/features/informes/data/models/comparacion_periodos.dart';
import 'package:frontend/shared/utils/importe.dart';

// "Ingresos y gastos" (maqueta L506-510): un chip con cuánto cambiaron los gastos respecto del período
// anterior, columnas de ingresos y gastos por período, la leyenda y una línea con el último período.
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
  static const double _altoMaximo = 120;
  static const double _anchoMinimoColumna = 56;

  late Future<ComparacionPeriodos> _futuro = _cargar();

  Future<ComparacionPeriodos> _cargar() => (widget.api ?? InformeApi(ApiClient())).comparacion(
        startDate: widget.startDate,
        endDate: widget.endDate,
        granularidad: widget.granularidad,
      );

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final c = context.colores;
    return Tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Ingresos y gastos',
              style: textos.bodyMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
          FutureBuilder<ComparacionPeriodos>(
            future: _futuro,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Esqueleto(alto: 170, radio: Radios.mini);
              }
              if (snapshot.hasError) {
                final e = snapshot.error;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    Text(
                      e is ApiException ? e.message : 'No se pudieron cargar los datos.',
                      style: textos.bodySmall?.copyWith(color: c.suave),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _futuro = _cargar()),
                      child: const Text('Reintentar'),
                    ),
                  ],
                );
              }
              final periodos = snapshot.data!.periodos;
              if (periodos.isEmpty) {
                return Text(
                  'Todavía no hay datos en el período.',
                  style: textos.bodySmall?.copyWith(color: c.suave),
                );
              }
              return _contenido(context, periodos);
            },
          ),
        ],
      ),
    );
  }

  Widget _contenido(BuildContext context, List<PeriodoComparacion> periodos) {
    final textos = Theme.of(context).textTheme;
    final c = context.colores;
    var maximo = 0.0;
    for (final p in periodos) {
      maximo = math.max(maximo, math.max(p.ingresos.abs(), p.egresos.abs()));
    }
    final ultimo = periodos.last;
    final chip = _chipVariacion(ultimo.variacionEgresos);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        ?chip,
        Semantics(
          label: 'Ingresos y gastos por período',
          child: _barras(periodos, maximo),
        ),
        Row(
          spacing: 16,
          children: [
            _referencia(context, c.barra, 'Ingresos'),
            _referencia(context, c.texto.withValues(alpha: .78), 'Gastos'),
          ],
        ),
        Text(
          '${ultimo.etiqueta}: entraron ${importe(ultimo.ingresos)} y salieron ${importe(ultimo.egresos)}.',
          style: textos.bodySmall?.copyWith(color: c.suave),
        ),
      ],
    );
  }

  Widget? _chipVariacion(double? variacion) {
    if (variacion == null) return null;
    final porcentaje = variacion.round();
    final contra = widget.granularidad == 'SEMANA' ? 'la semana anterior' : 'el mes anterior';
    final texto = porcentaje < 0
        ? 'Gastaste ${-porcentaje}% menos que $contra'
        : porcentaje > 0
            ? 'Gastaste $porcentaje% más que $contra'
            : 'Gastaste lo mismo que $contra';
    return ChipEstado(texto, porcentaje <= 0 ? TonoChip.menta : TonoChip.ambar);
  }

  Widget _barras(List<PeriodoComparacion> periodos, double maximo) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = math.max(constraints.maxWidth, periodos.length * _anchoMinimoColumna);
        final columnas = SizedBox(
          width: ancho,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: 8,
            children: [
              for (final p in periodos)
                Expanded(child: _columna(context, p, maximo)),
            ],
          ),
        );
        if (ancho <= constraints.maxWidth) return columnas;
        // Con muchos períodos se desliza de costado, empezando por el más nuevo.
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true,
          child: columnas,
        );
      },
    );
  }

  Widget _columna(BuildContext context, PeriodoComparacion p, double maximo) {
    final textos = Theme.of(context).textTheme;
    final c = context.colores;
    double alto(double valor) => maximo > 0 ? math.max(3, (valor.abs() / maximo * _altoMaximo).roundToDouble()) : 3;
    return Semantics(
      label: '${p.etiqueta}: ingresos ${importe(p.ingresos)}, gastos ${importe(p.egresos)}',
      excludeSemantics: true,
      child: Column(
        spacing: 6,
        children: [
          SizedBox(
            height: _altoMaximo,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: 4,
              children: [
                _barra(alto(p.ingresos), c.barra),
                _barra(alto(p.egresos), c.texto.withValues(alpha: .78)),
              ],
            ),
          ),
          Text(
            p.etiqueta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textos.bodySmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: c.suave),
          ),
        ],
      ),
    );
  }

  Widget _barra(double alto, Color color) {
    return Container(
      width: 16,
      height: alto,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(6),
          topRight: Radius.circular(6),
          bottomLeft: Radius.circular(2),
          bottomRight: Radius.circular(2),
        ),
      ),
    );
  }

  Widget _referencia(BuildContext context, Color color, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        Text(
          texto,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
