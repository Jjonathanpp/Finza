package com.finza.backend.dto.informe;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.finza.backend.dto.panel.GastoPorCategoriaDTO;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class PeriodoComparacionDTO {

    private final String etiqueta;

    @JsonFormat(pattern = "yyyy-MM-dd")
    private final LocalDate fechaInicio;

    @JsonFormat(pattern = "yyyy-MM-dd")
    private final LocalDate fechaFin;

    private final BigDecimal ingresos;
    private final BigDecimal egresos;
    private final BigDecimal saldo;

    private final BigDecimal variacionIngresos;
    private final BigDecimal variacionEgresos;

    private final List<GastoPorCategoriaDTO> categorias;
}