package com.finza.backend.dto.movimiento;

import java.math.BigDecimal;
import java.time.LocalDate;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.finza.backend.dto.CategoriaResponseDTO;
import com.finza.backend.model.Movimiento;
import lombok.Getter;

@Getter
public class MovimientoResponseDTO {

    private final Long id;
    private final String tipo;
    private final BigDecimal monto;
    private final String descripcion;

    @JsonFormat(pattern = "dd-MM-yyyy")
    private final LocalDate fecha;
    
    private final String estado;
    private final CategoriaResponseDTO categoria;
    private final Long perfilId;

    public MovimientoResponseDTO(Movimiento movimiento) {
        this.id = movimiento.getId();
        this.tipo = movimiento.isEsIngreso() ? "ingreso" : "egreso";
        this.monto = movimiento.getMonto();
        this.descripcion = movimiento.getDescripcion();
        this.fecha = movimiento.getFecha();
        this.estado = movimiento.getEstado().name();
        this.categoria = new CategoriaResponseDTO(movimiento.getCategoria());
        this.perfilId = movimiento.getPerfil().getId();
    }
}