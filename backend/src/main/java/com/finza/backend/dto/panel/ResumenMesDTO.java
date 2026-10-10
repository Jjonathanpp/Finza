package com.finza.backend.dto.panel;

import java.math.BigDecimal;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
public class ResumenMesDTO {
    private BigDecimal totalIngresos;
    private BigDecimal totalEgresos;
    private BigDecimal saldo;
}
