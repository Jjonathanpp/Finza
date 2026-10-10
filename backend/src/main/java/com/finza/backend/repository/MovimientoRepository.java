package com.finza.backend.repository;

import java.time.LocalDate;
import java.util.Optional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.math.BigDecimal;
import java.time.LocalDate;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

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
}