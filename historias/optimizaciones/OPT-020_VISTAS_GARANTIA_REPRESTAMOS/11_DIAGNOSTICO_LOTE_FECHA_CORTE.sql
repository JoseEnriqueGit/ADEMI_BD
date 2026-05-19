-- =====================================================================
-- OPT-020 - Diagnostico de volumen por FECHA_CORTE
-- Entorno objetivo: QA02 / QADEMI02_19C
--
-- Objetivo:
--   Validar por que LOTE_DE_CARAGA_REPRESTAMO = 20000 termina dejando
--   alrededor de 3000 registros RE, e identificar si otra FECHA_CORTE
--   aumenta el universo elegible.
--
-- Uso:
--   1. Cambiar P_FECHA_CORTE.
--   2. Ejecutar para 12/11/2025 y 31/07/2025.
--   3. Enviar la salida completa para comparar filtros.
-- =====================================================================

DEFINE P_FECHA_CORTE = '31/07/2025';

SET LINESIZE 220
SET PAGESIZE 500

PROMPT
PROMPT Q01 - Parametros clave
PROMPT

SELECT codigo_parametro, valor
  FROM PA.PA_PARAMETROS_MVP
 WHERE codigo_mvp = 'REPRESTAMOS'
   AND codigo_parametro IN (
       'LOTE_DE_CARAGA_REPRESTAMO',
       'PRECAL_MORA_MAYOR_PR',
       'CAPITAL_PAGADO',
       'MESES_MAX_X_DESEMBOLSO',
       'PERSONA_FISICA',
       'CLIENTES_A_SOLA_FIRMA'
   )
 ORDER BY codigo_parametro;

PROMPT
PROMPT Q02 - Fechas de corte disponibles
PROMPT

SELECT fecha_corte,
       COUNT(*) total,
       COUNT(DISTINCT no_credito) creditos,
       COUNT(DISTINCT codigo_cliente) clientes
  FROM PA.PA_DETALLADO_DE08
 WHERE fuente = 'PR'
 GROUP BY fecha_corte
 ORDER BY fecha_corte DESC
 FETCH FIRST 20 ROWS ONLY;

PROMPT
PROMPT Q03 - Conteo progresivo de candidatos para &P_FECHA_CORTE
PROMPT

