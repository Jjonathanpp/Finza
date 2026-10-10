package com.finza.backend.service;

import java.util.NoSuchElementException;

import org.springframework.stereotype.Service;

import com.finza.backend.repository.PerfilRepository;

@Service
public class PerfilService {

    private final PerfilRepository perfilRepository;

    public PerfilService(PerfilRepository perfilRepository) {
        this.perfilRepository = perfilRepository;
    }

    // El perfil con el que trabaja la cuenta del token. En la Fase 1 cada cuenta tiene uno solo,
    // el principal, que se crea al registrarse.
    public Long idPrincipal(Long cuentaId) {
        return perfilRepository.findByCuentaIdAndEsPrincipalTrue(cuentaId)
                .orElseThrow(() -> new NoSuchElementException("La cuenta no tiene un perfil principal"))
                .getId();
    }
}
