package com.finza.backend.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.finza.backend.model.MetaDeAhorro;

public interface MetaDeAhorroRepository extends JpaRepository<MetaDeAhorro, Long> {

    List<MetaDeAhorro> findByPerfilId(Long perfilId);
    List<MetaDeAhorro> findByCuentaCompartidaId(Long cuentaCompartidaId);
}
