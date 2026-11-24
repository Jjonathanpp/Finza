package com.finza.backend.dto.mercadopago;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SincronizacionResumenDTO {
    private int procesadas;
    private int creadas;
    private int omitidas;
    private int errores;
}