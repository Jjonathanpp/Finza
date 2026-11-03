enum EstadoInvitacion {
  pendiente,
  aceptada,
  rechazada,
  expirada,
  cancelada;

  static EstadoInvitacion desdeTexto(String valor) {
    return EstadoInvitacion.values.firstWhere(
      (e) => e.name.toUpperCase() == valor.toUpperCase(),
      orElse: () => EstadoInvitacion.pendiente,
    );
  }
}

class InvitacionEnviada {
  final int id;
  final String emailInvitado;
  final EstadoInvitacion estado;
  final DateTime fechaExpiracion;

  InvitacionEnviada({
    required this.id,
    required this.emailInvitado,
    required this.estado,
    required this.fechaExpiracion,
  });

  factory InvitacionEnviada.fromJson(Map<String, dynamic> json) {
    return InvitacionEnviada(
      id: json['id'] as int,
      emailInvitado: json['emailInvitado'] as String,
      estado: EstadoInvitacion.desdeTexto(json['estado'] as String),
      fechaExpiracion: DateTime.parse(json['fechaExpiracion'] as String),
    );
  }
}
