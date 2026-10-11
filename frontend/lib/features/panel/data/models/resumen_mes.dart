// Lo que la tarjeta usa de GET /api/panel/resumen (T-5.1.1). El resto (totales, últimos
// movimientos) se suma acá cuando una pantalla lo necesite.
class ResumenMes {
  const ResumenMes({
    required this.saldoTotal,
    required this.saldoMes,
    this.totalIngresos = 0.0,
    this.totalEgresos = 0.0,
  });

  // Tipo billetera: todo lo que entró menos todo lo que salió, desde el primer movimiento.
  final double saldoTotal;
  // Ingresos menos egresos del mes (el período de las preferencias del perfil, mensual por defecto).
  final double saldoMes;
  final double totalIngresos;
  final double totalEgresos;

  factory ResumenMes.fromJson(Map<String, dynamic> json) => ResumenMes(
        saldoTotal: (json['saldoTotal'] as num).toDouble(),
        saldoMes: (json['saldo'] as num).toDouble(),
        totalIngresos: (json['totalIngresos'] as num?)?.toDouble() ?? 0.0,
        totalEgresos: (json['totalEgresos'] as num?)?.toDouble() ?? 0.0,
      );
}