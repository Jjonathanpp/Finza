package com.finza.backend.service;

import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

import com.finza.backend.exception.EnvioCorreoException;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;


@Service
public class EmailService {

    private final RestClient restClient = RestClient.create("https://api.brevo.com/v3");

    private final String apiKey;
    private final String senderEmail;
    private final String senderName;

    public EmailService(@Value("${brevo.api-key}") String apiKey,
                        @Value("${brevo.sender-email}") String senderEmail,
                        @Value("${brevo.sender-name}") String senderName) {
        this.apiKey = apiKey;
        this.senderEmail = senderEmail;
        this.senderName = senderName;
    }

public void enviarCodigoRecuperacion(String destino, String codigo) {
    Map<String, Object> body = Map.of(
            "sender", Map.of("name", senderName, "email", senderEmail),
            "to", List.of(Map.of("email", destino)),
            "subject", "Código para restablecer tu contraseña",
            "textContent", "Tu código es: " + codigo
                    + "\n\nExpira en 5 minutos. Si no lo solicitaste, ignora este correo."
    );

    try {
        restClient.post()
                .uri("/smtp/email")
                .header("api-key", apiKey)
                .contentType(MediaType.APPLICATION_JSON)
                .body(body)
                .retrieve()
                .toBodilessEntity();
    } catch (RestClientException e) {
        throw new EnvioCorreoException("Fallo al enviar el correo con Brevo", e);
    }
}
}