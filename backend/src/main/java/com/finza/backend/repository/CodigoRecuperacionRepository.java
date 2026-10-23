package com.finza.backend.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.finza.backend.model.CodigoRecuperacion;
import com.finza.backend.model.Cuenta;

public interface CodigoRecuperacionRepository extends JpaRepository<CodigoRecuperacion, Long> {

    Optional<CodigoRecuperacion> findFirstByCuentaAndUsadoFalseOrderByExpiraEnDesc(Cuenta cuenta);

    void deleteByCuenta(Cuenta cuenta);
}
