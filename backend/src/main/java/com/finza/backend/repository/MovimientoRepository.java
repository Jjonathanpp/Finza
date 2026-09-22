package com.finza.backend.repository;

import com.finza.backend.model.Movimiento;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;

@Repository
public interface MovimientoRepository extends JpaRepository<Movimiento, Long> {

       boolean existsByCategoriaId(Long categoriaId);

       @Query("SELECT m FROM Movimiento m WHERE m.perfil.id = :perfilId " +
           "AND (:fechaInicio IS NULL OR m.fecha >= :fechaInicio) " +
           "AND (:fechaFin IS NULL OR m.fecha <= :fechaFin) " +
           "AND (:categoriaId IS NULL OR m.categoria.id = :categoriaId) " +
           "AND (:esIngreso IS NULL OR m.esIngreso = :esIngreso) " +
           "AND (:estado IS NULL OR m.estado = :estado)")
    Page<Movimiento> buscarConFiltros(
            @Param("perfilId") Long perfilId,
            @Param("fechaInicio") LocalDate fechaInicio,
            @Param("fechaFin") LocalDate fechaFin,
            @Param("categoriaId") Long categoriaId,
            @Param("esIngreso") Boolean esIngreso,
            @Param("estado") Movimiento.EstadoMovimiento estado, // <-- NUEVO
            Pageable pageable);
}