package com.finza.backend.service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.NoSuchElementException;
import java.util.Set;
import java.util.stream.Collectors;

import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.finza.backend.dto.meta_de_ahorro.AporteIntegranteDTO;
import com.finza.backend.dto.meta_de_ahorro.AporteMetaAhorroResponseDTO;
import com.finza.backend.dto.meta_de_ahorro.ResumenAportesMetaDTO;
import com.finza.backend.exception.BadRequestException;
import com.finza.backend.model.AporteMetaAhorro;
import com.finza.backend.model.Categoria;
import com.finza.backend.model.MetaDeAhorro;
import com.finza.backend.model.Movimiento;
import com.finza.backend.model.Perfil;
import com.finza.backend.repository.AporteMetaAhorroRepository;
import com.finza.backend.repository.CategoriaRepository;
import com.finza.backend.repository.MetaDeAhorroRepository;
import com.finza.backend.repository.MovimientoRepository;

@Service
public class MetaDeAhorroService {

    private final MetaDeAhorroRepository metaRepository;
    private final AporteMetaAhorroRepository aporteRepository;
    private final CategoriaRepository categoriaRepository;
    private final MovimientoRepository movimientoRepository;
    private final PerfilService perfilService;

    public MetaDeAhorroService(
            MetaDeAhorroRepository metaRepository,
            AporteMetaAhorroRepository aporteRepository,
            CategoriaRepository categoriaRepository,
            MovimientoRepository movimientoRepository,
            PerfilService perfilService) {
        this.metaRepository = metaRepository;
        this.aporteRepository = aporteRepository;
        this.categoriaRepository = categoriaRepository;
        this.movimientoRepository = movimientoRepository;
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
     * - Si es personal: toma el perfil activo del usuario.
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
        if (perfil.getCuenta() != null) {
            aporte.setUsuario(perfil.getCuenta().getUsuario());
        }
        aporte.setMonto(montoAbono);
        aporteRepository.save(aporte);

        registrarMovimientoMeta(meta, perfil, montoAbono, false);
        return metaRepository.save(meta);
    }

    /**
     * Retira dinero de una meta. Cualquier miembro de la cuenta compartida puede
     * retirar, pero nunca más que el saldo actual.
     */
    @Transactional
    public MetaDeAhorro retirarDinero(Long cuentaId, Long metaId, BigDecimal montoRetiro) {
        if (montoRetiro == null || montoRetiro.compareTo(BigDecimal.ZERO) <= 0) {
            throw new BadRequestException("El monto a retirar debe ser mayor a cero");
        }

        MetaDeAhorro meta = metaRepository.findByIdForUpdate(metaId)
                .orElseThrow(() -> new NoSuchElementException("Meta de ahorro no encontrada con ID: " + metaId));
        Perfil perfil;
        if (meta.getCuentaCompartida() != null) {
            Perfil miembro = perfilService.exigirMiembro(cuentaId, meta.getCuentaCompartida().getId());
            perfil = perfilService.perfilActivo(cuentaId);
            if (!miembro.getId().equals(perfil.getId())) {
                throw new AccessDeniedException("Selecciona el perfil de esta cuenta compartida para retirar");
            }
        } else {
            validarPermiso(cuentaId, meta, false);
            perfil = perfilService.perfilActivo(cuentaId);
        }

        if (montoRetiro.compareTo(meta.getMontoActual()) > 0) {
            throw new BadRequestException("El monto a retirar no puede superar el saldo disponible de la meta");
        }

        meta.setMontoActual(meta.getMontoActual().subtract(montoRetiro));
        actualizarAportesDisponibles(meta, perfil);
        registrarMovimientoMeta(meta, perfil, montoRetiro, true);
        return metaRepository.save(meta);
    }

