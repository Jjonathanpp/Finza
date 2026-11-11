import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/widgets/avatar_inicial.dart';
import 'package:frontend/core/widgets/chip_estado.dart';
import 'package:frontend/core/widgets/tarjeta.dart';
import 'package:frontend/features/presupuestos/data/models/presupuesto.dart';
import 'package:frontend/features/presupuestos/presentation/widgets/barra_progreso_presupuesto.dart';
import 'package:frontend/core/widgets/monto.dart';

// "Cuánto gastó cada uno" en el detalle de un presupuesto de una cuenta compartida (t-13.2.2): cuánto gastó
// cada integrante, de mayor a menor como lo manda el backend, y qué parte del tope es. La barrita de cada
// uno lleva el color de su avatar; el verde, el ámbar y el coral quedan para el total.
class DesgloseIntegrantes extends StatelessWidget {
  const DesgloseIntegrantes({
    super.key,
    required this.presupuesto,
    required this.miPerfilId,
  });

  final Presupuesto presupuesto;
  final int? miPerfilId;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Semantics(
            header: true,
            child: Text('Cuánto gastó cada uno', style: textos.titleMedium?.copyWith(fontSize: 15)),
          ),
          if (presupuesto.montoGastado == 0)
            Text(
              'Todavía nadie gastó en ${presupuesto.categoriaNombre} este mes.',
              style: textos.bodySmall,
            ),
          for (final gasto in presupuesto.porPerfil)
            _FilaIntegrante(gasto: gasto, esVos: gasto.perfilId == miPerfilId),
        ],
      ),
    );
  }
}

class _FilaIntegrante extends StatelessWidget {
  const _FilaIntegrante({required this.gasto, required this.esVos});

  final GastoDePerfil gasto;
  final bool esVos;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    final negrita = textos.bodyMedium?.copyWith(fontWeight: FontWeight.w700);
    final color = esVos ? c.barra : c.serie[gasto.perfilId % c.serie.length];

    return Row(
      spacing: 10,
      children: [
        AvatarInicial(gasto.nombre, serie: esVos ? null : gasto.perfilId),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 6,
            children: [
              Row(
                spacing: 8,
                children: [
                  Expanded(
                    child: Row(
                      spacing: 6,
                      children: [
                        Flexible(
                          child: Text(gasto.nombre, maxLines: 1, overflow: TextOverflow.ellipsis, style: negrita),
                        ),
                        if (esVos) const ChipEstado('vos', TonoChip.menta, chico: true),
                        if (!gasto.activo) const ChipEstado('ya no está', TonoChip.hundido, chico: true),
                      ],
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      text: Monto.texto(gasto.gastado),
                      style: negrita,
                      children: [
                        TextSpan(
                          text: ' · ${textoPorcentaje(gasto.porcentaje)}',
                          style: TextStyle(fontWeight: FontWeight.w600, color: c.suave),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // La barra de cada uno: el riel (.pista) y el relleno con el color de la persona.
              ExcludeSemantics(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(color: c.pista, borderRadius: BorderRadius.circular(Radios.pastilla)),
                  child: FractionallySizedBox(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: (gasto.porcentaje / 100).clamp(0.0, 1.0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(Radios.pastilla)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
