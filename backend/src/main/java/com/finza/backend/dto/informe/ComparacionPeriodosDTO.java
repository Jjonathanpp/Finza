package com.finza.backend.dto.informe;

import java.util.List;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class ComparacionPeriodosDTO {

    private final String granularidad;

    private final List<PeriodoComparacionDTO> periodos;
}