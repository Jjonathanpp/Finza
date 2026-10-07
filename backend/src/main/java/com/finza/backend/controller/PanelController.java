package com.finza.backend.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.finza.backend.dto.Response;
import com.finza.backend.service.PanelService;

@RestController
@RequestMapping("/api/panel")
public class PanelController {

    private final PanelService panelService;

    public PanelController(PanelService panelService) {
        this.panelService = panelService;
    }

    // "¿En qué gastaste este mes?" (US-5.4).
    @GetMapping("/gastos-por-categoria")
    public ResponseEntity<Object> gastosPorCategoria() {
        Long perfilIdAutenticado = 1L; // fijo hasta el scoping (T-1.6.1), como el listado de movimientos
        return Response.ok(panelService.gastosPorCategoria(perfilIdAutenticado), "Gastos por categoría del mes");
    }
}
