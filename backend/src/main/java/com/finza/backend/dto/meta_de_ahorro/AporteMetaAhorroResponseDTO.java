package com.finza.backend.dto.meta_de_ahorro;

import java.math.BigDecimal;

public record AporteMetaAhorroResponseDTO(
        Long perfilId,
        String nombre,
        BigDecimal monto) {
}
