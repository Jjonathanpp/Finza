ALTER TABLE movimiento ADD COLUMN importado_por BIGINT;

CREATE INDEX idx_mov_importado_por ON movimiento(importado_por);
