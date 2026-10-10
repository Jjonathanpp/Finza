package com.finza.backend.service.impl;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.YearMonth;
import java.time.temporal.IsoFields;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.finza.backend.dto.movimiento.MovimientoResponseDTO;
import com.finza.backend.dto.panel.GastoPorCategoriaDTO;
import com.finza.backend.dto.panel.ResumenGastosDTO;
import com.finza.backend.dto.panel.ResumenMesDTO;
import com.finza.backend.model.PreferenciasSistema;
import com.finza.backend.repository.MovimientoRepository;
import com.finza.backend.repository.PreferenciasSistemaRepository;
import com.finza.backend.service.MovimientoService;
import com.finza.backend.service.PanelService;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class PanelServiceImpl implements PanelService {

    private final MovimientoRepository movimientoRepository;
    private final PreferenciasSistemaRepository preferenciasRepository;
    private final MovimientoService movimientoService;

    @Override
    @Transactional(readOnly = true)
    public ResumenMesDTO obtenerResumen(Long perfilId, Long cuentaIdAutenticada, int limite) {

        // 1. Buscamos preferencias y fechas
        PreferenciasSistema prefs = preferenciasRepository.findByPerfilId(perfilId).orElse(new PreferenciasSistema());
        LocalDate[] rangoFechas = calcularRangoDeFechas(prefs);

        // 2. Totales matemáticos
        BigDecimal totalIngresos = movimientoRepository.sumarMontoPorTipoYFechas(
                perfilId, cuentaIdAutenticada, true, rangoFechas[0], rangoFechas[1]);
        BigDecimal totalEgresos = movimientoRepository.sumarMontoPorTipoYFechas(
                perfilId, cuentaIdAutenticada, false, rangoFechas[0], rangoFechas[1]);
        BigDecimal saldo = totalIngresos.subtract(totalEgresos);

        // 3. Delegamos la búsqueda de las 3 listas
        List<MovimientoResponseDTO> ultimosTodos = movimientoService.obtenerUltimosMovimientos(perfilId, cuentaIdAutenticada, limite);
        List<MovimientoResponseDTO> ultimosIngresos = movimientoService.obtenerUltimosIngresos(perfilId, cuentaIdAutenticada, limite);
        List<MovimientoResponseDTO> ultimosEgresos = movimientoService.obtenerUltimosEgresos(perfilId, cuentaIdAutenticada, limite);

        // 4. Empaquetamos todo
        return new ResumenMesDTO(totalIngresos, totalEgresos, saldo, ultimosTodos, ultimosIngresos, ultimosEgresos);
    }

    private LocalDate[] calcularRangoDeFechas(PreferenciasSistema prefs) {
        LocalDate hoy = LocalDate.now();
        LocalDate inicio = null;
        LocalDate fin = null;

        switch (prefs.getVistaBalance()) {
            case BIMESTRAL:
                int mesActualBi = hoy.getMonthValue();
                int inicioMesBi = (mesActualBi % 2 == 0) ? mesActualBi - 1 : mesActualBi;
                inicio = LocalDate.of(hoy.getYear(), inicioMesBi, 1);
                fin = YearMonth.of(hoy.getYear(), inicioMesBi + 1).atEndOfMonth();
                break;
            case TRIMESTRAL:
                int mesPrimerTrimestre = ((hoy.get(IsoFields.QUARTER_OF_YEAR) - 1) * 3) + 1;
                inicio = LocalDate.of(hoy.getYear(), mesPrimerTrimestre, 1);
                fin = YearMonth.of(hoy.getYear(), mesPrimerTrimestre + 2).atEndOfMonth();
                break;
            case CUATRIMESTRAL:
                int mesActualCuatri = hoy.getMonthValue();
                int inicioMesCuatri = 1;
                if (mesActualCuatri >= 5 && mesActualCuatri <= 8) inicioMesCuatri = 5;
                else if (mesActualCuatri >= 9) inicioMesCuatri = 9;
                
                inicio = LocalDate.of(hoy.getYear(), inicioMesCuatri, 1);
                fin = YearMonth.of(hoy.getYear(), inicioMesCuatri + 3).atEndOfMonth();
                break;
            case ANUAL:
                inicio = LocalDate.of(hoy.getYear(), 1, 1);
                fin = LocalDate.of(hoy.getYear(), 12, 31);
                break;
            case PERSONALIZADO:
                inicio = prefs.getFechaBalanceInicio();
                fin = prefs.getFechaBalanceFin();
                break;
            case MENSUAL_ACTUAL:
            default:
                YearMonth mesActual = YearMonth.now();
                inicio = mesActual.atDay(1);
                fin = mesActual.atEndOfMonth();
                break;
        }
        
        return new LocalDate[]{inicio, fin};
    }

    @Override
    public ResumenGastosDTO gastosPorCategoria(Long perfilId) {
        YearMonth mes = YearMonth.now();
        List<GastoPorCategoriaDTO> categorias =
                movimientoRepository.sumarGastosPorCategoria(perfilId, mes.atDay(1), mes.atEndOfMonth());

        BigDecimal total = categorias.stream()
                .map(GastoPorCategoriaDTO::getTotal)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        // Sin gastos la lista viene vacía y no se divide nada: el total queda en 0.
        for (GastoPorCategoriaDTO categoria : categorias) {
            categoria.setPorcentaje(categoria.getTotal()
                    .multiply(BigDecimal.valueOf(100))
                    .divide(total, 1, RoundingMode.HALF_UP));
        }
        return new ResumenGastosDTO(total, categorias);
    }
}
