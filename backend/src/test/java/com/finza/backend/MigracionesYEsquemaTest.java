package com.finza.backend;

import static org.assertj.core.api.Assertions.assertThat;

import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import jakarta.persistence.EntityManager;

@SpringBootTest
@ActiveProfiles("test")
class MigracionesYEsquemaTest {

    @Autowired
    private Flyway flyway;

    @Autowired
    private EntityManager entityManager;

    @Test
    void migracionesCorrenSobrePostgresVacioYEntidadesCoincidenConElEsquema() {
        assertThat(flyway.info().applied()).isNotEmpty();
        assertThat(flyway.info().pending()).isEmpty();

        Long cantidadCategorias = ((Number) entityManager
                .createNativeQuery("SELECT COUNT(*) FROM categoria")
                .getSingleResult()).longValue();
        assertThat(cantidadCategorias).isGreaterThan(0L);
    }
}