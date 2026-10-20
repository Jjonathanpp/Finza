package com.finza.backend.service;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

import com.finza.backend.dto.preferencias.MonedaDTO;
import com.finza.backend.model.PreferenciasSistema.Moneda;

import lombok.extern.slf4j.Slf4j;

// Cotizaciones oficiales (venta) de DolarApi, gratis y sin clave.
@Slf4j
@Service
public class CotizacionService {

    // De la respuesta solo se usan estos dos: también trae compra, casa y nombre
    record Cotizacion(BigDecimal venta, Instant fechaActualizacion) {}

    record Guardada(Cotizacion cotizacion, Instant pedida) {}

    private static final Duration VIGENCIA = Duration.ofHours(1);

    private final RestTemplate restTemplate;
    private final String apiUrl;
    // En memoria: si Render reinicia, la primera consulta la vuelve a pedir
    private final Map<Moneda, Guardada> guardadas = new ConcurrentHashMap<>();

    public CotizacionService(@Value("${cotizaciones.api.url}") String apiUrl) {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(5000);
        factory.setReadTimeout(5000);
        this.restTemplate = new RestTemplate(factory);
        this.apiUrl = apiUrl;
    }

    public MonedaDTO conCotizacion(Moneda moneda) {
        Cotizacion cotizacion = switch (moneda) {
            case PESO -> null;
            case DOLAR -> buscar(moneda, "/dolares/oficial");
            case EURO -> buscar(moneda, "/cotizaciones/eur");
        };
        return cotizacion == null
                ? new MonedaDTO(moneda, null, null)
                : new MonedaDTO(moneda, cotizacion.venta(), cotizacion.fechaActualizacion());
    }

    // La guardada si es de hace menos de una hora. Si DolarApi falla, la última que haya (o ninguna):
    // al usuario nunca le llega un error por esto, la app muestra pesos.
    private Cotizacion buscar(Moneda moneda, String ruta) {
        Guardada guardada = guardadas.get(moneda);
        if (guardada != null && guardada.pedida().plus(VIGENCIA).isAfter(Instant.now())) {
            return guardada.cotizacion();
        }
        try {
            Cotizacion nueva = restTemplate.getForObject(apiUrl + ruta, Cotizacion.class);
            log.info("Cotización de {} pedida a DolarApi", moneda);
            guardadas.put(moneda, new Guardada(nueva, Instant.now()));
            return nueva;
        } catch (RestClientException e) {
            // ponytail: con DolarApi caído, cada consulta lo vuelve a intentar (hasta 5 s). Guardar el intento si molesta.
            log.warn("DolarApi no respondió la cotización de {}: {}", moneda, e.getMessage());
            return guardada == null ? null : guardada.cotizacion();
        }
    }
}
