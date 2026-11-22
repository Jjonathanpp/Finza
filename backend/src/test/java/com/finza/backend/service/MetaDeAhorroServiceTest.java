package com.finza.backend.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import com.finza.backend.exception.BadRequestException;
import com.finza.backend.model.AporteMetaAhorro;
import com.finza.backend.model.Categoria;
import com.finza.backend.model.CuentaCompartida;
import com.finza.backend.model.MetaDeAhorro;
import com.finza.backend.model.Movimiento;
import com.finza.backend.model.Perfil;
import com.finza.backend.repository.AporteMetaAhorroRepository;
import com.finza.backend.repository.CategoriaRepository;
import com.finza.backend.repository.MetaDeAhorroRepository;
import com.finza.backend.repository.MovimientoRepository;

class MetaDeAhorroServiceTest {

    private final MetaDeAhorroRepository metaRepository = mock(MetaDeAhorroRepository.class);
    private final AporteMetaAhorroRepository aporteRepository = mock(AporteMetaAhorroRepository.class);
    private final CategoriaRepository categoriaRepository = mock(CategoriaRepository.class);
    private final MovimientoRepository movimientoRepository = mock(MovimientoRepository.class);
    private final PerfilService perfilService = mock(PerfilService.class);
    private final MetaDeAhorroService service = new MetaDeAhorroService(
            metaRepository, aporteRepository, categoriaRepository, movimientoRepository, perfilService);

    private final Perfil perfil = new Perfil();
    private final MetaDeAhorro meta = new MetaDeAhorro();
    private final Categoria categoria = new Categoria();

    @BeforeEach
    void prepararMetaPersonal() {
        perfil.setId(7L);
        meta.setId(11L);
        meta.setPerfil(perfil);
        meta.setMontoObjetivo(new BigDecimal("500.00"));
        meta.setMontoActual(new BigDecimal("100.00"));

        when(perfilService.perfilActivo(3L)).thenReturn(perfil);
        when(metaRepository.findByIdForUpdate(11L)).thenReturn(Optional.of(meta));
        when(metaRepository.save(any(MetaDeAhorro.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(categoriaRepository
                .findFirstByCuentaIsNullAndCuentaCompartidaIsNullAndNombreIgnoreCaseAndTipoCategoriaPredefinida(
                        "Meta Ahorro", Categoria.TipoCategoria.AMBOS))
                .thenReturn(Optional.of(categoria));
    }

    @Test
    void abonarCreaUnGastoConCategoriaMetaAhorro() {
        service.abonarDinero(3L, 11L, new BigDecimal("25.00"));

        ArgumentCaptor<Movimiento> movimiento = ArgumentCaptor.forClass(Movimiento.class);
        verify(movimientoRepository).save(movimiento.capture());
        assertEquals(false, movimiento.getValue().isEsIngreso());
        assertEquals(categoria, movimiento.getValue().getCategoria());
        assertEquals(new BigDecimal("25.00"), movimiento.getValue().getMonto());
        assertEquals(new BigDecimal("125.00"), meta.getMontoActual());
    }

    @Test
    void miembroDeCuentaCompartidaPuedeRetirarSaldoDisponibleComoIngreso() {
        CuentaCompartida compartida = new CuentaCompartida();
        compartida.setId(19L);
        perfil.setCuentaCompartida(compartida);
        meta.setCuentaCompartida(compartida);
        when(perfilService.exigirMiembro(3L, 19L)).thenReturn(perfil);
        AporteMetaAhorro aporte = crearAporte("100.00", perfil);
        when(aporteRepository.findByMetaIdOrderByIdAsc(11L)).thenReturn(List.of(aporte));

        service.retirarDinero(3L, 11L, new BigDecimal("100.00"));

        ArgumentCaptor<Movimiento> movimiento = ArgumentCaptor.forClass(Movimiento.class);
        verify(movimientoRepository).save(movimiento.capture());
        assertEquals(true, movimiento.getValue().isEsIngreso());
        assertEquals(perfil, movimiento.getValue().getPerfil());
        assertEquals(categoria, movimiento.getValue().getCategoria());
        assertEquals(new BigDecimal("0.00"), meta.getMontoActual());
        verify(aporteRepository).delete(aporte);
    }

    @Test
    void retirarReduceElAporteGuardadoDelIntegrante() {
        AporteMetaAhorro aporte = crearAporte("100.00", perfil);
        when(aporteRepository.findByMetaIdOrderByIdAsc(11L)).thenReturn(List.of(aporte));

        service.retirarDinero(3L, 11L, new BigDecimal("40.00"));

        assertEquals(new BigDecimal("60.00"), aporte.getMonto());
        assertEquals(new BigDecimal("60.00"), meta.getMontoActual());
    }

    @Test
    void noPermiteRetirarMasQueElSaldoDisponible() {
        assertThrows(
                BadRequestException.class,
                () -> service.retirarDinero(3L, 11L, new BigDecimal("100.01")));
    }

    private AporteMetaAhorro crearAporte(String monto, Perfil perfil) {
        AporteMetaAhorro aporte = new AporteMetaAhorro();
        aporte.setMeta(meta);
        aporte.setPerfil(perfil);
        aporte.setMonto(new BigDecimal(monto));
        return aporte;
    }
}
