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
import com.finza.backend.repository.CategoriaRepository;
import com.finza.backend.repository.CuentaCompartidaRepository;
import com.finza.backend.repository.InvitacionCuentaRepository;
import com.finza.backend.repository.PerfilRepository;
import com.finza.backend.repository.PresupuestoRepository;

@Service
public class PerfilService {

    private final PerfilRepository perfilRepository;
    private final CuentaCompartidaRepository cuentaCompartidaRepository;
    private final InvitacionCuentaRepository invitacionCuentaRepository;
    private final PresupuestoRepository presupuestoRepository;
    private final CategoriaRepository categoriaRepository;

    public PerfilService(PerfilRepository perfilRepository, CuentaCompartidaRepository cuentaCompartidaRepository,
            InvitacionCuentaRepository invitacionCuentaRepository, PresupuestoRepository presupuestoRepository,
            CategoriaRepository categoriaRepository) {
        this.perfilRepository = perfilRepository;
        this.cuentaCompartidaRepository = cuentaCompartidaRepository;
        this.invitacionCuentaRepository = invitacionCuentaRepository;
        this.presupuestoRepository = presupuestoRepository;
        this.categoriaRepository = categoriaRepository;
    }

    // El perfil con el que trabaja el pedido. Se sigue llamando así para no tocar
    // los controllers
    // que lo usan, pero devuelve el perfil activo (ver perfilActivo).
    public Long idPrincipal(Long cuentaId) {
        return perfilActivo(cuentaId).getId();
    }

    // El perfil que eligió la app en el selector de cuenta (header X-Perfil-Id,
    // t-13.1.2): el personal
    // o el de una cuenta compartida. Tiene que ser de la cuenta del token (si no,
    // 403). Sin el header,
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

    // Para el selector de cuenta: las cuentas compartidas en las que está la cuenta
    // del token, con su
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

    // Crea la cuenta compartida y, en la cuenta de quien la crea, un perfil ADMIN
    // para ella
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

    // Para las acciones que solo puede hacer el administrador de una cuenta
    // compartida (invitar,
    // cambiar roles, crear categorías, crear y editar el presupuesto compartido).
    // Devuelve el perfil
    // ADMIN de la cuenta del token en esa cuenta compartida; si no tiene perfil
    // ahí, es MIEMBRO o no
    // vino la cuenta compartida, 403. (Con null, Spring buscaría "IS NULL" y
    // encontraría el perfil personal.)
    public Perfil exigirAdmin(Long cuentaId, Long cuentaCompartidaId) {
        return Optional.ofNullable(cuentaCompartidaId)
                .flatMap(id -> perfilRepository.findByCuentaIdAndCuentaCompartidaId(cuentaId, id))
                .filter(perfil -> perfil.getRol() == Perfil.Rol.ADMIN)
                .orElseThrow(() -> new AccessDeniedException(
                        "Solo el administrador de la cuenta compartida puede hacer esto"));
    }

