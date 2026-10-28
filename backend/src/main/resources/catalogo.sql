-- ============================================================
-- catalogo.sql - Categorias predefinidas del sistema (t-1.8.2, catalogo nuevo en t-4.1.3)
-- Perfil docker: se carga antes de import.sql.
-- Perfil prod: es lo unico que se carga (sin datos de prueba).
-- Corre en cada arranque: si ya se aplico, cada paso no cambia nada.
-- ============================================================

-- 1) Las que siguen del catalogo original, con su id fijo (cuenta_id NULL = globales)
INSERT INTO categoria (id, cuenta_id, nombre, color, es_predefinida, tipo_categoria_predefinida)
VALUES
  (1, NULL, 'Sueldo',      '#22C55E', TRUE, 'INGRESO'),
  (4, NULL, 'Inversiones', '#06B6D4', TRUE, 'INGRESO'),
  (5, NULL, 'Otros',       '#94A3B8', TRUE, 'INGRESO'),
  (6, NULL, 'Comida',      '#EF4444', TRUE, 'EGRESO'),
  (7, NULL, 'Transporte',  '#8B5CF6', TRUE, 'EGRESO'),
  (8, NULL, 'Servicios',   '#6366F1', TRUE, 'EGRESO')
ON CONFLICT (id) DO NOTHING;

-- 2) Freelance (2) y Alquiler de ingreso (3) salieron del catalogo: lo que las usaba
-- pasa a "Otros" de ingreso (5) y despues se borran. Sus ids no se reusan.
UPDATE movimiento SET categoria_id = 5
WHERE categoria_id IN (SELECT id FROM categoria WHERE id IN (2, 3) AND cuenta_id IS NULL);

UPDATE presupuestos SET categoria_id = 5
WHERE categoria_id IN (SELECT id FROM categoria WHERE id IN (2, 3) AND cuenta_id IS NULL);

DELETE FROM categoria WHERE id IN (2, 3) AND cuenta_id IS NULL;

-- 3) Las nuevas van sin id fijo, porque en las bases que ya existen los ids que siguen
-- son categorias propias: se agregan solo si no hay una global con ese nombre y tipo.
-- Antes, el contador de ids pasa por lo menos el 12: en una base de cero del perfil
-- docker, los ids 9 a 12 son las categorias propias que carga import.sql.
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
  WHERE c.cuenta_id IS NULL AND c.nombre = nueva.nombre AND c.tipo_categoria_predefinida = nueva.tipo
)
ORDER BY nueva.orden;

-- 4) Una categoria propia que se llama igual que una global del mismo tipo se une con ella:
-- sus movimientos y presupuestos pasan a la global y la propia se borra. Por ejemplo, el
-- "Otros" de egreso que la sincronizacion de Mercado Pago creaba en cada cuenta.
-- Compara como CategoriaRepository.buscarPropiaOGlobal (sin mayusculas ni espacios de mas).
UPDATE movimiento m SET categoria_id = g.id
FROM categoria p, categoria g
WHERE m.categoria_id = p.id
  AND p.cuenta_id IS NOT NULL AND g.cuenta_id IS NULL
  AND LOWER(TRIM(p.nombre)) = LOWER(g.nombre)
  AND p.tipo_categoria_predefinida = g.tipo_categoria_predefinida;

UPDATE presupuestos ps SET categoria_id = g.id
FROM categoria p, categoria g
WHERE ps.categoria_id = p.id
  AND p.cuenta_id IS NOT NULL AND g.cuenta_id IS NULL
  AND LOWER(TRIM(p.nombre)) = LOWER(g.nombre)
  AND p.tipo_categoria_predefinida = g.tipo_categoria_predefinida;

DELETE FROM categoria p
USING categoria g
WHERE p.cuenta_id IS NOT NULL AND g.cuenta_id IS NULL
  AND LOWER(TRIM(p.nombre)) = LOWER(g.nombre)
  AND p.tipo_categoria_predefinida = g.tipo_categoria_predefinida;

-- 5) Resincronizar la secuencia (los ids entraron a mano)
SELECT setval(pg_get_serial_sequence('categoria', 'id'), (SELECT COALESCE(MAX(id), 1) FROM categoria));

-- 6) Las preferencias pasaron de la cuenta al perfil (10/10). En las bases creadas antes quedo
-- la columna vieja cuenta_id, obligatoria, y no deja guardar preferencias (t-8.2.1).
ALTER TABLE preferencias_sistema DROP COLUMN IF EXISTS cuenta_id;

-- 7) El rol del perfil paso a ser ADMIN o MIEMBRO (t-11.3.1). Antes nadie lo cargaba (o en los
-- datos de prueba decia USUARIO): el perfil principal de cada cuenta es el administrador.
UPDATE perfil SET rol = 'ADMIN'
WHERE es_principal AND (rol IS NULL OR rol NOT IN ('ADMIN', 'MIEMBRO'));

-- 8) El perfil de una cuenta compartida queda en ella aunque su dueno se de de baja (t-11.3.1).
-- En las bases creadas antes, cuenta_id era obligatoria (Hibernate no saca el NOT NULL solo).
ALTER TABLE perfil ALTER COLUMN cuenta_id DROP NOT NULL;
