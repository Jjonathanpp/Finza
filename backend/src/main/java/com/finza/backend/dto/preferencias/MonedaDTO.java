package com.finza.backend.dto.preferencias;

import java.math.BigDecimal;
import java.time.Instant;

import com.finza.backend.model.PreferenciasSistema.Moneda;

import lombok.AllArgsConstructor;
import lombok.Getter;

// La moneda en la que el perfil ve los montos (US-8.2). Los montos se guardan en pesos: la app
// los divide por la cotización (pesos por dólar o por euro). Con PESO, o si no hay cotización, van null.
@Getter
@AllArgsConstructor
public class MonedaDTO {
    private final Moneda moneda;
    private final BigDecimal cotizacion;
    private final Instant actualizada;
}
