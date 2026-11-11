import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/widgets/campo.dart';
import 'package:frontend/core/widgets/tocable.dart';

// .caja de la maqueta con una fecha: un recuadro hundido de 48 px que, al tocarlo, abre el selector de fecha.
// Sin fecha muestra textoVacio, en suave. Con etiqueta lleva arriba su título (.campo); sin etiqueta va
// dentro de un Campo que lo pone.
class CajaFecha extends StatelessWidget {
  const CajaFecha({
    super.key,
    required this.fecha,
    required this.alTocar,
    this.etiqueta,
    this.textoVacio = 'Elegir',
  });

  final DateTime? fecha;
  final VoidCallback alTocar;
  final String? etiqueta;
  final String textoVacio;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    String dos(int n) => n.toString().padLeft(2, '0');
    final f = fecha;
    final texto = f == null ? textoVacio : '${dos(f.day)}/${dos(f.month)}/${f.year}';
    final caja = Tocable(
      alTocar: alTocar,
      etiqueta: '${etiqueta ?? 'Fecha'}: $texto',
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: c.hundido,
          borderRadius: BorderRadius.circular(Radios.control),
        ),
        child: Row(
          spacing: 8,
          children: [
            Expanded(
              child: Text(
                texto,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: f == null ? c.suave : c.texto,
                  fontWeight: f == null ? FontWeight.w500 : null,
                ),
              ),
            ),
            Icon(Icons.calendar_today_outlined, size: 18, color: c.suave),
          ],
        ),
      ),
    );
    final titulo = etiqueta;
    return titulo == null ? caja : Campo(etiqueta: titulo, child: caja);
  }
}
