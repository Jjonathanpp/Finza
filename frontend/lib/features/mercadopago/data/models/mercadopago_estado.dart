class MercadoPagoEstado {
  const MercadoPagoEstado({
    required this.conectado,
    this.mpUserId,
  });

  final bool conectado;
  final String? mpUserId;

  factory MercadoPagoEstado.fromJson(Map<String, dynamic> json) =>
      MercadoPagoEstado(
        conectado: json['conectado'] as bool? ?? false,
        mpUserId: json['mpUserId']?.toString(),
      );
}