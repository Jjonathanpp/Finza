package com.finza.backend.repository;

import java.time.LocalDateTime;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.finza.backend.model.EstadoInvitacion;
import com.finza.backend.model.InvitacionCuenta;

public interface InvitacionCuentaRepository extends JpaRepository<InvitacionCuenta, Long> {

    Optional<InvitacionCuenta> findByTokenHash(String tokenHash);

    boolean existsByCuentaCompartidaIdAndEmailInvitadoIgnoreCaseAndEstadoAndFechaExpiracionAfter(
            Long cuentaCompartidaId, String email, EstadoInvitacion estado, LocalDateTime ahora);
}
