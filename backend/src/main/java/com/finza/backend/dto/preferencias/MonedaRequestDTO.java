package com.finza.backend.dto.preferencias;

import com.finza.backend.model.PreferenciasSistema.Moneda;

import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class MonedaRequestDTO {

    @NotNull(message = "La moneda es obligatoria")
    private Moneda moneda;
}
