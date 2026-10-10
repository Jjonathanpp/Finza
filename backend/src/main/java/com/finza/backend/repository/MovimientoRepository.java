package com.finza.backend.repository;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.finza.backend.dto.panel.GastoPorCategoriaDTO;
import com.finza.backend.model.Movimiento;

@Repository
public interface MovimientoRepository extends JpaRepository<Movimiento, Long> {

       boolean existsByCategoriaId(Long categoriaId);

      @Query("SELECT m FROM Movimiento m WHERE m.perfil.id = :perfilId " +
              "AND m.perfil.cuenta.id = :cuentaId " + 
              "AND (CAST(:fechaInicio AS date) IS NULL OR m.fecha >= :fechaInicio) " +
              "AND (CAST(:fechaFin AS date) IS NULL OR m.fecha <= :fechaFin) " +
              "AND (:categoriaId IS NULL OR m.categoria.id = :categoriaId) " +
              "AND (:esIngreso IS NULL OR m.esIngreso = :esIngreso) " +
              "AND (:estado IS NULL OR m.estado = :estado)")
       Page<Movimiento> buscarConFiltros(
              @Param("perfilId") Long perfilId,
              @Param("cuentaId") Long cuentaId, 
              @Param("fechaInicio") LocalDate fechaInicio,
              @Param("fechaFin") LocalDate fechaFin,
              @Param("categoriaId") Long categoriaId,
              @Param("esIngreso") Boolean esIngreso,
              @Param("estado") Movimiento.EstadoMovimiento estado,
              Pageable pageable);

       Optional<Movimiento> findByIdAndPerfilId(Long id, Long perfilId);

       boolean existsByExternalId(String externalId);

       Optional<Movimiento> findByExternalId(String externalId);

       // Los gastos aprobados del perfil entre dos fechas, sumados por categoría, de mayor a menor.
       // Los pendientes (de Mercado Pago) no suman hasta que el usuario los confirme.
       // Monto mayor a 0: la voz guarda primero un movimiento con monto 0, y con 0 el porcentaje dividiría por cero.
       @Query("SELECT new com.finza.backend.dto.panel.GastoPorCategoriaDTO(c.id, c.nombre, c.color, SUM(m.monto)) " +
              "FROM Movimiento m JOIN m.categoria c " +
              "WHERE m.perfil.id = :perfilId AND m.esIngreso = false AND m.estado = APROBADO AND m.monto > 0 " +
              "AND m.fecha BETWEEN :desde AND :hasta " +
              "GROUP BY c.id, c.nombre, c.color " +
              "ORDER BY SUM(m.monto) DESC")
       List<GastoPorCategoriaDTO> sumarGastosPorCategoria(
              @Param("perfilId") Long perfilId,
              @Param("desde") LocalDate desde,
              @Param("hasta") LocalDate hasta);

       @Query("SELECT COALESCE(SUM(m.monto), 0) FROM Movimiento m " +
           "WHERE m.perfil.id = :perfilId " +
           "AND m.perfil.cuenta.id = :cuentaId " +
           "AND m.esIngreso = :esIngreso " +
           "AND (cast(:inicio as date) IS NULL OR m.fecha >= :inicio) " +
           "AND (cast(:fin as date) IS NULL OR m.fecha <= :fin) " +
           "AND m.estado = 'APROBADO'")
       BigDecimal sumarMontoPorTipoYFechas(
            @Param("perfilId") Long perfilId,
            @Param("cuentaId") Long cuentaId,
            @Param("esIngreso") boolean esIngreso,
            @Param("inicio") LocalDate inicio,
            @Param("fin") LocalDate fin);

       @Query("SELECT m FROM Movimiento m " +
           "WHERE m.perfil.id = :perfilId AND m.perfil.cuenta.id = :cuentaId " +
           "ORDER BY m.fecha DESC, m.fechaCreacion DESC")
       List<Movimiento> buscarUltimosMovimientos(
            @Param("perfilId") Long perfilId, 
            @Param("cuentaId") Long cuentaId, 
            Pageable pageable);

       // 2. Últimos 5 Ingresos (esIngreso = true)
       @Query("SELECT m FROM Movimiento m " +
              "WHERE m.perfil.id = :perfilId AND m.perfil.cuenta.id = :cuentaId " +
              "AND m.esIngreso = true " +
              "ORDER BY m.fecha DESC, m.fechaCreacion DESC")
       List<Movimiento> buscarUltimosIngresos(
              @Param("perfilId") Long perfilId, 
              @Param("cuentaId") Long cuentaId, 
              Pageable pageable);

       // 3. Últimos 5 Egresos (esIngreso = false)
       @Query("SELECT m FROM Movimiento m " +
              "WHERE m.perfil.id = :perfilId AND m.perfil.cuenta.id = :cuentaId " +
              "AND m.esIngreso = false " +
              "ORDER BY m.fecha DESC, m.fechaCreacion DESC")
       List<Movimiento> buscarUltimosEgresos(
              @Param("perfilId") Long perfilId, 
              @Param("cuentaId") Long cuentaId, 
              Pageable pageable);
}