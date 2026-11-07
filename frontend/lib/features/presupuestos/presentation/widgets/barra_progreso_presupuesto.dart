import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';

// El color de un presupuesto según cuánto se usó, en degradé continuo:
// 0% verde → 50% amarillo → 100% (o más) rojo. Se mezcla en HSV para que los
// intermedios sean vivos (verde lima, naranja) y no marrones.
const _verde = Color(0xFF22A45D);
const _amarillo = Color(0xFFF5C21B);
const _rojo = AppColors.danger;

Color colorPorConsumo(double porcentaje) {
  final p = porcentaje.isNaN ? 0.0 : porcentaje.clamp(0.0, 100.0);
  return p <= 50
      ? _mezclar(_verde, _amarillo, p / 50)
      : _mezclar(_amarillo, _rojo, (p - 50) / 50);
}

// El mismo tono, oscurecido para que se lea como texto sobre fondo claro
// (el amarillo puro sobre blanco casi no se ve).
Color colorTextoPorConsumo(double porcentaje) => oscurecerParaTexto(colorPorConsumo(porcentaje));

Color oscurecerParaTexto(Color color) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withLightness(hsl.lightness.clamp(0.0, 0.36)).toColor();
}

Color _mezclar(Color a, Color b, double t) =>
    HSVColor.lerp(HSVColor.fromColor(a), HSVColor.fromColor(b), t)!.toColor();

// Barra de consumo: se llena con un degradé desde el verde hasta el color que
// corresponde al porcentaje, y crece animada (quieta con "reducir animaciones").
//
// Se dibuja con CustomPaint y no con FractionallySizedBox: ese, con la animación en 0 %,
// informa un ancho infinito cuando un padre pregunta su tamaño "natural" (lo hace
// AlertDialog), y el cuadro de aviso de presupuesto no se podía dibujar.
class BarraProgresoPresupuesto extends StatelessWidget {
  const BarraProgresoPresupuesto({
    super.key,
    required this.porcentaje,
    this.altura = 8,
  });

  final double porcentaje;
  final double altura;

  @override
  Widget build(BuildContext context) {
    final valor = (porcentaje / 100).clamp(0.0, 1.0);
    final animar = !MediaQuery.disableAnimationsOf(context);

    return Semantics(
      label: 'Consumo del presupuesto',
      value: '${porcentaje.toStringAsFixed(0)}%',
      child: SizedBox(
        width: double.infinity,
        height: altura,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: valor),
          duration: animar ? const Duration(milliseconds: 650) : Duration.zero,
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => CustomPaint(painter: _PintorBarra(v)),
        ),
      ),
    );
  }
}

class _PintorBarra extends CustomPainter {
  _PintorBarra(this.valor);

  // Cuánto se llena, de 0 a 1.
  final double valor;

  @override
  void paint(Canvas canvas, Size size) {
    final radio = Radius.circular(size.height / 2);

    // El fondo, toda la barra
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, radio),
      Paint()..color = AppColors.surface3,
    );

    if (valor <= 0) return;

    // Lo consumido, con el degradé hasta el color del porcentaje
    final lleno = Rect.fromLTWH(0, 0, size.width * valor, size.height);
    canvas.drawRRect(
      RRect.fromRectAndRadius(lleno, radio),
      Paint()
        ..shader = LinearGradient(
          colors: [colorPorConsumo(0), colorPorConsumo(valor * 100)],
        ).createShader(lleno),
    );
  }

  @override
  bool shouldRepaint(_PintorBarra anterior) => anterior.valor != valor;
}