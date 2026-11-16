package com.finza.backend.dto.meta_de_ahorro;

import com.fasterxml.jackson.annotation.JsonPropertyOrder;
import com.finza.backend.model.MetaDeAhorro;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDate;

@Getter
@Setter
@JsonPropertyOrder({
        "cuentaCompartidaId",
        "id",
        "perfilId",
        "nombre",
        "montoObjetivo",
        "fechaLimite",
        "fechaCreacion"
})
public class MetaDeAhorroResponseDTO {
    private Long cuentaCompartidaId;
    private Long id;
    private Long perfilId;
    private String nombre;
    private BigDecimal montoObjetivo;
    private LocalDate fechaLimite;
    private LocalDate fechaCreacion;

    /**
     * Método estático de mapeo para transformar la Entidad en su DTO de respuesta.
     */
    public static MetaDeAhorroResponseDTO fromEntity(MetaDeAhorro meta) {
        MetaDeAhorroResponseDTO dto = new MetaDeAhorroResponseDTO();
        dto.setId(meta.getId());
        dto.setNombre(meta.getNombre());
        dto.setMontoObjetivo(meta.getMontoObjetivo());
        dto.setFechaLimite(meta.getFechaLimite());

        if (meta.getFechaCreacion() != null) {
            dto.setFechaCreacion(meta.getFechaCreacion().toLocalDate());
        }

        if (meta.getPerfil() != null) {
            dto.setPerfilId(meta.getPerfil().getId());
        }
        if (meta.getCuentaCompartida() != null) {
            dto.setCuentaCompartidaId(meta.getCuentaCompartida().getId());
        }

        return dto;
    }
}