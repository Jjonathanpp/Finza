import 'package:frontend/features/panel/data/models/resumen_gastos.dart';

class ComparacionPeriodos {
  const ComparacionPeriodos({
    required this.granularidad,
    required this.periodos,
  });

  final String granularidad;
  final List<PeriodoComparacion> periodos;

  factory ComparacionPeriodos.fromJson(Map<String, dynamic> json) =>
      ComparacionPeriodos(
        granularidad: json['granularidad'] as String,
        periodos: (json['periodos'] as List)
            .map((p) => PeriodoComparacion.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}

class PeriodoComparacion {
  const PeriodoComparacion({
    required this.etiqueta,
    required this.fechaInicio,
    required this.fechaFin,
    required this.ingresos,
    required this.egresos,
    required this.saldo,
    this.variacionIngresos,
    this.variacionEgresos,
    this.categorias = const [],
  });

  final String etiqueta;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final double ingresos;
  final double egresos;
  final double saldo;
  // Porcentaje de variación respecto del período anterior (null si es el primero).
  final double? variacionIngresos;
  final double? variacionEgresos;
  final List<GastoCategoria> categorias;

  factory PeriodoComparacion.fromJson(Map<String, dynamic> json) =>
      PeriodoComparacion(
        etiqueta: json['etiqueta'] as String,
        fechaInicio: DateTime.parse(json['fechaInicio'] as String),
        fechaFin: DateTime.parse(json['fechaFin'] as String),
        ingresos: (json['ingresos'] as num).toDouble(),
        egresos: (json['egresos'] as num).toDouble(),
        saldo: (json['saldo'] as num).toDouble(),
        variacionIngresos: json['variacionIngresos'] == null
            ? null
            : (json['variacionIngresos'] as num).toDouble(),
        variacionEgresos: json['variacionEgresos'] == null
            ? null
            : (json['variacionEgresos'] as num).toDouble(),
        categorias: json['categorias'] == null
            ? const []
            : (json['categorias'] as List)
                .map((c) => GastoCategoria.fromJson(c as Map<String, dynamic>))
                .toList(),
      );
}