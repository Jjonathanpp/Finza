package com.finza.backend.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.finza.backend.model.Perfil;

public interface PerfilRepository extends JpaRepository<Perfil, Long> {
    @Query("SELECT p FROM Perfil p WHERE p.cuenta.usuario.id = :usuarioId AND p.esPrincipal = true")
    Optional<Perfil> findPrincipalByUsuarioId(@Param("usuarioId") Long usuarioId);

    Optional<Perfil> findByCuentaIdAndEsPrincipalTrue(Long cuentaId);

    Optional<Perfil> findByCuentaIdAndCuentaCompartidaId(Long cuentaId, Long cuentaCompartidaId);

    Optional<Perfil> findByIdAndCuentaId(Long id, Long cuentaId);

    List<Perfil> findByCuentaIdAndCuentaCompartidaIsNotNull(Long cuentaId);

    List<Perfil> findByCuentaCompartidaId(Long cuentaCompartidaId);

    // Los integrantes que siguen en la cuenta compartida, el que entró primero adelante (t-11.3.4).
    List<Perfil> findByCuentaCompartidaIdAndEsActivoTrueOrderByIdAsc(Long cuentaCompartidaId);
}