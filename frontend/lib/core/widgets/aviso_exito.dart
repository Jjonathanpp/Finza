import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';

// Un círculo verde con un tilde y el mensaje abajo: sube desde abajo de la pantalla, rebota y vuelve a bajar.
// Se dibuja en el Overlay (la capa de arriba de todas las pantallas) y se saca solo al terminar.
void mostrarExito(BuildContext context, String mensaje) {
  late final OverlayEntry entrada;
  entrada = OverlayEntry(
    builder: (_) => _TildeQueSalta(mensaje: mensaje, alTerminar: () => entrada.remove()),
  );
  Overlay.of(context).insert(entrada);
}

class _TildeQueSalta extends StatefulWidget {
  const _TildeQueSalta({required this.mensaje, required this.alTerminar});

  final String mensaje;
  final VoidCallback alTerminar;

  @override
  State<_TildeQueSalta> createState() => _TildeQueSaltaState();
}

class _TildeQueSaltaState extends State<_TildeQueSalta> with SingleTickerProviderStateMixin {
  static const _tamanio = 96.0;
  // Lo que mide todo junto (círculo + mensaje), para esconderlo entero debajo del borde.
  static const _altoTotal = 160.0;

  late final _controlador = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

  // 0 = escondido abajo de la pantalla, 1 = arriba, en su lugar.
  late final _subida = TweenSequence<double>([
    // Sube con rebote, como un resorte.
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 50),
    // Se queda un momento.
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 25),
    // Toma un poco de impulso y baja hasta desaparecer.
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeInBack)), weight: 25),
  ]).animate(_controlador);

  @override
  void initState() {
    super.initState();
    _controlador.forward().whenComplete(widget.alTerminar);
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _subida,
        builder: (context, aviso) {
          final alto = MediaQuery.sizeOf(context).height;
          // Arriba queda al 30% de la pantalla, contando desde abajo; escondido, debajo del borde.
          final desdeAbajo = -_altoTotal + _subida.value * (alto * 0.3 + _altoTotal);
          return Stack(
            children: [Positioned(left: 0, right: 0, bottom: desdeAbajo, child: aviso!)],
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _tamanio,
              height: _tamanio,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 58),
            ),
            const SizedBox(height: 12),
            // Material porque el Overlay está fuera de la pantalla y el texto necesita uno para verse bien.
            Material(
              color: AppColors.surface,
              elevation: 2,
              shape: const StadiumBorder(side: BorderSide(color: AppColors.line)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                child: Text(
                  widget.mensaje,
                  style: const TextStyle(color: AppColors.text, fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
