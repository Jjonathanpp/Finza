package com.finza.backend.dto.meta_de_ahorro;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.FutureOrPresent;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDate;

@Getter
@Setter
public class MetaDeAhorroRequestDTO {

    @NotBlank(message = "El nombre de la meta es obligatorio")
    @Size(max = 100, message = "El nombre de la meta no puede superar los 100 caracteres")
    private String nombre;

    @NotNull(message = "El monto objetivo es obligatorio")
    @DecimalMin(value = "0.01", message = "El monto objetivo debe ser mayor a cero")
    private BigDecimal montoObjetivo;

    @FutureOrPresent(message = "La fecha límite no puede estar en el pasado")
    private LocalDate fechaLimite;

    // Si viene con valor, la meta es de esa cuenta compartida. Si es null, es personal.
    @Positive(message = "La cuenta compartida debe ser válida")
    private Long cuentaCompartidaId;
}