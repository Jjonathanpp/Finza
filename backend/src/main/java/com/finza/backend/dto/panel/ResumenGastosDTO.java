package com.finza.backend.dto.panel;

import java.math.BigDecimal;
import java.util.List;

import lombok.AllArgsConstructor;
import lombok.Getter;

// "¿En qué gastaste este mes?": el total gastado y cada categoría, de mayor a menor.
@Getter
@AllArgsConstructor
public class ResumenGastosDTO {
    private BigDecimal total;
    private List<GastoPorCategoriaDTO> categorias;
}
