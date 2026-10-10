package com.finza.backend.service;

import java.util.List;

import com.finza.backend.dto.movimiento.MovimientoRequest;
import com.finza.backend.dto.movimiento.MovimientoResponseDTO;
import com.finza.backend.dto.movimiento.MovimientosRegistroRequest;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDate;

public interface MovimientoService {
    List<MovimientoResponseDTO> registrar(MovimientosRegistroRequest requests, Long cuentaIdAutenticada);

    void eliminar(Long id, Long cuentaIdAutenticada);

    MovimientoResponseDTO actualizar(Long id, Long perfilId, MovimientoRequest request, Long cuentaIdAutenticada);

    Page<MovimientoResponseDTO> listarMovimientos(Long perfilId, Long cuentaIdAutenticada, LocalDate fechaInicio, LocalDate fechaFin,
            Long categoriaId, Boolean esIngreso, String estadoStr, Pageable pageable);

    MovimientoResponseDTO cambiarEstado(Long id, String nuevoEstado, Long cuentaIdAutenticada);
    
    List<MovimientoResponseDTO> registrarDesdeAudio(MultipartFile audio, Long perfilId, Long cuentaIdAutenticada) throws Exception;

    List<MovimientoResponseDTO> obtenerUltimosMovimientos(Long perfilId, Long cuentaIdAutenticada, int limite);
    List<MovimientoResponseDTO> obtenerUltimosIngresos(Long perfilId, Long cuentaIdAutenticada, int limite);
    List<MovimientoResponseDTO> obtenerUltimosEgresos(Long perfilId, Long cuentaIdAutenticada, int limite);
}
