package com.finza.backend.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.finza.backend.model.Categoria;
import com.finza.backend.repository.CategoriaRepository;
import com.finza.backend.repository.MovimientoRepository;

@Service
public class CategoriaService {

    private final CategoriaRepository categoriaRepository;
    private final MovimientoRepository movimientoRepository;

    public CategoriaService(CategoriaRepository categoriaRepository, MovimientoRepository movimientoRepository) {
        this.categoriaRepository = categoriaRepository;
        this.movimientoRepository = movimientoRepository;
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