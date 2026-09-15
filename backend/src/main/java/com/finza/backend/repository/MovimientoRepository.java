package com.finza.backend.repository;

import java.time.LocalDate;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import com.finza.backend.model.Movimiento;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

@Repository
public interface MovimientoRepository extends JpaRepository<Movimiento, Long> {
    @Query("SELECT m FROM Movimiento m WHERE m.perfil.id = :perfilId " +
           "AND (CAST(:fechaInicio AS date) IS NULL OR m.fecha >= :fechaInicio) " +
           "AND (CAST(:fechaFin AS date) IS NULL OR m.fecha <= :fechaFin) " +
           "AND (:categoriaId IS NULL OR m.categoria.id = :categoriaId) " +
           "AND (:esIngreso IS NULL OR m.esIngreso = :esIngreso)")
    Page<Movimiento> buscarConFiltros(
            @Param("perfilId") Long perfilId,
            @Param("fechaInicio") LocalDate fechaInicio,
            @Param("fechaFin") LocalDate fechaFin,
            @Param("categoriaId") Long categoriaId,
            @Param("esIngreso") Boolean esIngreso,
            Pageable pageable);

    boolean existsByCategoriaId(Long categoriaId);
}