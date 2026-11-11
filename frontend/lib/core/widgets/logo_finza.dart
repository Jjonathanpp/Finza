import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';

// El logo de Finza de la maqueta (svg de viewBox 108): fondo redondeado, la F y la hoja. Es la marca,
// por eso lleva los mismos colores en claro y en oscuro.
class LogoFinza extends StatelessWidget {
  const LogoFinza({super.key, this.tamano = 72});

  final double tamano;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: tamano,
        height: tamano,
        child: const CustomPaint(painter: _PintorLogo()),
      ),
    );
  }
}

class _PintorLogo extends CustomPainter {
  const _PintorLogo();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 108);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 108, 108),
        const Radius.circular(28),
      ),
      Paint()..color = const Color(0xFF15784F),
    );
    canvas.translate(54, 54);
    canvas.scale(.74);
    canvas.translate(-58, -50);

    final letra = Path()
      ..moveTo(39, 78)
      ..lineTo(39, 33.5)
      ..moveTo(39, 33.5)
      ..lineTo(61, 33.5)
      ..moveTo(39, 55.5)
      ..lineTo(56, 55.5);
    canvas.drawPath(
      letra,
      Paint()
        ..color = const Color(0xFFF4F2EC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12.5
        ..strokeCap = StrokeCap.round,
    );

    final hoja = Path()
      ..moveTo(61, 33.5)
      ..cubicTo(63, 21, 74, 14.5, 86, 16)
      ..cubicTo(85.5, 28.5, 75, 37, 61, 33.5)
      ..close();
    canvas.drawPath(hoja, Paint()..color = const Color(0xFF9BE3BF));

    // La nervadura de la hoja.
    final nervadura = Path()
      ..moveTo(64, 31.8)
      ..cubicTo(70, 26.5, 76.5, 21.8, 83.2, 18.8);
    canvas.drawPath(
      nervadura,
      Paint()
        ..color = const Color(0xFF15784F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_PintorLogo anterior) => false;
}

// El nombre "finza" de la maqueta: la i sin punto lleva una hojita arriba. Va en el texto del tema
// (displaySmall, 40/800) con la hoja posicionada en proporción al tamaño de la letra.
class NombreFinza extends StatelessWidget {
  const NombreFinza({super.key});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.displaySmall;
    final tamano = base?.fontSize ?? 40;
    final estilo = base?.copyWith(
      color: context.colores.texto,
      letterSpacing: -tamano * .03,
      height: 1,
    );
    final anchoHoja = tamano * .36;
    return Semantics(
      label: 'Finza',
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          style: estilo,
          children: [
            const TextSpan(text: 'f'),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Text('ı', style: estilo),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Transform.translate(
                        offset: Offset(anchoHoja * .2, tamano * .02),
                        child: CustomPaint(
                          size: Size(anchoHoja, tamano * .29),
                          painter: const _PintorHoja(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const TextSpan(text: 'nza'),
          ],
        ),
      ),
    );
  }
}

// La hojita sobre la i (viewBox de 30 x 24 en la maqueta).
class _PintorHoja extends CustomPainter {
  const _PintorHoja();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 30, size.height / 24);
    final hoja = Path()
      ..moveTo(2, 20)
      ..cubicTo(4, 9, 13, 3, 28, 3)
      ..cubicTo(27, 14, 18, 22, 2, 20)
      ..close();
    canvas.drawPath(hoja, Paint()..color = const Color(0xFF34C185));
  }

  @override
  bool shouldRepaint(_PintorHoja anterior) => false;
}
