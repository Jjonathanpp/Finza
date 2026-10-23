package com.finza.backend.dto.presupuesto;

import java.math.BigDecimal;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class PresupuestoCategoriaDTO {
    private final Long presupuestoId;
    private final Long categoriaId;
    private final String categoriaNombre;
    private final String categoriaColor;
    private final BigDecimal montoTope;
    private final BigDecimal montoGastado;
    private final BigDecimal porcentajeConsumo;
    private final String estado;
}