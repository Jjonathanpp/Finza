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
import com.finza.backend.repository.MovimientoRepository;
import com.finza.backend.repository.PerfilRepository;
import com.finza.backend.service.CategoriaService;
import com.finza.backend.service.IAService;
import com.finza.backend.service.MovimientoService;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.data.domain.Page;
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
                .setCategoria(categoriaService.buscarOCrearCategoria(request.getCategoria(), tipo, perfil.getCuenta()));
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
            movimiento.setOrigen(Movimiento.OrigenMovimiento.MANUAL); // Por defecto si se carga desde el formulario
                                                                      // normal
        }
        movimiento.setFechaCreacion(LocalDateTime.now());
        return movimiento;
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
        movimientoExistente.getPerfil().getCuenta()));
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
        // 1. Extraemos los bytes del audio INMEDIATAMENTE antes de que Spring destruya la petición
        final byte[] audioBytes = audio.getBytes();
        
        // 2. Buscamos el perfil
        Perfil perfil = obtenerPerfilValidado(perfilId, cuentaIdAutenticada);

        // 3. Creamos el movimiento "Placeholder" o Esqueleto
        Movimiento placeholder = new Movimiento();
        placeholder.setPerfil(perfil);
        placeholder.setMonto(BigDecimal.ZERO); // Monto en 0 temporalmente
        placeholder.setDescripcion("🤖 Analizando audio con IA...");
        placeholder.setFecha(LocalDate.now());
        placeholder.setEsIngreso(false); // Asumimos egreso por defecto
        placeholder.setEstado(Movimiento.EstadoMovimiento.PROCESANDO_IA); // Estado temporal
        placeholder.setOrigen(Movimiento.OrigenMovimiento.VOZ);
        placeholder.setFechaCreacion(LocalDateTime.now());
        
        // Le asignamos una categoría temporal genérica para que la base de datos no rechace el null
        Categoria catTemp = categoriaService.buscarOCrearCategoria("Procesando...", Categoria.TipoCategoria.EGRESO, perfil.getCuenta());
        placeholder.setCategoria(catTemp);

        // Guardamos el esqueleto en la base de datos para obtener su ID
        final Movimiento movimientoGuardado = movimientoRepository.save(placeholder);
        final Long idMovimiento = movimientoGuardado.getId();

        // 4. DISPARAMOS EL HILO EN SEGUNDO PLANO (Asíncrono)
        java.util.concurrent.CompletableFuture.runAsync(() -> {
        try {
                var datosExtraidos = iaService.procesarAudioYExtraerDatos(audioBytes);
                
                Movimiento aActualizar = movimientoRepository.findById(idMovimiento).orElseThrow();
                
                boolean esIngreso = "ingreso".equalsIgnoreCase(datosExtraidos.getTipo().trim());
                Categoria.TipoCategoria tipo = esIngreso ? Categoria.TipoCategoria.INGRESO : Categoria.TipoCategoria.EGRESO;
                
                aActualizar.setCategoria(categoriaService.buscarOCrearCategoria(datosExtraidos.getCategoria(), tipo, perfil.getCuenta()));
                aActualizar.setMonto(new BigDecimal(datosExtraidos.getMonto().trim()));
                aActualizar.setEsIngreso(esIngreso);
                aActualizar.setFecha(parsearFecha(datosExtraidos.getFecha()));
                aActualizar.setDescripcion(truncar(datosExtraidos.getDescripcion(), 250)); // <-- truncado defensivo
                aActualizar.setEstado(Movimiento.EstadoMovimiento.PENDIENTE);
                
                movimientoRepository.save(aActualizar);

            } catch (Exception e) {
                try {
                    movimientoRepository.findById(idMovimiento).ifPresent(aActualizar -> {
                        String msg = e.getMessage() != null ? e.getMessage() : "Error desconocido";
                        aActualizar.setDescripcion(truncar("❌ Error de IA: " + msg, 250)); // <-- truncado defensivo acá también
                        aActualizar.setEstado(Movimiento.EstadoMovimiento.ERROR_IA);
                        movimientoRepository.save(aActualizar);
                    });
                } catch (Exception errorAlGuardarError) {
                    // Si ESTO también falla, al menos lo vas a ver en los logs en vez de perderlo en silencio
                    System.err.println("No se pudo guardar el estado de error para el movimiento " + idMovimiento + ": " + errorAlGuardarError.getMessage());
                }
            }
        });
        // 5. Devolvemos el esqueleto al Controller de forma instantánea. El usuario no espera a la IA.
        return java.util.Collections.singletonList(new MovimientoResponseDTO(movimientoGuardado));
    }

    private String truncar(String texto, int maxLength) {
        if (texto == null) return null;
        return texto.length() > maxLength ? texto.substring(0, maxLength) : texto;
    }

}