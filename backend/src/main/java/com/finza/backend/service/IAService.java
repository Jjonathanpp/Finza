package com.finza.backend.service;

import java.net.URI;
import java.util.Base64;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;

@Service
public class IAService {

    @Value("${gemini.api.url}")
    private String apiUrl;

    @Value("${gemini.api.key}")
    private String apiKey;

    private final RestTemplate restTemplate = new RestTemplate();

    public String procesarAudio(MultipartFile archivoAudio) throws Exception {
        byte[] audioBytes = archivoAudio.getBytes();
        String base64Audio = Base64.getEncoder().encodeToString(audioBytes);
        String fechaHoy = java.time.LocalDate.now().format(java.time.format.DateTimeFormatter.ofPattern("dd-MM-yyyy"));

        String prompt = "Sos un asistente financiero. Hoy es " + fechaHoy + ". Escuchá este audio y extraé los datos. Devolveme ÚNICAMENTE un JSON válido con estas claves: 'tipo' (ingreso o egreso), 'monto' (solo el número), 'categoria' (inferida), 'descripcion' (breve) y 'fecha' (en formato dd-MM-yyyy, si el audio dice 'ayer' o 'el lunes' calculala, si no menciona fecha usá la de hoy). No agregues texto extra ni comillas.";

        String requestBody = """
            {
              "contents": [
                {
                  "parts": [
                    {
                      "text": "%s"
                    },
                    {
                      "inline_data": {
                        "mime_type": "audio/mp3",
                        "data": "%s"
                      }
                    }
                  ]
                }
              ]
            }
            """.formatted(prompt, base64Audio);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        
        // URL limpia apuntando al modelo 2.5 directo por URI
        String urlConKey = apiUrl.trim() + "?key=" + apiKey.trim();
        URI uri = new URI(urlConKey);
        
        HttpEntity<String> entity = new HttpEntity<>(requestBody, headers);
        ResponseEntity<String> response = restTemplate.postForEntity(uri, entity, String.class);

        return response.getBody();
    }
}