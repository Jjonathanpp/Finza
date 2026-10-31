package com.finza.backend.service.impl;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
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
import com.finza.backend.repository.MovimientoRepository;
import com.finza.backend.repository.PerfilRepository;
import com.finza.backend.service.CategoriaService;
import com.finza.backend.service.IAService;
import com.finza.backend.service.MovimientoService;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class MovimientoServiceImpl implements MovimientoService {

    private static final DateTimeFormatter FORMATO_FECHA = DateTimeFormatter.ofPattern("dd-MM-yyyy");

    private final MovimientoRepository movimientoRepository;
    private final CategoriaService categoriaService;
    private final PerfilRepository perfilRepository;
    private final IAService iaService;

    // --- VALIDADORES DE SCOPING ---
    private Perfil obtenerPerfilValidado(Long perfilId, Long cuentaIdAutenticada) {
        Perfil perfil = perfilRepository.findById(perfilId)
                .orElseThrow(() -> new NoSuchElementException("El perfil indicado no existe"));
                
        if (!perfil.getCuenta().getId().equals(cuentaIdAutenticada)) {
            throw new org.springframework.security.access.AccessDeniedException("No tenés permiso para operar sobre este perfil");
        }
        return perfil;
    }

    private Movimiento obtenerMovimientoValidado(Long movimientoId, Long cuentaIdAutenticada) {
        Movimiento movimiento = movimientoRepository.findById(movimientoId)
                .orElseThrow(() -> new NoSuchElementException("Movimiento no encontrado"));
                
        if (!movimiento.getPerfil().getCuenta().getId().equals(cuentaIdAutenticada)) {
            throw new org.springframework.security.access.AccessDeniedException("No tenés permiso para operar sobre este movimiento");
        }
        return movimiento;
    }
    // ------------------------------


    @Override
    @Transactional
    public List<MovimientoResponseDTO> registrar(MovimientosRegistroRequest request, Long cuentaIdAutenticada) {
        if (request.getMovimientos() == null || request.getMovimientos().isEmpty()) {
            throw new BadRequestException("Debe enviar al menos un movimiento");
        }
        
        Perfil perfil = obtenerPerfilValidado(request.getPerfilId(), cuentaIdAutenticada);

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
    public void eliminar(Long id, Long cuentaIdAutenticada) {
        obtenerMovimientoValidado(id, cuentaIdAutenticada);
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

        boolean esIngreso = "ingreso".equalsIgnoreCase(request.getTipo().trim());
        Categoria.TipoCategoria tipo = esIngreso ? Categoria.TipoCategoria.INGRESO : Categoria.TipoCategoria.EGRESO;

        movimiento
                .setCategoria(categoriaService.buscarOCrearCategoria(request.getCategoria(), tipo, perfil));
        movimiento.setMonto(new BigDecimal(request.getMonto().trim()));
        movimiento.setEsIngreso(esIngreso);
        movimiento.setFecha(parsearFecha(request.getFecha()));
        movimiento.setDescripcion(esVacio(request.getDescripcion()) ? null : request.getDescripcion().trim());
        if (!esVacio(request.getEstado())) {
         movimiento.setEstado(Movimiento.EstadoMovimiento.valueOf(request.getEstado().toUpperCase()));
     } else {
         movimiento.setEstado(Movimiento.EstadoMovimiento.APROBADO);
     }
        if (!esVacio(request.getOrigen())) {
            movimiento.setOrigen(Movimiento.OrigenMovimiento.valueOf(request.getOrigen().toUpperCase()));
        } else {
            movimiento.setOrigen(Movimiento.OrigenMovimiento.MANUAL); 
        }
        movimiento.setFechaCreacion(LocalDateTime.now());
        return movimiento;
    }

    private LocalDate parsearFecha(String fecha) {
        if (esVacio(fecha)) {
            return LocalDate.now();
        }
        try {
            return LocalDate.parse(fecha.trim(), FORMATO_FECHA);
        } catch (DateTimeParseException e) {
            throw new BadRequestException("Error: La fecha debe tener el formato dd-MM-yyyy");
        }
    }

    private boolean esVacio(String valor) {
        return valor == null || valor.isBlank();
    }

    @Override
    @Transactional
    public MovimientoResponseDTO actualizar(Long id, Long perfilId, MovimientoRequest request, Long cuentaIdAutenticada) {
        validar(request);
        Movimiento movimientoExistente = obtenerMovimientoValidado(id, cuentaIdAutenticada);

        if (!movimientoExistente.getPerfil().getId().equals(perfilId)) {
             throw new BadRequestException("El perfilId no coincide con el del movimiento");
        }

        boolean esIngreso = "ingreso".equalsIgnoreCase(request.getTipo().trim());
        Categoria.TipoCategoria tipo = esIngreso ? Categoria.TipoCategoria.INGRESO : Categoria.TipoCategoria.EGRESO;

        movimientoExistente.setCategoria(categoriaService.buscarOCrearCategoria(request.getCategoria(), tipo,
        movimientoExistente.getPerfil()));
        movimientoExistente.setMonto(new BigDecimal(request.getMonto().trim()));
        movimientoExistente.setEsIngreso(esIngreso);
        movimientoExistente.setFecha(parsearFecha(request.getFecha()));
        movimientoExistente.setDescripcion(esVacio(request.getDescripcion()) ? null : request.getDescripcion().trim());

        if (!esVacio(request.getOrigen())) {
            movimientoExistente.setOrigen(Movimiento.OrigenMovimiento.valueOf(request.getOrigen().toUpperCase()));
        }

        Movimiento movimientoActualizado = movimientoRepository.save(movimientoExistente);

        return new MovimientoResponseDTO(movimientoActualizado);
    }

    @Override
    @org.springframework.transaction.annotation.Transactional(readOnly = true)
    public Page<MovimientoResponseDTO> listarMovimientos(Long perfilId, Long cuentaIdAutenticada, LocalDate fechaInicio, LocalDate fechaFin,
            Long categoriaId, Boolean esIngreso, String estadoStr, Pageable pageable) {

        Movimiento.EstadoMovimiento estado = null;
        if (estadoStr != null && !estadoStr.isBlank()) {
            estado = Movimiento.EstadoMovimiento.valueOf(estadoStr.toUpperCase());
        }

        Page<Movimiento> paginaMovimientos = movimientoRepository.buscarConFiltros(
                perfilId, cuentaIdAutenticada, fechaInicio, fechaFin, categoriaId, esIngreso, estado, pageable);

        return paginaMovimientos.map(MovimientoResponseDTO::new);
    }

    @Override
    @org.springframework.transaction.annotation.Transactional
    public MovimientoResponseDTO cambiarEstado(Long id, String nuevoEstado, Long cuentaIdAutenticada) {
        Movimiento movimiento = obtenerMovimientoValidado(id, cuentaIdAutenticada);
                
        movimiento.setEstado(Movimiento.EstadoMovimiento.valueOf(nuevoEstado.toUpperCase()));
        return new MovimientoResponseDTO(movimientoRepository.save(movimiento));
    }

    @Override
    @Transactional
    public List<MovimientoResponseDTO> registrarDesdeAudio(MultipartFile audio, Long perfilId, Long cuentaIdAutenticada) throws Exception {
        final byte[] audioBytes = audio.getBytes();
        Perfil perfil = obtenerPerfilValidado(perfilId, cuentaIdAutenticada);

        // 1. Obtenemos el listado de categorías disponibles y lo convertimos a un String para el prompt.
        // Son las del perfil: en una cuenta compartida, las predefinidas y las de esa cuenta (t-13.1.2).
        String categoriasDisponibles = categoriaService.listarDelPerfil(perfil)
                .stream()
                .map(Categoria::getNombre)
                .distinct()
                .collect(java.util.stream.Collectors.joining(", "));

        // 2. Buscamos la categoría "Otros" (por defecto EGRESO para el placeholder)
        Categoria categoriaOtrosEsqueleto = categoriaService.buscar("Otros", Categoria.TipoCategoria.EGRESO, perfil)
                .orElseThrow(() -> new IllegalStateException("Falta categoría 'Otros' de egreso (T-4.1.3)"));

        // 3. Creamos el movimiento "Placeholder" usando "Otros" (sin crear "Procesando...")
        Movimiento placeholder = new Movimiento();
        placeholder.setPerfil(perfil);
        placeholder.setMonto(BigDecimal.ZERO);
        placeholder.setDescripcion("🤖 Analizando audio con IA...");
        placeholder.setFecha(LocalDate.now());
        placeholder.setEsIngreso(false);
        placeholder.setEstado(Movimiento.EstadoMovimiento.PROCESANDO_IA);
        placeholder.setOrigen(Movimiento.OrigenMovimiento.VOZ);
        placeholder.setFechaCreacion(LocalDateTime.now());
        placeholder.setCategoria(categoriaOtrosEsqueleto);

        final Movimiento movimientoGuardado = movimientoRepository.save(placeholder);
        final Long idMovimiento = movimientoGuardado.getId();

        // 4. DISPARAMOS EL HILO EN SEGUNDO PLANO
        java.util.concurrent.CompletableFuture.runAsync(() -> {
            try {
                // Ahora le mandamos la lista de categorías a Gemini
                var datosExtraidos = iaService.procesarAudioYExtraerDatos(audioBytes, categoriasDisponibles);
                
                Movimiento aActualizar = movimientoRepository.findById(idMovimiento).orElseThrow();
                
                boolean esIngreso = "ingreso".equalsIgnoreCase(datosExtraidos.getTipo().trim());
                Categoria.TipoCategoria tipo = esIngreso ? Categoria.TipoCategoria.INGRESO : Categoria.TipoCategoria.EGRESO;
                
                // Mapeo seguro: si Gemini inventó algo que no existe, forzamos a que use "Otros" del tipo correspondiente.
                Categoria catFinal = categoriaService.buscar(datosExtraidos.getCategoria().trim(), tipo, perfil)
                        .orElseGet(() -> categoriaService.buscar("Otros", tipo, perfil)
                                .orElseThrow(() -> new IllegalStateException("Falta categoría 'Otros' de " + tipo)));
                
                aActualizar.setCategoria(catFinal);
                aActualizar.setMonto(new BigDecimal(datosExtraidos.getMonto().trim()));
                aActualizar.setEsIngreso(esIngreso);
                aActualizar.setFecha(parsearFecha(datosExtraidos.getFecha()));
                aActualizar.setDescripcion(truncar(datosExtraidos.getDescripcion(), 250));
                aActualizar.setEstado(Movimiento.EstadoMovimiento.PENDIENTE);
                
                movimientoRepository.save(aActualizar);

            } catch (Exception e) {
                try {
                    movimientoRepository.findById(idMovimiento).ifPresent(aActualizar -> {
                        String msg = e.getMessage() != null ? e.getMessage() : "Error desconocido";
                        aActualizar.setDescripcion(truncar("❌ Error de IA: " + msg, 250));
                        aActualizar.setEstado(Movimiento.EstadoMovimiento.ERROR_IA);
                        movimientoRepository.save(aActualizar);
                    });
                } catch (Exception errorAlGuardarError) {
                    System.err.println("No se pudo guardar el estado de error para el movimiento " + idMovimiento + ": " + errorAlGuardarError.getMessage());
                }
            }
        });
        
        return java.util.Collections.singletonList(new MovimientoResponseDTO(movimientoGuardado));
    }

    private String truncar(String texto, int maxLength) {
        if (texto == null) return null;
        return texto.length() > maxLength ? texto.substring(0, maxLength) : texto;
    }
  

    @Override
    @org.springframework.transaction.annotation.Transactional(readOnly = true)
    public List<MovimientoResponseDTO> obtenerUltimosMovimientos(Long perfilId, Long cuentaIdAutenticada, int limite) {
        return movimientoRepository.buscarUltimosMovimientos(perfilId, cuentaIdAutenticada, PageRequest.of(0, limite))
                .stream().map(MovimientoResponseDTO::new).toList();
    }

    @Override
    @org.springframework.transaction.annotation.Transactional(readOnly = true)
    public List<MovimientoResponseDTO> obtenerUltimosIngresos(Long perfilId, Long cuentaIdAutenticada, int limite) {
        return movimientoRepository.buscarUltimosIngresos(perfilId, cuentaIdAutenticada, PageRequest.of(0, limite))
                .stream().map(MovimientoResponseDTO::new).toList();
    }

    @Override
    @org.springframework.transaction.annotation.Transactional(readOnly = true)
    public List<MovimientoResponseDTO> obtenerUltimosEgresos(Long perfilId, Long cuentaIdAutenticada, int limite) {
        return movimientoRepository.buscarUltimosEgresos(perfilId, cuentaIdAutenticada, PageRequest.of(0, limite))
                .stream().map(MovimientoResponseDTO::new).toList();
    }
    
    @Override
    @org.springframework.transaction.annotation.Transactional(readOnly = true)
    public List<MovimientoResponseDTO> obtenerPendientesMercadoPago(Long perfilId, Long cuentaIdAutenticada) {
        obtenerPerfilValidado(perfilId, cuentaIdAutenticada);
        List<Movimiento> pendientes = movimientoRepository.findPendientesMercadoPago(
                perfilId,
                Movimiento.OrigenMovimiento.MERCADOPAGO,
                Movimiento.EstadoMovimiento.PENDIENTE);
        return pendientes.stream()
                .map(MovimientoResponseDTO::new)
                .toList();
    }
}