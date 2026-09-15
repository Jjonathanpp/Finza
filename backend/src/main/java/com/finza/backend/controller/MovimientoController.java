package com.finza.backend.controller;

import java.time.LocalDate;
import java.util.List;

import com.finza.backend.dto.Response;
import com.finza.backend.dto.movimiento.MovimientoResponseDTO;
import com.finza.backend.dto.movimiento.MovimientosRegistroRequest;
import com.finza.backend.service.MovimientoService;

import org.springframework.data.web.PageableDefault;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/movimientos")
@RequiredArgsConstructor
public class MovimientoController {

    private final MovimientoService movimientoService;

    @PostMapping
    public ResponseEntity<Object> registrar(@RequestBody MovimientosRegistroRequest requests) {
        List<MovimientoResponseDTO> creados = movimientoService.registrar(requests);
        return Response.response(HttpStatus.CREATED, "Movimiento registrado exitosamente", creados);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Object> eliminar(@PathVariable Long id) {
        movimientoService.eliminar(id);
        return Response.response(HttpStatus.OK, "Movimiento eliminado exitosamente", null);
    }

   @GetMapping
    public ResponseEntity<Page<MovimientoResponseDTO>> obtenerMovimientos(
            @RequestParam(name = "fechaInicio", required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fechaInicio,
            @RequestParam(name = "fechaFin", required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fechaFin,
            @RequestParam(name = "categoriaId", required = false) Long categoriaId,
            @RequestParam(name = "esIngreso", required = false) String esIngresoStr, // <--- Lo recibimos como String
            @PageableDefault(size = 20, sort = "fecha", direction = Sort.Direction.DESC) Pageable pageable) {

        Long perfilIdAutenticado = 1L; 

        // Convertimos el String a Boolean de forma segura aca adentro
        Boolean esIngreso = esIngresoStr != null ? Boolean.parseBoolean(esIngresoStr) : null;

        Page<MovimientoResponseDTO> resultado = movimientoService.listarMovimientos(
                perfilIdAutenticado, fechaInicio, fechaFin, categoriaId, esIngreso, pageable);

        return ResponseEntity.ok(resultado);
    }
}