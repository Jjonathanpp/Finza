package com.finza.backend.service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.Base64;
import java.util.HexFormat;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import lombok.RequiredArgsConstructor;

import com.finza.backend.dto.Invitaciones_a_Cuenta.InvitacionRequest;
import com.finza.backend.dto.Invitaciones_a_Cuenta.InvitacionResponse;
import com.finza.backend.exception.BadRequestException;
import com.finza.backend.model.Cuenta;
import com.finza.backend.model.CuentaCompartida;
import com.finza.backend.model.EstadoInvitacion;
import com.finza.backend.model.InvitacionCuenta;
import com.finza.backend.model.Perfil;
import com.finza.backend.repository.CuentaCompartidaRepository;
import com.finza.backend.repository.CuentaRepository;
import com.finza.backend.repository.InvitacionCuentaRepository;
import com.finza.backend.repository.PerfilRepository;

@Service
@RequiredArgsConstructor
public class InvitacionService {

    private static final Duration VALIDEZ = Duration.ofHours(24);

    private final InvitacionCuentaRepository invitacionRepository;
    private final CuentaRepository cuentaRepository;
    private final PerfilRepository perfilRepository;
    private final CuentaCompartidaRepository cuentaCompartidaRepository;
    private final EmailService emailService; 

    @Value("${app.invitaciones.base-url}")
    private String baseUrl; 

@Transactional
public InvitacionResponse crear(Long cuentaCompartidaId, Long cuentaEmisorId, InvitacionRequest req) {
    CuentaCompartida compartida = cuentaCompartidaRepository.findById(cuentaCompartidaId)
            .orElseThrow(() -> new BadRequestException("La cuenta compartida no existe"));

    Cuenta cuentaEmisor = cuentaRepository.findById(cuentaEmisorId)
            .orElseThrow(() -> new BadRequestException("Cuenta no encontrada"));

    // 1) El emisor debe pertenecer a la cuenta compartida y ser ADMIN
    Perfil emisor = perfilRepository
            .findByCuentaIdAndCuentaCompartidaId(cuentaEmisor.getId(), cuentaCompartidaId)
            .orElseThrow(() -> new AccessDeniedException("No pertenecés a esta cuenta compartida"));

    if (emisor.getRol() != Perfil.Rol.ADMIN) {
        throw new AccessDeniedException("Solo un administrador puede invitar");
    }

    String email = req.email().trim();

    // 2) Validaciones
    if (email.equalsIgnoreCase(cuentaEmisor.getEmail())) {
        throw new BadRequestException("No podés invitarte a vos mismo");
    }

    boolean yaEsMiembro = cuentaRepository.findByEmailIgnoreCase(email)
            .flatMap(c -> perfilRepository.findByCuentaIdAndCuentaCompartidaId(c.getId(), cuentaCompartidaId))
            .isPresent();
    if (yaEsMiembro) {
        throw new BadRequestException("Esa persona ya es miembro de la cuenta compartida");
    }

    if (invitacionRepository
            .existsByCuentaCompartidaIdAndEmailInvitadoIgnoreCaseAndEstadoAndFechaExpiracionAfter(
                    cuentaCompartidaId, email, EstadoInvitacion.PENDIENTE, LocalDateTime.now())) {
        throw new BadRequestException("Ya existe una invitación pendiente para ese email");
    }

    // 3) Token (solo se guarda el hash)
    String token = generarToken();
    InvitacionCuenta inv = new InvitacionCuenta();
    inv.setCuentaCompartida(compartida);
    inv.setInvitadoPor(emisor);
    inv.setEmailInvitado(email);
    inv.setTokenHash(hash(token));
    inv.setFechaExpiracion(LocalDateTime.now().plus(VALIDEZ));
    invitacionRepository.save(inv);

    // 4) Correo
    String link = baseUrl + "?token=" + token;
    emailService.enviarInvitacion(email, emisor.getNombrePerfil(), link, inv.getFechaExpiracion());

    return new InvitacionResponse(inv.getId(), email, inv.getEstado(), inv.getFechaExpiracion());
}
    private String generarToken() {
        byte[] bytes = new byte[32];
        new SecureRandom().nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    static String hash(String token) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256")
                    .digest(token.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(digest);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }
}
