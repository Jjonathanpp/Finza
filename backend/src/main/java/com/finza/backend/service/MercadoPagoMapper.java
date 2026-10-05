package com.finza.backend.service;

import java.time.OffsetDateTime;
import java.time.LocalDateTime;

import org.springframework.stereotype.Component;

import com.finza.backend.dto.mercadopago.TransaccionMPResponseDTO;
import com.finza.backend.model.Categoria;
import com.finza.backend.model.Movimiento;
import com.finza.backend.model.Movimiento.EstadoMovimiento;
import com.finza.backend.model.Movimiento.OrigenMovimiento;
import com.finza.backend.model.Perfil;

@Component
public class MercadoPagoMapper {

    public Movimiento mapearAMovimiento(TransaccionMPResponseDTO dto, Long miMpUserId, Perfil perfil, Categoria categoriaOtros) {
        Movimiento movimiento = new Movimiento();

        movimiento.setPerfil(perfil);
        movimiento.setCategoria(categoriaOtros);

        movimiento.setMonto(dto.getMonto());
        movimiento.setDescripcion(dto.getDescripcion() != null ? dto.getDescripcion() : "Movimiento Mercado Pago");

        boolean esIngreso = dto.getCollectorId() != null && dto.getCollectorId().equals(miMpUserId);
        movimiento.setEsIngreso(esIngreso);

        movimiento.setExternalId(String.valueOf(dto.getId()));
        movimiento.setOrigen(OrigenMovimiento.MERCADOPAGO);
        movimiento.setFechaCreacion(LocalDateTime.now());

        if (dto.getFechaAprobacion() != null) {
            movimiento.setFecha(OffsetDateTime.parse(dto.getFechaAprobacion()).toLocalDate());
        }

        movimiento.setEstado(EstadoMovimiento.PENDIENTE);

        return movimiento;
    }
}