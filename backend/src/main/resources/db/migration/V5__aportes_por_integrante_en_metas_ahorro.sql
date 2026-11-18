ALTER TABLE metas_ahorro
    ADD COLUMN monto_aportes_sin_detalle NUMERIC(12, 2) NOT NULL DEFAULT 0.00
        CHECK (monto_aportes_sin_detalle >= 0);

-- Aportes de metas compartidas anteriores a este cambio no identificaban a quien los hizo.
UPDATE metas_ahorro
SET monto_aportes_sin_detalle = monto_actual
WHERE cuenta_compartida_id IS NOT NULL
  AND monto_actual > 0;

CREATE TABLE metas_ahorro_aportes (
    id BIGSERIAL PRIMARY KEY,
    meta_id BIGINT NOT NULL REFERENCES metas_ahorro(id) ON DELETE CASCADE,
    perfil_id BIGINT REFERENCES perfil(id) ON DELETE SET NULL,
    monto NUMERIC(12, 2) NOT NULL CHECK (monto > 0),
    fecha_aporte TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_metas_ahorro_aportes_meta_perfil
    ON metas_ahorro_aportes(meta_id, perfil_id);

-- En metas personales históricas, el perfil dueño sí permite atribuir el saldo existente.
INSERT INTO metas_ahorro_aportes (meta_id, perfil_id, monto)
SELECT id, perfil_id, monto_actual
FROM metas_ahorro
WHERE perfil_id IS NOT NULL
  AND monto_actual > 0;
