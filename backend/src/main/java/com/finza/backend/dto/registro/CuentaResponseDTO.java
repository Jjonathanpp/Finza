package com.finza.backend.dto.registro;

import com.finza.backend.model.Cuenta;
import com.finza.backend.model.Perfil;

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
    private Long perfilId;

    public CuentaResponseDTO(Cuenta cuenta,Perfil perfil) {
        this.id = cuenta.getId();
        this.email = cuenta.getEmail();
        this.estado = cuenta.getEstado() != null ? cuenta.getEstado().name() : null;
        this.perfilId = perfil.getId();
    }

}