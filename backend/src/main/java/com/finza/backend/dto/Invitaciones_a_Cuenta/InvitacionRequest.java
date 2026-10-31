package com.finza.backend.dto.Invitaciones_a_Cuenta;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public record InvitacionRequest(
        @NotBlank @Email String email
) {}
