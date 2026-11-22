ALTER TABLE categoria
    DROP CONSTRAINT IF EXISTS categoria_tipo_categoria_predefinida_check;

ALTER TABLE categoria
    ADD CONSTRAINT categoria_tipo_categoria_predefinida_check
        CHECK (tipo_categoria_predefinida IN ('INGRESO', 'EGRESO', 'AMBOS'));

INSERT INTO categoria (cuenta_id, cuenta_compartida_id, nombre, color, es_predefinida, tipo_categoria_predefinida)
SELECT NULL, NULL, 'Meta Ahorro', '#14B8A6', TRUE, 'AMBOS'
WHERE NOT EXISTS (
    SELECT 1
    FROM categoria
    WHERE cuenta_id IS NULL
      AND cuenta_compartida_id IS NULL
      AND LOWER(TRIM(nombre)) = LOWER('Meta Ahorro')
      AND tipo_categoria_predefinida = 'AMBOS'
);
