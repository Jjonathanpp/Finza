package com.finza.backend.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import jakarta.persistence.LockModeType;
import com.finza.backend.model.MetaDeAhorro;

public interface MetaDeAhorroRepository extends JpaRepository<MetaDeAhorro, Long> {

    List<MetaDeAhorro> findByPerfilId(Long perfilId);
    List<MetaDeAhorro> findByCuentaCompartidaId(Long cuentaCompartidaId);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT m FROM MetaDeAhorro m WHERE m.id = :id")
    Optional<MetaDeAhorro> findByIdForUpdate(@Param("id") Long id);
}
