package com.finza.backend.service;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.finza.backend.model.CuentaMP;
import com.finza.backend.model.Perfil;
import com.finza.backend.model.WebhookMP;
import com.finza.backend.repository.CuentaMPRepository;
import com.finza.backend.repository.PerfilRepository;
import com.finza.backend.repository.WebhookMPRepository;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Service
@RequiredArgsConstructor
public class MercadoPagoWebhookService {

    private final WebhookMPRepository webhookRepository;
    private final CuentaMPRepository cuentaMPRepository;
    private final PerfilRepository perfilRepository;
    private final MercadoPagoSyncService syncService;

    @Scheduled(fixedDelay = 60000)
    @Transactional
    public void procesarWebhooksPendientes() {
        List<WebhookMP> pendientes = webhookRepository.findByProcesadoFalse();

        if (pendientes.isEmpty()) {
            return;
        }

        log.info("Procesando {} webhooks pendientes de Mercado Pago", pendientes.size());

        List<CuentaMP> cuentas = cuentaMPRepository.findAll();
        for (CuentaMP cuenta : cuentas) {
            if (cuenta.getUsuario() == null) {
                continue;
            }

            Perfil perfilPrincipal = perfilRepository.findPrincipalByUsuarioId(cuenta.getUsuario().getId())
                    .orElse(null);
            if (perfilPrincipal == null) {
                continue;
            }

            try {
                syncService.sincronizarMovimientos(cuenta.getUsuario().getId(), perfilPrincipal.getId());
            } catch (Exception e) {
                log.error("Error sincronizando usuario {}: {}", cuenta.getUsuario().getId(), e.getMessage());
            }
        }

        for (WebhookMP webhook : pendientes) {
            webhook.setProcesado(true);
            webhookRepository.save(webhook);
        }

        log.info("Webhooks procesados correctamente");
    }
}