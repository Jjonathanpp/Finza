package com.finza.backend.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.finza.backend.model.Presupuesto;

@Repository
public interface PresupuestoRepository extends JpaRepository<Presupuesto, Long> {

    @Query("SELECT p FROM Presupuesto p JOIN FETCH p.categoria " +
           "WHERE p.perfil.id = :perfilId AND p.mes = :mes AND p.anio = :anio AND p.activo = true")
    List<Presupuesto> buscarActivosDelMes(
            @Param("perfilId") Long perfilId,
            @Param("mes") int mes,
            @Param("anio") int anio);

       // Regla de unicidad: verifica si ya existe uno activo para la misma categoría, mes y año
    boolean existsByPerfilIdAndCategoriaIdAndMesAndAnioAndActivoTrue(
            Long perfilId, Long categoriaId, int mes, int anio);

    // Para evitar falsos positivos al editar el mismo presupuesto
    boolean existsByPerfilIdAndCategoriaIdAndMesAndAnioAndActivoTrueAndIdNot(
            Long perfilId, Long categoriaId, int mes, int anio, Long id);

    // Lo mismo para los presupuestos de una cuenta compartida (t-13.1.2)
    @Query("SELECT p FROM Presupuesto p JOIN FETCH p.categoria " +
           "WHERE p.cuentaCompartida.id = :cuentaCompartidaId AND p.mes = :mes AND p.anio = :anio AND p.activo = true")
    List<Presupuesto> buscarActivosDelMesDeCuentaCompartida(
            @Param("cuentaCompartidaId") Long cuentaCompartidaId,
            @Param("mes") int mes,
            @Param("anio") int anio);

    boolean existsByCuentaCompartidaIdAndCategoriaIdAndMesAndAnioAndActivoTrue(
            Long cuentaCompartidaId, Long categoriaId, int mes, int anio);

    boolean existsByCuentaCompartidaIdAndCategoriaIdAndMesAndAnioAndActivoTrueAndIdNot(
            Long cuentaCompartidaId, Long categoriaId, int mes, int anio, Long id);
}