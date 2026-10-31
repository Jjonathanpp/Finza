package com.finza.backend.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.finza.backend.model.Cuenta;

public interface CuentaRepository extends JpaRepository<Cuenta, Long> {
    Optional<Cuenta> findByEmail(String email);

    Optional<Cuenta> findByEmailIgnoreCase(String email);

    boolean existsByEmail(String email);
}
