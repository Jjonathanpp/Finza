package com.finza.backend.dto.mercadopago;

import java.math.BigDecimal;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class TransaccionMPResponseDTO {

    private Long id;

    @JsonProperty("status")
    private String estado;

    @JsonProperty("transaction_amount")
    private BigDecimal monto;

    @JsonProperty("description")
    private String descripcion;

    @JsonProperty("date_approved")
    private String fechaAprobacion;

    @JsonProperty("operation_type")
    private String tipoOperacion;
}