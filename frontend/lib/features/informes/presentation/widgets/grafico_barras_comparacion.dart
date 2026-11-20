import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/widgets/esqueleto.dart';
import 'package:frontend/core/widgets/monto.dart';
import 'package:frontend/core/widgets/tarjeta.dart';
import 'package:frontend/core/widgets/tocable.dart';
import 'package:frontend/features/informes/data/datasources/informe_api.dart';
import 'package:frontend/features/informes/data/models/comparacion_periodos.dart';
import 'package:frontend/shared/utils/importe.dart';
import 'package:frontend/l10n/idioma.dart';

// "Ingresos y gastos" (maqueta L506-510): columnas de ingresos y gastos por período, con una etiqueta
// corta abajo ("nov" y el año solo cuando cambia; "10–16" y el mes en semanas), y el detalle del período
// elegido (el último, o el que se toque): su nombre completo, lo que entró, lo que salió y el saldo, y
// cuánto cambiaron los gastos respecto del anterior.
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
  // Cada columna mide lo que le toca del ancho de la tarjeta; si así quedaría más angosta que esto (más de
  // 12 períodos en un celular, por ejemplo muchas semanas), mide _anchoAlDeslizar y se desliza de costado.
  static const double _anchoMinimoColumna = 18;
  static const double _anchoAlDeslizar = 44;

  static const _meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

  late Future<ComparacionPeriodos> _futuro = _cargar();
  int? _elegido; // índice del período del detalle; null = el último

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
              context.tr('Ingresos y gastos'),
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
                      e is ApiException ? e.message : context.tr('No se pudieron cargar los datos.'),
                      style: textos.bodySmall?.copyWith(color: c.suave),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _futuro = _cargar()),
                      child: Text(context.tr('Reintentar')),
                    ),
                  ],
                );
              }
              final periodos = snapshot.data!.periodos;
              if (periodos.isEmpty) {
                return Text(
                  context.tr('Todavía no hay datos en el período.'),
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
    final c = context.colores;
    var maximo = 0.0;
    for (final p in periodos) {
      maximo = math.max(maximo, math.max(p.ingresos.abs(), p.egresos.abs()));
    }
    final elegido = math.min(_elegido ?? periodos.length - 1, periodos.length - 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Semantics(label: context.tr('Ingresos y gastos por período'), child: _barras(periodos, maximo, elegido)),
        Row(
          spacing: 16,
          children: [
            _referencia(context, c.barra, context.tr('Ingresos')),
            _referencia(context, c.texto.withValues(alpha: .78), context.tr('Gastos')),
          ],
        ),
        _detalle(context, periodos[elegido]),
      ],
    );
  }

  // El período elegido: el nombre completo arriba, el chip de variación y las tres cifras.
  Widget _detalle(BuildContext context, PeriodoComparacion p) {
    final textos = Theme.of(context).textTheme;
    final c = context.colores;
    final chip = _chipVariacion(p.variacionEgresos);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: c.hundido, borderRadius: BorderRadius.circular(Radios.control)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Text(p.etiqueta, style: textos.bodyMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w800)),
          ?chip,
          Row(
            children: [
              Expanded(child: _cifra(context, context.tr('Entró'), Monto.texto(p.ingresos), c.primario)),
              Expanded(child: _cifra(context, context.tr('Salió'), Monto.texto(p.egresos), c.texto)),
              Expanded(
                child: _cifra(
                  context,
                  context.tr('Saldo'),
                  Monto.texto(p.saldo, ingreso: p.saldo == 0 ? null : p.saldo > 0),
                  p.saldo < 0 ? c.coralTexto : c.texto,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cifra(BuildContext context, String etiqueta, String valor, Color color) {
    final textos = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        Text(etiqueta, style: textos.bodySmall?.copyWith(fontSize: 12, color: context.colores.suave)),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            valor,
            style: textos.bodyMedium?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  // Cuánto cambiaron los gastos respecto del período anterior, con una flecha. En texto y no en un chip
  // para que la frase entera entre en dos renglones si hace falta.
  Widget? _chipVariacion(double? variacion) {
    if (variacion == null) return null;
    final c = context.colores;
    final porcentaje = variacion.round();
    final semana = widget.granularidad == 'SEMANA';
    final datos = {'porcentaje': '${porcentaje.abs()}'};
    final (icono, texto) = porcentaje < 0
        ? (
            Icons.trending_down,
            semana
                ? context.tr('Gastaste {porcentaje}% menos que la semana pasada', datos)
                : context.tr('Gastaste {porcentaje}% menos que el mes pasado', datos),
          )
        : porcentaje > 0
        ? (
            Icons.trending_up,
            semana
                ? context.tr('Gastaste {porcentaje}% más que la semana pasada', datos)
                : context.tr('Gastaste {porcentaje}% más que el mes pasado', datos),
          )
        : (
            Icons.trending_flat,
            semana
                ? context.tr('Gastaste lo mismo que la semana pasada')
                : context.tr('Gastaste lo mismo que el mes pasado'),
          );
    final color = porcentaje <= 0 ? c.primario : c.ambarTexto;
    return Row(
      spacing: 6,
      children: [
        Icon(icono, size: 18, color: color),
        Expanded(
          child: Text(
            texto,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: color),
          ),
        ),
      ],
    );
  }

  // La etiqueta de abajo de cada columna, en dos renglones cortos que entran en 56 px.
  // Por mes: "nov" y abajo el año, solo en la primera columna y cuando cambia (en enero).
  // Por semana: "10–16" y abajo el mes ("oct–nov" si la semana cruza de mes).
  (String, String) _etiquetaCorta(List<PeriodoComparacion> periodos, int i) {
    final p = periodos[i];
    final ini = p.fechaInicio, fin = p.fechaFin;
    if (widget.granularidad == 'SEMANA') {
      final mes = ini.month == fin.month ? _meses[ini.month - 1] : '${_meses[ini.month - 1]}–${_meses[fin.month - 1]}';
      return ('${ini.day}–${fin.day}', mes);
    }
    final cambiaAnio = i == 0 || periodos[i - 1].fechaInicio.year != ini.year;
    return (_meses[ini.month - 1], cambiaAnio ? '${ini.year}' : '');
  }

  Widget _barras(List<PeriodoComparacion> periodos, double maximo, int elegido) {
    const separacion = 4.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final n = periodos.length;
        final queEntra = (constraints.maxWidth - separacion * (n - 1)) / n;
        final desliza = queEntra < _anchoMinimoColumna;
        final anchoColumna = desliza ? _anchoAlDeslizar : queEntra;
        final columnas = SizedBox(
          width: desliza ? n * (anchoColumna + separacion) - separacion : constraints.maxWidth,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: separacion,
            children: [
              for (var i = 0; i < n; i++)
                Expanded(child: _columna(context, periodos, i, maximo, i == elegido, anchoColumna)),
            ],
          ),
        );
        if (!desliza) return columnas;
        // Se desliza de costado, empezando por el más nuevo. También arrastrando con el mouse (en la
        // compu Flutter solo deja deslizar con el dedo o la rueda).
        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(dragDevices: PointerDeviceKind.values.toSet()),
          child: SingleChildScrollView(scrollDirection: Axis.horizontal, reverse: true, child: columnas),
        );
      },
    );
  }

  Widget _columna(
    BuildContext context,
    List<PeriodoComparacion> periodos,
    int i,
    double maximo,
    bool elegida,
    double anchoColumna,
  ) {
    final textos = Theme.of(context).textTheme;
    final c = context.colores;
    final p = periodos[i];
    final (arriba, abajo) = _etiquetaCorta(periodos, i);
    double alto(double valor) => maximo > 0 ? math.max(3, (valor.abs() / maximo * _altoMaximo).roundToDouble()) : 3;
    // Las columnas que no están elegidas se apagan un poco, así se ve cuál muestra el detalle.
    final opacidad = elegida ? 1.0 : .45;
    // Las dos barras se angostan con la columna (16 px cada una como máximo).
    final entreBarras = anchoColumna < 40 ? 2.0 : 4.0;
    final anchoBarra = ((anchoColumna - 6 - entreBarras) / 2).clamp(4.0, 16.0);
    // Todas las etiquetas con el mismo tamaño: más chico si las columnas son angostas (un año por mes).
    final angosta = anchoColumna < 30;
    return Tocable(
      etiqueta: '${p.etiqueta}: ingresos ${importe(p.ingresos)}, gastos ${importe(p.egresos)}',
      alTocar: () => setState(() => _elegido = i),
      child: Container(
        padding: const EdgeInsets.only(top: 6, bottom: 6),
        decoration: BoxDecoration(
          color: elegida ? c.hundido : Colors.transparent,
          borderRadius: BorderRadius.circular(Radios.control),
        ),
        child: Column(
          spacing: 6,
          children: [
            SizedBox(
              height: _altoMaximo,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                spacing: entreBarras,
                children: [
                  _barra(alto(p.ingresos), anchoBarra, c.barra.withValues(alpha: opacidad)),
                  _barra(alto(p.egresos), anchoBarra, c.texto.withValues(alpha: .78 * opacidad)),
                ],
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                arriba,
                maxLines: 1,
                style: textos.bodySmall?.copyWith(
                  fontSize: angosta ? 10.5 : 12,
                  fontWeight: elegida ? FontWeight.w800 : FontWeight.w600,
                  color: elegida ? c.texto : c.suave,
                ),
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                abajo,
                maxLines: 1,
                style: textos.bodySmall?.copyWith(fontSize: angosta ? 9 : 10.5, color: c.suave),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _barra(double alto, double ancho, Color color) {
    final radio = math.min(6.0, ancho / 2);
    return Container(
      width: ancho,
      height: alto,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(radio),
          topRight: Radius.circular(radio),
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
