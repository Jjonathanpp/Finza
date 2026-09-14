package com.finza.backend.repository;

import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import com.finza.backend.model.Categoria;

@Repository
public interface CategoriaRepository extends JpaRepository<Categoria, Long> {
    Optional<Categoria> findByIdAndCuentaId(Long id, Long cuentaId);

    // Busca una categoria propia de la cuenta o global (cuenta_id NULL, ver import.sql)
    // con el mismo nombre (sin distinguir mayusculas/espacios) y el mismo tipo.
    // Se usa tanto para rechazar duplicados en el alta (t-4.2.1) como para el
    // find-or-create de MovimientoServiceImpl.
    @Query("""
        SELECT c FROM Categoria c
        WHERE LOWER(TRIM(c.nombre)) = LOWER(TRIM(:nombre))
          AND c.tipoCategoriaPredefinida = :tipo
          AND (c.cuenta.id = :cuentaId OR c.cuenta IS NULL)
        """)
    Optional<Categoria> buscarPropiaOGlobal(@Param("nombre") String nombre,
                                             @Param("tipo") Categoria.TipoCategoria tipo,
                                             @Param("cuentaId") Long cuentaId);
}
