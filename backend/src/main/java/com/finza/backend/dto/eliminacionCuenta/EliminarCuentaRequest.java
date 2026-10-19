package com.finza.backend.dto.eliminacionCuenta;

import jakarta.validation.constraints.NotBlank;

public class EliminarCuentaRequest {

    @NotBlank(message = "La contraseña es obligatoria")
    private String password;

    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }
}