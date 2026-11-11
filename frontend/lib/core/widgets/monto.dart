import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/shared/utils/importe.dart';

// .monto de la maqueta (15/700, números tabulares) con el formato de importe.dart, o sea en la moneda
// elegida. Un ingreso se ve verde y con "+ $ 1.000"; un gasto, con el color del texto y "− $ 1.000";
// con ingreso null, el monto solo ("$ 1.000"). Pasá el valor en pesos y sin signo (se muestra el
// absoluto cuando hay ingreso o gasto). Los centavos se ven solo si el monto los tiene ("1.234,56", pero
// "1.234" y no "1.234,00"), y nunca se redondea.
class Monto extends StatelessWidget {
  const Monto(
    this.pesos, {
    super.key,
    this.ingreso,
    this.estilo,
  });

  final double pesos;
  final bool? ingreso;

  // Para cambiar algo del estilo (por ejemplo fontSize: 14); se mezcla con el estándar.
  final TextStyle? estilo;

  // "+ $ 1.000" / "− $ 1.000" / "$ 1.000". Sirve también para FilaMovimiento.monto.
  static String texto(double pesos, {bool? ingreso}) {
    // Con la moneda elegida: si el valor convertido tiene centavos, se muestran.
    final tieneCentavos = (enMonedaVista(pesos).abs() * 100).round() % 100 != 0;
    if (ingreso == null) return importe(pesos, centavos: tieneCentavos);
    return '${ingreso ? '+' : '−'} ${importe(pesos.abs(), centavos: tieneCentavos)}';
  }

  // Verde para un ingreso; para un gasto o un monto sin tipo, el color del texto.
  static Color color(BuildContext context, bool? ingreso) =>
      ingreso == true ? context.colores.primario : context.colores.texto;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.labelLarge;
    return Text(
      texto(pesos, ingreso: ingreso),
      maxLines: 1,
      softWrap: false,
      style: base?.copyWith(color: color(context, ingreso)).merge(estilo),
    );
  }
}
