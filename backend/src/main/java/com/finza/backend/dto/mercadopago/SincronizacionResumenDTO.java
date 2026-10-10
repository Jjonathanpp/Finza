package com.finza.backend.dto.mercadopago;

import java.util.List;
import com.finza.backend.model.Movimiento;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SincronizacionResumenDTO {
    private int procesadas;
    private int creadas;
    private int omitidas;
    private int errores;
    private List<Movimiento> movimientos;
}