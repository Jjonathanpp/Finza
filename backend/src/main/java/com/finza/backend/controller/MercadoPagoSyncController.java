package com.finza.backend.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.finza.backend.dto.mercadopago.BusquedaMPResponseDTO;
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
}