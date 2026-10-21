package com.finza.backend.service.impl;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.YearMonth;
import java.time.format.DateTimeFormatter;
import java.time.temporal.IsoFields;
import java.time.temporal.TemporalAdjusters;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.finza.backend.dto.movimiento.MovimientoResponseDTO;
import com.finza.backend.dto.panel.GastoPorCategoriaDTO;
import com.finza.backend.dto.panel.ResumenGastosDTO;
import com.finza.backend.dto.panel.ResumenMesDTO;
import com.finza.backend.dto.informe.ComparacionPeriodosDTO;
import com.finza.backend.dto.informe.PeriodoComparacionDTO;
import com.finza.backend.exception.BadRequestException;
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
    public ResumenMesDTO obtenerResumen(Long perfilId, Long cuentaIdAutenticada, int limite, LocalDate startDate, LocalDate endDate) {

        PreferenciasSistema prefs = preferenciasRepository.findByPerfilId(perfilId).orElse(new PreferenciasSistema());
        LocalDate[] rangoFechas = calcularRangoDeFechas(prefs, startDate, endDate); // <-- Todo resuelto acá

        BigDecimal totalIngresos = movimientoRepository.sumarMontoPorTipoYFechas(
                perfilId, cuentaIdAutenticada, true, rangoFechas[0], rangoFechas[1]);
        BigDecimal totalEgresos = movimientoRepository.sumarMontoPorTipoYFechas(
                perfilId, cuentaIdAutenticada, false, rangoFechas[0], rangoFechas[1]);
        BigDecimal saldo = totalIngresos.subtract(totalEgresos);
        
        BigDecimal saldoTotal = movimientoRepository.sumarMontoPorTipoYFechas(perfilId, cuentaIdAutenticada, true, null, null)
                .subtract(movimientoRepository.sumarMontoPorTipoYFechas(perfilId, cuentaIdAutenticada, false, null, null));

        List<MovimientoResponseDTO> ultimosTodos = movimientoService.obtenerUltimosMovimientos(perfilId, cuentaIdAutenticada, limite);
        List<MovimientoResponseDTO> ultimosIngresos = movimientoService.obtenerUltimosIngresos(perfilId, cuentaIdAutenticada, limite);
        List<MovimientoResponseDTO> ultimosEgresos = movimientoService.obtenerUltimosEgresos(perfilId, cuentaIdAutenticada, limite);

        return new ResumenMesDTO(totalIngresos, totalEgresos, saldo, saldoTotal, ultimosTodos, ultimosIngresos, ultimosEgresos);
    }

    @Override
    public ResumenGastosDTO gastosPorCategoria(Long perfilId, LocalDate startDate, LocalDate endDate) {
        
        PreferenciasSistema prefs = preferenciasRepository.findByPerfilId(perfilId).orElse(new PreferenciasSistema());
        LocalDate[] rangoFechas = calcularRangoDeFechas(prefs, startDate, endDate); // <-- Todo resuelto acá también

        List<GastoPorCategoriaDTO> categorias =
                movimientoRepository.sumarGastosPorCategoria(perfilId, rangoFechas[0], rangoFechas[1]);

        BigDecimal total = categorias.stream()
                .map(GastoPorCategoriaDTO::getTotal)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        for (GastoPorCategoriaDTO categoria : categorias) {
            categoria.setPorcentaje(categoria.getTotal()
                    .multiply(BigDecimal.valueOf(100))
                    .divide(total, 1, RoundingMode.HALF_UP));
        }
        return new ResumenGastosDTO(total, categorias);
    }

    @Override
    @Transactional(readOnly = true)
    public ComparacionPeriodosDTO compararPeriodos(Long perfilId, Long cuentaIdAutenticada, LocalDate startDate, LocalDate endDate, String granularidad) {

        String granularidadElegida = normalizarGranularidad(granularidad);

        if ((startDate == null) != (endDate == null)) {
            throw new BadRequestException("Si mandás fechas, mandá las dos: startDate y endDate");
        }

        PreferenciasSistema prefs = preferenciasRepository.findByPerfilId(perfilId).orElse(new PreferenciasSistema());
        LocalDate[] rango = calcularRangoDeFechas(prefs, startDate, endDate);

        if (rango[0] == null || rango[1] == null) {
            throw new BadRequestException("No hay un período definido para comparar. Mandá startDate y endDate.");
        }

        List<Periodo> periodos = granularidadElegida.equals("SEMANA")
                ? dividirEnSemanas(rango[0], rango[1])
                : dividirEnMeses(rango[0], rango[1]);

        List<PeriodoComparacionDTO> comparados = new ArrayList<>();
        BigDecimal ingresosAnterior = null;
        BigDecimal egresosAnterior = null;

        for (Periodo periodo : periodos) {
            BigDecimal ingresos = movimientoRepository.sumarMontoPorTipoYFechas(
                    perfilId, cuentaIdAutenticada, true, periodo.inicio(), periodo.fin());
            BigDecimal egresos = movimientoRepository.sumarMontoPorTipoYFechas(
                    perfilId, cuentaIdAutenticada, false, periodo.inicio(), periodo.fin());
            BigDecimal saldo = ingresos.subtract(egresos);

            List<GastoPorCategoriaDTO> categorias = gastosPorCategoria(
                    perfilId, periodo.inicio(), periodo.fin()).getCategorias();

            comparados.add(new PeriodoComparacionDTO(
                    periodo.etiqueta(),
                    periodo.inicio(),
                    periodo.fin(),
                    ingresos,
                    egresos,
                    saldo,
                    calcularVariacion(ingresos, ingresosAnterior),
                    calcularVariacion(egresos, egresosAnterior),
                    categorias));

            ingresosAnterior = ingresos;
            egresosAnterior = egresos;
        }

        return new ComparacionPeriodosDTO(granularidadElegida, comparados);
    }

    // El método ahora maneja la prioridad (parámetros explícitos) y la validación
    private LocalDate[] calcularRangoDeFechas(PreferenciasSistema prefs, LocalDate startDate, LocalDate endDate) {
        
        if (startDate != null && endDate != null) {
            if (startDate.isAfter(endDate)) {
                throw new BadRequestException("La fecha de inicio (startDate) no puede ser posterior a la fecha de fin (endDate).");
            }
            return new LocalDate[]{startDate, endDate};
        }

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

    private record Periodo(String etiqueta, LocalDate inicio, LocalDate fin) {}

    private List<Periodo> dividirEnMeses(LocalDate desde, LocalDate hasta) {
        List<Periodo> periodos = new ArrayList<>();
        YearMonth mes = YearMonth.from(desde);
        YearMonth ultimo = YearMonth.from(hasta);

        while (!mes.isAfter(ultimo)) {
            LocalDate inicio = mes.atDay(1).isBefore(desde) ? desde : mes.atDay(1);
            LocalDate fin = mes.atEndOfMonth().isAfter(hasta) ? hasta : mes.atEndOfMonth();
            String etiqueta = capitalizar(nombreMes(inicio)) + " " + inicio.getYear();
            periodos.add(new Periodo(etiqueta, inicio, fin));
            mes = mes.plusMonths(1);
        }
        return periodos;
    }

    private List<Periodo> dividirEnSemanas(LocalDate desde, LocalDate hasta) {
        List<Periodo> periodos = new ArrayList<>();
        LocalDate lunes = desde.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));

        while (!lunes.isAfter(hasta)) {
            LocalDate domingo = lunes.plusDays(6);
            LocalDate inicio = lunes.isBefore(desde) ? desde : lunes;
            LocalDate fin = domingo.isAfter(hasta) ? hasta : domingo;
            periodos.add(new Periodo(etiquetaSemana(inicio, fin), inicio, fin));
            lunes = lunes.plusWeeks(1);
        }
        return periodos;
    }

    private String etiquetaSemana(LocalDate inicio, LocalDate fin) {
        String mesInicio = nombreMes(inicio);
        String mesFin = nombreMes(fin);
        if (mesInicio.equals(mesFin)) {
            return "Semana del " + inicio.getDayOfMonth() + " al " + fin.getDayOfMonth() + " de " + mesInicio;
        }
        return "Semana del " + inicio.getDayOfMonth() + " de " + mesInicio + " al " + fin.getDayOfMonth() + " de " + mesFin;
    }

    private String nombreMes(LocalDate fecha) {
        return fecha.format(DateTimeFormatter.ofPattern("MMMM", new Locale("es", "ES")));
    }

    private String capitalizar(String texto) {
        return texto.substring(0, 1).toUpperCase(Locale.ROOT) + texto.substring(1);
    }

    private String normalizarGranularidad(String granularidad) {
        if (granularidad == null || granularidad.isBlank()) {
            return "MES";
        }
        String valor = granularidad.trim().toUpperCase(Locale.ROOT);
        if (!valor.equals("MES") && !valor.equals("SEMANA")) {
            throw new BadRequestException("La granularidad debe ser MES o SEMANA");
        }
        return valor;
    }

    private BigDecimal calcularVariacion(BigDecimal actual, BigDecimal anterior) {
        if (anterior == null) {
            return null;
        }
        if (anterior.compareTo(BigDecimal.ZERO) == 0) {
            return actual.compareTo(BigDecimal.ZERO) == 0 ? BigDecimal.ZERO.setScale(1) : null;
        }
        return actual.subtract(anterior)
                .multiply(BigDecimal.valueOf(100))
                .divide(anterior, 1, RoundingMode.HALF_UP);
    }
}

