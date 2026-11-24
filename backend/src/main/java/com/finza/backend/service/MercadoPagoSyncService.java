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
import com.finza.backend.dto.movimiento.MovimientoResponseDTO;
import com.finza.backend.dto.mercadopago.SincronizacionResumenDTO;
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
    private final MercadoPagoOAuthService mercadoPagoOAuthService;

    public BusquedaMPResponseDTO obtenerMovimientosDesdeMP(Long usuarioId) {
        CuentaMP cuentaMP = cuentaMPRepository.findByUsuarioId(usuarioId)
                .orElseThrow(() -> new BadRequestException(
                        "No se encontró una cuenta de Mercado Pago vinculada para el usuario"));

        HttpHeaders headers = new HttpHeaders();
        String accessToken = mercadoPagoOAuthService.obtenerAccessTokenVigente(usuarioId);
        headers.setBearerAuth(accessToken);

        HttpEntity<Void> peticion = new HttpEntity<>(headers);

        try {
            ResponseEntity<BusquedaMPResponseDTO> respuesta = restTemplate.exchange(
                    MP_URL_PAGOS,
                    HttpMethod.GET,
                    peticion,
                    BusquedaMPResponseDTO.class);

            BusquedaMPResponseDTO body = respuesta.getBody();
            if (body != null && body.getResultados() != null) {
                Long miMpUserId = cuentaMP.getMpIdUser() != null ? Long.valueOf(cuentaMP.getMpIdUser()) : null;
                for (TransaccionMPResponseDTO dto : body.getResultados()) {
                    boolean esIngreso = dto.getCollectorId() != null && dto.getCollectorId().equals(miMpUserId);
                    dto.setEsIngreso(esIngreso);
                }
            }
            return body;
        } catch (Exception e) {

            log.error("Error al consultar la API de Mercado Pago para el usuario {}: {}", usuarioId, e.getMessage());
            throw new RuntimeException("Error al comunicarse con la API de Mercado Pago", e);
        }
    }

    public List<MovimientoResponseDTO> obtenerMovimientosMapeados(Long usuarioId, Long perfilId) {
        CuentaMP cuentaMP = cuentaMPRepository.findByUsuarioId(usuarioId)
                .orElseThrow(() -> new BadRequestException(
                        "No se encontró una cuenta de Mercado Pago vinculada para el usuario"));

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
            Categoria categoria = categoriaService.buscarOCrearCategoria("Otros", tipo, perfil);

            Movimiento movimiento = mercadoPagoMapper.mapearAMovimiento(dto, miMpUserId, perfil, categoria);
            movimientos.add(movimiento);
        }

        return movimientos.stream()
                .map(MovimientoResponseDTO::new)
                .toList();
    }

    public SincronizacionResumenDTO sincronizarMovimientos(Long usuarioId, Long perfilId) {
        CuentaMP cuentaMP = cuentaMPRepository.findByUsuarioId(usuarioId)
                .orElseThrow(() -> new BadRequestException(
                        "No se encontró una cuenta de Mercado Pago vinculada para el usuario"));

        Perfil perfil = perfilRepository.findById(perfilId)
                .orElseThrow(() -> new BadRequestException("El perfil indicado no existe"));

        BusquedaMPResponseDTO busqueda = obtenerMovimientosDesdeMP(usuarioId);
        if (busqueda == null || busqueda.getResultados() == null || busqueda.getResultados().isEmpty()) {
            return SincronizacionResumenDTO.builder()
                    .procesadas(0)
                    .creadas(0)
                    .omitidas(0)
                    .errores(0)
                    .build();
        }

        Long miMpUserId = cuentaMP.getMpIdUser() != null ? Long.valueOf(cuentaMP.getMpIdUser()) : null;
        List<Movimiento> nuevosMovimientos = new ArrayList<>();
        int duplicadosOmitidos = 0;

        int errores = 0;
        for (TransaccionMPResponseDTO dto : busqueda.getResultados()) {
            try {
                if (dto.getId() == null) {
                    continue;
                }

                String externalId = String.valueOf(dto.getId());

                if (movimientoRepository.existsByExternalIdAndPerfilId(externalId, perfil.getId())) {
                    duplicadosOmitidos++;
                    continue;
                }

                boolean esIngreso = dto.getCollectorId() != null && dto.getCollectorId().equals(miMpUserId);
                Categoria.TipoCategoria tipo = esIngreso ? Categoria.TipoCategoria.INGRESO
                        : Categoria.TipoCategoria.EGRESO;
                Categoria categoria = categoriaService.buscarOCrearCategoria("Otros", tipo, perfil);

                Movimiento nuevo = mercadoPagoMapper.mapearAMovimiento(dto, miMpUserId, perfil, categoria);
                nuevosMovimientos.add(nuevo);
            } catch (Exception e) {
                log.error("Error al procesar movimiento individual de MP (id={}): {}", dto.getId(), e.getMessage());
                errores++;
            }
        }

        List<Movimiento> guardados = nuevosMovimientos.isEmpty() ? List.of()
                : movimientoRepository.saveAll(nuevosMovimientos);

        return SincronizacionResumenDTO.builder()
                .procesadas(busqueda.getResultados().size())
                .creadas(guardados.size())
                .omitidas(duplicadosOmitidos)
                .errores(errores)
                .build();
    }

    public BusquedaMPResponseDTO obtenerDisponiblesParaImportar(Long usuarioId) {
        return obtenerMovimientosDesdeMP(usuarioId);
    }

    public SincronizacionResumenDTO importarSeleccionados(Long usuarioId, List<String> externalIds,
            Long perfilIdDestino) {
        CuentaMP cuentaMP = cuentaMPRepository.findByUsuarioId(usuarioId)
                .orElseThrow(() -> new BadRequestException(
                        "No se encontró una cuenta de Mercado Pago vinculada para el usuario"));

        Perfil perfil = perfilRepository.findById(perfilIdDestino)
                .orElseThrow(() -> new BadRequestException("El perfil indicado no existe"));

        BusquedaMPResponseDTO busqueda = obtenerMovimientosDesdeMP(usuarioId);
        if (busqueda == null || busqueda.getResultados() == null || busqueda.getResultados().isEmpty()) {
            return SincronizacionResumenDTO.builder()
                    .procesadas(0)
                    .creadas(0)
                    .omitidas(0)
                    .errores(0)
                    .build();
        }

        Long miMpUserId = cuentaMP.getMpIdUser() != null ? Long.valueOf(cuentaMP.getMpIdUser()) : null;
        List<Movimiento> nuevosMovimientos = new ArrayList<>();
        int duplicadosOmitidos = 0;
        int procesadas = 0;

        int errores = 0;
        for (TransaccionMPResponseDTO dto : busqueda.getResultados()) {
            try {
                if (dto.getId() == null) {
                    continue;
                }

                String externalId = String.valueOf(dto.getId());

                if (!externalIds.contains(externalId)) {
                    continue;
                }

                procesadas++;

                if (movimientoRepository.existsByExternalIdAndPerfilId(externalId, perfil.getId())) {
                    duplicadosOmitidos++;
                    continue;
                }

                boolean esIngreso = dto.getCollectorId() != null && dto.getCollectorId().equals(miMpUserId);
                Categoria.TipoCategoria tipo = esIngreso ? Categoria.TipoCategoria.INGRESO
                        : Categoria.TipoCategoria.EGRESO;
                Categoria categoria = categoriaService.buscarOCrearCategoria("Otros", tipo, perfil);

                Movimiento nuevo = mercadoPagoMapper.mapearAMovimiento(dto, miMpUserId, perfil, categoria);
                nuevo.setImportadoPor(usuarioId);
                nuevosMovimientos.add(nuevo);
            } catch (Exception e) {
                log.error("Error al importar movimiento seleccionado de MP (id={}): {}", dto.getId(), e.getMessage());
                errores++;
            }
        }

        List<Movimiento> guardados = nuevosMovimientos.isEmpty() ? List.of()
                : movimientoRepository.saveAll(nuevosMovimientos);

        return SincronizacionResumenDTO.builder()
                .procesadas(procesadas)
                .creadas(guardados.size())
                .omitidas(duplicadosOmitidos)
                .errores(errores)
                .build();
    }
}