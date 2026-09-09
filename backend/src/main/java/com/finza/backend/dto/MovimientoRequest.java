package com.finza.backend.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class MovimientoRequest {

    private String tipo;
    private String monto;
    private String categoria;
    private String descripcion;
    private String fecha;
}