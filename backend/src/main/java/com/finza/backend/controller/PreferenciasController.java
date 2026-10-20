package com.finza.backend.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.finza.backend.dto.Response;
import com.finza.backend.dto.preferencias.MonedaRequestDTO;
import com.finza.backend.service.CotizacionService;
import com.finza.backend.service.PerfilService;
import com.finza.backend.service.PreferenciasService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/preferencias")
@RequiredArgsConstructor
public class PreferenciasController {

    private final PreferenciasService preferenciasService;
    private final CotizacionService cotizacionService;
    private final PerfilService perfilService;

    @GetMapping("/moneda")
    public ResponseEntity<Object> moneda(@AuthenticationPrincipal Long cuentaId) {
        return Response.ok(cotizacionService.conCotizacion(preferenciasService.moneda(perfilService.idPrincipal(cuentaId))),
                "Moneda de visualización");
    }

    @PutMapping("/moneda")
    public ResponseEntity<Object> cambiarMoneda(@AuthenticationPrincipal Long cuentaId,
            @Valid @RequestBody MonedaRequestDTO request) {
        preferenciasService.cambiarMoneda(perfilService.idPrincipal(cuentaId), request.getMoneda());
        return Response.ok(cotizacionService.conCotizacion(request.getMoneda()), "Moneda actualizada");
    }
}
