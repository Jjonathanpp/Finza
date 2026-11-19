CREATE TABLE metas_ahorro (
    id BIGSERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    monto_objetivo NUMERIC(12, 2) NOT NULL CHECK (monto_objetivo > 0),
    monto_actual NUMERIC(12, 2) NOT NULL DEFAULT 0.00 CHECK (monto_actual >= 0),
    fecha_limite DATE,
    
    -- Relaciones (Claves ajenas)
    perfil_id BIGINT REFERENCES perfil(id) ON DELETE CASCADE,
    cuenta_compartida_id BIGINT REFERENCES cuentas_compartidas(id) ON DELETE CASCADE,
    
    fecha_creacion TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Restricción: La meta debe pertenecer a un perfil personal O a una cuenta compartida, nunca a ambos a la vez
    CONSTRAINT chk_propietario_meta_ahorro CHECK (
        (perfil_id IS NOT NULL AND cuenta_compartida_id IS NULL) OR 
        (perfil_id IS NULL AND cuenta_compartida_id IS NOT NULL)
    )
);

-- Índices para mejorar el rendimiento de búsqueda por propietario
CREATE INDEX idx_metas_ahorro_perfil ON metas_ahorro(perfil_id) WHERE perfil_id IS NOT NULL;
CREATE INDEX idx_metas_ahorro_cuenta_compartida ON metas_ahorro(cuenta_compartida_id) WHERE cuenta_compartida_id IS NOT NULL;