    private void actualizarAportesDisponibles(MetaDeAhorro meta, Perfil perfilQueRetira) {
        List<AporteMetaAhorro> aportes = new ArrayList<>(
                aporteRepository.findByMetaIdOrderByIdAsc(meta.getId()));
        BigDecimal totalAportes = aportes.stream()
                .map(AporteMetaAhorro::getMonto)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        if (totalAportes.compareTo(meta.getMontoActual()) < 0) {
            AporteMetaAhorro aporteSinAtribuir = new AporteMetaAhorro();
            aporteSinAtribuir.setMeta(meta);
            aporteSinAtribuir.setMonto(meta.getMontoActual().subtract(totalAportes));
            aporteRepository.save(aporteSinAtribuir);
            aportes.add(aporteSinAtribuir);
            totalAportes = meta.getMontoActual();
        }

        BigDecimal montoAReducir = totalAportes.subtract(meta.getMontoActual());
        if (montoAReducir.signum() <= 0) {
            return;
        }

        aportes.sort(Comparator
                .comparing((AporteMetaAhorro aporte) -> !esAporteDePerfil(aporte, perfilQueRetira))
                .thenComparing(AporteMetaAhorro::getId, Comparator.nullsLast(Comparator.naturalOrder())));

        for (AporteMetaAhorro aporte : aportes) {
            if (montoAReducir.signum() == 0) {
                break;
            }
            BigDecimal reduccion = aporte.getMonto().min(montoAReducir);
            BigDecimal montoActualizado = aporte.getMonto().subtract(reduccion);
            if (montoActualizado.signum() == 0) {
                aporteRepository.delete(aporte);
            } else {
                aporte.setMonto(montoActualizado);
            }
            montoAReducir = montoAReducir.subtract(reduccion);
        }
    }

    private boolean esAporteDePerfil(AporteMetaAhorro aporte, Perfil perfil) {
        return aporte.getPerfil() != null && aporte.getPerfil().getId().equals(perfil.getId());
    }

