package com.finza.backend.controller.Cuenta;

import com.finza.backend.dto.Response;
import com.finza.backend.dto.login.LoginRequestDTO;
import com.finza.backend.dto.registro.CuentaRegistroDTO;
import com.finza.backend.service.CuentaService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final CuentaService cuentaService;

    public AuthController(CuentaService cuentaService) {
        this.cuentaService = cuentaService;
    }

    @PostMapping("/registro")
    public ResponseEntity<Object> registrar(@Valid @RequestBody CuentaRegistroDTO dto) {
        return Response.created(cuentaService.crear(dto), "Cuenta creada");
    }

    @PostMapping("/login")
    public ResponseEntity<Object> login(@Valid @RequestBody LoginRequestDTO dto) {
        return Response.ok(cuentaService.login(dto));
    }
}