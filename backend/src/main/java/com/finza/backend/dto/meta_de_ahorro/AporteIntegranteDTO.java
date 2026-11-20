package com.finza.backend.dto.meta_de_ahorro;

import java.math.BigDecimal;

public record AporteIntegranteDTO(
        Long perfilId,
        Long usuarioId,
        String nombre,
        BigDecimal monto,
        BigDecimal porcentaje,
        boolean activo) {
}