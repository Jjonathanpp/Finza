package com.finza.backend.service.impl;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.NoSuchElementException;
import java.util.stream.Collectors;

import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.finza.backend.dto.panel.GastoPorCategoriaDTO;
import com.finza.backend.dto.presupuesto.PresupuestoCategoriaDTO;
import com.finza.backend.dto.presupuesto.PresupuestoMesDTO;
import com.finza.backend.dto.presupuesto.PresupuestoRequest;
import com.finza.backend.exception.BadRequestException;
import com.finza.backend.model.Categoria;
import com.finza.backend.model.Perfil;
import com.finza.backend.model.Presupuesto;
import com.finza.backend.repository.CategoriaRepository;
import com.finza.backend.repository.MovimientoRepository;
import com.finza.backend.repository.PerfilRepository;
import com.finza.backend.repository.PresupuestoRepository;
import com.finza.backend.service.PresupuestoService;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class PresupuestoServiceImpl implements PresupuestoService {

    private final PresupuestoRepository presupuestoRepository;
    private final MovimientoRepository movimientoRepository;
    private final PerfilRepository perfilRepository;
    private final CategoriaRepository categoriaRepository;
    /* 
    private Perfil obtenerPerfilValidado(Long perfilId, Long cuentaIdAutenticada) {
        Perfil perfil = perfilRepository.findById(perfilId)
                .orElseThrow(() -> new NoSuchElementException("El perfil indicado no existe"));
                
        if (!perfil.getCuenta().getId().equals(cuentaIdAutenticada)) {
            throw new AccessDeniedException("No tenés permiso para operar sobre este perfil");
        }
        return perfil;
    }
        */

    private Perfil obtenerPerfilValidado(Long perfilId, Long cuentaIdAutenticada) {
        Perfil perfil = perfilRepository.findById(perfilId)
                .orElseThrow(() -> new NoSuchElementException("El perfil indicado no existe"));
                
        if (!perfil.getCuenta().getId().equals(cuentaIdAutenticada)) {
            throw new AccessDeniedException("No tenés permiso para operar sobre este perfil");
        }
        return perfil;
    }

    private Presupuesto obtenerPresupuestoValidado(Long presupuestoId, Long cuentaIdAutenticada) {
        Presupuesto presupuesto = presupuestoRepository.findById(presupuestoId)
                .orElseThrow(() -> new NoSuchElementException("Presupuesto no encontrado"));

        if (!presupuesto.getPerfil().getCuenta().getId().equals(cuentaIdAutenticada)) {
            throw new AccessDeniedException("No tenés permiso para operar sobre este presupuesto");
        }
        return presupuesto;
    }

    private Categoria obtenerCategoriaValidada(Long categoriaId, Long cuentaIdAutenticada) {
        Categoria categoria = categoriaRepository.findById(categoriaId)
                .orElseThrow(() -> new NoSuchElementException("La categoría indicada no existe"));

        if (categoria.getCuenta() != null && !categoria.getCuenta().getId().equals(cuentaIdAutenticada)) {
            throw new AccessDeniedException("No tenés permiso para usar esta categoría");
        }
        return categoria;
    }

    private void validarDatos(PresupuestoRequest request) {
        if (request.getMontoTope() == null || request.getMontoTope().compareTo(BigDecimal.ZERO) <= 0) {
            throw new BadRequestException("El monto tope debe ser mayor a cero");
        }
        if (request.getMes() == null || request.getMes() < 1 || request.getMes() > 12) {
            throw new BadRequestException("El mes debe ser un valor válido entre 1 y 12");
        }
        if (request.getAnio() == null || request.getAnio() < 2000) {
            throw new BadRequestException("El año ingresado es inválido");
        }
    }

    private String calcularEstado(BigDecimal porcentaje) {
        if (porcentaje.compareTo(BigDecimal.valueOf(100)) >= 0) {
            return "EXCEDIDO";
        }
        if (porcentaje.compareTo(BigDecimal.valueOf(80)) >= 0) {
            return "ALERTA";
        }
        return "OK";
    }

    @Override
    @Transactional(readOnly = true)
    public PresupuestoMesDTO obtenerPresupuestosDelMes(Long perfilId, Long cuentaIdAutenticada, int mes, int anio) {
        obtenerPerfilValidado(perfilId, cuentaIdAutenticada);

        List<Presupuesto> presupuestos = presupuestoRepository.buscarActivosDelMes(perfilId, mes, anio);

        YearMonth yearMonth = YearMonth.of(anio, mes);
        LocalDate desde = yearMonth.atDay(1);
        LocalDate hasta = yearMonth.atEndOfMonth();

        List<GastoPorCategoriaDTO> gastos = movimientoRepository.sumarGastosPorCategoria(perfilId, desde, hasta);
        
        Map<Long, BigDecimal> gastosPorCatMap = gastos.stream()
                .collect(Collectors.toMap(GastoPorCategoriaDTO::getId, GastoPorCategoriaDTO::getTotal));

        List<PresupuestoCategoriaDTO> categoriasDTO = new ArrayList<>();
        BigDecimal totalPresupuestado = BigDecimal.ZERO;
        BigDecimal totalGastado = BigDecimal.ZERO;

        for (Presupuesto p : presupuestos) {
            BigDecimal tope = p.getMontoTope() != null ? p.getMontoTope() : BigDecimal.ZERO;
            totalPresupuestado = totalPresupuestado.add(tope);

            Long categoriaId = p.getCategoria().getId();
            BigDecimal gastado = gastosPorCatMap.getOrDefault(categoriaId, BigDecimal.ZERO);
            totalGastado = totalGastado.add(gastado);

            BigDecimal porcentaje = BigDecimal.ZERO;
            if (tope.compareTo(BigDecimal.ZERO) > 0) {
                porcentaje = gastado.multiply(BigDecimal.valueOf(100))
                        .divide(tope, 1, RoundingMode.HALF_UP);
            }

            String estado = calcularEstado(porcentaje);

            categoriasDTO.add(new PresupuestoCategoriaDTO(
                    p.getId(),
                    categoriaId,
                    p.getCategoria().getNombre(),
                    p.getCategoria().getColor(),
                    tope,
                    gastado,
                    porcentaje,
                    estado
            ));
        }

        BigDecimal porcentajeTotal = BigDecimal.ZERO;
        if (totalPresupuestado.compareTo(BigDecimal.ZERO) > 0) {
            porcentajeTotal = totalGastado.multiply(BigDecimal.valueOf(100))
                    .divide(totalPresupuestado, 1, RoundingMode.HALF_UP);
        }

        return new PresupuestoMesDTO(mes, anio, totalPresupuestado, totalGastado, porcentajeTotal, categoriasDTO);
    }

    @Override
    @Transactional
    public PresupuestoCategoriaDTO crearPresupuesto(Long perfilId, Long cuentaIdAutenticada, PresupuestoRequest request) {
        validarDatos(request);
        if (request.getCategoriaId() == null) {
            throw new BadRequestException("La categoría es obligatoria");
        }

        Perfil perfil = obtenerPerfilValidado(perfilId, cuentaIdAutenticada);
        Categoria categoria = obtenerCategoriaValidada(request.getCategoriaId(), cuentaIdAutenticada);

        // Regla de unicidad: una sola categoría por mes y año activa
        if (presupuestoRepository.existsByPerfilIdAndCategoriaIdAndMesAndAnioAndActivoTrue(
                perfilId, categoria.getId(), request.getMes(), request.getAnio())) {
            throw new BadRequestException("Ya existe un presupuesto activo para esta categoría en el período indicado");
        }

        Presupuesto presupuesto = new Presupuesto();
        presupuesto.setPerfil(perfil);
        presupuesto.setCategoria(categoria);
        presupuesto.setMontoTope(request.getMontoTope());
        presupuesto.setMes(request.getMes());
        presupuesto.setAnio(request.getAnio());
        presupuesto.setActivo(true);

        Presupuesto guardado = presupuestoRepository.save(presupuesto);

        // Consultamos gastos actuales para responder con el DTO completo
        YearMonth ym = YearMonth.of(request.getAnio(), request.getMes());
        List<GastoPorCategoriaDTO> gastos = movimientoRepository.sumarGastosPorCategoria(
                perfilId, ym.atDay(1), ym.atEndOfMonth());
        
        BigDecimal gastado = gastos.stream()
                .filter(g -> g.getId().equals(categoria.getId()))
                .map(GastoPorCategoriaDTO::getTotal)
                .findFirst().orElse(BigDecimal.ZERO);

        BigDecimal porcentaje = guardado.getMontoTope().compareTo(BigDecimal.ZERO) > 0
                ? gastado.multiply(BigDecimal.valueOf(100)).divide(guardado.getMontoTope(), 1, RoundingMode.HALF_UP)
                : BigDecimal.ZERO;

        String estado = calcularEstado(porcentaje);

        return new PresupuestoCategoriaDTO(
                guardado.getId(),
                categoria.getId(),
                categoria.getNombre(),
                categoria.getColor(),
                guardado.getMontoTope(),
                gastado,
                porcentaje,
                estado
        );
    }

    @Override
    @Transactional
    public PresupuestoCategoriaDTO editarPresupuesto(Long id, Long perfilId, Long cuentaIdAutenticada, PresupuestoRequest request) {
        validarDatos(request);

        Presupuesto presupuesto = obtenerPresupuestoValidado(id, cuentaIdAutenticada);
        if (!presupuesto.getPerfil().getId().equals(perfilId)) {
            throw new BadRequestException("El presupuesto no pertenece al perfil indicado");
        }

        Long categoriaIdFinal = request.getCategoriaId() != null ? request.getCategoriaId() : presupuesto.getCategoria().getId();
        Categoria categoria = obtenerCategoriaValidada(categoriaIdFinal, cuentaIdAutenticada);

        // Validar unicidad excluyendo el propio ID
        if (presupuestoRepository.existsByPerfilIdAndCategoriaIdAndMesAndAnioAndActivoTrueAndIdNot(
                perfilId, categoria.getId(), request.getMes(), request.getAnio(), id)) {
            throw new BadRequestException("Ya existe otro presupuesto activo para esta categoría en el período indicado");
        }

        presupuesto.setCategoria(categoria);
        presupuesto.setMontoTope(request.getMontoTope());
        presupuesto.setMes(request.getMes());
        presupuesto.setAnio(request.getAnio());

        Presupuesto actualizado = presupuestoRepository.save(presupuesto);

        YearMonth ym = YearMonth.of(request.getAnio(), request.getMes());
        List<GastoPorCategoriaDTO> gastos = movimientoRepository.sumarGastosPorCategoria(
                perfilId, ym.atDay(1), ym.atEndOfMonth());

        BigDecimal gastado = gastos.stream()
                .filter(g -> g.getId().equals(categoria.getId()))
                .map(GastoPorCategoriaDTO::getTotal)
                .findFirst().orElse(BigDecimal.ZERO);

        BigDecimal porcentaje = actualizado.getMontoTope().compareTo(BigDecimal.ZERO) > 0
                ? gastado.multiply(BigDecimal.valueOf(100)).divide(actualizado.getMontoTope(), 1, RoundingMode.HALF_UP)
                : BigDecimal.ZERO;

        String estado = calcularEstado(porcentaje);

        return new PresupuestoCategoriaDTO(
                actualizado.getId(),
                categoria.getId(),
                categoria.getNombre(),
                categoria.getColor(),
                actualizado.getMontoTope(),
                gastado,
                porcentaje,
                estado
        );
    }

    @Override
    @Transactional
    public void desactivarPresupuesto(Long id, Long perfilId, Long cuentaIdAutenticada) {
        Presupuesto presupuesto = obtenerPresupuestoValidado(id, cuentaIdAutenticada);
        if (!presupuesto.getPerfil().getId().equals(perfilId)) {
            throw new BadRequestException("El presupuesto no pertenece al perfil indicado");
        }

        presupuesto.setActivo(false);
        presupuestoRepository.save(presupuesto);
    }
}