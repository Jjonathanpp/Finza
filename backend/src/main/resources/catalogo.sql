-- ============================================================
-- catalogo.sql - Categorias predefinidas del sistema (t-1.8.2)
-- Perfil docker: se carga antes de import.sql.
-- Perfil prod: es lo unico que se carga (sin datos de prueba).
-- Idempotente: no duplica filas si ya existen (ON CONFLICT (id) DO NOTHING).
-- ============================================================

-- Catalogo de categorias predefinidas (cuenta_id NULL = globales)
INSERT INTO categoria (id, cuenta_id, nombre, color, es_predefinida, tipo_categoria_predefinida)
VALUES
  (1, NULL, 'Sueldo',      '#22C55E', TRUE, 'INGRESO'),
  (2, NULL, 'Freelance',   '#84CC16', TRUE, 'INGRESO'),
  (3, NULL, 'Alquiler',    '#F59E0B', TRUE, 'INGRESO'),
  (4, NULL, 'Inversiones', '#06B6D4', TRUE, 'INGRESO'),
  (5, NULL, 'Otros',       '#94A3B8', TRUE, 'INGRESO'),
  (6, NULL, 'Comida',      '#EF4444', TRUE, 'EGRESO'),
  (7, NULL, 'Transporte',  '#8B5CF6', TRUE, 'EGRESO'),
  (8, NULL, 'Servicios',   '#6366F1', TRUE, 'EGRESO')
ON CONFLICT (id) DO NOTHING;

-- Resincronizar la secuencia (los ids entraron a mano)
SELECT setval(pg_get_serial_sequence('categoria', 'id'), (SELECT COALESCE(MAX(id), 1) FROM categoria));
