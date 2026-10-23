package com.finza.backend.dto.cambio_contrasena_Sin_Cuenta;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public record OlvideContrasenaRequest(
        @NotBlank @Email String email) {}