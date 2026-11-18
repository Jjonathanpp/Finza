package com.finza.backend.dto.meta_de_ahorro;

import com.fasterxml.jackson.annotation.JsonPropertyOrder;
import com.finza.backend.model.MetaDeAhorro;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@Getter
@Setter
@JsonPropertyOrder({
        "cuentaCompartidaId",
        "id",
        "perfilId",
        "nombre",
        "montoObjetivo",
        "montoActual",
        "montoRestante",
        "aportes",
        "cuotaDiaria",
        "cuotaDiariaFinal",
        "cuotaSemanal",
        "cuotaSemanalFinal",
        "cuotaMensual",
        "cuotaMensualFinal",
        "fechaLimite",
        "fechaCreacion"
})
public class MetaDeAhorroResponseDTO {
    private Long cuentaCompartidaId;
    private Long id;
    private Long perfilId;
    private String nombre;
    private BigDecimal montoObjetivo;
    private BigDecimal montoActual;
    private BigDecimal montoRestante;
    private List<AporteMetaAhorroResponseDTO> aportes;
    private BigDecimal cuotaDiaria;
    private BigDecimal cuotaDiariaFinal;
    private BigDecimal cuotaSemanal;
    private BigDecimal cuotaSemanalFinal;
    private BigDecimal cuotaMensual;
    private BigDecimal cuotaMensualFinal;
    private LocalDate fechaLimite;
    private LocalDate fechaCreacion;

    /**
     * Método estático de mapeo para transformar la Entidad en su DTO de respuesta.
     */
    public static MetaDeAhorroResponseDTO fromEntity(
            MetaDeAhorro meta,
            BigDecimal montoRestante,
            BigDecimal cuotaDiaria,
            BigDecimal cuotaDiariaFinal,
            BigDecimal cuotaSemanal,
            BigDecimal cuotaSemanalFinal,
            BigDecimal cuotaMensual,
            BigDecimal cuotaMensualFinal,
            List<AporteMetaAhorroResponseDTO> aportes) {
        MetaDeAhorroResponseDTO dto = new MetaDeAhorroResponseDTO();
        dto.setId(meta.getId());
        dto.setNombre(meta.getNombre());
        dto.setMontoObjetivo(meta.getMontoObjetivo());
        dto.setMontoActual(meta.getMontoActual());
        dto.setMontoRestante(montoRestante);
        dto.setAportes(aportes);
        dto.setCuotaDiaria(cuotaDiaria);
        dto.setCuotaDiariaFinal(cuotaDiariaFinal);
        dto.setCuotaSemanal(cuotaSemanal);
        dto.setCuotaSemanalFinal(cuotaSemanalFinal);
        dto.setCuotaMensual(cuotaMensual);
        dto.setCuotaMensualFinal(cuotaMensualFinal);
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