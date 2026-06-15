-- =====================================================================
-- Verificacion "a ver si es verdad" del embudo del flujo
-- Precalifica_Represtamo, contra lo que la DIAGNOSTICA guardo.
-- Entorno: QA02. Solo lectura. Ejecutar cada query con F9 (Data Grid).
--
-- Query 1: lee el embudo PERSISTIDO (lo que se inserto en la prueba,
--          ultima ejecucion). Rapido (solo lee la tabla de tracking).
-- Query 2: RECALCULA en vivo los filtros BARATOS del cursor (los de
--          alto volumen: tipo/periodo/DE08/carga/mora/SIB/capital/empresa).
--          Sin garantia/PEP/lista negra (esas son las lentas). Rapido.
-- Query 3: MUESTRA de hasta 100 creditos que un filtro barato descarta,
--          con el valor real de DE08, para validar a mano.
--
-- Nota: Query 1 es el estado capturado en la corrida; Query 2/3 miden
-- datos VIGENTES ahora. Pueden diferir un poco por datos vivos, pero el
-- orden de magnitud y donde cae el grueso del volumen deben coincidir.
-- =====================================================================

--------------------------------------------------------------------------------
-- Query 0 (F9): embudo PERSISTIDO de los 5 procedimientos (ultima ejecucion).
--   Lo mismo que la Query 1 pero para TODOS los flujos, agrupado por
--   procedimiento. Asi se ve, en la tabla de tracking, el desglose por
--   filtro de cada procedure.
--------------------------------------------------------------------------------
SELECT f.flujo,
       f.fase,
       f.orden_filtro,
       f.codigo_filtro,
       f.descripcion,
       f.candidatos_antes,
       f.candidatos_pasan,
       f.candidatos_descartados
  FROM PR.PR_JOB_PRECALIFICA_FILTRO_TRACK f
 WHERE f.tipo_medicion = 'DIAGNOSTICA'
   AND f.id_ejecucion = (SELECT id_ejecucion
                           FROM (SELECT id_ejecucion
                                   FROM PR.PR_JOB_PRECALIFICA_TRACK
                                  WHERE id_paso = 0
                                  ORDER BY fecha_inicio DESC)
                          WHERE ROWNUM = 1)
 ORDER BY f.flujo, f.orden_filtro;

--------------------------------------------------------------------------------
-- Query 1 (F9): embudo PERSISTIDO del flujo Represtamo (ultima ejecucion)
--------------------------------------------------------------------------------
SELECT f.fase,
       f.orden_filtro,
       f.codigo_filtro,
       f.descripcion,
       f.candidatos_antes,
       f.candidatos_pasan,
       f.candidatos_descartados
  FROM PR.PR_JOB_PRECALIFICA_FILTRO_TRACK f
 WHERE f.tipo_medicion = 'DIAGNOSTICA'
   AND f.flujo = 'Precalifica_Represtamo'
   AND f.id_ejecucion = (SELECT id_ejecucion
                           FROM (SELECT id_ejecucion
                                   FROM PR.PR_JOB_PRECALIFICA_TRACK
                                  WHERE id_paso = 0
                                  ORDER BY fecha_inicio DESC)
                          WHERE ROWNUM = 1)
 ORDER BY f.orden_filtro;

--------------------------------------------------------------------------------
-- Query 2 (F9): recalculo EN VIVO del embudo barato del cursor
--------------------------------------------------------------------------------
WITH params AS (
    SELECT (SELECT MAX(p.fecha_corte) FROM PA.PA_DETALLADO_DE08 p WHERE p.fuente = 'PR') fecha_corte,
           PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO empresa,
           TO_NUMBER(PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('PRECAL_MORA_MAYOR_PR')) mora_max,
           TO_NUMBER(PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('CAPITAL_PAGADO')) capital_pagado
      FROM dual
),
base AS (
    SELECT a.no_credito, a.codigo_cliente, a.codigo_empresa, a.tipo_credito,
           a.codigo_periodo_cuota,
           b.dias_atraso, b.califica_cliente, b.mto_balance_capital,
           b.monto_desembolsado, b.monto_credito
      FROM PR.PR_CREDITOS a
      CROSS JOIN params p
      JOIN PA.PA_DETALLADO_DE08 b
        ON b.no_credito = a.no_credito
       AND b.fecha_corte = p.fecha_corte
       AND b.fuente = 'PR'
       AND b.tipo_credito = a.tipo_credito
),
f1_tipo AS (
    SELECT b.* FROM base b
     WHERE EXISTS (SELECT 1 FROM PR.PR_TIPO_CREDITO_REPRESTAMO c WHERE c.tipo_credito = b.tipo_credito)
),
f2_periodo AS (
    SELECT b.* FROM f1_tipo b
     WHERE EXISTS (SELECT 1 FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('PERIODOS_CUOTA')) s WHERE s.column_value = b.codigo_periodo_cuota)
        OR NOT EXISTS (SELECT 1 FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('PERIODOS_CUOTA')) s)
),
f3_carga AS (
    SELECT b.* FROM f2_periodo b
     WHERE EXISTS (SELECT 1 FROM PR.PR_TIPO_CREDITO_REPRESTAMO c WHERE c.tipo_credito = b.tipo_credito AND c.carga = 'S')
),
f4_mora AS (
    SELECT b.* FROM f3_carga b CROSS JOIN params p WHERE b.dias_atraso <= p.mora_max
),
f5_sib AS (
    SELECT b.* FROM f4_mora b
     WHERE b.califica_cliente IN (SELECT column_value FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('CLASIFICACION_SIB')))
),
f6_capital AS (
    SELECT b.* FROM f5_sib b CROSS JOIN params p
     WHERE NVL(CASE WHEN b.monto_desembolsado = 0 THEN b.monto_credito ELSE b.monto_desembolsado END, 0) <> 0
       AND ((b.mto_balance_capital / CASE WHEN b.monto_desembolsado = 0 THEN b.monto_credito ELSE b.monto_desembolsado END) * 100)
            <= 100 - p.capital_pagado
),
f7_empresa AS (
    SELECT b.* FROM f6_capital b CROSS JOIN params p WHERE b.codigo_empresa = p.empresa
)
SELECT 0 orden, 'BASE: PR_CREDITOS x DE08 (corte/fuente/tipo)' filtro, (SELECT COUNT(*) FROM base) pasan,
       NULL descartados FROM dual UNION ALL
