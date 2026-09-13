package com.finza.backend.controller;

import java.util.List;

import com.finza.backend.dto.Response;
import com.finza.backend.dto.movimiento.MovimientoResponseDTO;
import com.finza.backend.dto.movimiento.MovimientosRegistroRequest;
import com.finza.backend.model.Movimiento;
import com.finza.backend.service.MovimientoService;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

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
}