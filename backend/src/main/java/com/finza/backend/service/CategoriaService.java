package com.finza.backend.service;

import java.util.List;
import java.util.NoSuchElementException;
import java.util.Optional;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.finza.backend.dto.CategoriaRequest;
import com.finza.backend.dto.CategoriaResponseDTO;
import com.finza.backend.exception.BadRequestException;
import com.finza.backend.model.Categoria;
import com.finza.backend.model.Cuenta;
import com.finza.backend.model.CuentaCompartida;
import com.finza.backend.model.Perfil;
import com.finza.backend.repository.CategoriaRepository;
import com.finza.backend.repository.CuentaRepository;
import com.finza.backend.repository.MovimientoRepository;

@Service
public class CategoriaService {

    private final CategoriaRepository categoriaRepository;
    private final MovimientoRepository movimientoRepository;
    private final CuentaRepository cuentaRepository;
    private final PerfilService perfilService;

    public CategoriaService(CategoriaRepository categoriaRepository,
                             MovimientoRepository movimientoRepository,
                             CuentaRepository cuentaRepository,
                             PerfilService perfilService) {
        this.categoriaRepository = categoriaRepository;
        this.movimientoRepository = movimientoRepository;
        this.cuentaRepository = cuentaRepository;
        this.perfilService = perfilService;
    }

    // Las de la cuenta activa (t-13.1.2): en el perfil personal, las predefinidas y las propias;
    // en una cuenta compartida, las predefinidas y las de esa cuenta compartida.
    public List<CategoriaResponseDTO> listarCategorias(Long cuentaId) {
        if (!cuentaRepository.existsById(cuentaId)) {
            throw new BadRequestException("La cuenta indicada no existe");
        }
        return listarDelPerfil(perfilService.perfilActivo(cuentaId)).stream()
                .map(CategoriaResponseDTO::new)
                .toList();
    }

    // Las que puede usar el perfil: las predefinidas y las propias de su cuenta o, si es de una cuenta
    // compartida, las de esa cuenta compartida. También la usa la voz para armar la lista de la IA.
    public List<Categoria> listarDelPerfil(Perfil perfil) {
        CuentaCompartida compartida = perfil.getCuentaCompartida();
        return compartida == null
                ? categoriaRepository.listarPredefinidasYPropias(perfil.getCuenta().getId())
                : categoriaRepository.listarPredefinidasYDeCuentaCompartida(compartida.getId());
    }

    // En una cuenta compartida la crea solo el administrador, y queda de la cuenta compartida.
    @Transactional
    public CategoriaResponseDTO crearCategoria(Long cuentaId, CategoriaRequest request) {
        Cuenta cuenta = cuentaRepository.findById(cuentaId)
                .orElseThrow(() -> new BadRequestException("La cuenta indicada no existe"));
        Perfil activo = perfilService.perfilActivo(cuentaId);
        CuentaCompartida compartida = activo.getCuentaCompartida();
        if (compartida != null) {
            perfilService.exigirAdmin(cuentaId, compartida.getId());
        }

        String nombreLimpio = request.getNombre().trim();

        if (buscar(nombreLimpio, request.getTipo(), activo).isPresent()) {
            throw new IllegalArgumentException("Ya existe una categoría con ese nombre para el tipo indicado");
        }

        Categoria categoria = crearYGuardar(compartida == null ? cuenta : null, compartida, nombreLimpio,
                request.getColor(), request.getTipo());
        return new CategoriaResponseDTO(categoria);
    }

