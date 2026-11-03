class Presupuesto {
  const Presupuesto({
    required this.presupuestoId,
    required this.categoriaId,
    required this.categoriaNombre,
    required this.categoriaColor,
    required this.montoTope,
    required this.montoGastado,
    required this.porcentajeConsumo,
    this.porPerfil = const [],
  });

  final int presupuestoId;
  final int categoriaId;
  final String categoriaNombre;
  final String categoriaColor;
  final double montoTope;
  final double montoGastado;
  final double porcentajeConsumo;
  // Cuánto gastó cada integrante (t-13.2.2): solo en una cuenta compartida; en la personal, vacía.
  final List<GastoDePerfil> porPerfil;

  bool get alertaAlcanzada => porcentajeConsumo >= 80.0;

  factory Presupuesto.fromJson(Map<String, dynamic> json) => Presupuesto(
        presupuestoId: json['presupuestoId'] as int? ?? 0,
        categoriaId: json['categoriaId'] as int? ?? 0,
        categoriaNombre: json['categoriaNombre']?.toString() ?? 'Sin categoría',
        categoriaColor: json['categoriaColor']?.toString() ?? '#2196F3',
        montoTope: json['montoTope'] != null ? (json['montoTope'] as num).toDouble() : 0.0,
        montoGastado: json['montoGastado'] != null ? (json['montoGastado'] as num).toDouble() : 0.0,
        porcentajeConsumo: json['porcentajeConsumo'] != null ? (json['porcentajeConsumo'] as num).toDouble() : 0.0,
        porPerfil: (json['porPerfil'] as List<dynamic>? ?? [])
            .map((g) => GastoDePerfil.fromJson(g as Map<String, dynamic>))
            .toList(),
      );
}

// Lo que gastó un integrante en la categoría del presupuesto. porcentaje: qué parte del tope es.
// activo: false si se dio de baja (su perfil queda en la cuenta compartida con lo que cargó).
class GastoDePerfil {
  const GastoDePerfil({
    required this.perfilId,
    required this.nombre,
    required this.gastado,
    required this.porcentaje,
    this.activo = true,
  });

  final int perfilId;
  final String nombre;
  final double gastado;
  final double porcentaje;
  final bool activo;

  factory GastoDePerfil.fromJson(Map<String, dynamic> json) => GastoDePerfil(
        perfilId: json['perfilId'] as int? ?? 0,
        nombre: json['nombre']?.toString() ?? '',
        gastado: json['gastado'] != null ? (json['gastado'] as num).toDouble() : 0.0,
        porcentaje: json['porcentaje'] != null ? (json['porcentaje'] as num).toDouble() : 0.0,
        activo: json['activo'] as bool? ?? true,
      );
}
