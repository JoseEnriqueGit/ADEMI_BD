/*
  Produccion - Validacion de equivalencia:
  Cursor original CREDITOS_PROCESAR vs tracker FAST.

  Uso:
  - Ejecutar cada bloque por separado en Toad/F9.
  - Seleccionar desde WITH params AS hasta el ORDER BY/SELECT final del bloque.
  - Los bloques no tienen terminador final para evitar ORA-00911 invalid character.

  Regla de lectura:
  - La equivalencia confiable se valida SIN lote, porque el cursor usa ROWNUM sin ORDER BY.
  - Con lote se compara conteo; las filas exactas pueden variar por plan de ejecucion.
*/

--------------------------------------------------------------------------------
-- 1) Parametros que gobiernan ambas consultas.
--------------------------------------------------------------------------------
WITH params AS (
    SELECT (SELECT MAX(p.fecha_corte)
              FROM PA.PA_DETALLADO_DE08 p
             WHERE p.fuente = 'PR') fecha_corte,
           TO_NUMBER(PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('LOTE_DE_CARAGA_REPRESTAMO')) lote,
           PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO empresa,
           TO_NUMBER(PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('PRECAL_MORA_MAYOR_PR')) mora_max,
           TO_NUMBER(PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('CAPITAL_PAGADO')) capital_pagado,
           TO_NUMBER(PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('MESES_MAX_X_DESEMBOLSO')) meses_desembolso,
           PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('PERSONA_FISICA') persona_fisica,
           PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('CLIENTES_A_SOLA_FIRMA') clientes_a_sola_firma
      FROM dual
)
SELECT p.fecha_corte,
       p.lote,
       p.empresa,
       p.mora_max,
       p.capital_pagado,
       p.meses_desembolso,
       p.persona_fisica,
       p.clientes_a_sola_firma,
       (SELECT COUNT(*)
          FROM PA.PA_DETALLADO_DE08 d
         WHERE d.fuente = 'PR'
           AND d.fecha_corte = p.fecha_corte) registros_de08_fecha
  FROM params p

--------------------------------------------------------------------------------
-- 1.1) Control del denominador del calculo CAPITAL_PAGADO.
--      Debe dar 0 para que el guard NVL(..., 0) <> 0 no cambie resultados.
--------------------------------------------------------------------------------
WITH params AS (
    SELECT (SELECT MAX(p.fecha_corte)
              FROM PA.PA_DETALLADO_DE08 p
             WHERE p.fuente = 'PR') fecha_corte,
           TO_NUMBER(PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('PRECAL_MORA_MAYOR_PR')) mora_max
      FROM dual
)
SELECT COUNT(*) candidatos_denominador_cero
  FROM PR.PR_CREDITOS a
  JOIN PR.PR_TIPO_CREDITO_REPRESTAMO c
    ON c.tipo_credito = a.tipo_credito
  CROSS JOIN params p
  JOIN PA.PA_DETALLADO_DE08 b
    ON b.tipo_credito = c.tipo_credito
   AND b.fecha_corte = p.fecha_corte
   AND b.no_credito = a.no_credito
   AND b.fuente = 'PR'
 WHERE c.carga = 'S'
   AND b.dias_atraso <= p.mora_max
   AND b.califica_cliente IN (
          SELECT column_value
            FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('CLASIFICACION_SIB'))
       )
   AND NVL(CASE WHEN b.monto_desembolsado = 0 THEN b.monto_credito ELSE b.monto_desembolsado END, 0) = 0

