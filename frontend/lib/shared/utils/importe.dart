import 'package:flutter/foundation.dart';

// Punto de miles: 1250000 → 1.250.000.
String miles(int numero) => numero.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');

// En qué moneda se ven los montos (US-8.2): PESO, DOLAR o EURO, con los pesos que vale uno
// (la cotización oficial del día, que da el backend). Todo se guarda en pesos: para mostrarlo
// se divide por la cotización. Sin cotización se ve en pesos.
typedef MonedaVista = ({String moneda, double? cotizacion, DateTime? actualizada});

const MonedaVista enPesos = (moneda: 'PESO', cotizacion: null, actualizada: null);

// La elegida, para toda la app: la pide PantallaPrincipal al entrar y la cambia Configuración.
final monedaVista = ValueNotifier<MonedaVista>(enPesos);

MonedaVista monedaDesdeJson(Map<String, dynamic> json) => (
      moneda: json['moneda'] as String,
      cotizacion: (json['cotizacion'] as num?)?.toDouble(),
      actualizada: json['actualizada'] == null ? null : DateTime.parse(json['actualizada'] as String).toLocal(),
    );

bool get convierte => monedaVista.value.moneda != 'PESO' && monedaVista.value.cotizacion != null;

String get simboloMoneda => !convierte ? '\$' : (monedaVista.value.moneda == 'DOLAR' ? 'US\$' : '€');

String get nombreMoneda => !convierte ? 'Pesos' : (monedaVista.value.moneda == 'DOLAR' ? 'Dólares' : 'Euros');

// De dónde sale la conversión, para mostrarlo una vez (no en cada monto): "Dólar oficial: $ 1.540 · 20/10".
String? get aclaracionCotizacion {
  if (!convierte) return null;
  final m = monedaVista.value;
  final fecha = m.actualizada == null ? '' : ' · ${m.actualizada!.day}/${m.actualizada!.month}';
  return '${m.moneda == 'DOLAR' ? 'Dólar' : 'Euro'} oficial: \$ ${miles(m.cotizacion!.round())}$fecha';
}

double enMonedaVista(double pesos) => convierte ? pesos / monedaVista.value.cotizacion! : pesos;

// Un monto en pesos, en la moneda elegida. Los pesos, como en la maqueta: sin centavos y con punto
// de miles (200000 → $ 200.000, -5000 → −$ 5.000), salvo que se pidan. Dólares y euros siempre con
// centavos, porque son montos chicos (15400 con el dólar a 1540 → US$ 10,00).
String importe(double pesos, {bool centavos = false}) {
  final valor = enMonedaVista(pesos);
  final enCentavos = (valor.abs() * 100).round();
  final numero = centavos || convierte
      ? '${miles(enCentavos ~/ 100)},${(enCentavos % 100).toString().padLeft(2, '0')}'
      : miles(valor.abs().round());
  return '${valor < 0 ? '−' : ''}$simboloMoneda $numero';
}
