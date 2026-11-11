import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';

// Un círculo verde con un tilde que se dibuja y el mensaje abajo: sube desde abajo de la pantalla, rebota y vuelve a bajar.
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
  static const _total = Duration(milliseconds: 1800);

  late final _controlador = AnimationController(vsync: this, duration: _total);

  // 0 = escondido abajo de la pantalla, 1 = arriba, en su lugar.
  late final _subida = TweenSequence<double>([
    // Sube con rebote, como un resorte.
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 50),
    // Se queda un momento.
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 25),
    // Toma un poco de impulso y baja hasta desaparecer.
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeInBack)), weight: 25),
  ]).animate(_controlador);

  // El tilde (.dibuja): espera Duraciones.dibujaRetraso y se dibuja en Duraciones.dibuja.
  late final _tilde = CurvedAnimation(
    parent: _controlador,
    curve: Interval(
      Duraciones.dibujaRetraso.inMilliseconds / _total.inMilliseconds,
      (Duraciones.dibujaRetraso + Duraciones.dibuja).inMilliseconds / _total.inMilliseconds,
      curve: Curvas.salida,
    ),
  );

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
    final colores = context.colores;
    // Con "reducir animaciones" el tilde aparece ya dibujado.
    final sinAnimar = MediaQuery.disableAnimationsOf(context);
    return IgnorePointer(
      child: Semantics(
        liveRegion: true,
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
              DecoratedBox(
                decoration: BoxDecoration(color: colores.menta, shape: BoxShape.circle, boxShadow: colores.sombra),
                child: SizedBox(
                  width: _tamanio,
                  height: _tamanio,
                  child: AnimatedBuilder(
                    animation: _tilde,
                    builder: (context, _) => CustomPaint(
                      painter: _PintorTilde(color: colores.primario, avance: sinAnimar ? 1 : _tilde.value),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Material porque el Overlay está fuera de la pantalla y el texto necesita uno para verse bien.
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colores.tarjeta,
                  borderRadius: BorderRadius.circular(Radios.pastilla),
                  boxShadow: colores.sombra,
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Text(
                      widget.mensaje,
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(fontSize: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// El anillo y el tilde de la maqueta (viewBox de 36: círculo r16 y el camino M11 18.5 l5 5 9-10), a escala.
// El tilde se va dibujando según avance, de 0 a 1.
class _PintorTilde extends CustomPainter {
  _PintorTilde({required this.color, required this.avance});

  final Color color;
  final double avance;

  @override
  void paint(Canvas canvas, Size size) {
    final escala = size.width / 36 * 0.8;
    final desvio = (size.width - 36 * escala) / 2;
    canvas.save();
    canvas.translate(desvio, desvio);
    canvas.scale(escala);

    final pincel = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawCircle(const Offset(18, 18), 16, pincel..strokeWidth = 3);

    final tilde = Path()
      ..moveTo(11, 18.5)
      ..relativeLineTo(5, 5)
      ..relativeLineTo(9, -10);
    final metrica = tilde.computeMetrics().first;
    canvas.drawPath(metrica.extractPath(0, metrica.length * avance), pincel..strokeWidth = 3.2);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PintorTilde anterior) => anterior.avance != avance || anterior.color != color;
}
