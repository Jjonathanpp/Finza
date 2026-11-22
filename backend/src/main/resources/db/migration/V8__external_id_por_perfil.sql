-- Elimina la restricción que impedía repetir el external_id en toda la tabla
ALTER TABLE movimiento DROP CONSTRAINT IF EXISTS ukqf5i4w08xveef72si69043731;

-- Nueva restricción: el external_id es único por perfil (permite tener el mismo movimiento en personal y compartida)
ALTER TABLE movimiento ADD CONSTRAINT uk_movimiento_external_id_perfil UNIQUE (external_id, perfil_id);