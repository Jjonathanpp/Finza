package com.finza.backend.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.finza.backend.dto.Response;
import com.finza.backend.service.PanelService;

import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/panel")
@RequiredArgsConstructor
public class PanelController {

    private final PanelService panelService;
    
    @Autowired
    private HttpServletRequest httpRequest;

    // Método temporal hasta implementar JWT
    private Long obtenerCuentaAutenticada() {
        String testId = httpRequest.getHeader("X-Test-Cuenta-Id");
        return testId != null ? Long.parseLong(testId) : 1L;
    }

    @GetMapping("/resumen")
    public ResponseEntity<Object> obtenerResumen(
            @RequestParam(name = "perfilId") Long perfilId,
            @RequestParam(name = "limite", defaultValue = "5") int limite) {
            
        var resumen = panelService.obtenerResumen(perfilId, obtenerCuentaAutenticada(), limite);
        return Response.response(HttpStatus.OK, "Resumen del balance obtenido", resumen);
    }
}
