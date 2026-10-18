package com.finza.backend.service;

import com.finza.backend.dto.presupuesto.PresupuestoMesDTO;

public interface PresupuestoService {
    PresupuestoMesDTO obtenerPresupuestosDelMes(Long perfilId, Long cuentaIdAutenticada, int mes, int anio);
}