package com.finza.backend.service;

import java.util.List;

import com.finza.backend.dto.MovimientoRequest;
import com.finza.backend.model.Movimiento;

public interface MovimientoService {
    List<Movimiento> registrar(List<MovimientoRequest> requests);
}