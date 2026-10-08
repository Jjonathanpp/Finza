package com.finza.backend.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.servlet.view.RedirectView;

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

    @GetMapping("/autorizar")
    public RedirectView autorizar(@RequestParam Long usuarioId) {
        String url = oAuthService.generarUrlAutorizacion(usuarioId);
        return new RedirectView(url);
    }

    @GetMapping("/callback")
    public ResponseEntity<Object> callback(@RequestParam String code, @RequestParam String state) {
        CuentaMP cuentaGuardada = oAuthService.procesarCallback(code, state);
        return Response.ok(
            Map.of("mpUserId", cuentaGuardada.getMpIdUser()),
            "Cuenta vinculada exitosamente"
        );
    }

    @DeleteMapping("/desvincular")
    public ResponseEntity<Object> desvincular(@RequestParam Long usuarioId) {
        oAuthService.desvincular(usuarioId);
        return Response.ok(null, "Cuenta de Mercado Pago desvinculada exitosamente.");
    }

    @GetMapping("/estado")
    public ResponseEntity<Object> obtenerEstado(@RequestParam Long usuarioId) {
        boolean conectado = oAuthService.estaConectado(usuarioId);
        return Response.ok(
            Map.of("conectado", conectado),
            "Estado de vinculación obtenido correctamente"
        );
    }
}