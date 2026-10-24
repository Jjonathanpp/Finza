package com.finza.backend.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.finza.backend.model.CuentaMP;

import java.util.Optional;

@Repository
public interface CuentaMPRepository extends JpaRepository<CuentaMP, Long> {

    Optional<CuentaMP> findByUsuarioId(Long usuarioId);

    @Modifying
    @Query("DELETE FROM CuentaMP c WHERE c.usuario.id = :usuarioId")
    void deleteByUsuarioId(@Param("usuarioId") Long usuarioId);
}