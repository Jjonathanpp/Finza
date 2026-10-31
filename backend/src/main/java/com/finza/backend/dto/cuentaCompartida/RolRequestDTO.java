package com.finza.backend.dto.cuentaCompartida;

import com.finza.backend.model.Perfil.Rol;

import jakarta.validation.constraints.NotNull;

public record RolRequestDTO(@NotNull(message = "El rol es obligatorio") Rol rol) {}
