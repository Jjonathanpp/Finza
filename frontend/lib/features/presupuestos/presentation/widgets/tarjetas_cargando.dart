import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/widgets/esqueleto.dart';
import 'package:frontend/core/widgets/tarjeta.dart';

// Mientras llegan los presupuestos del mes (t-13.2.2): tarjetas con la forma de las de verdad hechas de
// Esqueleto (bloques grises con un destello). No lleva padding horizontal: lo pone la pantalla. Con
// "reducir animaciones" del teléfono, quietas.
class TarjetasCargando extends StatelessWidget {
  const TarjetasCargando({super.key, this.cantidad = 4});

  final int cantidad;

  // El ancho de la línea del nombre en cada tarjeta, para que no sean todas iguales.
  static const _nombres = [120.0, 96.0, 140.0, 108.0];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: 'Cargando presupuestos',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            for (var i = 0; i < cantidad; i++) _TarjetaEsqueleto(anchoNombre: _nombres[i % _nombres.length]),
          ],
        ),
      ),
    );
  }
}

class _TarjetaEsqueleto extends StatelessWidget {
  const _TarjetaEsqueleto({required this.anchoNombre});

  final double anchoNombre;

  @override
  Widget build(BuildContext context) {
    return Tarjeta(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Row(
            spacing: 12,
            children: [
              const Esqueleto(ancho: 36, alto: 36, radio: Radios.pastilla),
              Esqueleto(ancho: anchoNombre, alto: 12, radio: Radios.pastilla),
              const Spacer(),
              const Esqueleto(ancho: 40, alto: 12, radio: Radios.pastilla),
            ],
          ),
          const Esqueleto(alto: 8, radio: Radios.pastilla),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Esqueleto(ancho: 110, alto: 10, radio: Radios.pastilla),
              Esqueleto(ancho: 80, alto: 10, radio: Radios.pastilla),
            ],
          ),
        ],
      ),
    );
  }
}
