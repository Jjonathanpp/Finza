package com.finza.backend.dto.registro;

import com.finza.backend.model.Cuenta;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CuentaResponseDTO {

    private Long id;
    private String email;
    private String estado;

    public CuentaResponseDTO(Cuenta cuenta) {
        this.id = cuenta.getId();
        this.email = cuenta.getEmail();
        this.estado = cuenta.getEstado() != null ? cuenta.getEstado().name() : null;
    }

}