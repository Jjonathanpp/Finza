package com.finza.backend.service;

import com.finza.backend.dto.panel.ResumenMesDTO;

public interface PanelService {
    ResumenMesDTO obtenerResumen(Long perfilId, Long cuentaIdAutenticada, int limite);
}
