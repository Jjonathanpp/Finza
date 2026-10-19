import 'package:frontend/features/categorias/data/models/categoria.dart';

class Presupuesto {
  const Presupuesto({
    required this.id,
    required this.categoria,
    required this.montoMaximo,
    required this.montoGastado,
    required this.mes,
    required this.anio,
  });

  final int id;
  final Categoria categoria;
  final double montoMaximo;
  final double montoGastado;
  final int mes;
  final int anio;

  double get porcentajeConsumido => montoMaximo > 0 ? (montoGastado / montoMaximo) : 0.0;
  bool get alertaAlcanzada => porcentajeConsumido >= 0.8;

  factory Presupuesto.fromJson(Map<String, dynamic> json) => Presupuesto(
        id: json['id'],
        categoria: Categoria.fromJson(json['categoria']),
        montoMaximo: (json['montoMaximo'] as num).toDouble(),
        montoGastado: (json['montoGastado'] as num).toDouble(),
        mes: json['mes'],
        anio: json['anio'],
      );
}