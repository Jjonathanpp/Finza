-- ============================================================
-- import.sql - Datos de prueba Finza (t-1.1.3)
-- Se ejecuta en cada arranque del backend (spring.sql.init).
-- Idempotente: reemplaza a spring.sql.init default y NO duplica
-- datos si las filas ya existen (ON CONFLICT (id) DO NOTHING).
-- ============================================================

-- 1) USUARIOS de prueba
INSERT INTO usuario (id, dni, telefono, nombre, apellido, fecha_nacimiento, genero)
VALUES
  (1, 10101010, '+54 11 5555-0101', 'Juan',  'Perez',     '1990-05-14', 'MASCULINO'),
  (2, 20202020, '+54 11 5555-0202', 'Maria', 'Gomez',     '1995-11-02', 'FEMENINO'),
  (3, 30303030, '+54 11 5555-0303', 'Lucia', 'Fernandez', '1998-03-22', 'FEMENINO')
ON CONFLICT (id) DO NOTHING;

-- 2) CUENTAS (tabla: cuentas)
INSERT INTO cuentas (id, usuario_id, email, password, email_verificado, fecha_creacion, estado)
VALUES
  (1, 1, 'juan@finza.local',  'demo1234', TRUE, NOW() - INTERVAL '30 days', 'ACTIVA'),
  (2, 2, 'maria@finza.local', 'demo1234', TRUE, NOW() - INTERVAL '15 days', 'ACTIVA'),
  (3, 3, 'lucia@finza.local', 'demo1234', TRUE, NOW() - INTERVAL '2 days',  'ACTIVA')
ON CONFLICT (id) DO NOTHING;

-- 3) PERFILES
INSERT INTO perfil (id, cuenta_id, nombre_perfil, rol, foto_url, es_principal, es_activo)
VALUES
  (1, 1, 'Perfil Principal', 'ADMIN',   NULL, TRUE, TRUE),
  (2, 2, 'Perfil Principal', 'USUARIO', NULL, TRUE, TRUE),
  (3, 3, 'Perfil Principal', 'ADMIN',   NULL, TRUE, TRUE)
ON CONFLICT (id) DO NOTHING;

-- 4) CATALOGO de categorias predefinidas (cuenta_id NULL = globales)
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

-- 4.1) CATEGORIAS propias (cuenta_id no nulo) - creadas via POST /api/categorias (t-4.2.1),
-- cubren los casos de negocio del endpoint: propia sin choque (9), mismo nombre que una
-- global pero tipo distinto (10), mismo nombre que otra cuenta pero cuenta distinta (11),
-- y una sin movimientos asociados para poder demostrar PUT/DELETE en vivo (12).
INSERT INTO categoria (id, cuenta_id, nombre, color, es_predefinida, tipo_categoria_predefinida)
VALUES
  (9,  1, 'Mascotas',      '#F97316', FALSE, 'EGRESO'),
  (10, 1, 'Alquiler',      '#EA580C', FALSE, 'EGRESO'),
  (11, 2, 'Mascotas',      '#10B981', FALSE, 'EGRESO'),
  (12, 1, 'Suscripciones', '#A855F7', FALSE, 'EGRESO')
ON CONFLICT (id) DO NOTHING;

-- 5) MOVIMIENTOS de prueba
INSERT INTO movimiento (id, perfil_id, categoria_id, monto, es_ingreso, fecha, descripcion, estado, origen, fecha_creacion, external_id)
VALUES
  (1, 1, 1, 600000.00, TRUE,  '2026-08-05', 'Sueldo agosto',     'APROBADO', 'MANUAL', NOW() - INTERVAL '30 days', NULL),
  (2, 1, 2,  28500.00, TRUE,  '2026-08-12', 'Proyecto diseno',   'APROBADO', 'MANUAL', NOW() - INTERVAL '28 days', NULL),
  (3, 1, 6,   8500.00, FALSE, '2026-08-15', 'Verduleria',        'APROBADO', 'MANUAL', NOW() - INTERVAL '26 days', NULL),
  (4, 1, 7,  12000.00, FALSE, '2026-08-20', 'SUBTE y tren',      'APROBADO', 'MANUAL', NOW() - INTERVAL '20 days', NULL),
  (5, 2, 1, 600000.00, TRUE,  '2026-09-01', 'Sueldo septiembre', 'APROBADO', 'MANUAL', NOW() - INTERVAL '5 days',  NULL),
  (6, 2, 8,  45000.00, FALSE, '2026-09-08', 'Luz y agua',        'APROBADO', 'MANUAL', NOW() - INTERVAL '1 day',   NULL)
ON CONFLICT (id) DO NOTHING;

-- 5.1) MOVIMIENTOS que ejercitan las categorias propias nuevas: el par 7/8 es la
-- regresion del bug fixeado en 93a1a54 (mismo nombre "Alquiler", tipo distinto ->
-- categoria distinta), y el par 9/10 muestra el aislamiento por cuenta (mismo nombre
-- "Mascotas" en cuenta 1 y cuenta 2 -> filas distintas).
INSERT INTO movimiento (id, perfil_id, categoria_id, monto, es_ingreso, fecha, descripcion, estado, origen, fecha_creacion, external_id)
VALUES
  (7,  1, 3,  18500.00, TRUE,  '2026-08-25', 'Inquilino del departamento', 'APROBADO', 'MANUAL', NOW() - INTERVAL '19 days', NULL),
  (8,  1, 10,  9000.00, FALSE, '2026-08-27', 'Alquiler de cochera',        'APROBADO', 'MANUAL', NOW() - INTERVAL '17 days', NULL),
  (9,  1, 9,  15000.00, FALSE, '2026-09-02', 'Veterinaria',                'APROBADO', 'MANUAL', NOW() - INTERVAL '11 days', NULL),
  (10, 2, 11,  9500.00, FALSE, '2026-09-05', 'Alimento para gato',         'APROBADO', 'MANUAL', NOW() - INTERVAL '8 days',  NULL),
  (11, 2, 5,   6000.00, TRUE,  '2026-09-10', 'Venta de acciones',          'APROBADO', 'MANUAL', NOW() - INTERVAL '3 days',  NULL),
  (12, 3, 1, 550000.00, TRUE,  '2026-09-01', 'Sueldo septiembre',          'APROBADO', 'MANUAL', NOW() - INTERVAL '5 days',  NULL)
ON CONFLICT (id) DO NOTHING;

-- 6) Resincronizar secuencias (los ids entraron a mano)
SELECT setval(pg_get_serial_sequence('usuario',   'id'), (SELECT COALESCE(MAX(id), 1) FROM usuario));
SELECT setval(pg_get_serial_sequence('cuentas',   'id'), (SELECT COALESCE(MAX(id), 1) FROM cuentas));
SELECT setval(pg_get_serial_sequence('perfil',    'id'), (SELECT COALESCE(MAX(id), 1) FROM perfil));
SELECT setval(pg_get_serial_sequence('categoria', 'id'), (SELECT COALESCE(MAX(id), 1) FROM categoria));
SELECT setval(pg_get_serial_sequence('movimiento','id'), (SELECT COALESCE(MAX(id), 1) FROM movimiento));