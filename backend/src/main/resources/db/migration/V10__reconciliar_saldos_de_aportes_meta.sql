-- Mantiene el desglose de aportes alineado con el saldo real después de retiros
-- anteriores que solo actualizaron metas_ahorro.monto_actual.
WITH aportes_ordenados AS (
    SELECT a.id,
           m.monto_actual,
           COALESCE(
               SUM(a.monto) OVER (
                   PARTITION BY a.meta_id
                   ORDER BY a.id DESC
                   ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
               ),
               0
           ) AS monto_anterior
    FROM metas_ahorro_aportes a
    JOIN metas_ahorro m ON m.id = a.meta_id
)
DELETE FROM metas_ahorro_aportes a
USING aportes_ordenados orden
WHERE a.id = orden.id
  AND orden.monto_anterior >= orden.monto_actual;

WITH aportes_ordenados AS (
    SELECT a.id,
           a.monto,
           m.monto_actual,
           COALESCE(
               SUM(a.monto) OVER (
                   PARTITION BY a.meta_id
                   ORDER BY a.id DESC
                   ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
               ),
               0
           ) AS monto_anterior
    FROM metas_ahorro_aportes a
    JOIN metas_ahorro m ON m.id = a.meta_id
),
aportes_ajustados AS (
    SELECT id,
           LEAST(monto, monto_actual - monto_anterior) AS monto
    FROM aportes_ordenados
)
UPDATE metas_ahorro_aportes a
SET monto = ajustado.monto
FROM aportes_ajustados ajustado
WHERE a.id = ajustado.id
  AND a.monto <> ajustado.monto;

-- Los saldos históricos que ya no tenían un desglose por integrante quedan
-- identificados como aportes sin atribución, en vez de perderse del resumen.
INSERT INTO metas_ahorro_aportes (meta_id, perfil_id, monto)
SELECT m.id,
       NULL,
       m.monto_actual - COALESCE(SUM(a.monto), 0)
FROM metas_ahorro m
LEFT JOIN metas_ahorro_aportes a ON a.meta_id = m.id
GROUP BY m.id, m.monto_actual
HAVING m.monto_actual > COALESCE(SUM(a.monto), 0);
