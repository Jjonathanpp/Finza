package com.finza.backend.service;

import java.util.ArrayList;
import java.util.List;

import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.scheduling.annotation.Scheduled;

import com.finza.backend.dto.mercadopago.BusquedaMPResponseDTO;
import com.finza.backend.dto.mercadopago.TransaccionMPResponseDTO;
import com.finza.backend.exception.BadRequestException;
import com.finza.backend.model.Categoria;
import com.finza.backend.model.CuentaMP;
import com.finza.backend.model.Movimiento;
import com.finza.backend.model.Perfil;
import com.finza.backend.repository.CuentaMPRepository;
import com.finza.backend.repository.PerfilRepository;
import com.finza.backend.repository.MovimientoRepository;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Service
@RequiredArgsConstructor
public class MercadoPagoSyncService {

    private static final String MP_URL_PAGOS = "https://api.mercadopago.com/v1/payments/search?sort=date_created&criteria=desc&begin_date=NOW-30DAYS";

    private final CuentaMPRepository cuentaMPRepository;
    private final PerfilRepository perfilRepository;
    private final MovimientoRepository movimientoRepository;
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

    public List<Movimiento> sincronizarMovimientos(Long usuarioId, Long perfilId) {
        CuentaMP cuentaMP = cuentaMPRepository.findByUsuarioId(usuarioId)
                .orElseThrow(() -> new BadRequestException("No se encontró una cuenta de Mercado Pago vinculada para el usuario"));

        Perfil perfil = perfilRepository.findById(perfilId)
                .orElseThrow(() -> new BadRequestException("El perfil indicado no existe"));

        BusquedaMPResponseDTO busqueda = obtenerMovimientosDesdeMP(usuarioId);
        if (busqueda == null || busqueda.getResultados() == null || busqueda.getResultados().isEmpty()) {
            return List.of();
        }

        Long miMpUserId = cuentaMP.getMpIdUser() != null ? Long.valueOf(cuentaMP.getMpIdUser()) : null;
        List<Movimiento> nuevosMovimientos = new ArrayList<>();
        int duplicadosOmitidos = 0;

        for (TransaccionMPResponseDTO dto : busqueda.getResultados()) {
            if (dto.getId() == null) {
                continue;
            }

            String externalId = String.valueOf(dto.getId());

            if (movimientoRepository.existsByExternalId(externalId)) {
                duplicadosOmitidos++;
                continue;
            }

            boolean esIngreso = dto.getCollectorId() != null && dto.getCollectorId().equals(miMpUserId);
            Categoria.TipoCategoria tipo = esIngreso ? Categoria.TipoCategoria.INGRESO : Categoria.TipoCategoria.EGRESO;
            Categoria categoria = categoriaService.buscarOCrearCategoria("Otros", tipo, perfil.getCuenta());

            Movimiento nuevo = mercadoPagoMapper.mapearAMovimiento(dto, miMpUserId, perfil, categoria);
            nuevosMovimientos.add(nuevo);
        }

        log.info("Sincronización completada para usuario {}: {} nuevos guardados, {} duplicados omitidos.",
                usuarioId, nuevosMovimientos.size(), duplicadosOmitidos);

        if (nuevosMovimientos.isEmpty()) {
            return List.of();
        }

        return movimientoRepository.saveAll(nuevosMovimientos);
    }

    @Scheduled(cron = "0 0 */4 * * *")
    public void sincronizarAutomaticamenteTodasLasCuentas() {
        log.info("Iniciando tarea programada: sincronización periódica de Mercado Pago...");
        List<CuentaMP> cuentasConectadas = cuentaMPRepository.findAll();

        for (CuentaMP cuentaMP : cuentasConectadas) {
            if (cuentaMP.getUsuario() == null) {
                continue;
            }

            Long usuarioId = cuentaMP.getUsuario().getId();

            try {
                Perfil perfilPrincipal = perfilRepository.findPrincipalByUsuarioId(usuarioId)
                        .orElse(null);

                if (perfilPrincipal == null) {
                    log.warn("Usuario {} tiene Mercado Pago conectado pero no tiene un perfil principal asignado.", usuarioId);
                    continue;
                }

                sincronizarMovimientos(usuarioId, perfilPrincipal.getId());
            } catch (Exception e) {
                log.error("Falló la sincronización automática para el usuario {}: {}", usuarioId, e.getMessage());
            }
        }

        log.info("Tarea programada de Mercado Pago finalizada.");
    }
}