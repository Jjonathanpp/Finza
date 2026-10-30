package com.finza.backend.service;

import java.util.List;
import java.util.Map;
import java.util.NoSuchElementException;
import java.util.Optional;

import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import com.finza.backend.exception.BadRequestException;
import com.finza.backend.model.CuentaCompartida;
import com.finza.backend.model.Perfil;
import com.finza.backend.repository.CuentaCompartidaRepository;
import com.finza.backend.repository.PerfilRepository;

@Service
public class PerfilService {

    private final PerfilRepository perfilRepository;
    private final CuentaCompartidaRepository cuentaCompartidaRepository;

    public PerfilService(PerfilRepository perfilRepository, CuentaCompartidaRepository cuentaCompartidaRepository) {
        this.perfilRepository = perfilRepository;
        this.cuentaCompartidaRepository = cuentaCompartidaRepository;
    }

    // El perfil con el que trabaja el pedido. Se sigue llamando así para no tocar los controllers
    // que lo usan, pero devuelve el perfil activo (ver perfilActivo).
    public Long idPrincipal(Long cuentaId) {
        return perfilActivo(cuentaId).getId();
    }

    // El perfil que eligió la app en el selector de cuenta (header X-Perfil-Id, t-13.1.2): el personal
    // o el de una cuenta compartida. Tiene que ser de la cuenta del token (si no, 403). Sin el header,
    // el principal, como antes.
    public Perfil perfilActivo(Long cuentaId) {
        String elegido = RequestContextHolder.getRequestAttributes() instanceof ServletRequestAttributes pedido
                ? pedido.getRequest().getHeader("X-Perfil-Id")
                : null;
        if (elegido == null) {
            return perfilRepository.findByCuentaIdAndEsPrincipalTrue(cuentaId)
                    .orElseThrow(() -> new NoSuchElementException("La cuenta no tiene un perfil principal"));
        }
        try {
            return perfilRepository.findByIdAndCuentaId(Long.valueOf(elegido.trim()), cuentaId)
                    .orElseThrow(() -> new AccessDeniedException("Ese perfil no es de tu cuenta"));
        } catch (NumberFormatException e) {
            throw new BadRequestException("El perfil elegido no es válido");
        }
    }

    // Para el selector de cuenta: las cuentas compartidas en las que está la cuenta del token, con su
    // perfil ahí (el que la app manda en X-Perfil-Id) y su rol.
    public List<Map<String, Object>> misCuentasCompartidas(Long cuentaId) {
        return perfilRepository.findByCuentaIdAndCuentaCompartidaIsNotNull(cuentaId).stream()
                .map(perfil -> Map.<String, Object>of(
                        "id", perfil.getCuentaCompartida().getId(),
                        "nombre", perfil.getCuentaCompartida().getNombre(),
                        "rol", perfil.getRol(),
                        "perfilId", perfil.getId()))
                .toList();
    }

    // Crea la cuenta compartida y, en la cuenta de quien la crea, un perfil ADMIN para ella
    // (aparte de su perfil personal), con el mismo nombre que el personal.
    @Transactional
    public Map<String, Object> crearCuentaCompartida(Long cuentaId, String nombre) {
        Perfil personal = perfilRepository.findByCuentaIdAndEsPrincipalTrue(cuentaId)
                .orElseThrow(() -> new NoSuchElementException("La cuenta no tiene un perfil principal"));

        CuentaCompartida compartida = new CuentaCompartida();
        compartida.setNombre(nombre.trim());
        cuentaCompartidaRepository.save(compartida);

        Perfil perfil = new Perfil();
        perfil.setCuenta(personal.getCuenta());
        perfil.setCuentaCompartida(compartida);
        perfil.setNombrePerfil(personal.getNombrePerfil());
        perfil.setRol(Perfil.Rol.ADMIN);
        perfil.setEsActivo(true);
        perfilRepository.save(perfil);
        compartida.setCreador(perfil);

        return Map.of("id", compartida.getId(), "nombre", compartida.getNombre(), "perfilId", perfil.getId());
    }

    // Para las acciones que solo puede hacer el administrador de una cuenta compartida (invitar,
    // cambiar roles, crear categorías, crear y editar el presupuesto compartido). Devuelve el perfil
    // ADMIN de la cuenta del token en esa cuenta compartida; si no tiene perfil ahí, es MIEMBRO o no
    // vino la cuenta compartida, 403. (Con null, Spring buscaría "IS NULL" y encontraría el perfil personal.)
    public Perfil exigirAdmin(Long cuentaId, Long cuentaCompartidaId) {
        return Optional.ofNullable(cuentaCompartidaId)
                .flatMap(id -> perfilRepository.findByCuentaIdAndCuentaCompartidaId(cuentaId, id))
                .filter(perfil -> perfil.getRol() == Perfil.Rol.ADMIN)
                .orElseThrow(() -> new AccessDeniedException(
                        "Solo el administrador de la cuenta compartida puede hacer esto"));
    }

    // El administrador cambia el rol de otro perfil de su cuenta compartida. El suyo y el de quien
    // la creó no: así la cuenta compartida nunca se queda sin administrador ni sin su dueño.
    @Transactional
    public void cambiarRol(Long cuentaId, Long perfilId, Perfil.Rol rol) {
        Perfil perfil = perfilRepository.findById(perfilId)
                .orElseThrow(() -> new NoSuchElementException("Perfil no encontrado"));
        if (perfil.getCuentaCompartida() == null) {
            throw new BadRequestException("Solo se puede cambiar el rol de un perfil de una cuenta compartida");
        }

        Perfil admin = exigirAdmin(cuentaId, perfil.getCuentaCompartida().getId());
        if (admin.getId().equals(perfil.getId())) {
            throw new BadRequestException("No podés cambiar tu propio rol");
        }
        // Mismo objeto: en una transacción, Hibernate carga una sola vez cada perfil.
        if (perfil.equals(perfil.getCuentaCompartida().getCreador())) {
            throw new BadRequestException("No se le puede cambiar el rol a quien creó la cuenta compartida");
        }

        perfil.setRol(rol);
    }
}
