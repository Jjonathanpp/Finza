package com.finza.backend.dto.mercadopago;

import java.util.List;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class BusquedaMPResponseDTO {

    @JsonProperty("results")
    private List<TransaccionMPResponseDTO> resultados;
}