package com.finza.backend.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.finza.backend.dto.CategoriaRequest;
import com.finza.backend.dto.Response;
import com.finza.backend.model.Categoria;
import com.finza.backend.service.CategoriaService;

@RestController
@RequestMapping("/api/categorias")
public class CategoriaController {

    private final CategoriaService categoriaService;

    public CategoriaController(CategoriaService categoriaService) {
        this.categoriaService = categoriaService;
    }

    @PutMapping("/{id}")
    public ResponseEntity<Object> editarCategoria(
            @PathVariable Long id,
            @RequestParam Long cuentaId,
            @RequestBody CategoriaRequest request) {
        Categoria categoria = categoriaService.editarCategoria(
                id,
                cuentaId,
                request.getNombre(),
                request.getColor()
        );
        return Response.ok(categoria, "Categoría actualizada correctamente");
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Object> eliminarCategoria(
            @PathVariable Long id,
            @RequestParam Long cuentaId) {
        categoriaService.eliminarCategoria(id, cuentaId);
        return Response.ok(null, "Categoría eliminada correctamente");
    }
}