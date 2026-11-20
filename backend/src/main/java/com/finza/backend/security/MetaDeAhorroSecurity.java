package com.finza.backend.security;

import java.util.Optional;

import org.springframework.stereotype.Component;

import com.finza.backend.model.MetaDeAhorro;
import com.finza.backend.model.Perfil;
import com.finza.backend.repository.MetaDeAhorroRepository;
import com.finza.backend.repository.PerfilRepository;

@Component("metaSecurity")
public class MetaDeAhorroSecurity {

    private final MetaDeAhorroRepository metaRepository;
    private final PerfilRepository perfilRepository;

    public MetaDeAhorroSecurity(
            MetaDeAhorroRepository metaRepository,
            PerfilRepository perfilRepository) {
        this.metaRepository = metaRepository;
        this.perfilRepository = perfilRepository;
    }

    /**
     * Valida en @PreAuthorize que solo el ADMIN de la cuenta compartida
     * (o el dueño de una meta personal) pueda modificar o eliminar la meta.
     */
    public boolean puedeAdministrarMeta(Object principal, Long metaId) {
        if (!(principal instanceof Long cuentaId) || metaId == null) {
            return false;
        }

        Optional<MetaDeAhorro> metaOpt = metaRepository.findById(metaId);
        if (metaOpt.isEmpty()) {
            // Deja pasar al servicio para que devuelva 404 (NoSuchElementException)
            return true;
        }

        MetaDeAhorro meta = metaOpt.get();
        if (meta.getCuentaCompartida() != null) {
            return perfilRepository
                    .findByCuentaIdAndCuentaCompartidaId(cuentaId, meta.getCuentaCompartida().getId())
                    .map(perfil -> perfil.getRol() == Perfil.Rol.ADMIN)
                    .orElse(false);
        }

        if (meta.getPerfil() != null && meta.getPerfil().getCuenta() != null) {
            return meta.getPerfil().getCuenta().getId().equals(cuentaId);
        }

        return false;
    }
}