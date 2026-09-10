package com.finza.backend.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import com.finza.backend.model.Usuario;

public interface UsuarioRepository extends JpaRepository<Usuario, Long> {
    boolean existsByDni(Long dni);
}