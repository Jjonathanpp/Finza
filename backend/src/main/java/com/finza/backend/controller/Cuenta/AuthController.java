package com.finza.backend.controller.Cuenta;

import com.finza.backend.dto.registro.CuentaRegistroDTO;
import com.finza.backend.dto.registro.CuentaResponseDTO;
import com.finza.backend.service.CuentaService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
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
    public ResponseEntity<CuentaResponseDTO> registrar(@Valid @RequestBody CuentaRegistroDTO dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(cuentaService.crear(dto));
    }
}