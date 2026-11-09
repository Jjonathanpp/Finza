package com.finza.backend.dto.Invitaciones_a_Cuenta;

import jakarta.validation.constraints.NotBlank;

// El token del enlace de invitación, en JSON ({"token": "..."}). El token va en el cuerpo y no en
// la URL para que no quede en los registros del servidor.
public record TokenInvitacionRequest(@NotBlank(message = "Falta el token de la invitación") String token) {}