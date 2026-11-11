package com.finza.backend.service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.Base64;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import lombok.RequiredArgsConstructor;

import com.finza.backend.dto.Invitaciones_a_Cuenta.InvitacionDetalleResponse;
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

        return new InvitacionResponse(inv.getId(), email, inv.getEstado(), inv.getFechaExpiracion(), token);
    }

    // La ruta vieja (POST /api/cuentas-compartidas/{id}/invitaciones/aceptar): se deja igual
    // para no romper a quien la use (y al test de Cucumber de permisos).
    @Transactional
    public InvitacionResponse aceptarInvitacion(String token, Long cuentaId) {
        Aceptada aceptada = aceptar(token, cuentaId);
        InvitacionCuenta inv = aceptada.invitacion();
        return new InvitacionResponse(inv.getId(), inv.getEmailInvitado(), inv.getEstado(), inv.getFechaExpiracion(), token);
    }

    // ---------------- Desde el enlace de la invitación (t-11.2.2) ----------------
    // La app solo tiene el token (finza://invitacion?token=...): por eso estas no piden el id
    // de la cuenta compartida.

    // Lo que muestra la pantalla antes de aceptar o rechazar. No cambia nada.
    @Transactional(readOnly = true)
    public InvitacionDetalleResponse detalle(String token, Long cuentaId) {
        InvitacionCuenta inv = invitacionRepository.findByTokenHash(hash(token))
                .orElseThrow(() -> new BadRequestException("La invitación no existe o el enlace está incompleto"));
        Cuenta cuenta = cuentaRepository.findById(cuentaId)
                .orElseThrow(() -> new BadRequestException("Cuenta no encontrada"));

        boolean esParaVos = cuenta.getEmail().equalsIgnoreCase(inv.getEmailInvitado());
        boolean yaSosMiembro = perfilRepository
                .findByCuentaIdAndCuentaCompartidaId(cuentaId, inv.getCuentaCompartida().getId())
                .isPresent();

        return new InvitacionDetalleResponse(
                inv.getCuentaCompartida().getNombre(),
                inv.getInvitadoPor().getNombrePerfil(),
                // Si el enlace le llegó a otra persona, no se le muestra el email completo.
                esParaVos ? inv.getEmailInvitado() : enmascarar(inv.getEmailInvitado()),
                estadoVisible(inv, LocalDateTime.now()),
                inv.getFechaExpiracion(),
                esParaVos,
                yaSosMiembro);
    }

    // Acepta y devuelve la cuenta compartida con el mismo formato que GET /api/cuentas-compartidas
    // ({id, nombre, rol, perfilId}): la app la guarda como cuenta activa y entra directo a ella.
    @Transactional
    public Map<String, Object> aceptarPorToken(String token, Long cuentaId) {
        Perfil perfil = aceptar(token, cuentaId).perfil();
        CuentaCompartida compartida = perfil.getCuentaCompartida();
        return Map.of(
                "id", compartida.getId(),
                "nombre", compartida.getNombre(),
                "rol", perfil.getRol().name(),
                "perfilId", perfil.getId());
    }

    // Con las mismas condiciones que aceptar: pendiente, sin vencer y para el email de quien la rechaza.
    @Transactional
    public void rechazar(String token, Long cuentaId) {
        InvitacionCuenta inv = invitacionValida(token);
        exigirQueSeaParaVos(inv, cuentaId);
        inv.setEstado(EstadoInvitacion.RECHAZADA);
    }

    // ---------------- Compartido entre aceptar y rechazar ----------------

    private record Aceptada(InvitacionCuenta invitacion, Perfil perfil) {}

    private Aceptada aceptar(String token, Long cuentaId) {
        InvitacionCuenta inv = invitacionValida(token);
        Cuenta cuenta = exigirQueSeaParaVos(inv, cuentaId);

        boolean yaEsMiembro = perfilRepository.findByCuentaIdAndCuentaCompartidaId(
                cuenta.getId(), inv.getCuentaCompartida().getId()).isPresent();
        if (yaEsMiembro) {
            throw new BadRequestException("Ya sos miembro de esta cuenta compartida");
        }

        inv.setEstado(EstadoInvitacion.ACEPTADA);
        invitacionRepository.save(inv);

        Perfil perfil = new Perfil();
        perfil.setCuenta(cuenta);
        perfil.setCuentaCompartida(inv.getCuentaCompartida());
        perfil.setRol(Perfil.Rol.MIEMBRO);
        perfil.setNombrePerfil(cuenta.getEmail());
        perfil.setEsPrincipal(false);
        perfil.setEsActivo(true);
        perfilRepository.save(perfil);

        return new Aceptada(inv, perfil);
    }

    // La invitación del token, bloqueada para que dos pedidos a la vez no la usen dos veces;
    // tiene que estar pendiente y sin vencer.
    private InvitacionCuenta invitacionValida(String token) {
        InvitacionCuenta inv = invitacionRepository.findByTokenHashForUpdate(hash(token))
                .orElseThrow(() -> new BadRequestException("Token de invitación inválido"));

        if (inv.getEstado() != EstadoInvitacion.PENDIENTE) {
            throw new BadRequestException("La invitación ya no está pendiente");
        }
        if (inv.getFechaExpiracion().isBefore(LocalDateTime.now())) {
            throw new BadRequestException("La invitación expiró");
        }
        return inv;
    }

    private Cuenta exigirQueSeaParaVos(InvitacionCuenta inv, Long cuentaId) {
        Cuenta cuenta = cuentaRepository.findById(cuentaId)
                .orElseThrow(() -> new BadRequestException("Cuenta no encontrada"));
        if (!cuenta.getEmail().equalsIgnoreCase(inv.getEmailInvitado())) {
            throw new BadRequestException("El email de tu cuenta no coincide con el invitado");
        }
        return cuenta;
    }

    // juan.perez@gmail.com → ju***@gmail.com
    private static String enmascarar(String email) {
        int arroba = email.indexOf('@');
        if (arroba <= 0) return "***";
        String usuario = email.substring(0, arroba);
        return usuario.substring(0, Math.min(2, usuario.length())) + "***" + email.substring(arroba);
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

    @Transactional(readOnly = true)
    public List<InvitacionResponse> listar(Long cuentaCompartidaId, Long cuentaId) {
        Perfil perfil = perfilRepository
                .findByCuentaIdAndCuentaCompartidaId(cuentaId, cuentaCompartidaId)
                .orElseThrow(() -> new AccessDeniedException("No pertenecés a esta cuenta compartida"));

        if (perfil.getRol() != Perfil.Rol.ADMIN) {
            throw new AccessDeniedException("Solo un administrador puede ver las invitaciones");
        }

        LocalDateTime ahora = LocalDateTime.now();
        return invitacionRepository
                .findByCuentaCompartidaIdOrderByFechaCreacionDesc(cuentaCompartidaId)
                .stream()
                .map(i -> new InvitacionResponse(
                        i.getId(),
                        i.getEmailInvitado(),
                        estadoVisible(i, ahora),
                        i.getFechaExpiracion(),
                        null)) // el token no se puede mostrar: solo se guarda su hash
                .toList();
    }

    private EstadoInvitacion estadoVisible(InvitacionCuenta inv, LocalDateTime ahora) {
        boolean vencida = inv.getEstado() == EstadoInvitacion.PENDIENTE
                && inv.getFechaExpiracion().isBefore(ahora);
        return vencida ? EstadoInvitacion.EXPIRADA : inv.getEstado();
    }
}