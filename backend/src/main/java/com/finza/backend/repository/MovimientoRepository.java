package com.finza.backend.repository;

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
       @Query("SELECT new com.finza.backend.dto.panel.GastoPorCategoriaDTO(c.id, c.nombre, c.color, SUM(m.monto)) " +
              "FROM Movimiento m JOIN m.categoria c " +
              "WHERE m.perfil.id = :perfilId AND m.esIngreso = false AND m.estado = APROBADO " +
              "AND m.fecha BETWEEN :desde AND :hasta " +
              "GROUP BY c.id, c.nombre, c.color " +
              "ORDER BY SUM(m.monto) DESC")
       List<GastoPorCategoriaDTO> sumarGastosPorCategoria(
              @Param("perfilId") Long perfilId,
              @Param("desde") LocalDate desde,
              @Param("hasta") LocalDate hasta);
}