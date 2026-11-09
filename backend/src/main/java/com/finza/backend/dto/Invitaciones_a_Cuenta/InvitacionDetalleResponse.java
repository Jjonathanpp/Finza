package com.finza.backend.dto.Invitaciones_a_Cuenta;

import java.time.LocalDateTime;

import com.finza.backend.model.EstadoInvitacion;

// Lo que ve quien abre el enlace de una invitación (t-11.2.2), antes de aceptar o rechazar.
// esParaVos: el email de la cuenta logueada es el invitado (si no, emailInvitado viene enmascarado).
// yaSosMiembro: esa cuenta ya tiene un perfil en la cuenta compartida.
public record InvitacionDetalleResponse(
        String cuentaCompartidaNombre,
        String invitadoPor,
        String emailInvitado,
        EstadoInvitacion estado,
        LocalDateTime fechaExpiracion,
        boolean esParaVos,
        boolean yaSosMiembro
) {}
