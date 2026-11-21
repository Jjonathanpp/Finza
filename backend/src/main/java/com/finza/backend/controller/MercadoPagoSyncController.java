package com.finza.backend.controller;

import java.util.List;
import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.security.core.annotation.AuthenticationPrincipal;

import com.finza.backend.model.Cuenta;
import com.finza.backend.repository.CuentaRepository;
import com.finza.backend.service.PerfilService;
import com.finza.backend.exception.BadRequestException;
import com.finza.backend.dto.mercadopago.BusquedaMPResponseDTO;
import com.finza.backend.dto.mercadopago.SincronizacionResumenDTO;
import com.finza.backend.dto.Response;
import com.finza.backend.model.Movimiento;
import com.finza.backend.service.MercadoPagoSyncService;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping({ "/api/mercadopago", "/mercadopago" })
@RequiredArgsConstructor
public class MercadoPagoSyncController {

    private final MercadoPagoSyncService syncService;
    private final PerfilService perfilService;
    private final CuentaRepository cuentaRepository;

    @GetMapping("/movimientos/crudos")
    public ResponseEntity<BusquedaMPResponseDTO> obtenerMovimientosCrudos(@AuthenticationPrincipal Long cuentaId) {
        Cuenta cuenta = cuentaRepository.findById(cuentaId)
                .orElseThrow(() -> new BadRequestException("Cuenta no encontrada"));
        BusquedaMPResponseDTO respuesta = syncService.obtenerMovimientosDesdeMP(cuenta.getUsuario().getId());
        return ResponseEntity.ok(respuesta);
    }

    @GetMapping("/movimientos/mapeados")
    public ResponseEntity<List<Movimiento>> obtenerMovimientosMapeados(@AuthenticationPrincipal Long cuentaId) {
        Cuenta cuenta = cuentaRepository.findById(cuentaId)
                .orElseThrow(() -> new BadRequestException("Cuenta no encontrada"));
        Long perfilId = perfilService.idPrincipal(cuentaId);
        List<Movimiento> movimientos = syncService.obtenerMovimientosMapeados(cuenta.getUsuario().getId(), perfilId);
        return ResponseEntity.ok(movimientos);
    }

    @PostMapping("/sincronizar")
    public ResponseEntity<Object> sincronizar(@AuthenticationPrincipal Long cuentaId) {
        Cuenta cuenta = cuentaRepository.findById(cuentaId)
                .orElseThrow(() -> new BadRequestException("Cuenta no encontrada"));
        Long perfilId = perfilService.idPrincipal(cuentaId);
        SincronizacionResumenDTO resumen = syncService.sincronizarMovimientos(cuenta.getUsuario().getId(), perfilId);
        return Response.ok(resumen, "Sincronización completada exitosamente");
    }

    @GetMapping("/movimientos/disponibles")
    public ResponseEntity<Object> obtenerDisponibles(@AuthenticationPrincipal Long cuentaId) {
        Cuenta cuenta = cuentaRepository.findById(cuentaId)
                .orElseThrow(() -> new BadRequestException("Cuenta no encontrada"));
        BusquedaMPResponseDTO respuesta = syncService.obtenerDisponiblesParaImportar(cuenta.getUsuario().getId());
        return Response.ok(respuesta, "Movimientos disponibles obtenidos exitosamente");
    }

    @PostMapping("/importar-seleccionados")
    public ResponseEntity<Object> importarSeleccionados(
            @AuthenticationPrincipal Long cuentaId,
            @RequestBody Map<String, Object> body) {
        Cuenta cuenta = cuentaRepository.findById(cuentaId)
                .orElseThrow(() -> new BadRequestException("Cuenta no encontrada"));

        @SuppressWarnings("unchecked")
        List<String> externalIds = (List<String>) body.get("externalIds");
        Long perfilId = perfilService.idPrincipal(cuentaId);

        if (externalIds == null || externalIds.isEmpty()) {
            throw new BadRequestException("Debe enviar al menos un movimiento para importar");
        }

        SincronizacionResumenDTO resumen = syncService.importarSeleccionados(
                cuenta.getUsuario().getId(),
                externalIds,
                perfilId);

        return Response.ok(resumen, "Movimientos importados exitosamente");
    }
}