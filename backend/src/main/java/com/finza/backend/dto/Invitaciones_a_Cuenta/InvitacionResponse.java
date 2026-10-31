package com.finza.backend.dto.Invitaciones_a_Cuenta;

import java.time.LocalDateTime;

import com.finza.backend.model.EstadoInvitacion;

public record InvitacionResponse(
        Long id,
        String emailInvitado,
        EstadoInvitacion estado,
        LocalDateTime fechaExpiracion
) {}
