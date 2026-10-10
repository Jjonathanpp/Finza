import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/panel/data/datasources/panel_api.dart';
import 'package:frontend/features/panel/data/models/resumen_mes.dart';
import 'package:frontend/shared/utils/pesos.dart';

// La tarjeta de arriba del Inicio: tu plata en pesos, tipo billetera, y cómo vas este mes.
// El ojo esconde los montos, para mirar la app delante de otros.
class TarjetaSaldo extends StatefulWidget {
  const TarjetaSaldo({super.key, this.api});

  // Solo para los tests: en la app pide los datos al backend.
  final PanelApi? api;

  @override
  State<TarjetaSaldo> createState() => _TarjetaSaldoState();
}

class _TarjetaSaldoState extends State<TarjetaSaldo> {
  late final _resumen = (widget.api ?? PanelApi(ApiClient())).resumen();
  // ponytail: no se guarda; al cambiar de pestaña vuelve a mostrarse. Guardarlo si molesta.
  bool _oculto = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Pesos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              IconButton(
                tooltip: _oculto ? 'Mostrar montos' : 'Ocultar montos',
                icon: Icon(
                  _oculto ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppColors.muted,
                  size: 21,
                ),
                onPressed: () => setState(() => _oculto = !_oculto),
              ),
            ],
          ),
          FutureBuilder<ResumenMes>(future: _resumen, builder: (context, respuesta) => _contenido(respuesta)),
        ],
      ),
    );
  }

  Widget _contenido(AsyncSnapshot<ResumenMes> respuesta) {
    if (respuesta.connectionState != ConnectionState.done) {
      return const SizedBox(
        height: 70,
        child: Center(child: SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))),
      );
    }
    final error = respuesta.error;
    if (error != null) {
      return Text(
        error is ApiException ? error.message : 'No se pudo cargar tu saldo',
        style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
      );
    }
    final resumen = respuesta.data!;
    final centavos = (resumen.saldoTotal.abs() * 100).round();
    final mes = resumen.saldoMes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Como en la maqueta: los centavos más chicos y en gris.
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: _oculto ? '\$ ••••••' : '${resumen.saldoTotal < 0 ? '−' : ''}\$ ${miles(centavos ~/ 100)}',
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700, height: 1.1),
              ),
              if (!_oculto)
                TextSpan(
                  text: ',${(centavos % 100).toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.faint),
                ),
            ],
          ),
          style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            text: 'Este mes: ',
            children: [
              TextSpan(
                text: _oculto ? '••••' : '${mes > 0 ? '+' : ''}${pesos(mes)}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _oculto || mes == 0 ? AppColors.muted : (mes > 0 ? AppColors.accent : AppColors.danger),
                ),
              ),
            ],
          ),
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
      ],
    );
  }
}
