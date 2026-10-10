package com.finza.backend.service;

import com.finza.backend.dto.panel.ResumenGastosDTO;
import com.finza.backend.dto.panel.ResumenMesDTO;

public interface PanelService {
    ResumenMesDTO obtenerResumen(Long perfilId, Long cuentaIdAutenticada, int limite);

    // Los gastos del mes actual por categoría, con qué parte del total es cada una.
    ResumenGastosDTO gastosPorCategoria(Long perfilId);
}
