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

import com.finza.backend.dto.Response;
import com.finza.backend.dto.cuentaCompartida.CuentaCompartidaRequestDTO;
import com.finza.backend.dto.cuentaCompartida.MiembroDTO;
import com.finza.backend.dto.cuentaCompartida.RolRequestDTO;
import com.finza.backend.model.CuentaCompartida;
import com.finza.backend.model.Perfil;
import com.finza.backend.repository.PerfilRepository;
import com.finza.backend.service.PerfilService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

import java.util.List;

@RestController
@RequestMapping("/api/cuentas-compartidas")
@RequiredArgsConstructor
public class CuentaCompartidaController {

    private final PerfilService perfilService;
    private final PerfilRepository perfilRepository;

    // Para el selector de cuenta de la app.
    @GetMapping
    public ResponseEntity<Object> listarMias(@AuthenticationPrincipal Long cuentaId) {
        return Response.ok(perfilService.misCuentasCompartidas(cuentaId), "Cuentas compartidas obtenidas");
    }

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

    // Para el selector de perfil del filtro de movimientos: solo el ADMIN de esa
    // cuenta compartida.
    @GetMapping("/{id}/perfiles")
    public ResponseEntity<Object> perfilesDeCuentaCompartida(@PathVariable Long id,
            @AuthenticationPrincipal Long cuentaId) {
        return Response.ok(perfilService.perfilesDeCuentaCompartida(cuentaId, id), "Perfiles obtenidos");
    }

    @GetMapping("/miembros")
    public ResponseEntity<Object> listarMiembros(@AuthenticationPrincipal Long cuentaId) {
        Perfil perfilActivo = perfilService.perfilActivo(cuentaId);
        if (perfilActivo.getCuentaCompartida() == null) {
            return Response.ok(List.of(), "Cuenta personal, sin miembros");
        }
        CuentaCompartida compartida = perfilActivo.getCuentaCompartida();
        Long creadorId = compartida.getCreador() != null ? compartida.getCreador().getId() : null;

        // Solo los que siguen, en el orden en que entraron. Los que se fueron (baja de cuenta o
        // abandono, t-11.3.4 / t-12.1.7) quedan con cuenta null: con ellos getCuenta() daba 500.
        List<Perfil> miembros = perfilRepository
                .findByCuentaCompartidaIdAndEsActivoTrueOrderByIdAsc(compartida.getId());
        List<MiembroDTO> response = miembros.stream()
                .filter(p -> p.getCuenta() != null)
                .map(p -> new MiembroDTO(
                        p.getId(),
                        p.getCuenta().getUsuario().getId(),
                        p.getNombrePerfil(),
                        p.getRol().name(),
                        p.getId().equals(creadorId)))
                .toList();
        return Response.ok(response, "Miembros obtenidos");
    }

    @PostMapping("/{id}/abandonar")
    public ResponseEntity<Object> abandonarCuentaCompartida(@PathVariable Long id,
            @AuthenticationPrincipal Long cuentaId) {
        perfilService.abandonarCuentaCompartida(cuentaId, id);
        return Response.ok(null, "Abandonaste la cuenta compartida");
    }

}