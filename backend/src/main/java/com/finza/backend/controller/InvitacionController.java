package com.finza.backend.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.finza.backend.dto.Response;
import com.finza.backend.dto.Invitaciones_a_Cuenta.InvitacionRequest;
import com.finza.backend.service.InvitacionService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/cuentas-compartidas/{cuentaCompartidaId}/invitaciones")
public class InvitacionController {

    private final InvitacionService invitacionService;

    public InvitacionController(InvitacionService invitacionService) {
        this.invitacionService = invitacionService;
    }

    @PostMapping
    public ResponseEntity<Object> invitar(
            @PathVariable Long cuentaCompartidaId,
            @Valid @RequestBody InvitacionRequest request,
            Authentication authentication) {

        Long cuentaId = (Long) authentication.getPrincipal();

        return Response.created(
                invitacionService.crear(cuentaCompartidaId, cuentaId, request),
                "Invitación enviada");
    }
}