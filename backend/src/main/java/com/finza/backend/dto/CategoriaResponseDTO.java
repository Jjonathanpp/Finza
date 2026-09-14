package com.finza.backend.dto;

import com.finza.backend.model.Categoria;
import lombok.Getter;

@Getter
public class CategoriaResponseDTO {

    private final Long id;
    private final String nombre;
    private final String color;
    private final Categoria.TipoCategoria tipo;
    private final boolean esPredefinida;

    public CategoriaResponseDTO(Categoria categoria) {
        this.id = categoria.getId();
        this.nombre = categoria.getNombre();
        this.color = categoria.getColor();
        this.tipo = categoria.getTipoCategoriaPredefinida();
        this.esPredefinida = categoria.isEs_predefinida();
    }
}
