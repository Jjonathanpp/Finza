// Lo que responde GET /api/panel/gastos-por-categoria (T-5.4.1): el total gastado en el mes
// y cada categoría con lo que se gastó en ella, ya ordenadas de mayor a menor.
class ResumenGastos {
  const ResumenGastos({required this.total, required this.categorias});

  final double total;
  final List<GastoCategoria> categorias;

  // Los montos llegan como número con o sin decimales (0, 120000.00), por eso el "as num".
  factory ResumenGastos.fromJson(Map<String, dynamic> json) => ResumenGastos(
        total: (json['total'] as num).toDouble(),
        categorias: (json['categorias'] as List).map((c) => GastoCategoria.fromJson(c)).toList(),
      );
}

class GastoCategoria {
  const GastoCategoria({
    required this.id,
    required this.nombre,
    this.color,
    required this.total,
    required this.porcentaje,
  });

  final int id;
  final String nombre;
  final String? color;
  final double total;
  // Qué parte del gasto del mes es: 33.3 quiere decir 33,3 %.
  final double porcentaje;

  factory GastoCategoria.fromJson(Map<String, dynamic> json) => GastoCategoria(
        id: json['id'],
        nombre: json['nombre'],
        color: json['color'],
        total: (json['total'] as num).toDouble(),
        porcentaje: (json['porcentaje'] as num).toDouble(),
      );
}
