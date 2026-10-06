package com.finza.backend.controller;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.PostMapping;

import com.finza.backend.dto.mercadopago.BusquedaMPResponseDTO;
import com.finza.backend.model.Movimiento;
import com.finza.backend.service.MercadoPagoSyncService;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/mercadopago")
@RequiredArgsConstructor
public class MercadoPagoSyncController {

    private final MercadoPagoSyncService syncService;

    @GetMapping("/movimientos/crudos")
    public ResponseEntity<BusquedaMPResponseDTO> obtenerMovimientosCrudos(@RequestParam Long usuarioId) {
        BusquedaMPResponseDTO respuesta = syncService.obtenerMovimientosDesdeMP(usuarioId);
        return ResponseEntity.ok(respuesta);
    }

    @GetMapping("/movimientos/mapeados")
    public ResponseEntity<List<Movimiento>> obtenerMovimientosMapeados(
            @RequestParam Long usuarioId,
            @RequestParam(defaultValue = "1") Long perfilId) {
        List<Movimiento> movimientos = syncService.obtenerMovimientosMapeados(usuarioId, perfilId);
        return ResponseEntity.ok(movimientos);
    }

    @PostMapping("/sincronizar")
    public ResponseEntity<List<Movimiento>> sincronizar(
            @RequestParam Long usuarioId,
            @RequestParam(defaultValue = "1") Long perfilId) {
        List<Movimiento> guardados = syncService.sincronizarMovimientos(usuarioId, perfilId);
        return ResponseEntity.ok(guardados);
    }
}