package com.finza.backend.dto.movimiento;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class MovimientoIADTO {
    private String tipo;
    private String monto;
    private String categoria;
    private String descripcion;
    private String fecha;   
}
