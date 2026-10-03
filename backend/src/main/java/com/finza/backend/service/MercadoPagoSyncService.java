package com.finza.backend.service;

import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import com.finza.backend.dto.mercadopago.BusquedaMPResponseDTO;
import com.finza.backend.exception.BadRequestException;
import com.finza.backend.model.CuentaMP;
import com.finza.backend.repository.CuentaMPRepository;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Service
@RequiredArgsConstructor
public class MercadoPagoSyncService {

    private static final String MP_URL_PAGOS = "https://api.mercadopago.com/v1/payments/search?sort=date_created&criteria=desc";

    private final CuentaMPRepository cuentaMPRepository;
    private final RestTemplate restTemplate = new RestTemplate();

    public BusquedaMPResponseDTO obtenerMovimientosDesdeMP(Long usuarioId) {
        CuentaMP cuentaMP = cuentaMPRepository.findByUsuarioId(usuarioId)
                .orElseThrow(() -> new BadRequestException("No se encontró una cuenta de Mercado Pago vinculada para el usuario"));

        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(cuentaMP.getAccessToken());

        HttpEntity<Void> peticion = new HttpEntity<>(headers);

        try {
            ResponseEntity<BusquedaMPResponseDTO> respuesta = restTemplate.exchange(
                    MP_URL_PAGOS,
                    HttpMethod.GET,
                    peticion,
                    BusquedaMPResponseDTO.class
            );

            return respuesta.getBody();
        } catch (Exception e) {
            log.error("Error al consultar la API de Mercado Pago para el usuario {}: {}", usuarioId, e.getMessage());
            throw new RuntimeException("Error al comunicarse con la API de Mercado Pago", e);
        }
    }
}