package com.finza.backend.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.finza.backend.model.AporteMetaAhorro;

public interface AporteMetaAhorroRepository extends JpaRepository<AporteMetaAhorro, Long> {

    List<AporteMetaAhorro> findByMetaId(Long metaId);
}
