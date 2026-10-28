package com.finza.backend.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.finza.backend.model.CuentaCompartida;

public interface CuentaCompartidaRepository extends JpaRepository<CuentaCompartida, Long> {
}