WITH p AS (
    SELECT TO_DATE('&P_FECHA_CORTE', 'DD/MM/YYYY') fecha_corte,
           TO_NUMBER(PR.PR_PKG_REPRESTAMOS.f_obt_parametro_represtamo('LOTE_DE_CARAGA_REPRESTAMO')) lote
      FROM dual
),
s01 AS (
    SELECT a.codigo_empresa, a.no_credito, a.codigo_cliente, a.tipo_credito,
           a.codigo_periodo_cuota, b.dias_atraso, b.califica_cliente,
           b.mto_balance_capital, b.monto_desembolsado, b.monto_credito,
           c.carga
      FROM PR.PR_CREDITOS a
      JOIN PA.PA_DETALLADO_DE08 b
        ON b.no_credito = a.no_credito
       AND b.tipo_credito = a.tipo_credito
       AND b.fuente = 'PR'
       AND b.fecha_corte = (SELECT fecha_corte FROM p)
      JOIN PR.PR_TIPO_CREDITO_REPRESTAMO c
        ON c.tipo_credito = a.tipo_credito
),
s02 AS (
    SELECT *
      FROM s01
     WHERE codigo_empresa = PR.PR_PKG_REPRESTAMOS.f_obt_empresa_represtamo
       AND carga = 'S'
),
s03 AS (
    SELECT *
      FROM s02 a
     WHERE (
            EXISTS (
                SELECT 1
                  FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('PERIODOS_CUOTA')) subq
                 WHERE a.codigo_periodo_cuota = subq.column_value
            )
            OR NOT EXISTS (
                SELECT 1
                  FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('PERIODOS_CUOTA')) subq
            )
           )
),
s04 AS (
    SELECT *
      FROM s03 b
     WHERE b.dias_atraso <= PR.PR_PKG_REPRESTAMOS.f_obt_parametro_represtamo('PRECAL_MORA_MAYOR_PR')
       AND b.califica_cliente IN (
           SELECT column_value
             FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('CLASIFICACION_SIB'))
       )
       AND ((b.mto_balance_capital /
             CASE WHEN b.monto_desembolsado = 0 THEN b.monto_credito ELSE b.monto_desembolsado END) * 100)
           <= 100 - TO_NUMBER(PR.PR_PKG_REPRESTAMOS.f_obt_parametro_represtamo('CAPITAL_PAGADO'))
),
s05 AS (
    SELECT *
      FROM s04 a
     WHERE NOT EXISTS (
           SELECT 1
             FROM PR.PR_CREDITOS c
            WHERE c.codigo_empresa = a.codigo_empresa
              AND c.no_credito != a.no_credito
              AND c.codigo_cliente = a.codigo_cliente
              AND c.f_primer_desembolso > ADD_MONTHS(SYSDATE, - PR.PR_PKG_REPRESTAMOS.f_obt_parametro_represtamo('MESES_MAX_X_DESEMBOLSO'))
              AND c.estado IN (
                  SELECT column_value
                    FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('ESTADOS_CREDITOS'))
              )
       )
),
s06 AS (
    SELECT *
      FROM s05 a
     WHERE NOT EXISTS (
           SELECT 1
             FROM PR.PR_CREDITOS c
            WHERE c.codigo_empresa = a.codigo_empresa
              AND c.no_credito != a.no_credito
              AND c.codigo_cliente = a.codigo_cliente
              AND c.estado = 'E'
       )
),
s07 AS (
    SELECT *
      FROM s06 a
     WHERE EXISTS (
           SELECT 1
             FROM PA.PERSONAS pf
            WHERE pf.cod_persona = CAST(a.codigo_cliente AS VARCHAR2(15))
              AND pf.es_fisica = PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('PERSONA_FISICA')
       )
       AND EXISTS (
           SELECT 1
             FROM PA.ID_PERSONAS ip
            WHERE ip.cod_persona = CAST(a.codigo_cliente AS VARCHAR2(15))
              AND ip.cod_pais IN (
                  SELECT column_value
                    FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('NACIONALIDAD'))
              )
              AND ip.cod_tipo_id IN (
                  SELECT column_value
                    FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('TIPO_DOCUMENTO'))
              )
       )
),
s08 AS (
    SELECT *
      FROM s07 a
     WHERE NOT EXISTS (
           SELECT 1
             FROM PR.PR_REPRESTAMOS r
            WHERE r.codigo_empresa = a.codigo_empresa
              AND r.no_credito = a.no_credito
              AND r.estado IN (
                  SELECT column_value
                    FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('ESTADOS_NO_REPROCESO'))
              )
       )
),
s09 AS (
    SELECT *
      FROM s08 a
     WHERE NOT EXISTS (
           SELECT 1
             FROM PR.PR_AVAL_REPRE_X_CREDITO av
            WHERE av.codigo_empresa = a.codigo_empresa
              AND av.no_credito = a.no_credito
              AND av.codigo_aval_repre != a.codigo_cliente
              AND PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('CLIENTES_A_SOLA_FIRMA') = 'S'
       )
),
s10 AS (
    SELECT *
      FROM s09 a
     WHERE NOT EXISTS (
           SELECT 1
             FROM PR.V_REPRE_CREDITOS_GAR vg
            WHERE vg.codigo_empresa = PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
              AND vg.no_credito = a.no_credito
       )
),
s11 AS (
    SELECT *
      FROM s10 a
     WHERE PR.PR_PKG_REPRESTAMOS.F_Validar_Listas_PEP(1, a.codigo_cliente) = 0
       AND PR.PR_PKG_REPRESTAMOS.F_Validar_Lista_NEGRA(1, a.codigo_cliente) = 0
)
SELECT '01_JOIN_INICIAL' paso, COUNT(*) total FROM s01 UNION ALL
SELECT '02_EMPRESA_CARGA', COUNT(*) FROM s02 UNION ALL
SELECT '03_PERIODOS_CUOTA', COUNT(*) FROM s03 UNION ALL
SELECT '04_MORA_CLASIF_CAPITAL', COUNT(*) FROM s04 UNION ALL
SELECT '05_SIN_DESEMBOLSO_RECIENTE', COUNT(*) FROM s05 UNION ALL
SELECT '06_SIN_ESTADO_E', COUNT(*) FROM s06 UNION ALL
SELECT '07_PERSONA_NACIONALIDAD', COUNT(*) FROM s07 UNION ALL
SELECT '08_SIN_REPROCESO', COUNT(*) FROM s08 UNION ALL
SELECT '09_SIN_AVAL_NO_SOLAFIRMA', COUNT(*) FROM s09 UNION ALL
SELECT '10_SIN_GARANTE', COUNT(*) FROM s10 UNION ALL
SELECT '11_SIN_PEP_NEGRA', COUNT(*) FROM s11 UNION ALL
SELECT '12_FINAL_CON_LOTE_' || (SELECT lote FROM p), LEAST(COUNT(*), (SELECT lote FROM p)) FROM s11;
