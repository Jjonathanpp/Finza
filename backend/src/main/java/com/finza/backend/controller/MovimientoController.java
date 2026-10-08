package com.finza.backend.controller;

import java.time.LocalDate;
import java.util.List;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;

import com.finza.backend.dto.Response;
import com.finza.backend.dto.movimiento.MovimientoResponseDTO;
import com.finza.backend.dto.movimiento.MovimientosRegistroRequest;
import com.finza.backend.dto.movimiento.MovimientoIADTO;
import com.finza.backend.dto.movimiento.MovimientoRequest;
import com.finza.backend.service.MovimientoService;
import com.finza.backend.service.IAService;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/movimientos")
@RequiredArgsConstructor
public class MovimientoController {

    private final MovimientoService movimientoService;

    //BORRAR DESPUES OJOJOJO
    @Autowired
    private HttpServletRequest httpRequest;

    // EXTRAEREMOS ESTO DEL TOKEN JWT MÁS ADELANTE
    private Long obtenerCuentaAutenticada() {
        String testId = httpRequest.getHeader("X-Test-Cuenta-Id");
        return testId != null ? Long.parseLong(testId) : 1L; // Si no hay header, sigue siendo 1L
    }
    
    @PostMapping
    public ResponseEntity<Object> registrar(@RequestBody MovimientosRegistroRequest requests) {
        List<MovimientoResponseDTO> creados = movimientoService.registrar(requests, obtenerCuentaAutenticada());
        return Response.response(HttpStatus.CREATED, "Movimiento registrado exitosamente", creados);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Object> eliminar(@PathVariable Long id) {
        movimientoService.eliminar(id, obtenerCuentaAutenticada());
        return Response.response(HttpStatus.OK, "Movimiento eliminado exitosamente", null);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Object> actualizarMovimiento(
            @PathVariable Long id,
            @RequestBody MovimientoRequest request) {
        
        // Asumiendo que el request trae el perfilId adentro, si no lo trae, tendrías que obtener el perfil del movimiento antes.
        Long perfilId = 1L; // Reemplazar por request.getPerfilId() si existe en tu DTO
        MovimientoResponseDTO actualizado = movimientoService.actualizar(id, perfilId, request, obtenerCuentaAutenticada());
        return Response.ok(actualizado, "Movimiento actualizado exitosamente");
    }

    @GetMapping
    public ResponseEntity<Object> obtenerMovimientos(

            @RequestParam(name = "perfilId") Long perfilId,
            @RequestParam(name = "fechaInicio", required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fechaInicio,
            @RequestParam(name = "fechaFin", required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fechaFin,
            @RequestParam(name = "categoriaId", required = false) Long categoriaId,
            @RequestParam(name = "esIngreso", required = false) String esIngresoStr,
            @RequestParam(name = "estado", required = false) String estadoStr,
            @PageableDefault(size = 20, sort = "fecha", direction = Sort.Direction.DESC) Pageable pageable) {

        Boolean esIngreso = esIngresoStr != null ? Boolean.parseBoolean(esIngresoStr) : null;

        Page<MovimientoResponseDTO> resultado = movimientoService.listarMovimientos(
                perfilId, obtenerCuentaAutenticada(), fechaInicio, fechaFin, categoriaId, esIngreso, estadoStr, pageable);

        return Response.response(HttpStatus.OK, "Movimientos obtenidos", resultado);
    }

    @PostMapping("/procesar-audio")
    public ResponseEntity<Object> procesarAudio(@RequestParam("audio") MultipartFile audio) {
        try {
            Long perfilId = 1L; // Reemplazar cuando se mande desde Flutter
            return Response.response(HttpStatus.CREATED, "Movimiento de voz procesado y registrado como PENDIENTE", 
                    movimientoService.registrarDesdeAudio(audio, perfilId, obtenerCuentaAutenticada()));
        } catch (Exception e) {
            return Response.response(HttpStatus.INTERNAL_SERVER_ERROR, "Error procesando el audio: " + e.getMessage(), null);
        }
    }
    
    @PutMapping("/{id}/estado")
    public ResponseEntity<Object> cambiarEstado(@PathVariable Long id, @RequestParam("nuevoEstado") String nuevoEstado) {
        return Response.response(HttpStatus.OK, "Estado actualizado correctamente", movimientoService.cambiarEstado(id, nuevoEstado, obtenerCuentaAutenticada()));
    }
}