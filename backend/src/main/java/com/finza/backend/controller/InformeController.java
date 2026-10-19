package com.finza.backend.controller;

import java.time.LocalDate;

import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.finza.backend.dto.Response;
import com.finza.backend.service.PanelService;
import com.finza.backend.service.PerfilService;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/informes")
@RequiredArgsConstructor
public class InformeController {

    private final PanelService panelService;
    private final PerfilService perfilService;

    // Torta por categoría (US-6.1): el mismo cálculo que "En qué gastás" del panel, con el período elegido.
    // Sin fechas, el período de las preferencias del perfil (por defecto, el mes actual).
    @GetMapping("/por-categoria")
    public ResponseEntity<Object> porCategoria(
            @AuthenticationPrincipal Long cuentaId,
            @RequestParam(name = "startDate", required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(name = "endDate", required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        return Response.ok(panelService.gastosPorCategoria(perfilService.idPrincipal(cuentaId), startDate, endDate),
                "Gastos por categoría del período");
    }
}
