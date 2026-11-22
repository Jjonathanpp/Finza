import 'package:frontend/features/categorias/data/models/categoria.dart';
import 'package:frontend/features/presupuestos/data/models/presupuesto.dart';

// La categoría de un presupuesto, para dibujarla con CirculoCategoria.de. El presupuesto solo trae el
// nombre y el color, no si es predefinida; como el backend no deja repetir nombres, una que se llame como
// una predefinida lo es, y lleva su emoji. Las demás, su inicial.
Categoria categoriaDelPresupuesto(Presupuesto p) => Categoria(
      id: p.categoriaId,
      nombre: p.categoriaNombre,
      color: p.categoriaColor,
      tipo: 'EGRESO',
      esPredefinida: true,
    );
