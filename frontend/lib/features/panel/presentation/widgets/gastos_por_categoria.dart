import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/widgets/esqueleto.dart';
import 'package:frontend/core/widgets/tarjeta.dart';
import 'package:frontend/features/panel/data/datasources/panel_api.dart';
import 'package:frontend/features/panel/data/models/resumen_gastos.dart';
import 'package:frontend/features/panel/presentation/widgets/error_con_reintento.dart';
import 'package:frontend/shared/utils/color_hex.dart';
import 'package:frontend/shared/utils/importe.dart';

// "En qué gastás" (US-5.4), el bloque del panel con lo gastado en el mes por categoría, como en la maqueta:
// una barra partida por categoría y abajo la leyenda. El orden, los totales y los porcentajes ya vienen
// calculados del backend (T-5.4.1).
class GastosPorCategoria extends StatefulWidget {
  const GastosPorCategoria({super.key, this.api, this.startDate, this.endDate});
  final PanelApi? api;
  final DateTime? startDate;
  final DateTime? endDate;

  @override
  State<GastosPorCategoria> createState() => _GastosPorCategoriaState();
}

class _GastosPorCategoriaState extends State<GastosPorCategoria> {
  // Se pide al abrir el Inicio. El menú arma el Inicio de nuevo cada vez, así que trae lo último cargado.
  late Future<ResumenGastos> _resumen = _pedir();

  Future<ResumenGastos> _pedir() => (widget.api ?? PanelApi(ApiClient())).gastosPorCategoria(
    startDate: widget.startDate,
    endDate: widget.endDate,
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ResumenGastos>(
      future: _resumen,
      builder: (context, respuesta) {
        if (respuesta.connectionState != ConnectionState.done) return const Esqueleto(alto: 96);
        final textos = Theme.of(context).textTheme;
        final resumen = respuesta.data;
        return Tarjeta(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Row(
                spacing: 8,
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        'En qué gastás',
                        style: textos.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  if (resumen != null && resumen.categorias.isNotEmpty)
                    Text('Total ${importe(resumen.total)}', style: textos.bodySmall),
                ],
              ),
              ..._contenido(context, respuesta),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _contenido(BuildContext context, AsyncSnapshot<ResumenGastos> respuesta) {
    final error = respuesta.error;
    if (error != null) {
      return [
        ErrorConReintento(
          mensaje: error is ApiException ? error.message : 'No se pudieron cargar los gastos',
          alReintentar: () => setState(() => _resumen = _pedir()),
        ),
      ];
    }
    final categorias = respuesta.data!.categorias;
    if (categorias.isEmpty) {
      return [Text('Todavía no hay gastos este mes.', style: Theme.of(context).textTheme.bodySmall)];
    }
    return [
      _BarraSegmentada(categorias),
      LayoutBuilder(
        builder: (context, restricciones) {
          // La leyenda en dos columnas, como en la maqueta (8 de alto y 14 de ancho entre celdas).
          final ancho = (restricciones.maxWidth - 14) / 2;
          return Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              for (final gasto in categorias) SizedBox(width: ancho, child: _Leyenda(gasto)),
            ],
          );
        },
      ),
    ];
  }
}

// La barra de 12 de alto con un tramo por categoría, del ancho de su porcentaje y 2 de espacio entre tramos.
// Sin color (las categorías creadas desde un movimiento no tienen), colorDesdeHex da gris.
class _BarraSegmentada extends StatelessWidget {
  const _BarraSegmentada(this.categorias);

  final List<GastoCategoria> categorias;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radios.pastilla),
        child: SizedBox(
          height: 12,
          child: Row(
            spacing: 2,
            children: [
              for (final gasto in categorias)
                Expanded(
                  flex: math.max(1, (gasto.porcentaje * 10).round()),
                  child: ColoredBox(color: colorDesdeHex(gasto.color)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Leyenda extends StatelessWidget {
  const _Leyenda(this.gasto);

  final GastoCategoria gasto;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Row(
      spacing: 8,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: colorDesdeHex(gasto.color), shape: BoxShape.circle),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                gasto.nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textos.bodyMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              Text(
                importe(gasto.total),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textos.bodySmall?.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
        Text(
          _porcentaje(gasto.porcentaje),
          maxLines: 1,
          style: textos.bodySmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

// Con el decimal que manda el backend, con coma, y sin ",0" (50.0 → 50%, 33.3 → 33,3%).
String _porcentaje(double valor) {
  final texto = valor.toStringAsFixed(1).replaceAll('.', ',');
  return '${texto.endsWith(',0') ? texto.substring(0, texto.length - 2) : texto}%';
}
