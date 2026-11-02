package com.finza.backend.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
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

    // Cuando alguien se da de baja, sus perfiles de cuentas compartidas quedan en ellas (con lo que
    // cargó), pero ya sin nadie que los use.
    @Modifying
    @Query("UPDATE Perfil p SET p.cuenta = null, p.esActivo = false "
            + "WHERE p.cuenta.id = :cuentaId AND p.cuentaCompartida IS NOT NULL")
    void desvincularPerfilesCompartidos(@Param("cuentaId") Long cuentaId);
}