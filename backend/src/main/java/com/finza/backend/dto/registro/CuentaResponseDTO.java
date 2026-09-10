package com.finza.backend.dto.registro;

import com.finza.backend.model.Cuenta;

public class CuentaResponseDTO {

    private Long id;
    private String email;
    private String estado;

    public CuentaResponseDTO(Cuenta cuenta) {
        this.id = cuenta.getId();
        this.email = cuenta.getEmail();
        this.estado = cuenta.getEstado().name();
    }

    public Long getId() {
        return id;
    }

    public String getEmail() {
        return email;
    }

    public String getEstado() {
        return estado;
    }
}