package com.finza.backend.dto.mercadopago;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class EstadoMPResponseDTO {
    private boolean vinculado;
    private String mpUserId;
}