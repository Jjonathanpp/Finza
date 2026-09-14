-- ============================================================
-- import.sql - Datos de prueba Finza (t-1.1.3)
-- Se ejecuta en cada arranque del backend (spring.sql.init).
-- Idempotente: reemplaza a spring.sql.init default y NO duplica
-- datos si las filas ya existen (ON CONFLICT (id) DO NOTHING).
-- ============================================================

-- 1) USUARIOS de prueba
INSERT INTO usuario (id, dni, telefono, nombre, apellido, fecha_nacimiento, genero)
VALUES
  (1, 10101010, '+54 11 5555-0101', 'Juan',  'Perez', '1990-05-14', 'MASCULINO'),
  (2, 20202020, '+54 11 5555-0202', 'Maria', 'Gomez', '1995-11-02', 'FEMENINO')
ON CONFLICT (id) DO NOTHING;

-- 2) CUENTAS (tabla: cuentas)
INSERT INTO cuentas (id, usuario_id, email, password, email_verificado, fecha_creacion, estado)
VALUES
  (1, 1, 'juan@finza.local',  'demo1234', TRUE, NOW() - INTERVAL '30 days', 'ACTIVA'),
  (2, 2, 'maria@finza.local', 'demo1234', TRUE, NOW() - INTERVAL '15 days', 'ACTIVA')
ON CONFLICT (id) DO NOTHING;

-- 3) PERFILES
INSERT INTO perfil (id, cuenta_id, nombre_perfil, rol, foto_url, es_principal, es_activo)
VALUES
  (1, 1, 'Perfil Principal', 'ADMIN',   NULL, TRUE, TRUE),
  (2, 2, 'Perfil Principal', 'USUARIO', NULL, TRUE, TRUE)
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

-- 6) Resincronizar secuencias (los ids entraron a mano)
SELECT setval(pg_get_serial_sequence('usuario',   'id'), (SELECT COALESCE(MAX(id), 1) FROM usuario));
SELECT setval(pg_get_serial_sequence('cuentas',   'id'), (SELECT COALESCE(MAX(id), 1) FROM cuentas));
SELECT setval(pg_get_serial_sequence('perfil',    'id'), (SELECT COALESCE(MAX(id), 1) FROM perfil));
SELECT setval(pg_get_serial_sequence('categoria', 'id'), (SELECT COALESCE(MAX(id), 1) FROM categoria));
SELECT setval(pg_get_serial_sequence('movimiento','id'), (SELECT COALESCE(MAX(id), 1) FROM movimiento));