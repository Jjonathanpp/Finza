import 'package:flutter/material.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/session/cuenta_activa.dart';
import 'package:frontend/core/widgets/chip_estado.dart';
import 'package:frontend/core/widgets/circulo_categoria.dart';
import 'package:frontend/core/widgets/esqueleto.dart';
import 'package:frontend/core/widgets/fila_movimiento.dart';
import 'package:frontend/core/widgets/monto.dart';
import 'package:frontend/core/widgets/tarjeta.dart';
import 'package:frontend/core/widgets/titulo_seccion.dart';
import 'package:frontend/features/home/presentation/screens/pantalla_principal.dart';
import 'package:frontend/features/movimientos/data/models/movimiento.dart';
import 'package:frontend/features/panel/data/datasources/panel_api.dart';
import 'package:frontend/features/panel/data/models/resumen_mes.dart';
import 'package:frontend/features/panel/presentation/widgets/error_con_reintento.dart';

class UltimosMovimientos extends StatefulWidget {
  const UltimosMovimientos({super.key, this.api, this.startDate, this.endDate});

  final PanelApi? api;
  final DateTime? startDate;
  final DateTime? endDate;

  @override
  State<UltimosMovimientos> createState() => _UltimosMovimientosState();
}

class _UltimosMovimientosState extends State<UltimosMovimientos> {
  late Future<ResumenMes> _resumen = _pedir();

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
          return const EsqueletoLista(cantidad: 3);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            TituloSeccion(
              'Últimos movimientos',
              grande: true,
              link: 'Ver todos',
              // La pestaña 1 es Movimientos.
              alLink: () => pestanaPedida.value = 1,
            ),
            _contenido(context, respuesta),
          ],
        );
      },
    );
  }

  Widget _contenido(BuildContext context, AsyncSnapshot<ResumenMes> respuesta) {
    final error = respuesta.error;
    if (error != null) {
      return Tarjeta(
        child: ErrorConReintento(
          mensaje: error is ApiException ? error.message : 'No se pudieron cargar los movimientos',
          alReintentar: () => setState(() => _resumen = _pedir()),
        ),
      );
    }

    final movimientos = respuesta.data!.ultimosMovimientos;
    if (movimientos.isEmpty) {
      return Tarjeta(child: Text('Todavía no hay movimientos recientes.', style: Theme.of(context).textTheme.bodySmall));
    }

    return TarjetaLista(
      children: [for (final movimiento in movimientos) _Fila(movimiento)],
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila(this.movimiento);
  final Movimiento movimiento;

  String _formatearFecha(DateTime fecha) {
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    final ingreso = movimiento.esIngreso;
    final pendiente = movimiento.estado == 'PENDIENTE';
    // El autor solo importa en una cuenta compartida.
    final autor = cuentaActiva.value != null ? movimiento.perfilNombre : null;

    return FilaMovimiento(
      leading: CirculoCategoria.de(movimiento.categoria),
      titulo: movimiento.categoria.nombre,
      subtitulo: movimiento.descripcion?.isNotEmpty == true ? movimiento.descripcion! : _formatearFecha(movimiento.fecha),
      monto: Monto.texto(movimiento.monto, ingreso: ingreso),
      colorMonto: Monto.color(context, ingreso),
      chip: pendiente ? const ChipEstado('Por revisar', TonoChip.ambar, chico: true) : null,
      pie: autor == null || autor.isEmpty
          ? null
          : ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 96),
              child: Text(autor, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11.5)),
            ),
    );
  }
}
