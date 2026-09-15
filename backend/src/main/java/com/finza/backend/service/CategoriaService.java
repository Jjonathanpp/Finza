package com.finza.backend.service;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.finza.backend.dto.CategoriaRequest;
import com.finza.backend.dto.CategoriaResponseDTO;
import com.finza.backend.exception.BadRequestException;
import com.finza.backend.model.Categoria;
import com.finza.backend.model.Cuenta;
import com.finza.backend.repository.CategoriaRepository;
import com.finza.backend.repository.CuentaRepository;
import com.finza.backend.repository.MovimientoRepository;

@Service
public class CategoriaService {

    private final CategoriaRepository categoriaRepository;
    private final MovimientoRepository movimientoRepository;
    private final CuentaRepository cuentaRepository;

    public CategoriaService(CategoriaRepository categoriaRepository,
                             MovimientoRepository movimientoRepository,
                             CuentaRepository cuentaRepository) {
        this.categoriaRepository = categoriaRepository;
        this.movimientoRepository = movimientoRepository;
        this.cuentaRepository = cuentaRepository;
    }

    public List<CategoriaResponseDTO> listarCategorias(Long cuentaId) {
        if (!cuentaRepository.existsById(cuentaId)) {
            throw new BadRequestException("La cuenta indicada no existe");
        }
        return categoriaRepository.findByCuentaIdOrCuentaIsNull(cuentaId).stream()
                .map(CategoriaResponseDTO::new)
                .toList();
    }

    @Transactional
    public CategoriaResponseDTO crearCategoria(Long cuentaId, CategoriaRequest request) {
        Cuenta cuenta = cuentaRepository.findById(cuentaId)
                .orElseThrow(() -> new BadRequestException("La cuenta indicada no existe"));

        String nombreLimpio = request.getNombre().trim();

        if (!categoriaRepository.buscarPropiaOGlobal(nombreLimpio, request.getTipo(), cuentaId).isEmpty()) {
            throw new IllegalArgumentException("Ya existe una categoría con ese nombre para el tipo indicado");
        }

        Categoria categoria = crearYGuardar(cuenta, nombreLimpio, request.getColor(), request.getTipo());
        return new CategoriaResponseDTO(categoria);
    }

    // Usado por MovimientoServiceImpl. Recibe la Cuenta ya resuelta para no repetir
    // la consulta que el caller ya hizo al buscar el perfil. Corre dentro de la
    // transacción de MovimientoServiceImpl.registrar.
    public Categoria buscarOCrearCategoria(String nombre, Categoria.TipoCategoria tipo, Cuenta cuenta) {
        String nombreLimpio = nombre.trim();
        return categoriaRepository.buscarPropiaOGlobal(nombreLimpio, tipo, cuenta.getId()).stream()
                .findFirst()
                .orElseGet(() -> crearYGuardar(cuenta, nombreLimpio, null, tipo));
    }

    // Arma y persiste la entidad. Compartido por el alta explícita (POST /api/categorias,
    // con color) y el find-or-create implícito de movimientos (sin color).
    private Categoria crearYGuardar(Cuenta cuenta, String nombre, String color, Categoria.TipoCategoria tipo) {
        Categoria categoria = new Categoria();
        categoria.setCuenta(cuenta);
        categoria.setNombre(nombre);
        categoria.setColor(color);
        categoria.setTipoCategoriaPredefinida(tipo);
        return categoriaRepository.save(categoria);
    }

    @Transactional
    public Categoria editarCategoria(Long id, Long cuentaId, String nombre, String color) {
        Categoria categoria = categoriaRepository.findByIdAndCuentaId(id, cuentaId)
                .orElseThrow(() -> new RuntimeException("Categoría no encontrada o no pertenece a la cuenta"));

        categoria.setNombre(nombre);
        categoria.setColor(color);

        return categoriaRepository.save(categoria);
    }

    @Transactional
    public void eliminarCategoria(Long id, Long cuentaId) {
        Categoria categoria = categoriaRepository.findByIdAndCuentaId(id, cuentaId)
                .orElseThrow(() -> new RuntimeException("Categoría no encontrada o no pertenece a la cuenta"));

        if (movimientoRepository.existsByCategoriaId(id)) {
            throw new IllegalStateException("No se puede eliminar la categoría porque tiene movimientos asociados");
        }

        categoriaRepository.delete(categoria);
    }
}
