package com.finza.backend.controller.Cuenta;

import com.finza.backend.dto.Response;
import com.finza.backend.dto.cambio_contraseña.CambioPasswordRequestDTO;
import com.finza.backend.dto.eliminacionCuenta.EliminarCuentaRequest;
import com.finza.backend.dto.login.LoginRequestDTO;
import com.finza.backend.dto.registro.CuentaRegistroDTO;
import com.finza.backend.security.JwtService;
import com.finza.backend.service.CuentaService;
import jakarta.validation.Valid;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.security.core.Authentication;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final CuentaService cuentaService;
    private final JwtService jwtService;

    public AuthController(CuentaService cuentaService, JwtService jwtService) {
        this.cuentaService = cuentaService;
        this.jwtService = jwtService;
    }

    @PostMapping("/registro")
    public ResponseEntity<Object> registrar(@Valid @RequestBody CuentaRegistroDTO dto) {
        return Response.created(cuentaService.crear(dto), "Cuenta creada");
    }

    @PostMapping("/login")
    public ResponseEntity<Object> login(@Valid @RequestBody LoginRequestDTO dto) {
        return Response.ok(cuentaService.login(dto));
    }

    @DeleteMapping("/me")
    public ResponseEntity<Object> eliminarCuenta(
            @RequestHeader(value = "Authorization", required = false) String authHeader,
            @Valid @RequestBody EliminarCuentaRequest request) {

        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            return Response.unauthorized("No autenticado");
        }

        String token = authHeader.substring(7);
        boolean esAccessToken = jwtService.isTokenValid(token)
                && "access".equals(jwtService.extractClaims(token).get("type", String.class));

        if (!esAccessToken) {
            return Response.unauthorized("Token inválido o expirado");
        }

        Long cuentaId = jwtService.extractCuentaId(token);

        cuentaService.eliminarCuenta(cuentaId, request.getPassword());
        return Response.ok(null, "Cuenta eliminada correctamente");
    }

    @PostMapping("/cambio-contrasena")
    public ResponseEntity<Object> cambiarPassword(
            @Valid @RequestBody CambioPasswordRequestDTO dto,
            Authentication authentication) {

        Long cuentaId = (Long) authentication.getPrincipal();

        cuentaService.cambiarPassword(cuentaId, dto);

        return Response.ok(null, "Contraseña cambiada exitosamente");
    }

}