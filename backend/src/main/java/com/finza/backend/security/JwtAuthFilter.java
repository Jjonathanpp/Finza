package com.finza.backend.security;

import io.jsonwebtoken.Claims;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;

@Component
public class JwtAuthFilter extends OncePerRequestFilter {

    private final JwtService jwtService;

    // El atajo de autenticación de los tests de Cucumber (el header X-Test-Cuenta-Id, abajo) solo existe
    // donde se lo prende a propósito: va en true en application-docker.properties. Acá el valor por
    // defecto es false, así que en producción (perfil prod, que no la define) el bloque queda muerto:
    // si no, cualquiera entraría como cualquier cuenta mandando solo ese header, sin token.
    @Value("${app.auth-de-prueba:false}")
    private boolean authDePrueba;

    public JwtAuthFilter(JwtService jwtService) {
        this.jwtService = jwtService;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain)
            throws ServletException, IOException {

        String header = request.getHeader("Authorization");

        if (header != null && header.startsWith("Bearer ")) {
            String token = header.substring(7);

            if (jwtService.isTokenValid(token)) {
                Claims claims = jwtService.extractClaims(token);

                if ("access".equals(claims.get("type"))) {
                    Long cuentaId = Long.valueOf(claims.getSubject());

                    UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
                            cuentaId, null, List.of());

                    SecurityContextHolder.getContext().setAuthentication(authentication);
                    filterChain.doFilter(request, response);
                    return;
                }
            }
            filterChain.doFilter(request, response);
            return;
        }

        String testCuentaId = request.getHeader("X-Test-Cuenta-Id");
        if (authDePrueba && testCuentaId != null && !testCuentaId.isBlank()) {
            try {
                Long cuentaId = Long.valueOf(testCuentaId.trim());
                UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(cuentaId,
                        null, List.of());
                SecurityContextHolder.getContext().setAuthentication(authentication);
            } catch (NumberFormatException ignored) {
            }
        }

        filterChain.doFilter(request, response);
    }
}