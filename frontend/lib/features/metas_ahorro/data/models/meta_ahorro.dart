class AporteMetaAhorro {
  const AporteMetaAhorro({
    required this.perfilId,
    required this.nombre,
    required this.monto,
  });

  final int perfilId;
  final String nombre;
  final double monto;

  factory AporteMetaAhorro.fromJson(Map<String, dynamic> json) =>
      AporteMetaAhorro(
        perfilId: json['perfilId'] as int,
        nombre: json['nombre'] as String,
        monto: (json['monto'] as num).toDouble(),
      );
}

class MetaAhorro {
  const MetaAhorro({
    required this.id,
    required this.nombre,
    required this.montoObjetivo,
    required this.montoActual,
    required this.montoRestante,
    this.cuotaDiaria,
    this.cuotaSemanal,
    this.cuotaMensual,
    this.fechaLimite,
    this.fechaCreacion,
    this.cuentaCompartidaId,
    this.aportes = const [],
  });

  final int id;
  final String nombre;
  final double montoObjetivo;
  final double montoActual;
  final double montoRestante;
  final double? cuotaDiaria;
  final double? cuotaSemanal;
  final double? cuotaMensual;
  final DateTime? fechaLimite;
  final DateTime? fechaCreacion;
  final int? cuentaCompartidaId;
  final List<AporteMetaAhorro> aportes;

  double get progreso =>
      montoObjetivo <= 0 ? 0 : (montoActual / montoObjetivo).clamp(0, 1);

  List<({String periodo, double monto})> cuotasRecomendadas({DateTime? hoy}) {
    final fecha = fechaLimite;
    if (fecha == null || montoRestante <= 0) return const [];

    final ahora = hoy ?? DateTime.now();
    final hoySinHora = DateTime(ahora.year, ahora.month, ahora.day);
    final limiteSinHora = DateTime(fecha.year, fecha.month, fecha.day);
    final inicioSemanaHoy = hoySinHora.subtract(
      Duration(days: hoySinHora.weekday - DateTime.monday),
    );
    final inicioSemanaLimite = limiteSinHora.subtract(
      Duration(days: limiteSinHora.weekday - DateTime.monday),
    );
    final mismaSemana = inicioSemanaHoy == inicioSemanaLimite;
    final creacion = fechaCreacion;
    final puedeMostrarMensual =
        creacion != null && !_agregarMeses(creacion, 1).isAfter(limiteSinHora);

    final cuotas = <({String periodo, double? monto})>[
      (periodo: 'diaria', monto: cuotaDiaria),
      if (!mismaSemana) (periodo: 'semanal', monto: cuotaSemanal),
      if (puedeMostrarMensual && cuotaMensual != null)
        (periodo: 'mensual', monto: cuotaMensual),
    ];

    return [
      for (final cuota in cuotas)
        if (cuota.monto != null) (periodo: cuota.periodo, monto: cuota.monto!),
    ];
  }

  factory MetaAhorro.fromJson(Map<String, dynamic> json) => MetaAhorro(
    id: json['id'] as int,
    nombre: json['nombre'] as String,
    montoObjetivo: (json['montoObjetivo'] as num).toDouble(),
    montoActual: (json['montoActual'] as num?)?.toDouble() ?? 0,
    montoRestante:
        (json['montoRestante'] as num?)?.toDouble() ??
        ((json['montoObjetivo'] as num).toDouble() -
                ((json['montoActual'] as num?)?.toDouble() ?? 0))
            .clamp(0, double.infinity),
    cuotaDiaria: (json['cuotaDiaria'] as num?)?.toDouble(),
    cuotaSemanal: (json['cuotaSemanal'] as num?)?.toDouble(),
    cuotaMensual: (json['cuotaMensual'] as num?)?.toDouble(),
    fechaLimite: json['fechaLimite'] == null
        ? null
        : DateTime.parse(json['fechaLimite'] as String),
    fechaCreacion: json['fechaCreacion'] == null
        ? null
        : DateTime.parse(json['fechaCreacion'] as String),
    cuentaCompartidaId: (json['cuentaCompartidaId'] as num?)?.toInt(),
    aportes: (json['aportes'] as List<dynamic>? ?? [])
        .map((item) => AporteMetaAhorro.fromJson(item as Map<String, dynamic>))
        .toList(),
  );
}

DateTime _agregarMeses(DateTime fecha, int meses) {
  final indiceMes = fecha.month - 1 + meses;
  final anio = fecha.year + indiceMes ~/ 12;
  final mes = indiceMes % 12 + 1;
  final ultimoDiaDelMes = DateTime(anio, mes + 1, 0).day;
  final dia = fecha.day < ultimoDiaDelMes ? fecha.day : ultimoDiaDelMes;
  return DateTime(anio, mes, dia);
}
