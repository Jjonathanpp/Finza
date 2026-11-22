-- T-15.3.1: Registrar el usuario responsable de cada aporte en metas de ahorro.
-- Permite conservar trazabilidad aunque el perfil abandone la cuenta compartida.
ALTER TABLE metas_ahorro_aportes
    ADD COLUMN usuario_id BIGINT REFERENCES usuario(id) ON DELETE SET NULL;

UPDATE metas_ahorro_aportes a
SET usuario_id = c.usuario_id
FROM perfil p
JOIN cuentas c ON p.cuenta_id = c.id
WHERE a.perfil_id = p.id
  AND a.usuario_id IS NULL;

CREATE INDEX idx_metas_ahorro_aportes_usuario
    ON metas_ahorro_aportes(usuario_id)
    WHERE usuario_id IS NOT NULL;