import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/widgets/barra_con_volver.dart';
import 'package:frontend/core/widgets/circulo_categoria.dart';
import 'package:frontend/core/widgets/fila_opcion.dart';
import 'package:frontend/core/widgets/tarjeta.dart';
import 'package:frontend/features/mercadopago/data/models/sincronizacion_resumen.dart';

class SincronizacionResumenScreen extends StatelessWidget {
  final SincronizacionResumen resumen;

  const SincronizacionResumenScreen({
    super.key,
    required this.resumen,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    return Scaffold(
      appBar: barraConVolver(context, 'Resumen de importación'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          Tarjeta(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  child: CirculoCategoria(
                    icono: Icons.check_circle_outline,
                    color: c.primario,
                    fondo: c.menta,
                    tamano: 52,
                    tamanoIcono: 28,
                  ),
                ),
                const SizedBox(height: 14),
                Text('Sincronización completada', textAlign: TextAlign.center, style: textos.titleLarge),
                const SizedBox(height: 6),
                Text(
                  'Los nuevos movimientos quedaron registrados como pendientes para tu revisión.',
                  textAlign: TextAlign.center,
                  style: textos.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TarjetaLista(
            children: [
              _itemMetrica(
                context,
                icono: Icons.sync,
                color: c.serie[2],
                fondo: c.serieFondo[2],
                titulo: 'Procesadas',
                subtitulo: 'Total consultado en Mercado Pago',
                valor: resumen.procesadas,
              ),
              _itemMetrica(
                context,
                icono: Icons.add_circle_outline,
                color: c.primario,
                fondo: c.menta,
                titulo: 'Nuevas creadas',
                subtitulo: 'Movimientos listos para revisar',
                valor: resumen.creadas,
              ),
              _itemMetrica(
                context,
                icono: Icons.skip_next_outlined,
                color: c.suave,
                fondo: c.hundido,
                titulo: 'Omitidas',
                subtitulo: 'Transacciones ya existentes',
                valor: resumen.omitidas,
              ),
              if (resumen.errores > 0)
                _itemMetrica(
                  context,
                  icono: Icons.error_outline,
                  color: c.coralTexto,
                  fondo: c.coralFondo,
                  titulo: 'Errores',
                  subtitulo: 'No se pudieron procesar',
                  valor: resumen.errores,
                  colorValor: c.coralTexto,
                ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Widget _itemMetrica(
    BuildContext context, {
    required IconData icono,
    required Color color,
    required Color fondo,
    required String titulo,
    required String subtitulo,
    required int valor,
    Color? colorValor,
  }) {
    return FilaOpcion(
      leading: CirculoCategoria(icono: icono, color: color, fondo: fondo),
      titulo: titulo,
      subtitulo: subtitulo,
      trailing: Text(
        valor.toString(),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colorValor),
      ),
    );
  }
}
