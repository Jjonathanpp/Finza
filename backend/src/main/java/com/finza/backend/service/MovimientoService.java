package com.finza.backend.service;

import java.util.List;

import com.finza.backend.dto.movimiento.MovimientoResponseDTO;
import com.finza.backend.dto.movimiento.MovimientosRegistroRequest;

public interface MovimientoService {
    List<MovimientoResponseDTO> registrar(MovimientosRegistroRequest requests);
     void eliminar(Long id);
}

