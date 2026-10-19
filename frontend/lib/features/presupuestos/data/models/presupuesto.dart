class Presupuesto {
  const Presupuesto({
    required this.presupuestoId,
    required this.categoriaId,
    required this.categoriaNombre,
    required this.categoriaColor,
    required this.montoTope,
    required this.montoGastado,
    required this.porcentajeConsumo,
  });

  final int presupuestoId;
  final int categoriaId;
  final String categoriaNombre;
  final String categoriaColor;
  final double montoTope;
  final double montoGastado;
  final double porcentajeConsumo;

  bool get alertaAlcanzada => porcentajeConsumo >= 80.0;

  factory Presupuesto.fromJson(Map<String, dynamic> json) => Presupuesto(
        presupuestoId: json['presupuestoId'] as int? ?? 0,
        categoriaId: json['categoriaId'] as int? ?? 0,
        categoriaNombre: json['categoriaNombre']?.toString() ?? 'Sin categoría',
        categoriaColor: json['categoriaColor']?.toString() ?? '#2196F3',
        montoTope: json['montoTope'] != null ? (json['montoTope'] as num).toDouble() : 0.0,
        montoGastado: json['montoGastado'] != null ? (json['montoGastado'] as num).toDouble() : 0.0,
        porcentajeConsumo: json['porcentajeConsumo'] != null ? (json['porcentajeConsumo'] as num).toDouble() : 0.0,
      );
}