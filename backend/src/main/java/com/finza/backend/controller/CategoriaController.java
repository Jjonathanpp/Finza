package com.finza.backend.controller;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.finza.backend.dto.CategoriaRequest;
import com.finza.backend.dto.CategoriaResponseDTO;
import com.finza.backend.dto.Response;
import com.finza.backend.model.Categoria;
import com.finza.backend.service.CategoriaService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/categorias")
public class CategoriaController {

    private final CategoriaService categoriaService;

    public CategoriaController(CategoriaService categoriaService) {
        this.categoriaService = categoriaService;
    }

    @GetMapping
    public ResponseEntity<Object> listarCategorias(@RequestParam Long cuentaId) {
        return Response.ok(categoriaService.listarCategorias(cuentaId), "Categorías obtenidas correctamente");
    }

    @PostMapping
    public ResponseEntity<Object> crearCategoria(
            @RequestParam Long cuentaId,
            @Valid @RequestBody CategoriaRequest request) {
        CategoriaResponseDTO categoria = categoriaService.crearCategoria(cuentaId, request);
        return Response.response(HttpStatus.CREATED, "Categoría creada correctamente", categoria);
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
