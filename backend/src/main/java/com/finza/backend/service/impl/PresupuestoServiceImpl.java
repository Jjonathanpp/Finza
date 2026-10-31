package com.finza.backend.service.impl;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.NoSuchElementException;
import java.util.stream.Collectors;

import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.finza.backend.dto.panel.GastoPorCategoriaDTO;
import com.finza.backend.dto.presupuesto.GastoDePerfilDTO;
import com.finza.backend.dto.presupuesto.PresupuestoCategoriaDTO;
import com.finza.backend.dto.presupuesto.PresupuestoMesDTO;
import com.finza.backend.dto.presupuesto.PresupuestoRequest;
import com.finza.backend.exception.BadRequestException;
import com.finza.backend.model.Categoria;
import com.finza.backend.model.CuentaCompartida;
import com.finza.backend.model.Perfil;
import com.finza.backend.model.Presupuesto;
import com.finza.backend.repository.CategoriaRepository;
import com.finza.backend.repository.MovimientoRepository;
import com.finza.backend.repository.PerfilRepository;
import com.finza.backend.repository.PresupuestoRepository;
import com.finza.backend.service.PerfilService;
import com.finza.backend.service.PresupuestoService;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class PresupuestoServiceImpl implements PresupuestoService {

    private final PresupuestoRepository presupuestoRepository;
    private final MovimientoRepository movimientoRepository;
    private final PerfilRepository perfilRepository;
    private final CategoriaRepository categoriaRepository;
    private final PerfilService perfilService;
    /* 
    private Perfil obtenerPerfilValidado(Long perfilId, Long cuentaIdAutenticada) {
        Perfil perfil = perfilRepository.findById(perfilId)
                .orElseThrow(() -> new NoSuchElementException("El perfil indicado no existe"));
                
        if (!perfil.getCuenta().getId().equals(cuentaIdAutenticada)) {
            throw new AccessDeniedException("No tenés permiso para operar sobre este perfil");
        }
        return perfil;
    }
        */

    private Perfil obtenerPerfilValidado(Long perfilId, Long cuentaIdAutenticada) {
        Perfil perfil = perfilRepository.findById(perfilId)
                .orElseThrow(() -> new NoSuchElementException("El perfil indicado no existe"));
                
        if (!perfil.getCuenta().getId().equals(cuentaIdAutenticada)) {
            throw new AccessDeniedException("No tenés permiso para operar sobre este perfil");
        }
        return perfil;
    }

    // Solo los presupuestos personales: para estos endpoints, el de una cuenta compartida no existe.
    private Presupuesto obtenerPresupuestoValidado(Long presupuestoId, Long cuentaIdAutenticada) {
        Presupuesto presupuesto = presupuestoRepository.findById(presupuestoId)
                .filter(p -> p.getPerfil() != null)
                .orElseThrow(() -> new NoSuchElementException("Presupuesto no encontrado"));

        if (!presupuesto.getPerfil().getCuenta().getId().equals(cuentaIdAutenticada)) {
            throw new AccessDeniedException("No tenés permiso para operar sobre este presupuesto");
        }
        return presupuesto;
    }

    // El presupuesto que edita o desactiva el perfil activo. Personal: como siempre. En una cuenta
    // compartida (t-13.1.2): solo el administrador, y solo los de esa cuenta compartida (si no, 404).
    private Presupuesto obtenerPresupuestoDelPerfil(Long presupuestoId, Perfil perfil, Long cuentaIdAutenticada) {
        CuentaCompartida compartida = perfil.getCuentaCompartida();
        if (compartida == null) {
            Presupuesto presupuesto = obtenerPresupuestoValidado(presupuestoId, cuentaIdAutenticada);
            if (!presupuesto.getPerfil().getId().equals(perfil.getId())) {
                throw new BadRequestException("El presupuesto no pertenece al perfil indicado");
            }
            return presupuesto;
        }
        perfilService.exigirAdmin(cuentaIdAutenticada, compartida.getId());
        return presupuestoRepository.findById(presupuestoId)
                .filter(p -> p.getCuentaCompartida() != null && p.getCuentaCompartida().getId().equals(compartida.getId()))
                .orElseThrow(() -> new NoSuchElementException("Presupuesto no encontrado"));
    }

    // El gasto por categoría del período: del perfil o, en una cuenta compartida, de todos sus perfiles.
    private List<GastoPorCategoriaDTO> gastosDelPeriodo(Perfil perfil, LocalDate desde, LocalDate hasta) {
        CuentaCompartida compartida = perfil.getCuentaCompartida();
        return compartida == null
                ? movimientoRepository.sumarGastosPorCategoria(perfil.getId(), desde, hasta)
                : movimientoRepository.sumarGastosPorCategoriaDeCuentaCompartida(compartida.getId(), desde, hasta);
    }

    // Personal: una predefinida o una propia. En una cuenta compartida: una predefinida o una de esa
    // cuenta compartida (las personales de cada integrante no). Si no, 403.
    private Categoria obtenerCategoriaValidada(Long categoriaId, Long cuentaIdAutenticada, CuentaCompartida compartida) {
        Categoria categoria = categoriaRepository.findById(categoriaId)
                .orElseThrow(() -> new NoSuchElementException("La categoría indicada no existe"));

        boolean predefinida = categoria.getCuenta() == null && categoria.getCuentaCompartida() == null;
        boolean propia = compartida == null
                ? categoria.getCuenta() != null && categoria.getCuenta().getId().equals(cuentaIdAutenticada)
                : categoria.getCuentaCompartida() != null && categoria.getCuentaCompartida().getId().equals(compartida.getId());
        if (!predefinida && !propia) {
            throw new AccessDeniedException("No tenés permiso para usar esta categoría");
        }
        return categoria;
    }

    private void validarDatos(PresupuestoRequest request) {
        if (request.getMontoTope() == null || request.getMontoTope().compareTo(BigDecimal.ZERO) <= 0) {
            throw new BadRequestException("El monto tope debe ser mayor a cero");
        }
        if (request.getMes() == null || request.getMes() < 1 || request.getMes() > 12) {
            throw new BadRequestException("El mes debe ser un valor válido entre 1 y 12");
        }
        if (request.getAnio() == null || request.getAnio() < 2000) {
            throw new BadRequestException("El año ingresado es inválido");
        }
    }

    // Cuánto gastó cada integrante en la categoría, de mayor a menor (t-13.2.1): los actuales aunque
    // sea $0; los que se dieron de baja (perfil inactivo), solo si gastaron.
    private List<GastoDePerfilDTO> porPerfil(List<Perfil> integrantes, Map<Long, BigDecimal> gastos, BigDecimal tope) {
        return integrantes.stream()
                .filter(integrante -> integrante.isEsActivo() || gastos.containsKey(integrante.getId()))
                .map(integrante -> {
                    BigDecimal gastado = gastos.getOrDefault(integrante.getId(), BigDecimal.ZERO);
                    BigDecimal porcentaje = tope.signum() > 0
                            ? gastado.multiply(BigDecimal.valueOf(100)).divide(tope, 1, RoundingMode.HALF_UP)
                            : BigDecimal.ZERO;
                    return new GastoDePerfilDTO(integrante.getId(), integrante.getNombrePerfil(), gastado, porcentaje);
                })
                .sorted(Comparator.comparing(GastoDePerfilDTO::gastado).reversed().thenComparing(GastoDePerfilDTO::perfilId))
                .toList();
    }

    private String calcularEstado(BigDecimal porcentaje) {
        if (porcentaje.compareTo(BigDecimal.valueOf(100)) >= 0) {
            return "EXCEDIDO";
        }
        if (porcentaje.compareTo(BigDecimal.valueOf(80)) >= 0) {
            return "ALERTA";
        }
        return "OK";
    }

    @Override
    @Transactional(readOnly = true)
    public PresupuestoMesDTO obtenerPresupuestosDelMes(Long perfilId, Long cuentaIdAutenticada, int mes, int anio) {
        Perfil perfil = obtenerPerfilValidado(perfilId, cuentaIdAutenticada);
        // En una cuenta compartida, los de la cuenta compartida: los ve cualquier integrante
        CuentaCompartida compartida = perfil.getCuentaCompartida();
        List<Presupuesto> presupuestos = compartida == null
                ? presupuestoRepository.buscarActivosDelMes(perfilId, mes, anio)
                : presupuestoRepository.buscarActivosDelMesDeCuentaCompartida(compartida.getId(), mes, anio);

        YearMonth yearMonth = YearMonth.of(anio, mes);
        LocalDate desde = yearMonth.atDay(1);
        LocalDate hasta = yearMonth.atEndOfMonth();

        List<GastoPorCategoriaDTO> gastos = gastosDelPeriodo(perfil, desde, hasta);
        
        Map<Long, BigDecimal> gastosPorCatMap = gastos.stream()
                .collect(Collectors.toMap(GastoPorCategoriaDTO::getId, GastoPorCategoriaDTO::getTotal));

        // En una cuenta compartida, lo que gastó cada integrante en cada categoría (t-13.2.1)
        Map<Long, Map<Long, BigDecimal>> gastosPorCategoriaYPerfil = compartida == null ? Map.of()
                : movimientoRepository.sumarGastosPorCategoriaYPerfilDeCuentaCompartida(compartida.getId(), desde, hasta)
                        .stream()
                        .collect(Collectors.groupingBy(fila -> (Long) fila[0],
                                Collectors.toMap(fila -> (Long) fila[1], fila -> (BigDecimal) fila[2])));
        List<Perfil> integrantes = compartida == null ? List.of() : perfilRepository.findByCuentaCompartidaId(compartida.getId());

        List<PresupuestoCategoriaDTO> categoriasDTO = new ArrayList<>();
        BigDecimal totalPresupuestado = BigDecimal.ZERO;
        BigDecimal totalGastado = BigDecimal.ZERO;

        for (Presupuesto p : presupuestos) {
            BigDecimal tope = p.getMontoTope() != null ? p.getMontoTope() : BigDecimal.ZERO;
            totalPresupuestado = totalPresupuestado.add(tope);

            Long categoriaId = p.getCategoria().getId();
            BigDecimal gastado = gastosPorCatMap.getOrDefault(categoriaId, BigDecimal.ZERO);
            totalGastado = totalGastado.add(gastado);

            BigDecimal porcentaje = BigDecimal.ZERO;
            if (tope.compareTo(BigDecimal.ZERO) > 0) {
                porcentaje = gastado.multiply(BigDecimal.valueOf(100))
                        .divide(tope, 1, RoundingMode.HALF_UP);
            }

            String estado = calcularEstado(porcentaje);

            PresupuestoCategoriaDTO dto = new PresupuestoCategoriaDTO(
                    p.getId(),
                    categoriaId,
                    p.getCategoria().getNombre(),
                    p.getCategoria().getColor(),
                    tope,
                    gastado,
                    porcentaje,
                    estado
            );
            if (compartida != null) {
                dto.setPorPerfil(porPerfil(integrantes, gastosPorCategoriaYPerfil.getOrDefault(categoriaId, Map.of()), tope));
            }
            categoriasDTO.add(dto);
        }

        BigDecimal porcentajeTotal = BigDecimal.ZERO;
        if (totalPresupuestado.compareTo(BigDecimal.ZERO) > 0) {
            porcentajeTotal = totalGastado.multiply(BigDecimal.valueOf(100))
                    .divide(totalPresupuestado, 1, RoundingMode.HALF_UP);
        }

        return new PresupuestoMesDTO(mes, anio, totalPresupuestado, totalGastado, porcentajeTotal, categoriasDTO);
    }

    @Override
    @Transactional
    public PresupuestoCategoriaDTO crearPresupuesto(Long perfilId, Long cuentaIdAutenticada, PresupuestoRequest request) {
        validarDatos(request);
        if (request.getCategoriaId() == null) {
            throw new BadRequestException("La categoría es obligatoria");
        }

        Perfil perfil = obtenerPerfilValidado(perfilId, cuentaIdAutenticada);
        // En una cuenta compartida el presupuesto es de la cuenta compartida y lo crea solo el administrador
        CuentaCompartida compartida = perfil.getCuentaCompartida();
        if (compartida != null) {
            perfilService.exigirAdmin(cuentaIdAutenticada, compartida.getId());
        }
        Categoria categoria = obtenerCategoriaValidada(request.getCategoriaId(), cuentaIdAutenticada, compartida);

        // Regla de unicidad: una sola categoría por mes y año activa
        boolean repetido = compartida == null
                ? presupuestoRepository.existsByPerfilIdAndCategoriaIdAndMesAndAnioAndActivoTrue(
                        perfilId, categoria.getId(), request.getMes(), request.getAnio())
                : presupuestoRepository.existsByCuentaCompartidaIdAndCategoriaIdAndMesAndAnioAndActivoTrue(
                        compartida.getId(), categoria.getId(), request.getMes(), request.getAnio());
        if (repetido) {
            throw new BadRequestException("Ya existe un presupuesto activo para esta categoría en el período indicado");
        }

        Presupuesto presupuesto = new Presupuesto();
        presupuesto.setPerfil(compartida == null ? perfil : null);
        presupuesto.setCuentaCompartida(compartida);
        presupuesto.setCategoria(categoria);
        presupuesto.setMontoTope(request.getMontoTope());
        presupuesto.setMes(request.getMes());
        presupuesto.setAnio(request.getAnio());
        presupuesto.setActivo(true);

        Presupuesto guardado = presupuestoRepository.save(presupuesto);

        // Consultamos gastos actuales para responder con el DTO completo
        YearMonth ym = YearMonth.of(request.getAnio(), request.getMes());
        List<GastoPorCategoriaDTO> gastos = gastosDelPeriodo(perfil, ym.atDay(1), ym.atEndOfMonth());
        
        BigDecimal gastado = gastos.stream()
                .filter(g -> g.getId().equals(categoria.getId()))
                .map(GastoPorCategoriaDTO::getTotal)
                .findFirst().orElse(BigDecimal.ZERO);

        BigDecimal porcentaje = guardado.getMontoTope().compareTo(BigDecimal.ZERO) > 0
                ? gastado.multiply(BigDecimal.valueOf(100)).divide(guardado.getMontoTope(), 1, RoundingMode.HALF_UP)
                : BigDecimal.ZERO;

        String estado = calcularEstado(porcentaje);

        return new PresupuestoCategoriaDTO(
                guardado.getId(),
                categoria.getId(),
                categoria.getNombre(),
                categoria.getColor(),
                guardado.getMontoTope(),
                gastado,
                porcentaje,
                estado
        );
    }

    @Override
    @Transactional
    public PresupuestoCategoriaDTO editarPresupuesto(Long id, Long perfilId, Long cuentaIdAutenticada, PresupuestoRequest request) {
        validarDatos(request);

        Perfil perfil = obtenerPerfilValidado(perfilId, cuentaIdAutenticada);
        CuentaCompartida compartida = perfil.getCuentaCompartida();
        Presupuesto presupuesto = obtenerPresupuestoDelPerfil(id, perfil, cuentaIdAutenticada);

        Long categoriaIdFinal = request.getCategoriaId() != null ? request.getCategoriaId() : presupuesto.getCategoria().getId();
        Categoria categoria = obtenerCategoriaValidada(categoriaIdFinal, cuentaIdAutenticada, compartida);

        // Validar unicidad excluyendo el propio ID
        boolean repetido = compartida == null
                ? presupuestoRepository.existsByPerfilIdAndCategoriaIdAndMesAndAnioAndActivoTrueAndIdNot(
                        perfilId, categoria.getId(), request.getMes(), request.getAnio(), id)
                : presupuestoRepository.existsByCuentaCompartidaIdAndCategoriaIdAndMesAndAnioAndActivoTrueAndIdNot(
                        compartida.getId(), categoria.getId(), request.getMes(), request.getAnio(), id);
        if (repetido) {
            throw new BadRequestException("Ya existe otro presupuesto activo para esta categoría en el período indicado");
        }

        presupuesto.setCategoria(categoria);
        presupuesto.setMontoTope(request.getMontoTope());
        presupuesto.setMes(request.getMes());
        presupuesto.setAnio(request.getAnio());

        Presupuesto actualizado = presupuestoRepository.save(presupuesto);

        YearMonth ym = YearMonth.of(request.getAnio(), request.getMes());
        List<GastoPorCategoriaDTO> gastos = gastosDelPeriodo(perfil, ym.atDay(1), ym.atEndOfMonth());

        BigDecimal gastado = gastos.stream()
                .filter(g -> g.getId().equals(categoria.getId()))
                .map(GastoPorCategoriaDTO::getTotal)
                .findFirst().orElse(BigDecimal.ZERO);

        BigDecimal porcentaje = actualizado.getMontoTope().compareTo(BigDecimal.ZERO) > 0
                ? gastado.multiply(BigDecimal.valueOf(100)).divide(actualizado.getMontoTope(), 1, RoundingMode.HALF_UP)
                : BigDecimal.ZERO;

        String estado = calcularEstado(porcentaje);

        return new PresupuestoCategoriaDTO(
                actualizado.getId(),
                categoria.getId(),
                categoria.getNombre(),
                categoria.getColor(),
                actualizado.getMontoTope(),
                gastado,
                porcentaje,
                estado
        );
    }

    @Override
    @Transactional
    public void desactivarPresupuesto(Long id, Long perfilId, Long cuentaIdAutenticada) {
        Perfil perfil = obtenerPerfilValidado(perfilId, cuentaIdAutenticada);
        Presupuesto presupuesto = obtenerPresupuestoDelPerfil(id, perfil, cuentaIdAutenticada);

        presupuesto.setActivo(false);
        presupuestoRepository.save(presupuesto);
    }
}