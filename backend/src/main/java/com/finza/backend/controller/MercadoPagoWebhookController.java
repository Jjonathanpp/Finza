package com.finza.backend.controller;

import java.nio.charset.StandardCharsets;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDateTime;
import java.util.Base64;
import java.util.Map;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.finza.backend.config.MercadoPagoProperties;
import com.finza.backend.model.WebhookMP;
import com.finza.backend.repository.WebhookMPRepository;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@RestController
@RequestMapping("/api/mercadopago/webhook")
@RequiredArgsConstructor
public class MercadoPagoWebhookController {

    private final WebhookMPRepository webhookRepository;
    private final MercadoPagoProperties mpProperties;

    @PostMapping
    public ResponseEntity<Void> recibirWebhook(@RequestBody Map<String, Object> body,
            jakarta.servlet.http.HttpServletRequest request) {

        String signature = request.getHeader("x-signature");
        String webhookSecret = mpProperties.getWebhookSecret();

        if (webhookSecret != null && !webhookSecret.isEmpty()) {
            if (signature == null || signature.isEmpty()) {
                log.warn("Webhook MP sin firma y hay secreto configurado");
                return ResponseEntity.status(401).build();
            }
            if (!esFirmaValida(signature, body, webhookSecret)) {
                log.warn("Webhook MP con firma inválida");
                return ResponseEntity.status(401).build();
            }
        } else {
            if (signature == null || signature.isEmpty()) {
                log.warn("Webhook MP sin firma (sin secreto configurado)");
            }
        }

        String tipo = (String) body.get("type");

        Map<String, Object> data = (Map<String, Object>) body.get("data");
        String idRecurso = data != null ? String.valueOf(data.get("id")) : null;

        if (idRecurso == null) {
            log.warn("Webhook MP sin id de recurso");
            return ResponseEntity.badRequest().build();
        }

        if (webhookRepository.findByIdRecurso(idRecurso).isPresent()) {
            log.info("Webhook MP ya procesado: {}", idRecurso);
            return ResponseEntity.ok().build();
        }

        WebhookMP webhook = new WebhookMP();
        webhook.setTipoNotificacion(tipo);
        webhook.setIdRecurso(idRecurso);
        webhook.setFechaRecepcion(LocalDateTime.now());
        webhook.setProcesado(false);
        webhookRepository.save(webhook);

        log.info("Webhook MP guardado: tipo={}, idRecurso={}", tipo, idRecurso);

        return ResponseEntity.ok().build();
    }

    private boolean esFirmaValida(String signature, Map<String, Object> body, String secret) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            SecretKeySpec keySpec = new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256");
            mac.init(keySpec);

            String payload = body != null ? body.toString() : "";
            byte[] hmacBytes = mac.doFinal(payload.getBytes(StandardCharsets.UTF_8));
            String computed = Base64.getEncoder().encodeToString(hmacBytes);

            return computed.equals(signature);
        } catch (NoSuchAlgorithmException | InvalidKeyException e) {
            log.error("Error validando firma webhook", e);
            return false;
        }
    }
}