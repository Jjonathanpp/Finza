-- ============================================================
-- V3 - Catalogo de categorias predefinidas (T-1.10.2)
-- Antes era catalogo.sql y corria en cada arranque con spring.sql.init (t-1.8.2, t-4.1.3).
-- Ahora corre una sola vez por base. Para cambiar el catalogo, una migracion nueva.
-- En produccion las categorias ya estaban: cada paso no cambia nada.
-- ============================================================

-- 1) Las del catalogo original, con su id fijo (cuenta_id NULL = globales)
INSERT INTO categoria (id, cuenta_id, nombre, color, es_predefinida, tipo_categoria_predefinida)
VALUES
  (1, NULL, 'Sueldo',      '#22C55E', TRUE, 'INGRESO'),
  (4, NULL, 'Inversiones', '#06B6D4', TRUE, 'INGRESO'),
  (5, NULL, 'Otros',       '#94A3B8', TRUE, 'INGRESO'),
  (6, NULL, 'Comida',      '#EF4444', TRUE, 'EGRESO'),
  (7, NULL, 'Transporte',  '#8B5CF6', TRUE, 'EGRESO'),
  (8, NULL, 'Servicios',   '#6366F1', TRUE, 'EGRESO')
ON CONFLICT (id) DO NOTHING;

-- 2) Las nuevas van sin id fijo, porque en las bases que ya existen los ids que siguen
-- son categorias propias: se agregan solo si no hay una global con ese nombre y tipo.
-- Los ids 2 y 3 (Freelance y Alquiler de ingreso) salieron del catalogo y no se reusan.
-- Antes, el contador de ids pasa por lo menos el 12: en el Docker, los ids 9 a 12 son
-- las categorias propias de los datos de prueba (db/datos-prueba).
SELECT setval(pg_get_serial_sequence('categoria', 'id'), GREATEST((SELECT COALESCE(MAX(id), 1) FROM categoria), 12));

INSERT INTO categoria (cuenta_id, nombre, color, es_predefinida, tipo_categoria_predefinida)
SELECT NULL, nueva.nombre, nueva.color, TRUE, nueva.tipo
FROM (VALUES
  (1, 'Supermercado',    '#84CC16', 'EGRESO'),
  (2, 'Alquiler',        '#F59E0B', 'EGRESO'),
  (3, 'Salud',           '#EC4899', 'EGRESO'),
  (4, 'Educación',       '#0EA5E9', 'EGRESO'),
  (5, 'Entretenimiento', '#14B8A6', 'EGRESO'),
  (6, 'Ropa',            '#D946EF', 'EGRESO'),
  (7, 'Otros',           '#94A3B8', 'EGRESO')
) AS nueva (orden, nombre, color, tipo)
WHERE NOT EXISTS (
  SELECT 1 FROM categoria c
  WHERE c.cuenta_id IS NULL AND c.cuenta_compartida_id IS NULL
    AND c.nombre = nueva.nombre AND c.tipo_categoria_predefinida = nueva.tipo
)
ORDER BY nueva.orden;

-- 3) Resincronizar el contador (los ids entraron a mano)
SELECT setval(pg_get_serial_sequence('categoria', 'id'), (SELECT COALESCE(MAX(id), 1) FROM categoria));
