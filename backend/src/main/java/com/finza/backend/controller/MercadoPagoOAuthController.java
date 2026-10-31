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

import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

@RestController
@RequestMapping({"/api/mercadopago", "/mercadopago"})
@RequiredArgsConstructor
public class MercadoPagoOAuthController {

    private final MercadoPagoOAuthService oAuthService;
    private final CuentaRepository cuentaRepository;

    @GetMapping(value = "/callback", produces = "text/html;charset=UTF-8")
    public void callback(HttpServletResponse response, @RequestParam String code, @RequestParam String state) throws IOException {
        CuentaMP cuentaGuardada = oAuthService.procesarCallback(code, state);
        String mpUserId = cuentaGuardada.getMpIdUser() != null ? cuentaGuardada.getMpIdUser() : "";

        response.setContentType("text/html;charset=UTF-8");
        response.getWriter().write("""
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>Vinculando Mercado Pago con Finza</title>
            </head>
            <body style="font-family:sans-serif;display:flex;flex-direction:column;align-items:center;justify-content:center;height:100vh;margin:0;background:#f5f5f5;">
                <div style="text-align:center;padding:24px;background:#fff;border-radius:16px;box-shadow:0 2px 12px rgba(0,0,0,0.1);max-width:400px;">
                    <div style="font-size:48px;margin-bottom:16px;">💳</div>
                    <h2 style="margin:0 0 8px 0;font-size:20px;color:#1a1a1a;">Vinculación exitosa</h2>
                    <p style="margin:0 0 20px 0;color:#666;font-size:14px;">Tu cuenta de Mercado Pago quedó conectada con Finza. Redirigiendo a la app...</p>
                    <a href="finza://mercadopago/callback?exito=true&mpUserId=%s"
                    style="display:inline-block;padding:12px 24px;background:#009EE3;color:#fff;border-radius:8px;text-decoration:none;font-weight:bold;font-size:14px;">
                    Abrir Finza
                    </a>
                    <p style="margin-top:16px;font-size:12px;color:#999;">Si la app no se abre, tocá el botón de arriba.</p>
                </div>
                <script>
                    setTimeout(function() {
                        window.location = "finza://mercadopago/callback?exito=true&mpUserId=%s";
                    }, 800);
                </script>
            </body>
            </html>
            """.formatted(mpUserId, mpUserId));
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