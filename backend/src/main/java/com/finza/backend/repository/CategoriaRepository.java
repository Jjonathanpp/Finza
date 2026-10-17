package com.finza.backend.repository;

import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import com.finza.backend.model.Categoria;

@Repository
public interface CategoriaRepository extends JpaRepository<Categoria, Long> {
    Optional<Categoria> findByIdAndCuentaId(Long id, Long cuentaId);

    // Predefinidas (cuenta_id NULL) + propias de la cuenta, para GET /api/categorias.
    // Primero las predefinidas y después las propias, cada grupo en el orden en que se crearon:
    // sin ORDER BY, Postgres las devuelve como las tenga guardadas y quedan mezcladas.
    @Query("""
        SELECT c FROM Categoria c
        WHERE c.cuenta.id = :cuentaId OR c.cuenta IS NULL
        ORDER BY CASE WHEN c.cuenta IS NULL THEN 0 ELSE 1 END, c.id
        """)
    List<Categoria> listarPredefinidasYPropias(@Param("cuentaId") Long cuentaId);

    // Propias de la cuenta o globales (cuenta_id NULL), mismo nombre y tipo. Lista y no
    // Optional: si una carrera deja un duplicado, se usa la más vieja en vez de tirar 500.
    @Query("""
        SELECT c FROM Categoria c
        WHERE LOWER(TRIM(c.nombre)) = LOWER(:nombre)
          AND c.tipoCategoriaPredefinida = :tipo
          AND (c.cuenta.id = :cuentaId OR c.cuenta IS NULL)
        ORDER BY c.id
        """)
    List<Categoria> buscarPropiaOGlobal(@Param("nombre") String nombre,
                                         @Param("tipo") Categoria.TipoCategoria tipo,
                                         @Param("cuentaId") Long cuentaId);
}
