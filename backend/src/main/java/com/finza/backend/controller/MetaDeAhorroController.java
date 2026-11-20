package com.finza.backend.controller;

import com.finza.backend.dto.Response;
import com.finza.backend.dto.meta_de_ahorro.AbonarMetaDTO;
import com.finza.backend.dto.meta_de_ahorro.MetaDeAhorroRequestDTO;
import com.finza.backend.dto.meta_de_ahorro.MetaDeAhorroResponseDTO;
import com.finza.backend.dto.meta_de_ahorro.ResumenAportesMetaDTO;
import com.finza.backend.model.MetaDeAhorro;
import com.finza.backend.service.MetaDeAhorroService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/metas")
@PreAuthorize("isAuthenticated()")
public class MetaDeAhorroController {

    private final MetaDeAhorroService metaService;

    public MetaDeAhorroController(MetaDeAhorroService metaService) {
        this.metaService = metaService;
    }

    /**
     * Crea una nueva meta de ahorro (personal o en cuenta compartida).
     */
    @PostMapping
    public ResponseEntity<Object> crearMeta(
            @AuthenticationPrincipal Long cuentaId,
            @Valid @RequestBody MetaDeAhorroRequestDTO request) {

        MetaDeAhorro meta = metaService.crearMeta(
                cuentaId,
                request.getCuentaCompartidaId(),
                request.getNombre(),
                request.getMontoObjetivo(),
                request.getFechaLimite());

        MetaDeAhorroResponseDTO dto = convertirRespuesta(cuentaId, meta);
        return Response.created(dto, "Meta de ahorro creada exitosamente");
    }

    /**
     * Lista las metas según el contexto (perfil personal o cuenta compartida).
     */
    @GetMapping
    public ResponseEntity<Object> listarMetas(
            @AuthenticationPrincipal Long cuentaId,
            @RequestParam(required = false) Long cuentaCompartidaId) {

        List<MetaDeAhorro> metas = metaService.listarMetas(cuentaId, cuentaCompartidaId);
        List<MetaDeAhorroResponseDTO> response = metas.stream()
                .map(meta -> convertirRespuesta(cuentaId, meta))
                .collect(Collectors.toList());

        return Response.ok(response);
    }

    /**
     * T-15.3.3: Devuelve el resumen de avance total de la meta junto con
     * la lista de aportes desglosada por nombre de integrante.
     */
    @GetMapping("/{id}/aportes")
    public ResponseEntity<Object> obtenerResumenAportes(
            @AuthenticationPrincipal Long cuentaId,
            @PathVariable Long id) {

        ResumenAportesMetaDTO resumen = metaService.obtenerResumenAportes(cuentaId, id);
        return Response.ok(resumen, "Resumen de aportes obtenido exitosamente");
    }

    /**
     * Edita una meta existente (exige ADMIN si es compartida).
     */
    @PutMapping("/{id}")
    @PreAuthorize("@metaSecurity.puedeAdministrarMeta(authentication.principal, #id)")
    public ResponseEntity<Object> editarMeta(
            @AuthenticationPrincipal Long cuentaId,
            @PathVariable Long id,
            @Valid @RequestBody MetaDeAhorroRequestDTO request) {

        MetaDeAhorro meta = metaService.editarMeta(
                cuentaId,
                id,
                request.getNombre(),
                request.getMontoObjetivo(),
                request.getFechaLimite());

        MetaDeAhorroResponseDTO dto = convertirRespuesta(cuentaId, meta);
        return Response.ok(dto, "Meta de ahorro actualizada exitosamente");
    }

    /**
     * Abona dinero a una meta de ahorro.
     */
    @PostMapping("/{id}/abonar")
    public ResponseEntity<Object> abonarDinero(
            @AuthenticationPrincipal Long cuentaId,
            @PathVariable Long id,
            @Valid @RequestBody AbonarMetaDTO request) {

        MetaDeAhorro meta = metaService.abonarDinero(cuentaId, id, request.getMonto());

        MetaDeAhorroResponseDTO dto = convertirRespuesta(cuentaId, meta);
        return Response.ok(dto, "Abono realizado exitosamente");
    }

    /**
     * Elimina una meta de ahorro (exige ADMIN si es compartida).
     */
    @DeleteMapping("/{id}")
    @PreAuthorize("@metaSecurity.puedeAdministrarMeta(authentication.principal, #id)")
    public ResponseEntity<Object> eliminarMeta(
            @AuthenticationPrincipal Long cuentaId,
            @PathVariable Long id) {

        metaService.eliminarMeta(cuentaId, id);
        return Response.ok(null, "Meta de ahorro eliminada exitosamente");
    }

    private MetaDeAhorroResponseDTO convertirRespuesta(Long cuentaId, MetaDeAhorro meta) {
        MetaDeAhorroService.CuotasAhorro cuotas = metaService.calcularCuotas(meta);
        MetaDeAhorroService.ResumenAportes aportes = metaService.resumenAportes(cuentaId, meta);
        return MetaDeAhorroResponseDTO.fromEntity(
                meta,
                cuotas.montoRestante(),
                cuotas.cuotaDiaria(),
                cuotas.cuotaDiariaFinal(),
                cuotas.cuotaSemanal(),
                cuotas.cuotaSemanalFinal(),
                cuotas.cuotaMensual(),
                cuotas.cuotaMensualFinal(),
                aportes.integrantes());
    }
}