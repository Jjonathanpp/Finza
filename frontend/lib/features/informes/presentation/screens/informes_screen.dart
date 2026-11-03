import 'package:flutter/material.dart';
import 'package:frontend/features/informes/data/datasources/informe_api.dart';
import 'package:frontend/features/informes/presentation/widgets/grafico_barras_comparacion.dart';
import 'package:frontend/features/informes/presentation/widgets/grafico_torta_categorias.dart';
import 'package:frontend/features/panel/presentation/widgets/selector_rango_fechas.dart';
import 'package:frontend/core/network/api_client.dart';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:frontend/features/informes/presentation/widgets/exportar_reporte_dialog.dart';
import 'package:frontend/core/session/cuenta_activa.dart';
import 'dart:io';
class InformesScreen extends StatefulWidget {
  const InformesScreen({super.key});

  @override
  State<InformesScreen> createState() => _InformesScreenState();
}

class _InformesScreenState extends State<InformesScreen> {
  DateTime? _inicio;
  DateTime? _fin;
  String _granularidad = 'MES';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Informes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SelectorRangoFechas(
            key: const PageStorageKey('selector_rango_informes'),
            onCambio: (start, end) => setState(() {
                _inicio = start;
                _fin = end;
            }),
           ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'MES', label: Text('Por mes')),
              ButtonSegment(value: 'SEMANA', label: Text('Por semana')),
            ],
            selected: {_granularidad},
            onSelectionChanged: (s) => setState(() => _granularidad = s.first),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => ExportarReporteDialog.mostrar(
              context,
              fechaInicial: _inicio,
              fechaFinal: _fin,
              cuentaCompartidaActiva: cuentaActiva.value != null,
              onExportar: (alcance, desde, hasta) async {
                final api = InformeApi(ApiClient());
                final bytes = await api.descargarReporte(
                  alcance: alcance,
                  fechaDesde: desde,
                  fechaHasta: hasta,
                );
                final dir = await getTemporaryDirectory();
                final archivo = File('${dir.path}/reporte_finza.pdf');
                await archivo.writeAsBytes(bytes, flush: true);
                await SharePlus.instance.share(
                  ShareParams(
                    files: [XFile(archivo.path)],
                    text: 'Reporte Finza',
                  ),
                );
              },
            ),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Exportar reporte'),
          ),
          const SizedBox(height: 12),
          GraficoBarrasComparacion(
            key: ValueKey('${_inicio}_${_fin}_$_granularidad'),
            api: InformeApi(ApiClient()),
            startDate: _inicio,
            endDate: _fin,
            granularidad: _granularidad,
          ),
          const SizedBox(height: 12),
          GraficoTortaCategorias(
            key: ValueKey('torta_$_inicio$_fin'),
            api: InformeApi(ApiClient()),
            startDate: _inicio,
            endDate: _fin,
          ),
        ],
      ),
    );
  }
}