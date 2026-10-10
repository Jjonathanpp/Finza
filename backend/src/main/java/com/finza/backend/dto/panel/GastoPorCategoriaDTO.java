package com.finza.backend.dto.panel;

import java.math.BigDecimal;

import lombok.Getter;
import lombok.RequiredArgsConstructor;
import lombok.Setter;

// Una fila de "¿en qué gastaste este mes?": una categoría y cuánto se gastó en ella.
@Getter
@RequiredArgsConstructor
public class GastoPorCategoriaDTO {
    private final Long id;
    private final String nombre;
    private final String color;
    private final BigDecimal total;

    // Qué parte del gasto del mes es (40.5 = 40,5 %). La completa PanelService, que conoce el total.
    @Setter
    private BigDecimal porcentaje;
}
