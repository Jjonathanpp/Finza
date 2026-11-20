package com.finza.backend.dto.meta_de_ahorro;

import java.math.BigDecimal;
import java.util.List;

public record ResumenAportesMetaDTO(
        Long metaId,
        String nombreMeta,
        Long cuentaCompartidaId,
        BigDecimal montoObjetivo,
        BigDecimal montoActual,
        BigDecimal montoRestante,
        BigDecimal porcentajeAvance,
        List<AporteIntegranteDTO> aportes) {
}