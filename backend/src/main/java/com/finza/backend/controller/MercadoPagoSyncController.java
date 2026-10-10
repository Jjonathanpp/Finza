package com.finza.backend.controller;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.PostMapping;

import com.finza.backend.dto.mercadopago.BusquedaMPResponseDTO;
import com.finza.backend.dto.mercadopago.SincronizacionResumenDTO;
import com.finza.backend.dto.Response;
import com.finza.backend.model.Movimiento;
import com.finza.backend.service.MercadoPagoSyncService;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping({"/api/mercadopago", "/mercadopago"})
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
    public ResponseEntity<Object> sincronizar(
            @RequestParam Long usuarioId,
            @RequestParam(defaultValue = "1") Long perfilId) {
        SincronizacionResumenDTO resumen = syncService.sincronizarMovimientos(usuarioId, perfilId);
        return Response.ok(resumen, "Sincronización completada exitosamente");
    }
}