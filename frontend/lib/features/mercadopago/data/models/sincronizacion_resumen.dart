class SincronizacionResumen {
  final int procesadas;
  final int creadas;
  final int omitidas;
  final int errores;

  const SincronizacionResumen({
    required this.procesadas,
    required this.creadas,
    required this.omitidas,
    required this.errores,
  });

  factory SincronizacionResumen.fromJson(Map<String, dynamic> json) =>
      SincronizacionResumen(
        procesadas: json['procesadas'] as int? ?? 0,
        creadas: json['creadas'] as int? ?? 0,
        omitidas: json['omitidas'] as int? ?? 0,
        errores: json['errores'] as int? ?? 0,
      );
}