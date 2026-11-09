package com.finza.backend.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.finza.backend.dto.Response;
import com.finza.backend.dto.Invitaciones_a_Cuenta.TokenInvitacionRequest;
import com.finza.backend.service.InvitacionService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

// Para quien recibe la invitación y abre el enlace (t-11.2.2): ver de qué se trata, aceptar o
// rechazar, solo con el token. Hace falta estar logueado (SecurityConfig: anyRequest authenticated),
// y la invitación tiene que ser para el email de esa cuenta.
@RestController
@RequestMapping("/api/invitaciones")
@RequiredArgsConstructor
public class InvitacionRecibidaController {

    private final InvitacionService invitacionService;

    @PostMapping("/detalle")
    public ResponseEntity<Object> detalle(@AuthenticationPrincipal Long cuentaId,
            @Valid @RequestBody TokenInvitacionRequest request) {
        return Response.ok(invitacionService.detalle(request.token(), cuentaId), "Invitación obtenida");
    }

    @PostMapping("/aceptar")
    public ResponseEntity<Object> aceptar(@AuthenticationPrincipal Long cuentaId,
            @Valid @RequestBody TokenInvitacionRequest request) {
        return Response.ok(invitacionService.aceptarPorToken(request.token(), cuentaId), "Invitación aceptada");
    }

    @PostMapping("/rechazar")
    public ResponseEntity<Object> rechazar(@AuthenticationPrincipal Long cuentaId,
            @Valid @RequestBody TokenInvitacionRequest request) {
        invitacionService.rechazar(request.token(), cuentaId);
        return Response.ok(null, "Invitación rechazada");
    }
}