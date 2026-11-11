// lib/features/panel/presentation/widgets/tarjeta_saldo.dart
import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/widgets/esqueleto.dart';
import 'package:frontend/core/widgets/tarjeta.dart';
import 'package:frontend/features/panel/data/datasources/panel_api.dart';
import 'package:frontend/features/panel/data/models/resumen_mes.dart';
import 'package:frontend/features/panel/presentation/widgets/error_con_reintento.dart';
import 'package:frontend/shared/utils/importe.dart';

// La tarjeta destacada (.dest) de arriba del Inicio: tu plata (en la moneda elegida), tipo billetera, y
// cómo vas en el período, con los ingresos y los gastos abajo.
// El ojo esconde los montos, para mirar la app delante de otros.
class TarjetaSaldo extends StatefulWidget {
  // (O GraficoBalanceMes / UltimosMovimientos)
  const TarjetaSaldo({super.key, this.api, this.startDate, this.endDate});
  final PanelApi? api;
  final DateTime? startDate;
  final DateTime? endDate;

  @override
  State<TarjetaSaldo> createState() => _TarjetaSaldoState();
}

class _TarjetaSaldoState extends State<TarjetaSaldo> {
  late Future<ResumenMes> _resumen = _pedir();
  // ponytail: no se guarda; al cambiar de pestaña vuelve a mostrarse. Guardarlo si molesta.
  bool _oculto = false;

  Future<ResumenMes> _pedir() => (widget.api ?? PanelApi(ApiClient())).resumen(
    startDate: widget.startDate,
    endDate: widget.endDate,
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ResumenMes>(
      future: _resumen,
      builder: (context, respuesta) {
        if (respuesta.connectionState != ConnectionState.done) {
          return const Esqueleto(alto: 150, radio: Radios.destacada);
        }
        final error = respuesta.error;
        if (error != null) {
          return Tarjeta(
            child: ErrorConReintento(
              mensaje: error is ApiException ? error.message : 'No se pudo cargar tu saldo',
              alReintentar: () => setState(() => _resumen = _pedir()),
            ),
          );
        }
        return _tarjeta(context, respuesta.data!);
      },
    );
  }

  Widget _tarjeta(BuildContext context, ResumenMes resumen) {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    final total = enMonedaVista(resumen.saldoTotal);
    final centavos = (total.abs() * 100).round();
    final mes = resumen.saldoMes;
    final aclaracion = aclaracionCotizacion;
    // Coral solo si el total es negativo y los montos están a la vista (oculto, no revela el signo).
    final negativo = !_oculto && total < 0;
    return Tarjeta(
      destacada: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    nombreMoneda,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textos.labelLarge?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.destacadoSuave,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: _oculto ? 'Mostrar montos' : 'Ocultar montos',
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                style: IconButton.styleFrom(foregroundColor: c.destacadoTexto),
                icon: Icon(
                  _oculto ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 21,
                ),
                onPressed: () => setState(() => _oculto = !_oculto),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                // Los centavos van más chicos y en suave (en coral si el total es negativo).
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: _oculto
                              ? '$simboloMoneda ••••••'
                              : '${total < 0 ? '−' : ''}$simboloMoneda ${miles(centavos ~/ 100)}',
                        ),
                        if (!_oculto)
                          TextSpan(
                            text: ',${(centavos % 100).toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: negativo ? c.coral : c.destacadoSuave,
                            ),
                          ),
                      ],
                    ),
                    maxLines: 1,
                    softWrap: false,
                    style: textos.displaySmall?.copyWith(
                      height: 1.05,
                      color: negativo ? c.coral : c.destacadoTexto,
                    ),
                  ),
                ),
                Text.rich(
                  TextSpan(
                    text: 'Período de informe: ',
                    children: [
                      TextSpan(
                        text: _oculto ? '••••' : '${mes > 0 ? '+' : ''}${importe(mes)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _oculto || mes == 0
                              ? c.destacadoSuave
                              : (mes > 0 ? c.destacadoVerde : c.coral),
                        ),
                      ),
                    ],
                  ),
                  style: textos.bodySmall?.copyWith(color: c.destacadoSuave),
                ),
                if (aclaracion != null)
                  Text(
                    aclaracion,
                    style: textos.bodySmall?.copyWith(fontSize: 11.5, color: c.destacadoSuave),
                  ),
              ],
            ),
          ),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: _Mini(
                  etiqueta: 'Ingresos',
                  valor: _oculto ? '••••' : importe(resumen.totalIngresos.abs()),
                  color: c.destacadoVerde,
                ),
              ),
              Expanded(
                child: _Mini(
                  etiqueta: 'Gastos',
                  valor: _oculto ? '••••' : importe(resumen.totalEgresos.abs()),
                  color: c.destacadoTexto,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// .mini de la maqueta: una cajita con la etiqueta chica y el monto abajo, sobre el fondo destacado.
class _Mini extends StatelessWidget {
  const _Mini({required this.etiqueta, required this.valor, required this.color});

  final String etiqueta;
  final String valor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.destacadoTexto.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(Radios.mini),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2,
        children: [
          Text(
            etiqueta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textos.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: c.destacadoSuave,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              valor,
              maxLines: 1,
              softWrap: false,
              style: textos.labelLarge?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
