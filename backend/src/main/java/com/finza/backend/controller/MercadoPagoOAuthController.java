package com.finza.backend.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.servlet.view.RedirectView;
import org.springframework.security.core.annotation.AuthenticationPrincipal;

import com.finza.backend.model.Cuenta;
import com.finza.backend.repository.CuentaRepository;
import com.finza.backend.exception.BadRequestException;
import com.finza.backend.model.CuentaMP;
import com.finza.backend.service.MercadoPagoOAuthService;
import com.finza.backend.dto.Response;

import lombok.RequiredArgsConstructor;

import java.util.Map;

@RestController
@RequestMapping({"/api/mercadopago", "/mercadopago"})
@RequiredArgsConstructor
public class MercadoPagoOAuthController {

    private final MercadoPagoOAuthService oAuthService;
    private final CuentaRepository cuentaRepository;

    @GetMapping("/callback")
    public ResponseEntity<Object> callback(@RequestParam String code, @RequestParam String state) {
        CuentaMP cuentaGuardada = oAuthService.procesarCallback(code, state);
        return Response.ok(
            Map.of("mpUserId", cuentaGuardada.getMpIdUser()),
            "Cuenta vinculada exitosamente"
        );
    }

    @GetMapping("/autorizar")
    public ResponseEntity<Object> autorizar(@AuthenticationPrincipal Long cuentaId) {
        Cuenta cuenta = cuentaRepository.findById(cuentaId)
                .orElseThrow(() -> new BadRequestException("Cuenta no encontrada"));
        String url = oAuthService.generarUrlAutorizacion(cuenta.getUsuario().getId());
        return Response.ok(Map.of("url", url), "URL de autorización generada");
    }

    @DeleteMapping("/desvincular")
    public ResponseEntity<Object> desvincular(@AuthenticationPrincipal Long cuentaId) {
        Cuenta cuenta = cuentaRepository.findById(cuentaId)
                .orElseThrow(() -> new BadRequestException("Cuenta no encontrada"));
        oAuthService.desvincular(cuenta.getUsuario().getId());
        return Response.ok(null, "Cuenta de Mercado Pago desvinculada exitosamente.");
    }

    @GetMapping("/estado")
    public ResponseEntity<Object> obtenerEstado(@AuthenticationPrincipal Long cuentaId) {
        Cuenta cuenta = cuentaRepository.findById(cuentaId)
                .orElseThrow(() -> new BadRequestException("Cuenta no encontrada"));
        boolean conectado = oAuthService.estaConectado(cuenta.getUsuario().getId());
        return Response.ok(
            Map.of("conectado", conectado),
            "Estado de vinculación obtenido correctamente"
        );
    }
}