    private void registrarMovimientoMeta(MetaDeAhorro meta, Perfil perfil, BigDecimal monto, boolean esIngreso) {
        Categoria categoria = categoriaRepository
                .findFirstByCuentaIsNullAndCuentaCompartidaIsNullAndNombreIgnoreCaseAndTipoCategoriaPredefinida(
                        "Meta Ahorro", Categoria.TipoCategoria.AMBOS)
                .orElseThrow(() -> new IllegalStateException("No existe la categoría predefinida Meta Ahorro"));

        Movimiento movimiento = new Movimiento();
        movimiento.setPerfil(perfil);
        movimiento.setCategoria(categoria);
        movimiento.setMonto(monto);
        movimiento.setEsIngreso(esIngreso);
        movimiento.setFecha(LocalDate.now());
        movimiento.setDescripcion((esIngreso ? "Retiro de meta: " : "Aporte a meta: ") + meta.getNombre());
        movimiento.setEstado(Movimiento.EstadoMovimiento.APROBADO);
        movimiento.setOrigen(Movimiento.OrigenMovimiento.MANUAL);
        movimiento.setFechaCreacion(LocalDateTime.now());
        movimientoRepository.save(movimiento);
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
     * T-15.3.3: Devuelve el resumen de avance total de una meta junto con el desglose
     * de aportes por integrante (activos y ex integrantes que hayan aportado).
     */
    @Transactional(readOnly = true)
    public ResumenAportesMetaDTO obtenerResumenAportes(Long cuentaId, Long metaId) {
        MetaDeAhorro meta = obtenerMetaPorId(metaId);
        validarPermiso(cuentaId, meta, false);

        BigDecimal montoObjetivo = meta.getMontoObjetivo();
        BigDecimal montoActual = meta.getMontoActual();
        BigDecimal montoRestante = montoObjetivo.subtract(montoActual).max(BigDecimal.ZERO);
        BigDecimal porcentajeAvance = calcularPorcentaje(montoActual, montoObjetivo);

        List<AporteMetaAhorro> aportesGuardados = aporteRepository.findByMetaId(meta.getId());
        Map<Long, BigDecimal> montosPorPerfil = new LinkedHashMap<>();
        Map<Long, AporteMetaAhorro> referenciaPorPerfil = new LinkedHashMap<>();
        BigDecimal montoSinPerfil = BigDecimal.ZERO;

        for (AporteMetaAhorro aporte : aportesGuardados) {
            if (aporte.getPerfil() != null) {
                Long perfilId = aporte.getPerfil().getId();
                montosPorPerfil.merge(perfilId, aporte.getMonto(), BigDecimal::add);
                referenciaPorPerfil.putIfAbsent(perfilId, aporte);
            } else {
                montoSinPerfil = montoSinPerfil.add(aporte.getMonto());
            }
        }

        List<AporteIntegranteDTO> desglose = new ArrayList<>();
        Set<Long> perfilesIncluidos = new HashSet<>();

        if (meta.getCuentaCompartida() == null) {
            Perfil perfil = meta.getPerfil();
            Long perfilId = perfil.getId();
            perfilesIncluidos.add(perfilId);
            BigDecimal monto = montosPorPerfil.getOrDefault(perfilId, BigDecimal.ZERO.setScale(2));
            Long usuarioId = (perfil.getCuenta() != null && perfil.getCuenta().getUsuario() != null)
                    ? perfil.getCuenta().getUsuario().getId()
                    : extraerUsuarioId(referenciaPorPerfil.get(perfilId));
            desglose.add(new AporteIntegranteDTO(
                    perfilId,
                    usuarioId,
                    perfil.getNombrePerfil() != null ? perfil.getNombrePerfil() : "Sin nombre",
                    monto,
                    calcularPorcentaje(monto, montoObjetivo),
                    perfil.isEsActivo()));
        } else {
            List<Map<String, Object>> activos = perfilService.miembrosActivosDeCuentaCompartida(
                    cuentaId,
                    meta.getCuentaCompartida().getId());

            for (Map<String, Object> miembro : activos) {
                Long perfilId = (Long) miembro.get("perfilId");
                String nombre = (String) miembro.get("nombre");
                perfilesIncluidos.add(perfilId);

                BigDecimal monto = montosPorPerfil.getOrDefault(perfilId, BigDecimal.ZERO.setScale(2));
                desglose.add(new AporteIntegranteDTO(
                        perfilId,
                        extraerUsuarioId(referenciaPorPerfil.get(perfilId)),
                        nombre,
                        monto,
                        calcularPorcentaje(monto, montoObjetivo),
                        true));
            }

            // Ex integrantes que registraron aportes antes de salir de la cuenta compartida
            for (Map.Entry<Long, BigDecimal> entry : montosPorPerfil.entrySet()) {
                Long perfilId = entry.getKey();
                if (!perfilesIncluidos.contains(perfilId)) {
                    AporteMetaAhorro ref = referenciaPorPerfil.get(perfilId);
                    Perfil perfil = ref.getPerfil();
                    String nombre = (perfil != null && perfil.getNombrePerfil() != null)
                            ? perfil.getNombrePerfil()
                            : "Ex integrante";
                    BigDecimal monto = entry.getValue();
                    desglose.add(new AporteIntegranteDTO(
                            perfilId,
                            extraerUsuarioId(ref),
                            nombre,
                            monto,
                            calcularPorcentaje(monto, montoObjetivo),
                            false));
                }
            }
        }

        if (montoSinPerfil.signum() > 0) {
            desglose.add(new AporteIntegranteDTO(
                    null,
                    null,
                    "Ex integrante",
                    montoSinPerfil,
                    calcularPorcentaje(montoSinPerfil, montoObjetivo),
                    false));
        }

        desglose.sort(Comparator.comparing(AporteIntegranteDTO::monto).reversed()
                .thenComparing(AporteIntegranteDTO::perfilId, Comparator.nullsLast(Comparator.naturalOrder())));

        return new ResumenAportesMetaDTO(
                meta.getId(),
                meta.getNombre(),
                meta.getCuentaCompartida() != null ? meta.getCuentaCompartida().getId() : null,
                montoObjetivo,
                montoActual,
                montoRestante,
                porcentajeAvance,
                desglose);
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

    private Long extraerUsuarioId(AporteMetaAhorro aporte) {
        if (aporte == null) {
            return null;
        }
        if (aporte.getUsuario() != null) {
            return aporte.getUsuario().getId();
        }
        if (aporte.getPerfil() != null
                && aporte.getPerfil().getCuenta() != null
                && aporte.getPerfil().getCuenta().getUsuario() != null) {
            return aporte.getPerfil().getCuenta().getUsuario().getId();
        }
        return null;
    }

    private BigDecimal calcularPorcentaje(BigDecimal monto, BigDecimal objetivo) {
        if (objetivo == null || objetivo.signum() <= 0) {
            return BigDecimal.ZERO.setScale(1, RoundingMode.HALF_UP);
        }
        return monto.multiply(BigDecimal.valueOf(100))
                .divide(objetivo, 1, RoundingMode.HALF_UP);
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