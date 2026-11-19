package com.finza.backend.service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.Map;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.stream.Collectors;

import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.finza.backend.dto.meta_de_ahorro.AporteMetaAhorroResponseDTO;
import com.finza.backend.model.AporteMetaAhorro;
import com.finza.backend.exception.BadRequestException;
import com.finza.backend.model.MetaDeAhorro;
import com.finza.backend.model.Perfil;
import com.finza.backend.repository.AporteMetaAhorroRepository;
import com.finza.backend.repository.MetaDeAhorroRepository;

@Service
public class MetaDeAhorroService {

    private final MetaDeAhorroRepository metaRepository;
    private final AporteMetaAhorroRepository aporteRepository;
    private final PerfilService perfilService;

    public MetaDeAhorroService(
            MetaDeAhorroRepository metaRepository,
            AporteMetaAhorroRepository aporteRepository,
            PerfilService perfilService) {
        this.metaRepository = metaRepository;
        this.aporteRepository = aporteRepository;
        this.perfilService = perfilService;
    }

    /** Calcula aportes que, incluyendo el último aporte ajustado, suman el saldo pendiente. */
    public CuotasAhorro calcularCuotas(MetaDeAhorro meta) {
        BigDecimal montoRestante = meta.getMontoObjetivo()
                .subtract(meta.getMontoActual())
                .max(BigDecimal.ZERO);

        if (montoRestante.signum() == 0) {
            BigDecimal cero = BigDecimal.ZERO.setScale(2);
            return new CuotasAhorro(montoRestante, cero, cero, cero, cero, cero, cero);
        }

        if (meta.getFechaLimite() == null) {
            return new CuotasAhorro(montoRestante, null, null, null, null, null, null);
        }

        LocalDate hoy = LocalDate.now();
        LocalDate fechaLimite = meta.getFechaLimite();
        long diasDisponibles = Math.max(ChronoUnit.DAYS.between(hoy, fechaLimite) + 1, 1);
        Cuota diaria = calcularCuota(montoRestante, diasDisponibles);
        Cuota semanal = calcularCuota(montoRestante, (diasDisponibles + 6) / 7);
        Cuota mensual = null;
        if (meta.getFechaCreacion() != null
                && !meta.getFechaCreacion().toLocalDate().plusMonths(1).isAfter(fechaLimite)) {
            long mesesDisponibles = Math.max(ChronoUnit.MONTHS.between(hoy, fechaLimite) + 1, 1);
            mensual = calcularCuota(montoRestante, mesesDisponibles);
        }

        return new CuotasAhorro(
                montoRestante,
                diaria.aporte(),
                diaria.ultimoAporte(),
                semanal.aporte(),
                semanal.ultimoAporte(),
                mensual == null ? null : mensual.aporte(),
                mensual == null ? null : mensual.ultimoAporte());
    }

    public record CuotasAhorro(
            BigDecimal montoRestante,
            BigDecimal cuotaDiaria,
            BigDecimal cuotaDiariaFinal,
            BigDecimal cuotaSemanal,
            BigDecimal cuotaSemanalFinal,
            BigDecimal cuotaMensual,
            BigDecimal cuotaMensualFinal) {
    }

    private Cuota calcularCuota(BigDecimal montoRestante, long cantidadAportes) {
        BigDecimal cantidad = BigDecimal.valueOf(cantidadAportes);
        BigDecimal aporte = montoRestante.divide(cantidad, 2, RoundingMode.DOWN);
        BigDecimal ultimoAporte = montoRestante.subtract(
                aporte.multiply(BigDecimal.valueOf(cantidadAportes - 1)));
        return new Cuota(aporte, ultimoAporte);
    }

    private record Cuota(BigDecimal aporte, BigDecimal ultimoAporte) {
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

        MetaDeAhorro meta = metaRepository.findByIdForUpdate(metaId)
                .orElseThrow(() -> new NoSuchElementException("Meta de ahorro no encontrada con ID: " + metaId));
        Perfil perfil;
        if (meta.getCuentaCompartida() != null) {
            Perfil miembro = perfilService.exigirMiembro(cuentaId, meta.getCuentaCompartida().getId());
            perfil = perfilService.perfilActivo(cuentaId);
            if (!miembro.getId().equals(perfil.getId())) {
                throw new AccessDeniedException("Selecciona el perfil de esta cuenta compartida para aportar");
            }
        } else {
            validarPermiso(cuentaId, meta, false);
            perfil = perfilService.perfilActivo(cuentaId);
        }

        BigDecimal montoRestante = meta.getMontoObjetivo().subtract(meta.getMontoActual())
                .max(BigDecimal.ZERO);
        if (montoRestante.signum() == 0) {
            throw new BadRequestException("La meta de ahorro ya alcanzó su monto objetivo");
        }
        if (montoAbono.compareTo(montoRestante) > 0) {
            throw new BadRequestException("El monto a abonar no puede superar el monto restante de la meta");
        }

        meta.setMontoActual(meta.getMontoActual().add(montoAbono));

        AporteMetaAhorro aporte = new AporteMetaAhorro();
        aporte.setMeta(meta);
        aporte.setPerfil(perfil);
        aporte.setMonto(montoAbono);
        aporteRepository.save(aporte);

        return metaRepository.save(meta);
    }

    @Transactional(readOnly = true)
    public ResumenAportes resumenAportes(Long cuentaId, MetaDeAhorro meta) {
        validarPermiso(cuentaId, meta, false);
        List<Map<String, Object>> perfiles;
        if (meta.getCuentaCompartida() == null) {
            Perfil perfil = perfilService.perfilActivo(cuentaId);
            perfiles = List.of(Map.of(
                    "perfilId", perfil.getId(),
                    "nombre", perfil.getNombrePerfil() != null ? perfil.getNombrePerfil() : "Sin nombre"));
        } else {
            perfiles = perfilService.miembrosActivosDeCuentaCompartida(
                    cuentaId,
                    meta.getCuentaCompartida().getId());
        }

        List<AporteMetaAhorro> aportesGuardados = aporteRepository.findByMetaId(meta.getId());
        Map<Long, BigDecimal> montosPorPerfil = aportesGuardados.stream()
                .filter(aporte -> aporte.getPerfil() != null)
                .collect(Collectors.groupingBy(
                        aporte -> aporte.getPerfil().getId(),
                        Collectors.mapping(
                                AporteMetaAhorro::getMonto,
                                Collectors.reducing(BigDecimal.ZERO, BigDecimal::add))));

        List<AporteMetaAhorroResponseDTO> aportesPorPerfil = perfiles.stream()
                .map(perfil -> {
                    Long perfilId = (Long) perfil.get("perfilId");
                    return new AporteMetaAhorroResponseDTO(
                            perfilId,
                            (String) perfil.get("nombre"),
                            montosPorPerfil.getOrDefault(perfilId, BigDecimal.ZERO.setScale(2)));
                })
                .toList();

        return new ResumenAportes(aportesPorPerfil);
    }

    public record ResumenAportes(
            List<AporteMetaAhorroResponseDTO> integrantes) {
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