--------------------------------------------------------------------------------
-- 2) Conteo y diferencias agrupadas SIN lote.
--    Para equivalencia, ORIGINAL_MINUS_FAST y FAST_MINUS_ORIGINAL deben dar 0.
--------------------------------------------------------------------------------
WITH params AS (
    SELECT (SELECT MAX(p.fecha_corte)
              FROM PA.PA_DETALLADO_DE08 p
             WHERE p.fuente = 'PR') fecha_corte,
           TO_NUMBER(PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('LOTE_DE_CARAGA_REPRESTAMO')) lote,
           PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO empresa,
           TO_NUMBER(PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('PRECAL_MORA_MAYOR_PR')) mora_max,
           TO_NUMBER(PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('CAPITAL_PAGADO')) capital_pagado,
           TO_NUMBER(PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('MESES_MAX_X_DESEMBOLSO')) meses_desembolso,
           PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('PERSONA_FISICA') persona_fisica,
           PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('CLIENTES_A_SOLA_FIRMA') clientes_a_sola_firma
      FROM dual
),
original_sin_lote AS (
    SELECT a.codigo_empresa,
           a.codigo_cliente,
           a.no_credito,
           p.fecha_corte,
           a.tipo_credito,
           a.codigo_periodo_cuota,
           b.dias_atraso,
           b.califica_cliente,
           b.mto_balance_capital,
           b.monto_desembolsado,
           b.monto_credito,
           b.monto_desembolsado mto_aprobado
      FROM PR.PR_CREDITOS a
      JOIN PR.PR_TIPO_CREDITO_REPRESTAMO c
        ON c.tipo_credito = a.tipo_credito
      CROSS JOIN params p
      JOIN PA.PA_DETALLADO_DE08 b
        ON b.tipo_credito = c.tipo_credito
       AND b.fecha_corte = p.fecha_corte
       AND b.no_credito = a.no_credito
       AND b.fuente = 'PR'
     WHERE (
              EXISTS (
                    SELECT 1
                      FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('PERIODOS_CUOTA')) subq
                     WHERE a.codigo_periodo_cuota = subq.column_value
              )
              OR NOT EXISTS (
                    SELECT 1
                      FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('PERIODOS_CUOTA')) subq
              )
           )
       AND c.carga = 'S'
       AND b.dias_atraso <= p.mora_max
       AND b.califica_cliente IN (
              SELECT column_value
                FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('CLASIFICACION_SIB'))
           )
       AND NVL(CASE WHEN b.monto_desembolsado = 0 THEN b.monto_credito ELSE b.monto_desembolsado END, 0) <> 0
       AND ((b.mto_balance_capital /
            CASE WHEN b.monto_desembolsado = 0 THEN b.monto_credito ELSE b.monto_desembolsado END) * 100)
            <= 100 - p.capital_pagado
       AND a.codigo_empresa = p.empresa
       AND NOT EXISTS (
              SELECT 1
                FROM PR.PR_CREDITOS pc
               WHERE pc.codigo_empresa = a.codigo_empresa
                 AND pc.no_credito != a.no_credito
                 AND pc.codigo_cliente = a.codigo_cliente
                 AND pc.f_primer_desembolso > ADD_MONTHS(SYSDATE, - p.meses_desembolso)
                 AND pc.estado IN (
                      SELECT column_value
                        FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('ESTADOS_CREDITOS'))
                 )
           )
       AND NOT EXISTS (
              SELECT 1
                FROM PR.PR_CREDITOS pc
               WHERE pc.codigo_empresa = a.codigo_empresa
                 AND pc.no_credito != a.no_credito
                 AND pc.codigo_cliente = a.codigo_cliente
                 AND pc.estado = 'E'
           )
       AND EXISTS (
              SELECT 1
                FROM PA.PERSONAS per
               WHERE per.cod_persona = CAST(a.codigo_cliente AS VARCHAR2(15))
                 AND per.es_fisica = p.persona_fisica
           )
       AND EXISTS (
              SELECT 1
                FROM PA.ID_PERSONAS idp
               WHERE idp.cod_persona = CAST(a.codigo_cliente AS VARCHAR2(15))
                 AND idp.cod_pais IN (
                      SELECT column_value
                        FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('NACIONALIDAD'))
                 )
                 AND idp.cod_tipo_id IN (
                      SELECT column_value
                        FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('TIPO_DOCUMENTO'))
                 )
           )
       AND NOT EXISTS (
              SELECT 1
                FROM PR.PR_REPRESTAMOS r
               WHERE r.codigo_empresa = a.codigo_empresa
                 AND r.no_credito = a.no_credito
                 AND r.estado IN (
                      SELECT column_value
                        FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('ESTADOS_NO_REPROCESO'))
                 )
           )
       AND NOT EXISTS (
              SELECT 1
                FROM PR.PR_CREDITOS a1
                JOIN PR.PR_AVAL_REPRE_X_CREDITO aval
                  ON aval.codigo_empresa = a1.codigo_empresa
                 AND aval.no_credito = a1.no_credito
               WHERE a1.codigo_empresa = 1
                 AND a1.no_credito = a.no_credito
                 AND aval.codigo_aval_repre != a1.codigo_cliente
                 AND p.clientes_a_sola_firma = 'S'
           )
       AND PR.PR_PKG_REPRESTAMOS.F_TIENE_GARANTIA(a.no_credito) = 0
       AND PR.PR_PKG_REPRESTAMOS.F_VALIDAR_LISTAS_PEP(1, a.codigo_cliente) = 0
       AND PR.PR_PKG_REPRESTAMOS.F_VALIDAR_LISTA_NEGRA(1, a.codigo_cliente) = 0
),
s00 AS (
    SELECT a.*
      FROM PR.PR_CREDITOS a
),
s01 AS (
    SELECT a.*, c.carga carga_represtamo
      FROM s00 a
      JOIN PR.PR_TIPO_CREDITO_REPRESTAMO c
        ON c.tipo_credito = a.tipo_credito
),
s02 AS (
    SELECT a.*
      FROM s01 a
     WHERE EXISTS (
              SELECT 1
                FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('PERIODOS_CUOTA')) subq
               WHERE subq.column_value = a.codigo_periodo_cuota
           )
        OR NOT EXISTS (
              SELECT 1
                FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('PERIODOS_CUOTA')) subq
           )
),
s03 AS (
    SELECT a.codigo_empresa,
           a.codigo_cliente,
           a.no_credito,
           a.tipo_credito,
           a.codigo_periodo_cuota,
           p.fecha_corte,
           b.dias_atraso,
           b.califica_cliente,
           b.mto_balance_capital,
           b.monto_desembolsado,
           b.monto_credito,
           b.monto_desembolsado mto_aprobado,
           a.carga_represtamo
      FROM s02 a
      CROSS JOIN params p
      JOIN PA.PA_DETALLADO_DE08 b
        ON b.tipo_credito = a.tipo_credito
       AND b.fecha_corte = p.fecha_corte
       AND b.no_credito = a.no_credito
       AND b.fuente = 'PR'
),
s04 AS (
    SELECT a.*
      FROM s03 a
     WHERE a.carga_represtamo = 'S'
),
s05 AS (
    SELECT a.*
      FROM s04 a
      CROSS JOIN params p
     WHERE a.dias_atraso <= p.mora_max
),
s06 AS (
    SELECT a.*
      FROM s05 a
     WHERE a.califica_cliente IN (
              SELECT column_value
                FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('CLASIFICACION_SIB'))
           )
),
s07 AS (
    SELECT a.*
      FROM s06 a
      CROSS JOIN params p
     WHERE NVL(CASE WHEN a.monto_desembolsado = 0 THEN a.monto_credito ELSE a.monto_desembolsado END, 0) <> 0
       AND ((a.mto_balance_capital /
            CASE WHEN a.monto_desembolsado = 0 THEN a.monto_credito ELSE a.monto_desembolsado END) * 100)
            <= 100 - p.capital_pagado
),
s08 AS (
    SELECT a.*
      FROM s07 a
      CROSS JOIN params p
     WHERE a.codigo_empresa = p.empresa
),
s09 AS (
    SELECT a.*
      FROM s08 a
      CROSS JOIN params p
     WHERE NOT EXISTS (
              SELECT 1
                FROM PR.PR_CREDITOS pc
               WHERE pc.codigo_empresa = a.codigo_empresa
                 AND pc.no_credito != a.no_credito
                 AND pc.codigo_cliente = a.codigo_cliente
                 AND pc.f_primer_desembolso > ADD_MONTHS(SYSDATE, - p.meses_desembolso)
                 AND pc.estado IN (
                      SELECT column_value
                        FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('ESTADOS_CREDITOS'))
                 )
           )
),
s10 AS (
    SELECT a.*
      FROM s09 a
     WHERE NOT EXISTS (
              SELECT 1
                FROM PR.PR_CREDITOS pc
               WHERE pc.codigo_empresa = a.codigo_empresa
                 AND pc.no_credito != a.no_credito
                 AND pc.codigo_cliente = a.codigo_cliente
                 AND pc.estado = 'E'
           )
),
s11 AS (
    SELECT a.*
      FROM s10 a
      CROSS JOIN params p
     WHERE EXISTS (
              SELECT 1
                FROM PA.PERSONAS per
               WHERE per.cod_persona = CAST(a.codigo_cliente AS VARCHAR2(15))
                 AND per.es_fisica = p.persona_fisica
           )
),
s12 AS (
    SELECT a.*
      FROM s11 a
     WHERE EXISTS (
              SELECT 1
                FROM PA.ID_PERSONAS idp
               WHERE idp.cod_persona = CAST(a.codigo_cliente AS VARCHAR2(15))
                 AND idp.cod_pais IN (
                      SELECT column_value
                        FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('NACIONALIDAD'))
                 )
                 AND idp.cod_tipo_id IN (
                      SELECT column_value
                        FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('TIPO_DOCUMENTO'))
                 )
           )
),
s13 AS (
    SELECT a.*
      FROM s12 a
     WHERE NOT EXISTS (
              SELECT 1
                FROM PR.PR_REPRESTAMOS r
               WHERE r.codigo_empresa = a.codigo_empresa
                 AND r.no_credito = a.no_credito
                 AND r.estado IN (
                      SELECT column_value
                        FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('ESTADOS_NO_REPROCESO'))
                 )
           )
),
s14 AS (
    SELECT a.*
      FROM s13 a
      CROSS JOIN params p
     WHERE NOT EXISTS (
              SELECT 1
                FROM PR.PR_CREDITOS a1
                JOIN PR.PR_AVAL_REPRE_X_CREDITO aval
                  ON aval.codigo_empresa = a1.codigo_empresa
                 AND aval.no_credito = a1.no_credito
               WHERE a1.codigo_empresa = 1
                 AND a1.no_credito = a.no_credito
                 AND aval.codigo_aval_repre != a1.codigo_cliente
                 AND p.clientes_a_sola_firma = 'S'
           )
),
s15 AS (
    SELECT a.*
      FROM s14 a
     WHERE PR.PR_PKG_REPRESTAMOS.F_TIENE_GARANTIA(a.no_credito) = 0
),
s16 AS (
    SELECT a.*
      FROM s15 a
     WHERE PR.PR_PKG_REPRESTAMOS.F_VALIDAR_LISTAS_PEP(1, a.codigo_cliente) = 0
),
fast_sin_lote AS (
    SELECT a.codigo_empresa,
           a.codigo_cliente,
           a.no_credito,
           a.fecha_corte,
           a.tipo_credito,
           a.codigo_periodo_cuota,
           a.dias_atraso,
           a.califica_cliente,
           a.mto_balance_capital,
           a.monto_desembolsado,
           a.monto_credito,
           a.mto_aprobado
      FROM s16 a
     WHERE PR.PR_PKG_REPRESTAMOS.F_VALIDAR_LISTA_NEGRA(1, a.codigo_cliente) = 0
),
original_agg AS (
    SELECT codigo_empresa,
           codigo_cliente,
           no_credito,
           fecha_corte,
           tipo_credito,
           codigo_periodo_cuota,
           dias_atraso,
           califica_cliente,
           mto_balance_capital,
           monto_desembolsado,
           monto_credito,
           mto_aprobado,
           COUNT(*) cantidad
      FROM original_sin_lote
     GROUP BY codigo_empresa,
              codigo_cliente,
              no_credito,
              fecha_corte,
              tipo_credito,
              codigo_periodo_cuota,
              dias_atraso,
              califica_cliente,
              mto_balance_capital,
              monto_desembolsado,
              monto_credito,
              mto_aprobado
),
fast_agg AS (
    SELECT codigo_empresa,
           codigo_cliente,
           no_credito,
           fecha_corte,
           tipo_credito,
           codigo_periodo_cuota,
           dias_atraso,
           califica_cliente,
           mto_balance_capital,
           monto_desembolsado,
           monto_credito,
           mto_aprobado,
           COUNT(*) cantidad
      FROM fast_sin_lote
     GROUP BY codigo_empresa,
              codigo_cliente,
              no_credito,
              fecha_corte,
              tipo_credito,
              codigo_periodo_cuota,
              dias_atraso,
              califica_cliente,
              mto_balance_capital,
              monto_desembolsado,
              monto_credito,
              mto_aprobado
)
SELECT 'ORIGINAL_SIN_LOTE' medicion,
       COUNT(*) filas,
       COUNT(DISTINCT no_credito) creditos,
       COUNT(DISTINCT codigo_cliente) clientes
  FROM original_sin_lote
