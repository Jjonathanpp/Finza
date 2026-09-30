package com.finza.backend.controller.Cuenta;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.finza.backend.security.JwtService;

// TEMPORAL: solo para probar el filtro JWT antes de tener /login. Borrar cuando esté el login real.
@RestController
public class TestTokenController {

    private final JwtService jwtService;

    public TestTokenController(JwtService jwtService) {
        this.jwtService = jwtService;
    }

    @GetMapping("/api/test-token")
    public String generarTokenDePrueba(@RequestParam Long cuentaId, @RequestParam String email) {
        return jwtService.generateAccessToken(cuentaId, email);
    }
}