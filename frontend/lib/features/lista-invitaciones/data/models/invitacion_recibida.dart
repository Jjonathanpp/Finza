import 'package:frontend/features/lista-invitaciones/data/models/invitacion_enviada.dart';

// Lo que ve quien abre el enlace de una invitación (POST /api/invitaciones/detalle, t-11.2.2).
// esParaVos: la invitación es para el email de la cuenta logueada (si no, emailInvitado viene
// enmascarado, ej. ju***@gmail.com). yaSosMiembro: ya estás en esa cuenta compartida.
class InvitacionRecibida {
  const InvitacionRecibida({
    required this.cuentaCompartidaNombre,
    required this.invitadoPor,
    required this.emailInvitado,
    required this.estado,
    required this.fechaExpiracion,
    required this.esParaVos,
    required this.yaSosMiembro,
  });

  final String cuentaCompartidaNombre;
  final String invitadoPor;
  final String emailInvitado;
  final EstadoInvitacion estado;
  final DateTime fechaExpiracion;
  final bool esParaVos;
  final bool yaSosMiembro;

  // Se puede aceptar o rechazar solo si está pendiente, es para vos y todavía no estás adentro.
  bool get sePuedeResponder => estado == EstadoInvitacion.pendiente && esParaVos && !yaSosMiembro;

  factory InvitacionRecibida.fromJson(Map<String, dynamic> json) => InvitacionRecibida(
        cuentaCompartidaNombre: json['cuentaCompartidaNombre']?.toString() ?? 'Cuenta compartida',
        invitadoPor: json['invitadoPor']?.toString() ?? 'Alguien',
        emailInvitado: json['emailInvitado']?.toString() ?? '',
        estado: EstadoInvitacion.desdeTexto(json['estado']?.toString() ?? 'PENDIENTE'),
        fechaExpiracion: DateTime.parse(json['fechaExpiracion'] as String),
        esParaVos: json['esParaVos'] as bool? ?? false,
        yaSosMiembro: json['yaSosMiembro'] as bool? ?? false,
      );
}