import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';

// .brillo de la maqueta: un bloque gris (hundido) con un destello que lo cruza cada 1,4 s. Es la pieza con
// la que se arma el estado "cargando". Con ancho null ocupa todo el ancho disponible. Queda quieto, sin
// destello, si el sistema pide reducir movimiento.
class Esqueleto extends StatefulWidget {
  const Esqueleto({
    super.key,
    this.ancho,
    required this.alto,
    this.radio = Radios.tarjeta,
  });

  final double? ancho;
  final double alto;
  final double radio;

  @override
  State<Esqueleto> createState() => _EsqueletoState();
}

class _EsqueletoState extends State<Esqueleto>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controlador = AnimationController(
    vsync: this,
    duration: Duraciones.brillo,
  );
  bool _corriendo = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final quieto = MediaQuery.disableAnimationsOf(context);
    if (quieto && _corriendo) {
      _controlador.stop();
      _corriendo = false;
    } else if (!quieto && !_corriendo) {
      _controlador.repeat();
      _corriendo = true;
    }
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final forma = BorderRadius.circular(widget.radio);
    return ExcludeSemantics(
      child: SizedBox(
        width: widget.ancho,
        height: widget.alto,
        child: AnimatedBuilder(
          animation: _controlador,
          builder: (context, _) => DecoratedBox(
            decoration: BoxDecoration(
              color: c.hundido,
              borderRadius: forma,
              gradient: _corriendo
                  ? LinearGradient(
                      // El gradiente de la maqueta mide el doble del bloque (background-size: 200%) y se corre
                      // de un lado al otro: de -1 a +1 veces el ancho.
                      begin: Alignment.centerLeft,
                      end: const Alignment(3, 0),
                      colors: [c.hundido, c.brillo, c.hundido],
                      stops: const [.25, .5, .75],
                      tileMode: TileMode.repeated,
                      transform: _Desliza(_controlador.value * 2 - 1),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _Desliza extends GradientTransform {
  const _Desliza(this.fraccion);

  final double fraccion;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * fraccion, 0, 0);
}

// El estado "cargando" de una pantalla (L647-655 de la maqueta): filas con un círculo, dos líneas y un
// monto a la derecha, que se repiten cantidad veces. Con conBloques = true arrastra arriba los bloques del
// inicio (la tarjeta grande, una tarjeta mediana y dos cuadrados). No lleva padding horizontal: lo pone la
// pantalla. Se lee como "Cargando".
class EsqueletoLista extends StatelessWidget {
  const EsqueletoLista({super.key, this.cantidad = 5, this.conBloques = false});

  final int cantidad;
  final bool conBloques;

  // Anchos de las dos líneas y del monto de cada fila, como en la maqueta (65/40, 55/35) y alternando.
  static const _filas = [(.65, .40, 60.0), (.55, .35, 52.0)];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: 'Cargando',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 14,
          children: [
            if (conBloques) ...[
              const Esqueleto(alto: 150, radio: Radios.destacada),
              const Esqueleto(alto: 96),
              const Row(
                spacing: 12,
                children: [
                  Expanded(child: Esqueleto(alto: 110)),
                  Expanded(child: Esqueleto(alto: 110)),
                ],
              ),
            ],
            for (var i = 0; i < cantidad; i++)
              _FilaEsqueleto(_filas[i % _filas.length]),
          ],
        ),
      ),
    );
  }
}

class _FilaEsqueleto extends StatelessWidget {
  const _FilaEsqueleto(this.medidas);

  final (double, double, double) medidas;

  @override
  Widget build(BuildContext context) {
    final (linea1, linea2, monto) = medidas;
    return Row(
      spacing: 12,
      children: [
        const Esqueleto(ancho: 40, alto: 40, radio: Radios.pastilla),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: [
              FractionallySizedBox(
                widthFactor: linea1,
                child: const Esqueleto(alto: 11, radio: Radios.pastilla),
              ),
              FractionallySizedBox(
                widthFactor: linea2,
                child: const Esqueleto(alto: 9, radio: Radios.pastilla),
              ),
            ],
          ),
        ),
        Esqueleto(ancho: monto, alto: 11, radio: Radios.pastilla),
      ],
    );
  }
}
