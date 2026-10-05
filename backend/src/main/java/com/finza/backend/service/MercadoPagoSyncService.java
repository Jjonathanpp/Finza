package com.finza.backend.service;

import java.util.ArrayList;
import java.util.List;

import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import com.finza.backend.dto.mercadopago.BusquedaMPResponseDTO;
import com.finza.backend.dto.mercadopago.TransaccionMPResponseDTO;
import com.finza.backend.exception.BadRequestException;
import com.finza.backend.model.Categoria;
import com.finza.backend.model.CuentaMP;
import com.finza.backend.model.Movimiento;
import com.finza.backend.model.Perfil;
import com.finza.backend.repository.CuentaMPRepository;
import com.finza.backend.repository.PerfilRepository;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Service
@RequiredArgsConstructor
public class MercadoPagoSyncService {

    private static final String MP_URL_PAGOS = "https://api.mercadopago.com/v1/payments/search?sort=date_created&criteria=desc";

    private final CuentaMPRepository cuentaMPRepository;
    private final PerfilRepository perfilRepository;
    private final CategoriaService categoriaService;
    private final MercadoPagoMapper mercadoPagoMapper;
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

    public List<Movimiento> obtenerMovimientosMapeados(Long usuarioId, Long perfilId) {
        CuentaMP cuentaMP = cuentaMPRepository.findByUsuarioId(usuarioId)
                .orElseThrow(() -> new BadRequestException("No se encontró una cuenta de Mercado Pago vinculada para el usuario"));

        Perfil perfil = perfilRepository.findById(perfilId)
                .orElseThrow(() -> new BadRequestException("El perfil indicado no existe"));

        BusquedaMPResponseDTO busqueda = obtenerMovimientosDesdeMP(usuarioId);
        if (busqueda == null || busqueda.getResultados() == null) {
            return List.of();
        }

        Long miMpUserId = cuentaMP.getMpIdUser() != null ? Long.valueOf(cuentaMP.getMpIdUser()) : null;

        List<Movimiento> movimientos = new ArrayList<>();
        for (TransaccionMPResponseDTO dto : busqueda.getResultados()) {
            boolean esIngreso = dto.getCollectorId() != null && dto.getCollectorId().equals(miMpUserId);
            Categoria.TipoCategoria tipo = esIngreso ? Categoria.TipoCategoria.INGRESO : Categoria.TipoCategoria.EGRESO;
            Categoria categoria = categoriaService.buscarOCrearCategoria("Otros", tipo, perfil.getCuenta());

            Movimiento movimiento = mercadoPagoMapper.mapearAMovimiento(dto, miMpUserId, perfil, categoria);
            movimientos.add(movimiento);
        }

        return movimientos;
    }
}