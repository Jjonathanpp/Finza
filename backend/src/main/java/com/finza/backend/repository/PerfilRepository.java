package com.finza.backend.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.finza.backend.model.Perfil;

public interface PerfilRepository extends JpaRepository<Perfil, Long> {
    @Query("SELECT p FROM Perfil p WHERE p.cuenta.usuario.id = :usuarioId AND p.esPrincipal = true")
    Optional<Perfil> findPrincipalByUsuarioId(@Param("usuarioId") Long usuarioId);
}