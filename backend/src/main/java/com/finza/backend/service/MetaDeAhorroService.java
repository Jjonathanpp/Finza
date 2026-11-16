package com.finza.backend.service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.NoSuchElementException;

import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.finza.backend.exception.BadRequestException;
import com.finza.backend.model.MetaDeAhorro;
import com.finza.backend.model.Perfil;
import com.finza.backend.repository.MetaDeAhorroRepository;

@Service
public class MetaDeAhorroService {

    private final MetaDeAhorroRepository metaRepository;
    private final PerfilService perfilService;

    public MetaDeAhorroService(MetaDeAhorroRepository metaRepository, PerfilService perfilService) {
        this.metaRepository = metaRepository;
        this.perfilService = perfilService;
    }

    /**
     * Crea una nueva meta de ahorro.
     * - Si es cuenta compartida: exige que el usuario sea ADMIN.
     * - Si es personal: toma el perfil activo del usuario (quien ya es dueño/admin
     * de su perfil).
     */
    @Transactional
    public MetaDeAhorro crearMeta(Long cuentaId, Long cuentaCompartidaId, String nombre, BigDecimal montoObjetivo,
            LocalDate fechaLimite) {
        validarDatos(nombre, montoObjetivo, fechaLimite);

        MetaDeAhorro meta = new MetaDeAhorro();
        meta.setNombre(nombre);
        meta.setMontoObjetivo(montoObjetivo);
        meta.setFechaLimite(fechaLimite);

        if (cuentaCompartidaId != null) {
            Perfil adminPerfil = perfilService.exigirAdmin(cuentaId, cuentaCompartidaId);
            meta.setCuentaCompartida(adminPerfil.getCuentaCompartida());
        } else {
            meta.setPerfil(perfilPersonalActivo(cuentaId));
        }

        return metaRepository.save(meta);
    }

    /**
     * Edita una meta existente. Exige permisos de ADMIN si es compartida,
     * o ser el dueño si es perfil personal.
     */
    @Transactional
    public MetaDeAhorro editarMeta(Long cuentaId, Long metaId, String nombre, BigDecimal montoObjetivo,
            LocalDate fechaLimite) {
        MetaDeAhorro meta = obtenerMetaPorId(metaId);
        validarPermiso(cuentaId, meta, true);

        if (nombre != null) {
            validarNombre(nombre);
            meta.setNombre(nombre);
        }
        if (montoObjetivo != null) {
            validarMontoObjetivo(montoObjetivo);
            meta.setMontoObjetivo(montoObjetivo);
        }
        if (fechaLimite != null) {
            validarFechaLimite(fechaLimite);
            meta.setFechaLimite(fechaLimite);
        }

        return metaRepository.save(meta);
    }

    /**
     * Abona dinero a una meta.
     * Cualquier miembro de la cuenta compartida (o el dueño del perfil personal) puede aportar dinero.
     */
    @Transactional
    public MetaDeAhorro abonarDinero(Long cuentaId, Long metaId, BigDecimal montoAbono) {
        if (montoAbono == null || montoAbono.compareTo(BigDecimal.ZERO) <= 0) {
            throw new BadRequestException("El monto a abonar debe ser mayor a cero");
        }

        MetaDeAhorro meta = obtenerMetaPorId(metaId);
        validarPermiso(cuentaId, meta, false);

        meta.setMontoActual(meta.getMontoActual().add(montoAbono));

        return metaRepository.save(meta);
    }

    /**
     * Lista las metas según el contexto (perfil personal o cuenta compartida).
     */
    @Transactional(readOnly = true)
    public List<MetaDeAhorro> listarMetas(Long cuentaId, Long cuentaCompartidaId) {
        if (cuentaCompartidaId != null) {
            perfilService.exigirMiembro(cuentaId, cuentaCompartidaId);
            return metaRepository.findByCuentaCompartidaId(cuentaCompartidaId);
        } else {
            return metaRepository.findByPerfilId(perfilPersonalActivo(cuentaId).getId());
        }
    }

    /**
     * Elimina una meta. Exige permisos de ADMIN si es compartida.
     */
    @Transactional
    public void eliminarMeta(Long cuentaId, Long metaId) {
        MetaDeAhorro meta = obtenerMetaPorId(metaId);
        validarPermiso(cuentaId, meta, true);
        metaRepository.delete(meta);
    }

    // --- Métodos Auxiliares de Validación ---

    private MetaDeAhorro obtenerMetaPorId(Long metaId) {
        return metaRepository.findById(metaId)
                .orElseThrow(() -> new NoSuchElementException("Meta de ahorro no encontrada con ID: " + metaId));
    }

    private Perfil perfilPersonalActivo(Long cuentaId) {
        Perfil perfil = perfilService.perfilActivo(cuentaId);
        if (perfil.getCuentaCompartida() != null) {
            throw new BadRequestException("Indica la cuenta compartida para operar en ese contexto");
        }
        return perfil;
    }

    private void validarPermiso(Long cuentaId, MetaDeAhorro meta, boolean requiereAdmin) {
        if (meta.getCuentaCompartida() != null) {
            if (requiereAdmin) {
                perfilService.exigirAdmin(cuentaId, meta.getCuentaCompartida().getId());
            } else {
                perfilService.exigirMiembro(cuentaId, meta.getCuentaCompartida().getId());
            }
        } else if (meta.getPerfil() != null) {
            Perfil perfilActivo = perfilService.perfilActivo(cuentaId);
            if (!meta.getPerfil().getId().equals(perfilActivo.getId())) {
                String mensaje = requiereAdmin
                        ? "No tienes permisos de administración sobre esta meta personal"
                        : "No tienes acceso a esta meta personal";
                throw new AccessDeniedException(mensaje);
            }
        } else {
            throw new IllegalStateException("La meta de ahorro no tiene un propietario válido");
        }
    }

    private void validarDatos(String nombre, BigDecimal montoObjetivo, LocalDate fechaLimite) {
        validarNombre(nombre);
        validarMontoObjetivo(montoObjetivo);
        if (fechaLimite != null) {
            validarFechaLimite(fechaLimite);
        }
    }

    private void validarNombre(String nombre) {
        if (nombre == null || nombre.isBlank()) {
            throw new BadRequestException("El nombre de la meta es obligatorio");
        }
        if (nombre.length() > 100) {
            throw new BadRequestException("El nombre de la meta no puede superar los 100 caracteres");
        }
    }

    private void validarMontoObjetivo(BigDecimal montoObjetivo) {
        if (montoObjetivo == null || montoObjetivo.compareTo(BigDecimal.ZERO) <= 0) {
            throw new BadRequestException("El monto objetivo debe ser mayor a cero");
        }
    }

    private void validarFechaLimite(LocalDate fechaLimite) {
        if (fechaLimite.isBefore(LocalDate.now())) {
            throw new BadRequestException("La fecha límite no puede estar en el pasado");
        }
    }
}
