package com.finza.backend.service;

import java.time.LocalDate;

import com.finza.backend.dto.informe.ComparacionPeriodosDTO;
import com.finza.backend.dto.panel.ResumenGastosDTO;
import com.finza.backend.dto.panel.ResumenMesDTO;

public interface PanelService {
   ResumenMesDTO obtenerResumen(Long perfilId, Long cuentaIdAutenticada, int limite, LocalDate startDate, LocalDate endDate);

   ResumenGastosDTO gastosPorCategoria(Long perfilId, LocalDate startDate, LocalDate endDate);

   ComparacionPeriodosDTO compararPeriodos(Long perfilId, Long cuentaIdAutenticada, LocalDate startDate, LocalDate endDate, String granularidad);
}