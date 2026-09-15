package com.finza.backend.service;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import com.finza.backend.config.MercadoPagoProperties;
import com.finza.backend.dto.MercadoPagoTokenResponse;
import com.finza.backend.model.CuentaMP;
import com.finza.backend.model.Usuario;
import com.finza.backend.repository.CuentaMPRepository;
import com.finza.backend.repository.UsuarioRepository;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Service
@RequiredArgsConstructor
public class MercadoPagoOAuthService {

    private static final String MP_AUTH_URL = "https://auth.mercadopago.com.ar/authorization";
    private static final String MP_TOKEN_URL = "https://api.mercadopago.com/oauth/token";

    private final MercadoPagoProperties mpProperties;
    private final CuentaMPRepository cuentaMPRepository;
    private final UsuarioRepository usuarioRepository;
    private final RestTemplate restTemplate = new RestTemplate();

    private final Map<String, Long> stateStorage = new ConcurrentHashMap<>();

    public String generarUrlAutorizacion(Long usuarioId) {
        String state = UUID.randomUUID().toString();
        stateStorage.put(state, usuarioId);

        return UriComponentsBuilder.fromUriString(MP_AUTH_URL)
                .queryParam("client_id", mpProperties.getClientId())
                .queryParam("response_type", "code")
                .queryParam("platform_id", "mp")
                .queryParam("state", state)
                .queryParam("redirect_uri", mpProperties.getRedirectUri())
                .toUriString();
    }

    public CuentaMP procesarCallback(String code, String state) {
        Long usuarioId = stateStorage.remove(state);
        if (usuarioId == null) {
            throw new IllegalArgumentException("Parámetro 'state' inválido o expirado.");
        }

        Usuario usuario = usuarioRepository.findById(usuarioId)
                .orElseThrow(() -> new IllegalArgumentException("Usuario no encontrado con ID: " + usuarioId));

        MercadoPagoTokenResponse tokenResponse = intercambiarCodigoPorToken(code);

        CuentaMP cuentaMP = cuentaMPRepository.findByUsuarioId(usuarioId)
                .orElseGet(() -> {
                    CuentaMP nueva = new CuentaMP();
                    nueva.setUsuario(usuario);
                    return nueva;
                });

        cuentaMP.setAccessToken(tokenResponse.getAccessToken());
        cuentaMP.setRefreshToken(tokenResponse.getRefreshToken());
        cuentaMP.setMpIdUser(String.valueOf(tokenResponse.getUserId()));
        cuentaMP.setFechaExpiracionToken(LocalDateTime.now().plusSeconds(tokenResponse.getExpiresIn()));

        return cuentaMPRepository.save(cuentaMP);
    }

    private MercadoPagoTokenResponse intercambiarCodigoPorToken(String code) {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);

        Map<String, Object> body = Map.of(
                "client_secret", mpProperties.getClientSecret(),
                "client_id", mpProperties.getClientId(),
                "grant_type", "authorization_code",
                "code", code,
                "redirect_uri", mpProperties.getRedirectUri()
        );

        HttpEntity<Map<String, Object>> requestEntity = new HttpEntity<>(body, headers);

        try {
            return restTemplate.postForObject(MP_TOKEN_URL, requestEntity, MercadoPagoTokenResponse.class);
        } catch (Exception e) {
            log.error("Error al intercambiar código con Mercado Pago: {}", e.getMessage());
            throw new RuntimeException("Error en la autenticación con Mercado Pago", e);
        }
    }
}