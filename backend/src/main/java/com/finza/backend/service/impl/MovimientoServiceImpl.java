package com.finza.backend.service.impl;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.NoSuchElementException;

import com.finza.backend.dto.movimiento.MovimientoRequest;
import com.finza.backend.dto.movimiento.MovimientoResponseDTO;
import com.finza.backend.dto.movimiento.MovimientosRegistroRequest;
import com.finza.backend.exception.BadRequestException;
import com.finza.backend.model.Categoria;
import com.finza.backend.model.Movimiento;
import com.finza.backend.model.Perfil;
import com.finza.backend.repository.CategoriaRepository;
import com.finza.backend.repository.MovimientoRepository;
import com.finza.backend.repository.PerfilRepository;
import com.finza.backend.service.MovimientoService;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class MovimientoServiceImpl implements MovimientoService {

    private static final DateTimeFormatter FORMATO_FECHA = DateTimeFormatter.ofPattern("dd-MM-yyyy");

    private final MovimientoRepository movimientoRepository;
    private final CategoriaRepository categoriaRepository;
    private final PerfilRepository perfilRepository;

    @Override
    @Transactional
    public List<MovimientoResponseDTO> registrar(MovimientosRegistroRequest request) {
        if (request.getMovimientos() == null || request.getMovimientos().isEmpty()) {
            throw new BadRequestException("Debe enviar al menos un movimiento");
        }

        Perfil perfil = perfilRepository.findById(request.getPerfilId())
                .orElseThrow(() -> new BadRequestException("El perfil indicado no existe"));

        List<Movimiento> creados = new ArrayList<>();
        for (MovimientoRequest mov : request.getMovimientos()) {
            validar(mov);
            creados.add(crearMovimiento(mov, perfil));
        }

        return movimientoRepository.saveAll(creados).stream()
                .map(MovimientoResponseDTO::new)
                .toList();
    }

    @Override
    public void eliminar(Long id) {
        if (!movimientoRepository.existsById(id)) {
            throw new NoSuchElementException("Movimiento no encontrado");
        }
        movimientoRepository.deleteById(id);
    }

    private void validar(MovimientoRequest request) {
        if (esVacio(request.getTipo()) || esVacio(request.getMonto()) || esVacio(request.getCategoria())) {
            throw new BadRequestException("Error: Falta informacion obligatoria");
        }
        try {
            if (new BigDecimal(request.getMonto().trim()).signum() <= 0) {
                throw new BadRequestException("Error: Datos invalidos");
            }
        } catch (NumberFormatException e) {
            throw new BadRequestException("Error: Datos invalidos");
        }
    }

    private Movimiento crearMovimiento(MovimientoRequest request, Perfil perfil) {
        Movimiento movimiento = new Movimiento();
        movimiento.setPerfil(perfil);
        movimiento.setCategoria(buscarOCrearCategoria(request.getCategoria()));
        movimiento.setMonto(new BigDecimal(request.getMonto().trim()));
        movimiento.setEsIngreso("ingreso".equalsIgnoreCase(request.getTipo().trim()));
        movimiento.setFecha(parsearFecha(request.getFecha()));
        movimiento.setDescripcion(esVacio(request.getDescripcion()) ? null : request.getDescripcion().trim());
        movimiento.setEstado(Movimiento.EstadoMovimiento.APROBADO);
        movimiento.setOrigen(Movimiento.OrigenMovimiento.MANUAL);
        movimiento.setFechaCreacion(LocalDateTime.now());
        return movimiento;
    }

    private Categoria buscarOCrearCategoria(String nombre) {
        String nombreLimpio = nombre.trim();
        return categoriaRepository.findByNombre(nombreLimpio)
                .orElseGet(() -> {
                    Categoria categoria = new Categoria();
                    categoria.setNombre(nombreLimpio);
                    categoria.setTipoCategoriaPredefinida(Categoria.TipoCategoria.INGRESO);
                    return categoriaRepository.save(categoria);
                });
    }

    private LocalDate parsearFecha(String fecha) {
        if (esVacio(fecha)) {
            return LocalDate.now();
        }
        return LocalDate.parse(fecha.trim(), FORMATO_FECHA);
    }

    private boolean esVacio(String valor) {
        return valor == null || valor.isBlank();
    }

}