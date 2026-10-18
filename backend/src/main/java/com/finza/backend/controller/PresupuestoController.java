package com.finza.backend.controller;

import java.time.LocalDate;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.finza.backend.dto.Response;
import com.finza.backend.service.PerfilService;
import com.finza.backend.service.PresupuestoService;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/presupuestos")
@RequiredArgsConstructor
public class PresupuestoController {

    private final PresupuestoService presupuestoService;
    private final PerfilService perfilService;

    @GetMapping("/mes")
    public ResponseEntity<Object> obtenerPresupuestosDelMes(
            @AuthenticationPrincipal Long cuentaId,
            @RequestParam(name = "mes", required = false) Integer mes,
            @RequestParam(name = "anio", required = false) Integer anio) {

        LocalDate hoy = LocalDate.now();
        int mesConsulta = (mes != null) ? mes : hoy.getMonthValue();
        int anioConsulta = (anio != null) ? anio : hoy.getYear();

        Long perfilId = perfilService.idPrincipal(cuentaId);
        
        var resultado = presupuestoService.obtenerPresupuestosDelMes(perfilId, cuentaId, mesConsulta, anioConsulta);

        return Response.ok(resultado, "Presupuestos del mes obtenidos con éxito");
    }
}