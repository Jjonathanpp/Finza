package com.finza.backend.dto.presupuesto;

import java.math.BigDecimal;

// Lo que gastó un integrante de la cuenta compartida en la categoría de un presupuesto (t-13.2.1).
// porcentaje: qué parte del tope es (33.3 = 33,3 %).
public record GastoDePerfilDTO(Long perfilId, String nombre, BigDecimal gastado, BigDecimal porcentaje) {
}
