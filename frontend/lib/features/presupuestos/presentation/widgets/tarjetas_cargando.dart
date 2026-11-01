import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';

// Mientras llegan los presupuestos del mes (t-13.2.2): tarjetas grises con la forma de las de verdad,
// que laten, en vez de una ruedita en el medio. Con "reducir animaciones" del teléfono, quietas.
class TarjetasCargando extends StatefulWidget {
  const TarjetasCargando({super.key});

  @override
  State<TarjetasCargando> createState() => _TarjetasCargandoState();
}

class _TarjetasCargandoState extends State<TarjetasCargando> with SingleTickerProviderStateMixin {
  late final _latido = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
    lowerBound: 0.55,
    value: 1,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _latido.stop();
      _latido.value = 1;
    } else if (!_latido.isAnimating) {
      _latido.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _latido.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cargando presupuestos',
      child: ExcludeSemantics(
        child: FadeTransition(
          opacity: _latido,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final ancho in const [120.0, 96.0, 140.0])
                Padding(padding: const EdgeInsets.only(bottom: 16), child: _TarjetaGris(anchoNombre: ancho)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaGris extends StatelessWidget {
  const _TarjetaGris({required this.anchoNombre});

  final double anchoNombre;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [_Barra(ancho: anchoNombre, alto: 14), const _Barra(ancho: 44, alto: 14)],
          ),
          const SizedBox(height: 14),
          const _Barra(alto: 8),
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [_Barra(ancho: 110, alto: 12), _Barra(ancho: 90, alto: 12)],
          ),
        ],
      ),
    );
  }
}

class _Barra extends StatelessWidget {
  const _Barra({this.ancho = double.infinity, required this.alto});

  final double ancho;
  final double alto;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ancho,
      height: alto,
      decoration: BoxDecoration(color: AppColors.surface3, borderRadius: BorderRadius.circular(alto / 2)),
    );
  }
}
