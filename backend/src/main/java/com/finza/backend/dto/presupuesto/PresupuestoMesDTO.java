package com.finza.backend.dto.presupuesto;

import java.math.BigDecimal;
import java.util.List;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class PresupuestoMesDTO {
    private final int mes;
    private final int anio;
    private final BigDecimal totalPresupuestado;
    private final BigDecimal totalGastado;
    private final BigDecimal porcentajeTotal;
    private final List<PresupuestoCategoriaDTO> categorias;
}