UNION ALL
SELECT 'FAST_SIN_LOTE',
       COUNT(*),
       COUNT(DISTINCT no_credito),
       COUNT(DISTINCT codigo_cliente)
  FROM fast_sin_lote
UNION ALL
SELECT 'ORIGINAL_MINUS_FAST_AGG',
       COUNT(*),
       CAST(NULL AS NUMBER),
       CAST(NULL AS NUMBER)
  FROM (
        SELECT * FROM original_agg
        MINUS
        SELECT * FROM fast_agg
       )
UNION ALL
SELECT 'FAST_MINUS_ORIGINAL_AGG',
       COUNT(*),
       CAST(NULL AS NUMBER),
       CAST(NULL AS NUMBER)
  FROM (
        SELECT * FROM fast_agg
        MINUS
        SELECT * FROM original_agg
       )

--------------------------------------------------------------------------------
-- 3) Muestra de diferencias SIN lote.
--    Debe devolver cero filas si ambas logicas son equivalentes.
--------------------------------------------------------------------------------
WITH params AS (
    SELECT (SELECT MAX(p.fecha_corte)
              FROM PA.PA_DETALLADO_DE08 p
             WHERE p.fuente = 'PR') fecha_corte,
           PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO empresa,
           TO_NUMBER(PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('PRECAL_MORA_MAYOR_PR')) mora_max,
           TO_NUMBER(PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('CAPITAL_PAGADO')) capital_pagado,
           TO_NUMBER(PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('MESES_MAX_X_DESEMBOLSO')) meses_desembolso,
           PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('PERSONA_FISICA') persona_fisica,
           PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('CLIENTES_A_SOLA_FIRMA') clientes_a_sola_firma
      FROM dual
),
original_sin_lote AS (
    SELECT a.codigo_empresa,
           a.codigo_cliente,
           a.no_credito,
           p.fecha_corte,
           a.tipo_credito,
           a.codigo_periodo_cuota,
           b.dias_atraso,
           b.califica_cliente,
           b.mto_balance_capital,
           b.monto_desembolsado,
           b.monto_credito,
           b.monto_desembolsado mto_aprobado
      FROM PR.PR_CREDITOS a
      JOIN PR.PR_TIPO_CREDITO_REPRESTAMO c
        ON c.tipo_credito = a.tipo_credito
      CROSS JOIN params p
      JOIN PA.PA_DETALLADO_DE08 b
        ON b.tipo_credito = c.tipo_credito
       AND b.fecha_corte = p.fecha_corte
       AND b.no_credito = a.no_credito
       AND b.fuente = 'PR'
     WHERE (
              EXISTS (
                    SELECT 1
                      FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('PERIODOS_CUOTA')) subq
                     WHERE a.codigo_periodo_cuota = subq.column_value
              )
              OR NOT EXISTS (
                    SELECT 1
                      FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('PERIODOS_CUOTA')) subq
              )
           )
       AND c.carga = 'S'
       AND b.dias_atraso <= p.mora_max
       AND b.califica_cliente IN (
              SELECT column_value
                FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('CLASIFICACION_SIB'))
           )
       AND NVL(CASE WHEN b.monto_desembolsado = 0 THEN b.monto_credito ELSE b.monto_desembolsado END, 0) <> 0
       AND ((b.mto_balance_capital /
            CASE WHEN b.monto_desembolsado = 0 THEN b.monto_credito ELSE b.monto_desembolsado END) * 100)
            <= 100 - p.capital_pagado
       AND a.codigo_empresa = p.empresa
       AND NOT EXISTS (
              SELECT 1
                FROM PR.PR_CREDITOS pc
               WHERE pc.codigo_empresa = a.codigo_empresa
                 AND pc.no_credito != a.no_credito
                 AND pc.codigo_cliente = a.codigo_cliente
                 AND pc.f_primer_desembolso > ADD_MONTHS(SYSDATE, - p.meses_desembolso)
                 AND pc.estado IN (
                      SELECT column_value
                        FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('ESTADOS_CREDITOS'))
                 )
           )
       AND NOT EXISTS (
              SELECT 1
                FROM PR.PR_CREDITOS pc
               WHERE pc.codigo_empresa = a.codigo_empresa
                 AND pc.no_credito != a.no_credito
                 AND pc.codigo_cliente = a.codigo_cliente
                 AND pc.estado = 'E'
           )
       AND EXISTS (
              SELECT 1
                FROM PA.PERSONAS per
               WHERE per.cod_persona = CAST(a.codigo_cliente AS VARCHAR2(15))
                 AND per.es_fisica = p.persona_fisica
           )
       AND EXISTS (
              SELECT 1
                FROM PA.ID_PERSONAS idp
               WHERE idp.cod_persona = CAST(a.codigo_cliente AS VARCHAR2(15))
                 AND idp.cod_pais IN (
                      SELECT column_value
                        FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('NACIONALIDAD'))
                 )
                 AND idp.cod_tipo_id IN (
                      SELECT column_value
                        FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('TIPO_DOCUMENTO'))
                 )
           )
       AND NOT EXISTS (
              SELECT 1
                FROM PR.PR_REPRESTAMOS r
               WHERE r.codigo_empresa = a.codigo_empresa
                 AND r.no_credito = a.no_credito
                 AND r.estado IN (
                      SELECT column_value
                        FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('ESTADOS_NO_REPROCESO'))
                 )
           )
       AND NOT EXISTS (
              SELECT 1
                FROM PR.PR_CREDITOS a1
                JOIN PR.PR_AVAL_REPRE_X_CREDITO aval
                  ON aval.codigo_empresa = a1.codigo_empresa
                 AND aval.no_credito = a1.no_credito
               WHERE a1.codigo_empresa = 1
                 AND a1.no_credito = a.no_credito
                 AND aval.codigo_aval_repre != a1.codigo_cliente
                 AND p.clientes_a_sola_firma = 'S'
           )
       AND PR.PR_PKG_REPRESTAMOS.F_TIENE_GARANTIA(a.no_credito) = 0
       AND PR.PR_PKG_REPRESTAMOS.F_VALIDAR_LISTAS_PEP(1, a.codigo_cliente) = 0
       AND PR.PR_PKG_REPRESTAMOS.F_VALIDAR_LISTA_NEGRA(1, a.codigo_cliente) = 0
),
fast_sin_lote AS (
    SELECT a.codigo_empresa,
           a.codigo_cliente,
           a.no_credito,
           p.fecha_corte,
           a.tipo_credito,
           a.codigo_periodo_cuota,
           b.dias_atraso,
           b.califica_cliente,
           b.mto_balance_capital,
           b.monto_desembolsado,
           b.monto_credito,
           b.monto_desembolsado mto_aprobado
      FROM PR.PR_CREDITOS a
      JOIN PR.PR_TIPO_CREDITO_REPRESTAMO c
        ON c.tipo_credito = a.tipo_credito
      CROSS JOIN params p
      JOIN PA.PA_DETALLADO_DE08 b
        ON b.tipo_credito = a.tipo_credito
       AND b.fecha_corte = p.fecha_corte
       AND b.no_credito = a.no_credito
       AND b.fuente = 'PR'
     WHERE (
              EXISTS (
                    SELECT 1
                      FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('PERIODOS_CUOTA')) subq
                     WHERE a.codigo_periodo_cuota = subq.column_value
              )
              OR NOT EXISTS (
                    SELECT 1
                      FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('PERIODOS_CUOTA')) subq
              )
           )
       AND c.carga = 'S'
       AND b.dias_atraso <= p.mora_max
       AND b.califica_cliente IN (
              SELECT column_value
                FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('CLASIFICACION_SIB'))
           )
       AND NVL(CASE WHEN b.monto_desembolsado = 0 THEN b.monto_credito ELSE b.monto_desembolsado END, 0) <> 0
       AND ((b.mto_balance_capital /
            CASE WHEN b.monto_desembolsado = 0 THEN b.monto_credito ELSE b.monto_desembolsado END) * 100)
            <= 100 - p.capital_pagado
       AND a.codigo_empresa = p.empresa
       AND NOT EXISTS (
              SELECT 1
                FROM PR.PR_CREDITOS pc
               WHERE pc.codigo_empresa = a.codigo_empresa
                 AND pc.no_credito != a.no_credito
                 AND pc.codigo_cliente = a.codigo_cliente
                 AND pc.f_primer_desembolso > ADD_MONTHS(SYSDATE, - p.meses_desembolso)
                 AND pc.estado IN (
                      SELECT column_value
                        FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('ESTADOS_CREDITOS'))
                 )
           )
       AND NOT EXISTS (
              SELECT 1
                FROM PR.PR_CREDITOS pc
               WHERE pc.codigo_empresa = a.codigo_empresa
                 AND pc.no_credito != a.no_credito
                 AND pc.codigo_cliente = a.codigo_cliente
                 AND pc.estado = 'E'
           )
       AND EXISTS (
              SELECT 1
                FROM PA.PERSONAS per
               WHERE per.cod_persona = CAST(a.codigo_cliente AS VARCHAR2(15))
                 AND per.es_fisica = p.persona_fisica
           )
       AND EXISTS (
              SELECT 1
                FROM PA.ID_PERSONAS idp
               WHERE idp.cod_persona = CAST(a.codigo_cliente AS VARCHAR2(15))
                 AND idp.cod_pais IN (
                      SELECT column_value
                        FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('NACIONALIDAD'))
                 )
                 AND idp.cod_tipo_id IN (
                      SELECT column_value
                        FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('TIPO_DOCUMENTO'))
                 )
           )
       AND NOT EXISTS (
              SELECT 1
                FROM PR.PR_REPRESTAMOS r
               WHERE r.codigo_empresa = a.codigo_empresa
                 AND r.no_credito = a.no_credito
                 AND r.estado IN (
                      SELECT column_value
                        FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('ESTADOS_NO_REPROCESO'))
                 )
           )
       AND NOT EXISTS (
              SELECT 1
                FROM PR.PR_CREDITOS a1
                JOIN PR.PR_AVAL_REPRE_X_CREDITO aval
                  ON aval.codigo_empresa = a1.codigo_empresa
                 AND aval.no_credito = a1.no_credito
               WHERE a1.codigo_empresa = 1
                 AND a1.no_credito = a.no_credito
                 AND aval.codigo_aval_repre != a1.codigo_cliente
                 AND p.clientes_a_sola_firma = 'S'
           )
       AND PR.PR_PKG_REPRESTAMOS.F_TIENE_GARANTIA(a.no_credito) = 0
       AND PR.PR_PKG_REPRESTAMOS.F_VALIDAR_LISTAS_PEP(1, a.codigo_cliente) = 0
       AND PR.PR_PKG_REPRESTAMOS.F_VALIDAR_LISTA_NEGRA(1, a.codigo_cliente) = 0
),
diffs AS (
    SELECT 'ORIGINAL_MINUS_FAST' direccion, d.*
      FROM (
            SELECT * FROM original_sin_lote
            MINUS
            SELECT * FROM fast_sin_lote
           ) d
    UNION ALL
    SELECT 'FAST_MINUS_ORIGINAL' direccion, d.*
      FROM (
            SELECT * FROM fast_sin_lote
            MINUS
            SELECT * FROM original_sin_lote
           ) d
)
SELECT *
  FROM diffs
 WHERE ROWNUM <= 100