    // Usado por MovimientoServiceImpl y MercadoPagoSyncService, dentro de su transacción. Recibe el
    // perfil del movimiento: en una cuenta compartida busca entre las predefinidas y las de la cuenta
    // compartida, y si no existe la crea solo el administrador (un miembro recibe 400).
    public Categoria buscarOCrearCategoria(String nombre, Categoria.TipoCategoria tipo, Perfil perfil) {
        String nombreLimpio = nombre.trim();
        CuentaCompartida compartida = perfil.getCuentaCompartida();
        return buscar(nombreLimpio, tipo, perfil).orElseGet(() -> {
            if (compartida != null && perfil.getRol() != Perfil.Rol.ADMIN) {
                throw new BadRequestException(
                        "La categoría " + nombreLimpio + " no existe en " + compartida.getNombre());
            }
            return crearYGuardar(compartida == null ? perfil.getCuenta() : null, compartida, nombreLimpio, null, tipo);
        });
    }

    // La que puede usar el perfil con ese nombre y tipo, sin crearla: una predefinida o una propia (de su
    // cuenta, o de su cuenta compartida si el perfil es de una). Si una carrera dejó un duplicado, la más
    // vieja. También la usa la voz, que nunca crea categorías (T-3.1.6).
    public Optional<Categoria> buscar(String nombre, Categoria.TipoCategoria tipo, Perfil perfil) {
        CuentaCompartida compartida = perfil.getCuentaCompartida();
        if (compartida == null) {
            return categoriaRepository.buscarPropiaOGlobal(nombre, tipo, perfil.getCuenta().getId()).stream().findFirst();
        }
        return listarDelPerfil(perfil).stream()
                .filter(otra -> otra.getTipoCategoriaPredefinida() == tipo && otra.getNombre().trim().equalsIgnoreCase(nombre))
                .findFirst();
    }

    // Arma y persiste la entidad. Compartido por el alta explícita (POST /api/categorias,
    // con color), el find-or-create implícito de movimientos (sin color) y el alta en una
    // cuenta compartida. Va una de las dos: la cuenta o la cuenta compartida.
    private Categoria crearYGuardar(Cuenta cuenta, CuentaCompartida compartida, String nombre, String color,
                                    Categoria.TipoCategoria tipo) {
        Categoria categoria = new Categoria();
        categoria.setCuenta(cuenta);
        categoria.setCuentaCompartida(compartida);
        categoria.setNombre(nombre);
        categoria.setColor(color);
        categoria.setTipoCategoriaPredefinida(tipo);
        return categoriaRepository.save(categoria);
    }

    @Transactional
    public CategoriaResponseDTO editarCategoria(Long id, Long cuentaId, String nombre, String color) {
        Categoria categoria = categoriaRepository.findByIdAndCuentaId(id, cuentaId)
                .orElseThrow(() -> new NoSuchElementException("Categoría no encontrada o no pertenece a la cuenta"));

        String nombreLimpio = nombre.trim();

        // La misma búsqueda del alta, sin contar la categoría que se edita:
        // así se puede guardar sin cambiar el nombre (solo el color).
        boolean repetido = categoriaRepository
                .buscarPropiaOGlobal(nombreLimpio, categoria.getTipoCategoriaPredefinida(), cuentaId)
                .stream()
                .anyMatch(otra -> !otra.getId().equals(id));
        if (repetido) {
            throw new IllegalArgumentException("Ya existe una categoría con ese nombre para el tipo indicado");
        }

        categoria.setNombre(nombreLimpio);
        categoria.setColor(color);

        // El DTO y no la entidad: la entidad trae la cuenta adentro (email, contraseña, datos del usuario).
        return new CategoriaResponseDTO(categoriaRepository.save(categoria));
    }

    @Transactional
    public void eliminarCategoria(Long id, Long cuentaId) {
        Categoria categoria = categoriaRepository.findByIdAndCuentaId(id, cuentaId)
                .orElseThrow(() -> new NoSuchElementException("Categoría no encontrada o no pertenece a la cuenta"));

        if (movimientoRepository.existsByCategoriaId(id)) {
            throw new IllegalStateException("No se puede eliminar la categoría porque tiene movimientos asociados");
        }

        categoriaRepository.delete(categoria);
    }
}
