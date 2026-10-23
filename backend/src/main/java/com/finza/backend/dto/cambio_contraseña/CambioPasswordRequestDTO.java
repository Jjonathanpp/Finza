package com.finza.backend.dto.cambio_contraseña;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
public class CambioPasswordRequestDTO {

    @NotBlank
    @JsonProperty("contraseña_actual")
    private String contrasenaActual;

    @NotBlank
    @Size(min = 8, message = "La contraseña debe tener al menos 8 caracteres")
    @JsonProperty("nueva_contraseña")
    private String nuevaContrasena;
}