--------------------------------------------------------------------------------
-- 4) Validacion de conteo CON lote.
--    Debe coincidir en cantidad, pero no obliga a que sean las mismas filas.
--------------------------------------------------------------------------------
WITH params AS (
    SELECT (SELECT MAX(p.fecha_corte)
              FROM PA.PA_DETALLADO_DE08 p
             WHERE p.fuente = 'PR') fecha_corte,
           TO_NUMBER(PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('LOTE_DE_CARAGA_REPRESTAMO')) lote
      FROM dual
),
totales AS (
    SELECT p.lote,
           (
             SELECT COUNT(*)
               FROM PR.PR_CREDITOS a
               JOIN PR.PR_TIPO_CREDITO_REPRESTAMO c
                 ON c.tipo_credito = a.tipo_credito
               JOIN PA.PA_DETALLADO_DE08 b
                 ON b.tipo_credito = c.tipo_credito
                AND b.fecha_corte = p.fecha_corte
                AND b.no_credito = a.no_credito
                AND b.fuente = 'PR'
              WHERE c.carga = 'S'
           ) conteo_base_join_de08,
           (
             SELECT COUNT(*)
               FROM (
                     SELECT 1
                       FROM PR.PR_CREDITOS a
                       JOIN PR.PR_TIPO_CREDITO_REPRESTAMO c
                         ON c.tipo_credito = a.tipo_credito
                       JOIN PA.PA_DETALLADO_DE08 b
                         ON b.tipo_credito = c.tipo_credito
                        AND b.fecha_corte = p.fecha_corte
                        AND b.no_credito = a.no_credito
                        AND b.fuente = 'PR'
                      WHERE c.carga = 'S'
                        AND ROWNUM <= p.lote
                    )
           ) conteo_base_join_de08_con_lote
      FROM params p
)
SELECT lote,
       conteo_base_join_de08,
       conteo_base_join_de08_con_lote,
       LEAST(conteo_base_join_de08, lote) esperado_con_lote,
       CASE
         WHEN conteo_base_join_de08_con_lote = LEAST(conteo_base_join_de08, lote)
         THEN 'OK: el limite de lote recorta la cantidad esperada'
         ELSE 'REVISAR: el conteo con lote no coincide'
       END validacion
  FROM totales
