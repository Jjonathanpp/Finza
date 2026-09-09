package com.finza.backend.repository;

import com.finza.backend.model.Cuenta;

import org.springframework.data.jpa.repository.JpaRepository;

public interface CuentaRepository extends JpaRepository<Cuenta, Long> {
}