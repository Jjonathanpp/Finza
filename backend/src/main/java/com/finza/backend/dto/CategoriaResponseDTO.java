package com.finza.backend.dto;

import com.finza.backend.model.Categoria;
import lombok.Getter;

@Getter
public class CategoriaResponseDTO {

    private final Long id;
    private final String nombre;

    public CategoriaResponseDTO(Categoria categoria) {
        this.id = categoria.getId();
        this.nombre = categoria.getNombre();
    }
}