    // El administrador cambia el rol de otro perfil de su cuenta compartida. El
    // suyo y el de quien
    // la creó no: así la cuenta compartida nunca se queda sin administrador ni sin
    // su dueño.
    @Transactional
    public void cambiarRol(Long cuentaId, Long perfilId, Perfil.Rol rol) {
        Perfil perfil = perfilRepository.findById(perfilId)
                .orElseThrow(() -> new NoSuchElementException("Perfil no encontrado"));
        if (perfil.getCuentaCompartida() == null) {
            throw new BadRequestException("Solo se puede cambiar el rol de un perfil de una cuenta compartida");
        }

        if (perfil.getCuenta() == null) {
            throw new BadRequestException("Ese perfil ya no pertenece a la cuenta compartida");
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

    public List<Map<String, Object>> perfilesDeCuentaCompartida(Long cuentaId, Long cuentaCompartidaId) {
        exigirMiembro(cuentaId, cuentaCompartidaId);
        return perfilRepository.findByCuentaCompartidaId(cuentaCompartidaId).stream()
                .map(perfil -> Map.<String, Object>of(
                        "perfilId", perfil.getId(),
                        "nombre", perfil.getNombrePerfil() != null ? perfil.getNombrePerfil() : "Sin nombre",
                        "rol", perfil.getRol()))
                .toList();
    }

    // Al borrar una cuenta (t-11.3.4), en cada cuenta compartida en la que está: si
    // no queda ningún otro
    // integrante activo, la cuenta compartida se borra con todo. Si quedan, su
    // perfil sigue ahí con lo que
    // cargó, pero inactivo y sin cuenta; si era el único ADMIN, el que entró
    // primero pasa a ADMIN, y si era
    // el creador, el creador pasa a un ADMIN que queda, así nadie le puede sacar el
    // rol. Corre en la transacción de la baja: si algo falla, no se borra nada.

    @Transactional
    public void dejarCuentasCompartidas(Long cuentaId) {
        for (Perfil saliente : perfilRepository.findByCuentaIdAndCuentaCompartidaIsNotNull(cuentaId)) {
            salirDeCuentaCompartida(saliente);
        }
        // Antes de borrar la cuenta: si no, al borrarla se llevaría también estos
        // perfiles.
        perfilRepository.flush();
    }

    // T-12.1.7
    @Transactional
    public void abandonarCuentaCompartida(Long cuentaId, Long cuentaCompartidaId) {
        Perfil saliente = exigirMiembro(cuentaId, cuentaCompartidaId);
        salirDeCuentaCompartida(saliente);
    }

    // En este orden por las claves de la base: lo que apunta a la cuenta compartida
    // y a sus perfiles va
    // antes. Al borrar los perfiles se van sus movimientos y presupuestos (también
    // los de ex integrantes),
    // y al borrar las categorías, lo que haya quedado en ellas.
    private void borrarCuentaCompartida(CuentaCompartida compartida) {
        Long id = compartida.getId();
        invitacionCuentaRepository.deleteByCuentaCompartidaId(id);
        presupuestoRepository.deleteByCuentaCompartidaId(id);
        compartida.setCreador(null);
        perfilRepository.deleteAll(perfilRepository.findByCuentaCompartidaId(id));
        categoriaRepository.deleteByCuentaCompartidaId(id);
        cuentaCompartidaRepository.delete(compartida);
    }

    // Para lo que puede hacer cualquier integrante de una cuenta compartida (ADMIN
    // o MIEMBRO).
    public Perfil exigirMiembro(Long cuentaId, Long cuentaCompartidaId) {
        return Optional.ofNullable(cuentaCompartidaId)
                .flatMap(id -> perfilRepository.findByCuentaIdAndCuentaCompartidaId(cuentaId, id))
                .orElseThrow(() -> new AccessDeniedException("No sos integrante de esta cuenta compartida"));
    }

    // Saca a un perfil de su cuenta compartida (T-11.3.4 baja de cuenta y T-12.1.7
    // abandono voluntario).
    // Si se va un ADMIN y quedan integrantes activos, siempre queda un ADMIN: si ya
    // había otro, sigue ese;
    // si no, pasa a ADMIN el que entró primero. Si además era el creador, el
    // creador pasa a ese ADMIN.
    private void salirDeCuentaCompartida(Perfil saliente) {
        CuentaCompartida compartida = saliente.getCuentaCompartida();
        List<Perfil> quedan = perfilRepository
                .findByCuentaCompartidaIdAndEsActivoTrueOrderByIdAsc(compartida.getId())
                .stream().filter(otro -> !otro.equals(saliente)).toList();

        if (quedan.isEmpty()) {
            borrarCuentaCompartida(compartida);
            return;
        }

        if (saliente.getRol() == Perfil.Rol.ADMIN) {
            Perfil admin = quedan.stream().filter(otro -> otro.getRol() == Perfil.Rol.ADMIN).findFirst()
                    .orElse(quedan.get(0));
            admin.setRol(Perfil.Rol.ADMIN);
            if (saliente.equals(compartida.getCreador())) {
                compartida.setCreador(admin);
            }
        }

        saliente.setCuenta(null);
        saliente.setEsActivo(false);
    }
}
