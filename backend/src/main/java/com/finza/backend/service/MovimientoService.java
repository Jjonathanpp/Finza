package com.finza.backend.service;

import java.util.List;

import com.finza.backend.dto.movimiento.MovimientoResponseDTO;
import com.finza.backend.dto.movimiento.MovimientosRegistroRequest;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import java.time.LocalDate;

import java.time.LocalDate;

public interface MovimientoService {
    List<MovimientoResponseDTO> registrar(MovimientosRegistroRequest requests);
     void eliminar(Long id);

     Page<MovimientoResponseDTO> listarMovimientos(Long perfilId, LocalDate fechaInicio, LocalDate fechaFin, Long categoriaId, Boolean esIngreso, Pageable pageable);
}

