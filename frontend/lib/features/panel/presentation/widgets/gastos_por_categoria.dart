import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/panel/data/datasources/panel_api.dart';
import 'package:frontend/features/panel/data/models/resumen_gastos.dart';
import 'package:frontend/shared/utils/color_hex.dart';

// "En qué gastás" (US-5.4), el bloque del panel con lo gastado en el mes por categoría, como en la maqueta.
// El orden, los totales y los porcentajes ya vienen calculados del backend (T-5.4.1).
class GastosPorCategoria extends StatefulWidget {
  const GastosPorCategoria({super.key, this.api});

  // Solo para los tests: en la app pide los datos al backend.
  final PanelApi? api;

  @override
  State<GastosPorCategoria> createState() => _GastosPorCategoriaState();
}

class _GastosPorCategoriaState extends State<GastosPorCategoria> {
  // Se pide al abrir el panel. El menú arma el panel de nuevo cada vez, así que trae lo último cargado.
  late final _resumen = (widget.api ?? PanelApi(ApiClient())).gastosPorCategoria();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ResumenGastos>(
      future: _resumen,
      builder: (context, respuesta) {
        final resumen = respuesta.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 9),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('En qué gastás', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                  ),
                  if (resumen != null && resumen.categorias.isNotEmpty)
                    Text('Total ${_monto(resumen.total)}', style: _numeros.copyWith(color: AppColors.muted, fontSize: 12)),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.line),
              ),
              child: _contenido(respuesta),
            ),
          ],
        );
      },
    );
  }

  Widget _contenido(AsyncSnapshot<ResumenGastos> respuesta) {
    if (respuesta.connectionState != ConnectionState.done) {
      return const Center(child: SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5)));
    }
    final error = respuesta.error;
    if (error != null) {
      return _aviso(error is ApiException ? error.message : 'No se pudieron cargar los gastos');
    }
    final categorias = respuesta.data!.categorias;
    if (categorias.isEmpty) return _aviso('Todavía no hay gastos este mes.');
    return Column(spacing: 9, children: [for (final gasto in categorias) _Fila(gasto)]);
  }

  Widget _aviso(String texto) => Text(texto, style: const TextStyle(color: AppColors.muted, fontSize: 12.5));
}

class _Fila extends StatelessWidget {
  const _Fila(this.gasto);

  final GastoCategoria gasto;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Sin color (las categorías creadas desde un movimiento no tienen), colorDesdeHex da gris.
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: colorDesdeHex(gasto.color), borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            gasto.nombre,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
          ),
        ),
        const SizedBox(width: 9),
        Text(_monto(gasto.total), style: _numeros.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700)),
        SizedBox(
          width: 46,
          child: Text(
            _porcentaje(gasto.porcentaje),
            textAlign: TextAlign.right,
            style: _numeros.copyWith(color: AppColors.faint, fontSize: 11.5),
          ),
        ),
      ],
    );
  }
}

// Todos los números del mismo ancho, así los montos quedan alineados entre filas.
const _numeros = TextStyle(fontFeatures: [FontFeature.tabularFigures()]);

// Como en la maqueta: pesos sin centavos y con punto de miles (200000 → $ 200.000).
String _monto(double valor) {
  final entero = valor.round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  return '\$ $entero';
}

// Con el decimal que manda el backend, con coma, y sin ",0" (50.0 → 50%, 33.3 → 33,3%).
String _porcentaje(double valor) {
  final texto = valor.toStringAsFixed(1).replaceAll('.', ',');
  return '${texto.endsWith(',0') ? texto.substring(0, texto.length - 2) : texto}%';
}
