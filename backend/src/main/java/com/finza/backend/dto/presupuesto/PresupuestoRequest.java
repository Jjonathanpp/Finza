package com.finza.backend.dto.presupuesto;

import java.math.BigDecimal;

import lombok.Getter;
import lombok.Setter;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class PresupuestoRequest {
    private Long categoriaId;
    private BigDecimal montoTope;
    private Integer mes;
    private Integer anio;
}