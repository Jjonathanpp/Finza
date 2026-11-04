package com.finza.backend.repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.Lock;
import jakarta.persistence.LockModeType;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.finza.backend.model.EstadoInvitacion;
import com.finza.backend.model.InvitacionCuenta;

public interface InvitacionCuentaRepository extends JpaRepository<InvitacionCuenta, Long> {

    Optional<InvitacionCuenta> findByTokenHash(String tokenHash);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT i FROM InvitacionCuenta i WHERE i.tokenHash = :tokenHash")
    Optional<InvitacionCuenta> findByTokenHashForUpdate(@Param("tokenHash") String tokenHash);

    boolean existsByCuentaCompartidaIdAndEmailInvitadoIgnoreCaseAndEstadoAndFechaExpiracionAfter(
            Long cuentaCompartidaId, String email, EstadoInvitacion estado, LocalDateTime ahora);

    List<InvitacionCuenta> findByCuentaCompartidaIdOrderByFechaCreacionDesc(Long cuentaCompartidaId);

    // Al borrar una cuenta compartida que se quedó sin integrantes (t-11.3.4).
    void deleteByCuentaCompartidaId(Long cuentaCompartidaId);
}
