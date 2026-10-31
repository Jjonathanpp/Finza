package com.finza.backend.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.finza.backend.model.WebhookMP;

@Repository
public interface WebhookMPRepository extends JpaRepository<WebhookMP, Long> {

    Optional<WebhookMP> findByIdRecurso(String idRecurso);

    List<WebhookMP> findByProcesadoFalse();
}