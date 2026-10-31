package com.finza.backend.service;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import java.util.HashMap;

import org.springframework.web.util.HtmlUtils;

import com.finza.backend.exception.EnvioCorreoException;

@Service
public class EmailService {

    private static final DateTimeFormatter FORMATO_FECHA = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");

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
        enviar(destino,
                "Código para restablecer tu contraseña",
                "Tu código es: " + codigo
                        + "\n\nExpira en 5 minutos. Si no lo solicitaste, ignora este correo.",
                null);
    }

    public void enviarInvitacion(String destino, String nombreInvitador,
            String link, LocalDateTime expiracion) {
        String vence = expiracion.format(FORMATO_FECHA);
        String nombreSeguro = HtmlUtils.htmlEscape(nombreInvitador);
        String linkSeguro = HtmlUtils.htmlEscape(link);

        String textoPlano = nombreInvitador + " te invitó a unirte a su cuenta compartida en Finza."
                + "\n\nPara aceptar o rechazar la invitación, ingresá a este enlace:\n"
                + link
                + "\n\nLa invitación vence el " + vence
                + " (24 horas desde que fue enviada). Si no la esperabas, ignora este correo.";

        String html = """
                <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto;">
                  <h2>Te invitaron a una cuenta compartida</h2>
                  <p><b>%s</b> te invitó a unirte a su cuenta compartida en Finza.</p>
                  <p style="margin: 28px 0;">
                    <a href="%s"
                       style="background-color: #2e7d32; color: #ffffff; padding: 12px 24px;
                              text-decoration: none; border-radius: 6px; display: inline-block;">
                      Abrir invitación en Finza
                    </a>
                  </p>
                  <p style="color: #666; font-size: 13px;">
                    La invitación vence el %s (24 horas desde que fue enviada).
                    Si no la esperabas, ignora este correo.
                  </p>
                  <p style="color: #666; font-size: 13px;">
                    Si el botón no abre la app, copiá y pegá este enlace en el navegador del celular:<br>
                    %s
                  </p>
                </div>
                """.formatted(nombreSeguro, linkSeguro, vence, linkSeguro);

        enviar(destino, nombreInvitador + " te invitó a unirte a una cuenta compartida", textoPlano, html);
    }

    private void enviar(String destino, String asunto, String textoPlano, String html) {
        Map<String, Object> body = new HashMap<>();
        body.put("sender", Map.of("name", senderName, "email", senderEmail));
        body.put("to", List.of(Map.of("email", destino)));
        body.put("subject", asunto);
        body.put("textContent", textoPlano);
        if (html != null) {
            body.put("htmlContent", html);
        }

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