package com.finza.backend.dto.presupuesto;

import java.math.BigDecimal;
import java.util.List;

import com.fasterxml.jackson.annotation.JsonInclude;

import lombok.Getter;
import lombok.RequiredArgsConstructor;
import lombok.Setter;

@Getter
@RequiredArgsConstructor
public class PresupuestoCategoriaDTO {
    private final Long presupuestoId;
    private final Long categoriaId;
    private final String categoriaNombre;
    private final String categoriaColor;
    private final BigDecimal montoTope;
    private final BigDecimal montoGastado;
    private final BigDecimal porcentajeConsumo;
    private final String estado;

    // Solo en una cuenta compartida: cuánto gastó cada integrante, de mayor a menor (t-13.2.1).
    // En la personal queda vacío y no sale en el JSON.
    @Setter
    @JsonInclude(JsonInclude.Include.NON_NULL)
    private List<GastoDePerfilDTO> porPerfil;
}