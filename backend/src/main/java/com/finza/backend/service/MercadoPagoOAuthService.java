package com.finza.backend.service;

import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.util.Base64;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;
import org.springframework.transaction.annotation.Transactional;

import com.finza.backend.config.MercadoPagoProperties;
import com.finza.backend.dto.MercadoPagoTokenResponse;
import com.finza.backend.exception.BadRequestException;
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
    private static final long STATE_TTL_SECONDS = 600; // 10 minutos

    private final MercadoPagoProperties mpProperties;
    private final CuentaMPRepository cuentaMPRepository;
    private final UsuarioRepository usuarioRepository;
    private final RestTemplate restTemplate = new RestTemplate();

    private final Map<String, Long> stateStorage = new ConcurrentHashMap<>();

    public String generarUrlAutorizacion(Long usuarioId) {
        String state = UUID.randomUUID().toString();
        stateStorage.put(state, usuarioId);
        log.info("State generado: {}", state);
        return UriComponentsBuilder.fromUriString(MP_AUTH_URL)
                .queryParam("client_id", mpProperties.getClientId())
                .queryParam("response_type", "code")
                .queryParam("platform_id", "mp")
                .queryParam("state", state)
                .queryParam("redirect_uri", mpProperties.getRedirectUri())
                .toUriString();
    }

    public CuentaMP procesarCallback(String code, String state) {
        log.info("Callback recibido - state: {}", state);
        Long usuarioId = stateStorage.remove(state);
        if (usuarioId == null) {
            throw new IllegalArgumentException("Parámetro 'state' inválido o expirado.");
        }

        Usuario usuario = usuarioRepository.findById(usuarioId)
                .orElseThrow(() -> new IllegalArgumentException("Usuario no encontrado con ID: " + usuarioId));

        MercadoPagoTokenResponse tokenResponse = intercambiarCodigoPorToken(code);

        String mpUserId = String.valueOf(tokenResponse.getUserId());

        java.util.Optional<CuentaMP> existente = cuentaMPRepository.findByMpIdUser(mpUserId);
        if (existente.isPresent() && !existente.get().getUsuario().getId().equals(usuarioId)) {
            throw new BadRequestException(
                    "Esta cuenta de Mercado Pago ya está vinculada a otro usuario de Finza. "
                            + "Desvinculala desde la otra cuenta primero.");
        }

        CuentaMP cuentaMP = cuentaMPRepository.findByUsuarioId(usuarioId)
                .orElseGet(() -> {
                    CuentaMP nueva = new CuentaMP();
                    nueva.setUsuario(usuario);
                    return nueva;
                });

        cuentaMP.setAccessToken(tokenResponse.getAccessToken());
        cuentaMP.setRefreshToken(tokenResponse.getRefreshToken());
        cuentaMP.setMpIdUser(mpUserId);
        if (tokenResponse.getExpiresIn() != null && tokenResponse.getExpiresIn() > 0) {
            cuentaMP.setFechaExpiracionToken(LocalDateTime.now().plusSeconds(tokenResponse.getExpiresIn()));
        }

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
                "redirect_uri", mpProperties.getRedirectUri());

        HttpEntity<Map<String, Object>> requestEntity = new HttpEntity<>(body, headers);

        try {
            return restTemplate.postForObject(MP_TOKEN_URL, requestEntity, MercadoPagoTokenResponse.class);
        } catch (Exception e) {
            log.error("Error al intercambiar código con Mercado Pago: {}", e.getMessage());
            throw new RuntimeException("Error en la autenticación con Mercado Pago", e);
        }
    }

    @Transactional
    public void desvincular(Long usuarioId) {
        CuentaMP cuentaMP = cuentaMPRepository.findByUsuarioId(usuarioId)
                .orElseThrow(() -> new BadRequestException(
                        "No se encontró una cuenta de Mercado Pago vinculada para este usuario."));

        if (cuentaMP.getAccessToken() != null && !cuentaMP.getAccessToken().isBlank()
                && cuentaMP.getMpIdUser() != null) {
            revocarEnMercadoPago(cuentaMP.getAccessToken(), cuentaMP.getMpIdUser());
        }

        cuentaMPRepository.deleteByUsuarioId(usuarioId);
        cuentaMPRepository.flush();
        log.info("Cuenta de Mercado Pago desvinculada correctamente para el usuario {}", usuarioId);
    }

    private void revocarEnMercadoPago(String accessToken, String mpUserId) {
        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setBearerAuth(accessToken);
            HttpEntity<Void> entity = new HttpEntity<>(headers);
            String url = "https://api.mercadopago.com/users/" + mpUserId + "/applications/"
                    + mpProperties.getClientId();
            restTemplate.exchange(url, org.springframework.http.HttpMethod.DELETE, entity, Void.class);
            log.info("Aplicación desvinculada en Mercado Pago para mpUserId={}", mpUserId);
        } catch (Exception e) {
            log.warn("Aviso al revocar en MP (puede haberse desautorizado antes): {}", e.getMessage());
        }
    }

    public boolean estaConectado(Long usuarioId) {
        return cuentaMPRepository.findByUsuarioId(usuarioId).isPresent();
    }

    @Transactional
    public String obtenerAccessTokenVigente(Long usuarioId) {
        CuentaMP cuentaMP = cuentaMPRepository.findByUsuarioId(usuarioId)
                .orElseThrow(() -> new BadRequestException(
                        "No se encontró una cuenta de Mercado Pago vinculada"));

        if (cuentaMP.getFechaExpiracionToken() != null
                && cuentaMP.getFechaExpiracionToken().isAfter(LocalDateTime.now().plusMinutes(5))) {
            return cuentaMP.getAccessToken();
        }

        if (cuentaMP.getRefreshToken() == null || cuentaMP.getRefreshToken().isBlank()) {
            throw new BadRequestException(
                    "Mercado Pago necesita volver a vincularse");
        }

        Map<String, Object> body = Map.of(
                "client_secret", mpProperties.getClientSecret(),
                "client_id", mpProperties.getClientId(),
                "grant_type", "refresh_token",
                "refresh_token", cuentaMP.getRefreshToken());

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<Map<String, Object>> request = new HttpEntity<>(body, headers);

        try {
            MercadoPagoTokenResponse response = restTemplate.postForObject(
                    MP_TOKEN_URL, request, MercadoPagoTokenResponse.class);

            if (response == null || response.getAccessToken() == null) {
                throw new BadRequestException(
                        "Mercado Pago no pudo renovar la conexión");
            }

            cuentaMP.setAccessToken(response.getAccessToken());
            if (response.getRefreshToken() != null) {
                cuentaMP.setRefreshToken(response.getRefreshToken());
            }
            if (response.getUserId() != null) {
                cuentaMP.setMpIdUser(String.valueOf(response.getUserId()));
            }
            Long expiresIn = response.getExpiresIn();
            if (expiresIn == null || expiresIn <= 0) {
                throw new BadRequestException(
                        "Mercado Pago no informó cuándo vence la nueva conexión");
            }

            cuentaMP.setFechaExpiracionToken(
                    LocalDateTime.now().plusSeconds(expiresIn));

            cuentaMPRepository.save(cuentaMP);
            return response.getAccessToken();
        } catch (BadRequestException e) {
            throw e;
        } catch (Exception e) {
            log.error("Error renovando el token de Mercado Pago: {}", e.getMessage());
            throw new BadRequestException(
                    "Mercado Pago necesita volver a vincularse");
        }
    }
}