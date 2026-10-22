import 'package:flutter/material.dart';
import 'package:frontend/features/informes/data/datasources/informe_api.dart';
import 'package:frontend/features/informes/presentation/widgets/grafico_barras_comparacion.dart';
import 'package:frontend/features/panel/presentation/widgets/selector_rango_fechas.dart';
import 'package:frontend/core/network/api_client.dart';

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
          GraficoBarrasComparacion(
            key: ValueKey('${_inicio}_${_fin}_$_granularidad'),
            api: InformeApi(ApiClient()),
            startDate: _inicio,
            endDate: _fin,
            granularidad: _granularidad,
          ),
        ],
      ),
    );
  }
}