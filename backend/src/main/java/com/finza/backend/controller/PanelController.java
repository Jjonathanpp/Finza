package com.finza.backend.controller;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.finza.backend.dto.Response;
import com.finza.backend.service.PanelService;
import com.finza.backend.service.PerfilService;

@RestController
@RequestMapping("/api/panel")
public class PanelController {

    private final PanelService panelService;
    private final PerfilService perfilService;

    public PanelController(PanelService panelService, PerfilService perfilService) {
        this.panelService = panelService;
        this.perfilService = perfilService;
    }

    // Balance del período y últimos movimientos (US-5.1 y US-5.2), del perfil de la cuenta del token.
    @GetMapping("/resumen")
    public ResponseEntity<Object> obtenerResumen(
            @AuthenticationPrincipal Long cuentaId,
            @RequestParam(name = "limite", defaultValue = "5") int limite) {
        var resumen = panelService.obtenerResumen(perfilService.idPrincipal(cuentaId), cuentaId, limite);
        return Response.response(HttpStatus.OK, "Resumen del balance obtenido", resumen);
    }

    // "¿En qué gastaste este mes?" (US-5.4), del perfil de la cuenta del token.
    @GetMapping("/gastos-por-categoria")
    public ResponseEntity<Object> gastosPorCategoria(@AuthenticationPrincipal Long cuentaId) {
        return Response.ok(panelService.gastosPorCategoria(perfilService.idPrincipal(cuentaId)), "Gastos por categoría del mes");
    }
}