SELECT 1, 'TIPO_CREDITO en PR_TIPO_CREDITO_REPRESTAMO', (SELECT COUNT(*) FROM f1_tipo),
       (SELECT COUNT(*) FROM base) - (SELECT COUNT(*) FROM f1_tipo) FROM dual UNION ALL
SELECT 2, 'PERIODOS_CUOTA permitido', (SELECT COUNT(*) FROM f2_periodo),
       (SELECT COUNT(*) FROM f1_tipo) - (SELECT COUNT(*) FROM f2_periodo) FROM dual UNION ALL
SELECT 3, 'CARGA = S', (SELECT COUNT(*) FROM f3_carga),
       (SELECT COUNT(*) FROM f2_periodo) - (SELECT COUNT(*) FROM f3_carga) FROM dual UNION ALL
SELECT 4, 'DIAS_ATRASO <= PRECAL_MORA_MAYOR_PR', (SELECT COUNT(*) FROM f4_mora),
       (SELECT COUNT(*) FROM f3_carga) - (SELECT COUNT(*) FROM f4_mora) FROM dual UNION ALL
SELECT 5, 'CALIFICA_CLIENTE en CLASIFICACION_SIB', (SELECT COUNT(*) FROM f5_sib),
       (SELECT COUNT(*) FROM f4_mora) - (SELECT COUNT(*) FROM f5_sib) FROM dual UNION ALL
SELECT 6, 'CAPITAL_PAGADO cumple parametro', (SELECT COUNT(*) FROM f6_capital),
       (SELECT COUNT(*) FROM f5_sib) - (SELECT COUNT(*) FROM f6_capital) FROM dual UNION ALL
SELECT 7, 'CODIGO_EMPRESA = empresa', (SELECT COUNT(*) FROM f7_empresa),
       (SELECT COUNT(*) FROM f6_capital) - (SELECT COUNT(*) FROM f7_empresa) FROM dual
ORDER BY 1;

--------------------------------------------------------------------------------
-- Query 3 (F9): muestra de hasta 100 creditos descartados por un filtro barato,
--               con el valor real de DE08 para validar a mano.
--------------------------------------------------------------------------------
WITH params AS (
    SELECT (SELECT MAX(p.fecha_corte) FROM PA.PA_DETALLADO_DE08 p WHERE p.fuente = 'PR') fecha_corte,
           TO_NUMBER(PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('PRECAL_MORA_MAYOR_PR')) mora_max,
           TO_NUMBER(PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('CAPITAL_PAGADO')) capital_pagado
      FROM dual
),
cand AS (
    SELECT a.no_credito, a.codigo_cliente, a.tipo_credito,
           b.dias_atraso, b.califica_cliente,
           CASE WHEN NVL(CASE WHEN b.monto_desembolsado = 0 THEN b.monto_credito ELSE b.monto_desembolsado END, 0) = 0
                THEN NULL
                ELSE ROUND((b.mto_balance_capital / CASE WHEN b.monto_desembolsado = 0 THEN b.monto_credito ELSE b.monto_desembolsado END) * 100, 2)
           END pct_balance_capital,
           p.mora_max, p.capital_pagado
      FROM PR.PR_CREDITOS a
      CROSS JOIN params p
      JOIN PA.PA_DETALLADO_DE08 b
        ON b.no_credito = a.no_credito
       AND b.fecha_corte = p.fecha_corte
       AND b.fuente = 'PR'
       AND b.tipo_credito = a.tipo_credito
     WHERE EXISTS (SELECT 1 FROM PR.PR_TIPO_CREDITO_REPRESTAMO c WHERE c.tipo_credito = a.tipo_credito AND c.carga = 'S')
),
clasif AS (
    SELECT cand.*,
           CASE
             WHEN dias_atraso > mora_max THEN 'MORA: dias_atraso ' || dias_atraso || ' > ' || mora_max
             WHEN califica_cliente NOT IN (SELECT column_value FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('CLASIFICACION_SIB')))
                  THEN 'CLASIF_SIB: ' || NVL(califica_cliente, 'NULA') || ' no permitida'
             WHEN pct_balance_capital IS NULL OR pct_balance_capital > 100 - capital_pagado
                  THEN 'CAPITAL: ' || NVL(TO_CHAR(pct_balance_capital), 's/d') || '% balance > ' || (100 - capital_pagado) || '%'
             ELSE 'PASA LOS 3 FILTROS BARATOS'
           END motivo_descarte
      FROM cand
)
SELECT *
  FROM (
        SELECT motivo_descarte, no_credito, codigo_cliente, tipo_credito,
               dias_atraso, califica_cliente, pct_balance_capital
          FROM clasif
         WHERE motivo_descarte <> 'PASA LOS 3 FILTROS BARATOS'
         ORDER BY motivo_descarte, no_credito
       )
 WHERE ROWNUM <= 100;
