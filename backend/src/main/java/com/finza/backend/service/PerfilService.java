package com.finza.backend.service;

import java.util.Map;
import java.util.NoSuchElementException;
import java.util.Optional;

import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

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

    // El perfil con el que trabaja la cuenta del token. En la Fase 1 cada cuenta tiene uno solo,
    // el principal, que se crea al registrarse.
    public Long idPrincipal(Long cuentaId) {
        return perfilRepository.findByCuentaIdAndEsPrincipalTrue(cuentaId)
                .orElseThrow(() -> new NoSuchElementException("La cuenta no tiene un perfil principal"))
                .getId();
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

    // Para lo que puede ver cualquier integrante de una cuenta compartida. Devuelve el perfil de la
    // cuenta del token en esa cuenta compartida; si no tiene perfil ahí o no vino la cuenta
    // compartida, 403. (Con null, Spring buscaría "IS NULL" y encontraría el perfil personal.)
    public Perfil exigirMiembro(Long cuentaId, Long cuentaCompartidaId) {
        return Optional.ofNullable(cuentaCompartidaId)
                .flatMap(id -> perfilRepository.findByCuentaIdAndCuentaCompartidaId(cuentaId, id))
                .orElseThrow(() -> new AccessDeniedException("No sos parte de esta cuenta compartida"));
    }

    // Para las acciones que solo puede hacer el administrador de una cuenta compartida (invitar,
    // cambiar roles, crear categorías, editar el presupuesto compartido). Si es MIEMBRO, 403.
    public Perfil exigirAdmin(Long cuentaId, Long cuentaCompartidaId) {
        Perfil perfil = exigirMiembro(cuentaId, cuentaCompartidaId);
        if (perfil.getRol() != Perfil.Rol.ADMIN) {
            throw new AccessDeniedException("Solo el administrador de la cuenta compartida puede hacer esto");
        }
        return perfil;
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
