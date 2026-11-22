package com.finza.backend.dto.meta_de_ahorro;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;

@Getter
@Setter
public class AbonarMetaDTO {

    @NotNull(message = "El monto a abonar es obligatorio")
    @DecimalMin(value = "0.01", message = "El monto a abonar debe ser mayor a cero")
    private BigDecimal monto;
}