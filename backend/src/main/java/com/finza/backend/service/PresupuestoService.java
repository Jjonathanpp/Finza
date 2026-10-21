package com.finza.backend.service;

import com.finza.backend.dto.presupuesto.PresupuestoCategoriaDTO;
import com.finza.backend.dto.presupuesto.PresupuestoMesDTO;
import com.finza.backend.dto.presupuesto.PresupuestoRequest;

public interface PresupuestoService {
    PresupuestoMesDTO obtenerPresupuestosDelMes(Long perfilId, Long cuentaIdAutenticada, int mes, int anio);

    PresupuestoCategoriaDTO crearPresupuesto(Long perfilId, Long cuentaIdAutenticada, PresupuestoRequest request);

    PresupuestoCategoriaDTO editarPresupuesto(Long id, Long perfilId, Long cuentaIdAutenticada, PresupuestoRequest request);

    void desactivarPresupuesto(Long id, Long perfilId, Long cuentaIdAutenticada);
}