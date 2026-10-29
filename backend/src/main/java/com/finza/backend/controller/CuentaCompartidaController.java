package com.finza.backend.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.finza.backend.dto.CategoriaRequest;
import com.finza.backend.dto.Response;
import com.finza.backend.dto.cuentaCompartida.CuentaCompartidaRequestDTO;
import com.finza.backend.dto.cuentaCompartida.RolRequestDTO;
import com.finza.backend.service.CategoriaService;
import com.finza.backend.service.PerfilService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/cuentas-compartidas")
@RequiredArgsConstructor
public class CuentaCompartidaController {

    private final PerfilService perfilService;
    private final CategoriaService categoriaService;

    @PostMapping
    public ResponseEntity<Object> crear(@AuthenticationPrincipal Long cuentaId,
            @Valid @RequestBody CuentaCompartidaRequestDTO request) {
        return Response.created(perfilService.crearCuentaCompartida(cuentaId, request.nombre()),
                "Cuenta compartida creada");
    }

    @PutMapping("/perfiles/{id}/rol")
    public ResponseEntity<Object> cambiarRol(@PathVariable Long id,
            @AuthenticationPrincipal Long cuentaId,
            @Valid @RequestBody RolRequestDTO request) {
        perfilService.cambiarRol(cuentaId, id, request.rol());
        return Response.ok(null, "Rol actualizado");
    }

    // Predefinidas + las propias de la cuenta compartida. Cualquier integrante.
    @GetMapping("/{id}/categorias")
    public ResponseEntity<Object> listarCategorias(@PathVariable Long id, @AuthenticationPrincipal Long cuentaId) {
        return Response.ok(categoriaService.listarCategoriasDeCuentaCompartida(cuentaId, id),
                "Categorías obtenidas correctamente");
    }

    // Solo el administrador.
    @PostMapping("/{id}/categorias")
    public ResponseEntity<Object> crearCategoria(@PathVariable Long id,
            @AuthenticationPrincipal Long cuentaId,
            @Valid @RequestBody CategoriaRequest request) {
        return Response.created(categoriaService.crearCategoriaDeCuentaCompartida(cuentaId, id, request),
                "Categoría creada correctamente");
    }
}
