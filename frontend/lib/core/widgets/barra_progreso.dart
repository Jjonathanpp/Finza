import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';

// Los colores del relleno: bv (barra, en regla), ba (ámbar, cerca del tope) y bc (coral, pasada).
enum TonoBarra { barra, ambar, coral }

// .pista de la maqueta: una barra de 8 px (10 con grande = true, .pista.g) con el relleno que crece hasta
// valor (de 0 a 1; si pasa de 1 se ve llena) en Duraciones.llenar. Sin animación si el sistema pide
// reducir movimiento. etiqueta es lo que lee el lector de pantalla además del porcentaje.
class BarraProgreso extends StatelessWidget {
  const BarraProgreso({
    super.key,
    required this.valor,
    this.tono = TonoBarra.barra,
    this.grande = false,
    this.etiqueta,
  });

  final double valor;
  final TonoBarra tono;
  final bool grande;
  final String? etiqueta;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final relleno = switch (tono) {
      TonoBarra.barra => c.barra,
      TonoBarra.ambar => c.ambar,
      TonoBarra.coral => c.coral,
    };
    final objetivo = valor.isNaN ? 0.0 : valor.clamp(0.0, 1.0);
    final sinAnimacion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: etiqueta,
      value: '${(objetivo * 100).round()}%',
      child: ExcludeSemantics(
        child: Container(
          height: grande ? 10 : 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: c.pista,
            borderRadius: BorderRadius.circular(Radios.pastilla),
          ),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: objetivo),
            duration: sinAnimacion ? Duration.zero : Duraciones.llenar,
            curve: Curvas.salida,
            builder: (context, factor, _) => Align(
              alignment: AlignmentDirectional.centerStart,
              child: FractionallySizedBox(
                widthFactor: factor,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: relleno,
                    borderRadius: BorderRadius.circular(Radios.pastilla),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
