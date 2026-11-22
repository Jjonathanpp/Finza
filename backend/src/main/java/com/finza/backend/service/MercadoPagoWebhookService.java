package com.finza.backend.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.finza.backend.model.CuentaMP;
import com.finza.backend.model.Perfil;
import com.finza.backend.repository.CuentaMPRepository;
import com.finza.backend.repository.PerfilRepository;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Service
@RequiredArgsConstructor
public class MercadoPagoWebhookService {

    private final CuentaMPRepository cuentaMPRepository;
    private final PerfilRepository perfilRepository;
    private final MercadoPagoSyncService syncService;

    @Transactional
    public void procesarAvisoMP(String mpUserId, String tipo, String idRecurso) {
        if (mpUserId == null || mpUserId.isBlank()) {
            log.warn("Webhook MP recibido sin user_id (idRecurso={}). No se puede asociar a un usuario específico.",
                    idRecurso);
            return;
        }

        CuentaMP cuenta = cuentaMPRepository.findByMpIdUser(mpUserId).orElse(null);
        if (cuenta == null || cuenta.getUsuario() == null) {
            log.warn("No se encontró cuenta vinculada para mpUserId={}", mpUserId);
            return;
        }

        Long usuarioId = cuenta.getUsuario().getId();
        Perfil perfilPrincipal = perfilRepository.findPrincipalByUsuarioId(usuarioId).orElse(null);
        if (perfilPrincipal == null) {
            log.warn("Usuario {} no tiene perfil principal para sincronizar movimientos de Mercado Pago.", usuarioId);
            return;
        }

        try {
            log.info("Sincronizando movimientos de Mercado Pago para usuario {} (mpUserId={}) tras aviso tipo={}",
                    usuarioId, mpUserId, tipo);
            syncService.sincronizarMovimientos(usuarioId, perfilPrincipal.getId());
        } catch (Exception e) {
            log.error("Error sincronizando movimientos tras webhook para usuario {}: {}", usuarioId, e.getMessage(), e);
        }
    }
}
