package com.finza.backend.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.view.RedirectView;

import com.finza.backend.model.CuentaMP;
import com.finza.backend.service.MercadoPagoOAuthService;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/mercadopago")
@RequiredArgsConstructor
public class MercadoPagoOAuthController {

    private final MercadoPagoOAuthService oAuthService;

    @GetMapping("/autorizar")
    public RedirectView autorizar(@RequestParam Long usuarioId) {
        String url = oAuthService.generarUrlAutorizacion(usuarioId);
        return new RedirectView(url);
    }

    @GetMapping("/callback")
    public ResponseEntity<String> callback(@RequestParam String code, @RequestParam String state) {
        CuentaMP cuentaGuardada = oAuthService.procesarCallback(code, state);
        return ResponseEntity.ok("¡Cuenta vinculada exitosamente! MP User ID: " + cuentaGuardada.getMpIdUser());
    }
}