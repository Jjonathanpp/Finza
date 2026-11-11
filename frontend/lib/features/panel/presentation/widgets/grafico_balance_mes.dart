import 'package:flutter/material.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/widgets/barra_progreso.dart';
import 'package:frontend/core/widgets/esqueleto.dart';
import 'package:frontend/core/widgets/tarjeta.dart';
import 'package:frontend/features/panel/data/datasources/panel_api.dart';
import 'package:frontend/features/panel/data/models/resumen_mes.dart';
import 'package:frontend/shared/utils/importe.dart';

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
    final textos = Theme.of(context).textTheme;
    return FutureBuilder<ResumenMes>(
      future: _resumen,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Esqueleto(alto: 96);

        final data = snapshot.data;
        final ingresos = (data?.totalIngresos ?? 0.0).abs();
        final egresos = (data?.totalEgresos ?? 0.0).abs();
        final mayor = ingresos > egresos ? ingresos : egresos;

        return Tarjeta(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Ingresos y egresos del mes',
                  style: textos.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              _FilaBarra(
                etiqueta: 'Ingresos',
                monto: ingresos,
                factor: mayor > 0 ? ingresos / mayor : 0.0,
                tono: TonoBarra.barra,
              ),
              _FilaBarra(
                etiqueta: 'Egresos',
                monto: egresos,
                factor: mayor > 0 ? egresos / mayor : 0.0,
                tono: TonoBarra.coral,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilaBarra extends StatelessWidget {
  const _FilaBarra({
    required this.etiqueta,
    required this.monto,
    required this.factor,
    required this.tono,
  });

  final String etiqueta;
  final double monto;
  final double factor;
  final TonoBarra tono;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          spacing: 8,
          children: [
            Flexible(
              child: Text(
                etiqueta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textos.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              importe(monto),
              maxLines: 1,
              softWrap: false,
              style: textos.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        BarraProgreso(valor: factor, tono: tono, etiqueta: etiqueta),
      ],
    );
  }
}
