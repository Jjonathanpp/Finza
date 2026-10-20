package com.finza.backend.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.finza.backend.model.PreferenciasSistema;
import com.finza.backend.model.PreferenciasSistema.Moneda;
import com.finza.backend.repository.PerfilRepository;
import com.finza.backend.repository.PreferenciasSistemaRepository;

import lombok.RequiredArgsConstructor;

// Las preferencias del perfil. La fila se crea recién la primera vez que se cambia algo:
// hasta entonces valen los valores por defecto de PreferenciasSistema (como hace el panel).
@Service
@RequiredArgsConstructor
public class PreferenciasService {

    private final PreferenciasSistemaRepository preferenciasRepository;
    private final PerfilRepository perfilRepository;

    public Moneda moneda(Long perfilId) {
        return preferenciasRepository.findByPerfilId(perfilId)
                .map(PreferenciasSistema::getMoneda)
                .orElse(Moneda.PESO);
    }

    @Transactional
    public void cambiarMoneda(Long perfilId, Moneda moneda) {
        PreferenciasSistema preferencias = preferenciasRepository.findByPerfilId(perfilId).orElseGet(() -> {
            PreferenciasSistema nuevas = new PreferenciasSistema();
            nuevas.setPerfil(perfilRepository.getReferenceById(perfilId));
            return nuevas;
        });
        preferencias.setMoneda(moneda);
        preferenciasRepository.save(preferencias);
    }
}
