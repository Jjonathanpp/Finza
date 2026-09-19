package com.finza.backend.service;

import java.net.URI;
import java.util.Base64;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.HttpServerErrorException;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;

@Service
public class IAService {

    @Value("${gemini.api.url}")
    private String apiUrl;

    @Value("${gemini.api.key}")
    private String apiKey;

    private final RestTemplate restTemplate;

    // Configuramos los timeouts en el constructor
    public IAService() {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(10000); // 5 segundos máximo para establecer conexión
        factory.setReadTimeout(30000);   // 15 segundos máximo esperando la respuesta de Gemini
        this.restTemplate = new RestTemplate(factory);
    }

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
        
        String urlConKey = apiUrl.trim() + "?key=" + apiKey.trim();
        URI uri = new URI(urlConKey);
        HttpEntity<String> entity = new HttpEntity<>(requestBody, headers);

        try {
            // Intentamos pegarle a Google
            ResponseEntity<String> response = restTemplate.postForEntity(uri, entity, String.class);
            return response.getBody();
            
        } catch (ResourceAccessException e) {
            // Atrapa cortes de internet, Docker sin red, o si se superan los 15 segundos de timeout
            throw new RuntimeException("Sin conexión a internet o tiempo de espera agotado. Verificá tu red e intentá nuevamente.");
            
        } catch (HttpServerErrorException e) {
            // Atrapa errores 5xx (como el 503 de alta demanda que te pasó hoy)
            throw new RuntimeException("Los servidores de inteligencia artificial están saturados (" + e.getStatusCode() + "). Esperá unos segundos y volvé a intentar.");
            
        } catch (HttpClientErrorException e) {
            // Atrapa errores 4xx (como un 401 si se te vence la API Key)
            throw new RuntimeException("Error de autenticación con la IA o credenciales inválidas (" + e.getStatusCode() + ").");
            
        } catch (Exception e) {
            // Atrapa cualquier otro problema rarísimo
            throw new RuntimeException("Error inesperado comunicando con la IA: " + e.getMessage());
        }
    }
}