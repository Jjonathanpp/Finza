import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/features/presupuestos/data/models/presupuesto.dart';
import 'package:frontend/shared/utils/importe.dart';

// Lo que se ve al abrir la tarjeta de un presupuesto de una cuenta compartida (t-13.2.2): cuánto gastó
// cada integrante, de mayor a menor como lo manda el backend. La barrita de cada uno es gris a
// propósito: verde, amarillo y rojo quedan para el total. Si sos admin, abajo, "Editar tope".
class DesgloseIntegrantes extends StatelessWidget {
  const DesgloseIntegrantes({
    super.key,
    required this.presupuesto,
    required this.miPerfilId,
    this.alEditar,
  });

  final Presupuesto presupuesto;
  final int? miPerfilId;
  final VoidCallback? alEditar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, bottom: alEditar == null ? 16 : 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, thickness: 1, color: AppColors.line),
          const SizedBox(height: 14),
          const Text(
            'Cuánto gastó cada uno',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.muted),
          ),
          if (presupuesto.montoGastado == 0) ...[
            const SizedBox(height: 10),
            Text(
              'Todavía nadie gastó en ${presupuesto.categoriaNombre} este mes.',
              style: const TextStyle(fontSize: 13, height: 1.45, color: AppColors.muted),
            ),
          ],
          for (final gasto in presupuesto.porPerfil) ...[
            const SizedBox(height: 14),
            _FilaIntegrante(gasto: gasto, esVos: gasto.perfilId == miPerfilId),
          ],
          if (alEditar != null) ...[
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: alEditar,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Editar tope', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          ],
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
    const numeros = [FontFeature.tabularFigures()];
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surface2,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.line),
              ),
              child: Text(
                gasto.nombre.isEmpty ? '?' : gasto.nombre.characters.first.toUpperCase(),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(gasto.nombre, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
                  ),
                  if (esVos) ...[
                    const SizedBox(width: 6),
                    _Etiqueta('vos', fondo: AppColors.accent.withValues(alpha: 0.12), colorTexto: AppColors.text),
                  ],
                  if (!gasto.activo) ...[
                    const SizedBox(width: 6),
                    const _Etiqueta('ya no está', fondo: AppColors.surface3, colorTexto: AppColors.muted),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              importe(gasto.gastado),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, fontFeatures: numeros),
            ),
            SizedBox(
              width: 52,
              child: Text(
                '${gasto.porcentaje.toStringAsFixed(1)}%',
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 13, color: AppColors.muted, fontFeatures: numeros),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 38),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: (gasto.porcentaje / 100).clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: AppColors.surface3,
              valueColor: const AlwaysStoppedAnimation(AppColors.muted),
            ),
          ),
        ),
      ],
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta(this.texto, {required this.fondo, required this.colorTexto});

  final String texto;
  final Color fondo;
  final Color colorTexto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(6)),
      child: Text(texto, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: colorTexto)),
    );
  }
}
