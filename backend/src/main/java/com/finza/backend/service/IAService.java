package com.finza.backend.service;

import java.net.URI;
import java.net.URISyntaxException;
import java.util.Base64;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.client.HttpServerErrorException;
import org.springframework.web.client.RestTemplate;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.finza.backend.dto.movimiento.MovimientoIADTO;

@Service
public class IAService {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Value("${gemini.api.url}")
    private String apiUrl;

    @Value("${gemini.api.url.fallback}")
    private String apiUrlFallback;

    @Value("${gemini.api.key}")
    private String apiKey;

    private final RestTemplate restTemplate;

    public IAService() {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(10000);
        factory.setReadTimeout(30000);
        this.restTemplate = new RestTemplate(factory);
    }

    public String procesarAudio(byte[] audioBytes, String categoriasDisponibles) throws Exception {
        String base64Audio = Base64.getEncoder().encodeToString(audioBytes);
        String fechaHoy = java.time.LocalDate.now().format(java.time.format.DateTimeFormatter.ofPattern("dd-MM-yyyy"));
        
        String prompt = "Sos un asistente financiero. Hoy es " + fechaHoy + ". Escuchá este audio y extraé los datos. Devolveme ÚNICAMENTE un JSON válido con estas claves: 'tipo' (ingreso o egreso), 'monto' (solo el número), 'categoria' (Elegí obligatoriamente UNA de esta lista: [" + categoriasDisponibles + "]. Si ninguna coincide, devolvé 'Otros'), 'descripcion' (breve) y 'fecha' (en formato dd-MM-yyyy, si el audio dice 'ayer' o 'el lunes' calculala, si no menciona fecha usá la de hoy). No agregues texto extra ni comillas.";

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
                        "mime_type": "audio/mp4", 
                        "data": "%s"
                      }
                    }
                  ]
                }
              ]
            }
            """.formatted(prompt, base64Audio);

        try {
            return intentarLlamada(apiUrl, requestBody);
        } catch (HttpServerErrorException e) {
            try {
                return intentarLlamada(apiUrlFallback, requestBody);
            } catch (Exception fallbackEx) {
                throw new RuntimeException("Los servidores de IA están saturados incluso en el modelo de respaldo. Probá de nuevo en unos segundos.");
            }
        }
    }


    public MovimientoIADTO procesarAudioYExtraerDatos(byte[] audioBytes, String categoriasDisponibles) throws Exception {
        String jsonCrudoGemini = procesarAudio(audioBytes, categoriasDisponibles);
        
        JsonNode rootNode = objectMapper.readTree(jsonCrudoGemini);
        String textoDeLaIA = rootNode.path("candidates").path(0)
                                     .path("content")
                                     .path("parts").path(0)
                                     .path("text").asText();
        
        textoDeLaIA = textoDeLaIA.replace("```json", "").replace("```", "").trim();
        return objectMapper.readValue(textoDeLaIA, MovimientoIADTO.class);
    }

    private String intentarLlamada(String urlBase, String requestBody) {
        int intentos = 0;
        int maxIntentos = 3;
        while (true) {
            try {
                HttpHeaders headers = new HttpHeaders();
                headers.setContentType(MediaType.APPLICATION_JSON);
                URI uri;
                try {
                    uri = new URI(urlBase.trim() + "?key=" + apiKey.trim());
                } catch (URISyntaxException e) {
                    throw new RuntimeException("URL de la API mal formada: " + e.getMessage(), e);
                }
                HttpEntity<String> entity = new HttpEntity<>(requestBody, headers);
                ResponseEntity<String> response = restTemplate.postForEntity(uri, entity, String.class);
                return response.getBody();
            } catch (HttpServerErrorException e) {
                intentos++;
                if (intentos >= maxIntentos) throw e;
                try {
                    Thread.sleep(1000L * intentos);
                } catch (InterruptedException ignored) {}
            }
        }
    }
}