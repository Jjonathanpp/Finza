package com.finza.backend.service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.YearMonth;
import java.util.List;

import org.springframework.stereotype.Service;

import com.finza.backend.dto.panel.GastoPorCategoriaDTO;
import com.finza.backend.dto.panel.ResumenGastosDTO;
import com.finza.backend.repository.MovimientoRepository;

@Service
public class PanelService {

    private final MovimientoRepository movimientoRepository;

    public PanelService(MovimientoRepository movimientoRepository) {
        this.movimientoRepository = movimientoRepository;
    }

    // Los gastos del mes actual por categoría, con qué parte del total es cada una.
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
