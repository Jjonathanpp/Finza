import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/encabezado_pestana.dart';
import 'package:frontend/features/home/presentation/widgets/acciones_rapidas.dart';
import 'package:frontend/features/panel/presentation/widgets/gastos_por_categoria.dart';
import 'package:frontend/features/panel/presentation/widgets/tarjeta_saldo.dart';
import 'package:frontend/features/panel/presentation/widgets/grafico_balance_mes.dart';
import 'package:frontend/features/panel/presentation/widgets/ultimos_movimientos.dart';
import 'package:frontend/features/panel/presentation/widgets/selector_rango_fechas.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  void _onFechasCambiadas(DateTime? start, DateTime? end) {
    setState(() {
      _startDate = start;
      _endDate = end;
    });
  }

  @override
  Widget build(BuildContext context) {
    final recargaKey = ValueKey('${_startDate?.toIso8601String()}_${_endDate?.toIso8601String()}');

    return Scaffold(
      body: Column(
        children: [
          const EncabezadoInicio(),
          Expanded(
            child: ListView(
              // .scroll de la maqueta: 20 a los costados, 12 entre bloques.
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                SelectorRangoFechas(onCambio: _onFechasCambiadas),
                const SizedBox(height: 12),

                TarjetaSaldo(key: recargaKey, startDate: _startDate, endDate: _endDate),
                const SizedBox(height: 12),

                GastosPorCategoria(key: recargaKey, startDate: _startDate, endDate: _endDate),
                const SizedBox(height: 12),

                GraficoBalanceMes(key: recargaKey, startDate: _startDate, endDate: _endDate),
                const SizedBox(height: 12),

                UltimosMovimientos(key: recargaKey, startDate: _startDate, endDate: _endDate),
                const SizedBox(height: 12),

                const AccionesRapidas(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
