package com.finza.backend.dto.movimiento;

import java.util.List;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class MovimientosRegistroRequest {

    private Long perfilId;
    private List<MovimientoRequest> movimientos;
}