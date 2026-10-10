package com.finza.backend.dto.panel;

import java.math.BigDecimal;
import java.util.List;

import com.finza.backend.dto.movimiento.MovimientoResponseDTO;

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
    // Tipo billetera: todo lo que entró menos todo lo que salió, desde el primer movimiento (no se reinicia).
    private BigDecimal saldoTotal;
    private List<MovimientoResponseDTO> ultimosMovimientos;
    private List<MovimientoResponseDTO> ultimosIngresos;
    private List<MovimientoResponseDTO> ultimosEgresos;
}
