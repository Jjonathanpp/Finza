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
import com.finza.backend.model.Perfil;
import com.finza.backend.model.Presupuesto;
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

    private Perfil obtenerPerfilValidado(Long perfilId, Long cuentaIdAutenticada) {
        Perfil perfil = perfilRepository.findById(perfilId)
                .orElseThrow(() -> new NoSuchElementException("El perfil indicado no existe"));
                
        if (!perfil.getCuenta().getId().equals(cuentaIdAutenticada)) {
            throw new AccessDeniedException("No tenés permiso para operar sobre este perfil");
        }
        return perfil;
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

            categoriasDTO.add(new PresupuestoCategoriaDTO(
                    p.getId(),
                    categoriaId,
                    p.getCategoria().getNombre(),
                    p.getCategoria().getColor(),
                    tope,
                    gastado,
                    porcentaje
            ));
        }

        BigDecimal porcentajeTotal = BigDecimal.ZERO;
        if (totalPresupuestado.compareTo(BigDecimal.ZERO) > 0) {
            porcentajeTotal = totalGastado.multiply(BigDecimal.valueOf(100))
                    .divide(totalPresupuestado, 1, RoundingMode.HALF_UP);
        }

        return new PresupuestoMesDTO(mes, anio, totalPresupuestado, totalGastado, porcentajeTotal, categoriasDTO);
    }
}