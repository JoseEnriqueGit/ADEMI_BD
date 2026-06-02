WITH params AS (
    SELECT (SELECT MAX(p.fecha_corte)
              FROM PA.PA_DETALLADO_DE08 p
             WHERE p.fuente = 'PR') fecha_corte,
           TO_NUMBER(PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('LOTE_DE_CARAGA_REPRESTAMO')) lote,
           TO_NUMBER(PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('PRECAL_MORA_MAYOR_PR')) mora_max,
           TO_NUMBER(PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('CAPITAL_PAGADO')) capital_pagado,
           TO_NUMBER(PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('MESES_MAX_X_DESEMBOLSO')) meses_desembolso,
           PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO empresa,
           PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('PERSONA_FISICA') persona_fisica,
           PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('CLIENTES_A_SOLA_FIRMA') clientes_a_sola_firma
      FROM dual
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
    SELECT a.*,
           b.dias_atraso de08_dias_atraso,
           b.califica_cliente de08_califica_cliente,
           b.mto_balance_capital de08_mto_balance_capital,
           b.monto_desembolsado de08_monto_desembolsado,
           b.monto_credito de08_monto_credito
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
     WHERE a.de08_dias_atraso <= p.mora_max
),
s06 AS (
    SELECT a.*
      FROM s05 a
     WHERE a.de08_califica_cliente IN (
              SELECT column_value
                FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('CLASIFICACION_SIB'))
           )
),
s07 AS (
    SELECT a.*
      FROM s06 a
      CROSS JOIN params p
     WHERE NVL(CASE WHEN a.de08_monto_desembolsado = 0 THEN a.de08_monto_credito ELSE a.de08_monto_desembolsado END, 0) <> 0
       AND ((a.de08_mto_balance_capital /
            CASE WHEN a.de08_monto_desembolsado = 0 THEN a.de08_monto_credito ELSE a.de08_monto_desembolsado END) * 100)
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
                FROM PR.PR_CREDITOS c
               WHERE c.codigo_empresa = a.codigo_empresa
                 AND c.no_credito != a.no_credito
                 AND c.codigo_cliente = a.codigo_cliente
                 AND c.f_primer_desembolso > ADD_MONTHS(SYSDATE, - p.meses_desembolso)
                 AND c.estado IN (
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
                FROM PR.PR_CREDITOS c
               WHERE c.codigo_empresa = a.codigo_empresa
                 AND c.no_credito != a.no_credito
                 AND c.codigo_cliente = a.codigo_cliente
                 AND c.estado = 'E'
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
s17 AS (
    SELECT a.*
      FROM s16 a
     WHERE PR.PR_PKG_REPRESTAMOS.F_VALIDAR_LISTA_NEGRA(1, a.codigo_cliente) = 0
),
conteos AS (
    SELECT 0 orden, COUNT(*) cantidad FROM s00 UNION ALL
    SELECT 1, COUNT(*) FROM s01 UNION ALL
    SELECT 2, COUNT(*) FROM s02 UNION ALL
    SELECT 3, COUNT(*) FROM s03 UNION ALL
    SELECT 4, COUNT(*) FROM s04 UNION ALL
    SELECT 5, COUNT(*) FROM s05 UNION ALL
    SELECT 6, COUNT(*) FROM s06 UNION ALL
    SELECT 7, COUNT(*) FROM s07 UNION ALL
    SELECT 8, COUNT(*) FROM s08 UNION ALL
    SELECT 9, COUNT(*) FROM s09 UNION ALL
    SELECT 10, COUNT(*) FROM s10 UNION ALL
    SELECT 11, COUNT(*) FROM s11 UNION ALL
    SELECT 12, COUNT(*) FROM s12 UNION ALL
    SELECT 13, COUNT(*) FROM s13 UNION ALL
    SELECT 14, COUNT(*) FROM s14 UNION ALL
    SELECT 15, COUNT(*) FROM s15 UNION ALL
    SELECT 16, COUNT(*) FROM s16 UNION ALL
    SELECT 17, COUNT(*) FROM s17
),
pasos AS (
    SELECT 0 orden, 'BASE: PR_CREDITOS' filtro FROM dual UNION ALL
    SELECT 1, 'TIPO_CREDITO existe en PR_TIPO_CREDITO_REPRESTAMO' FROM dual UNION ALL
    SELECT 2, 'PERIODOS_CUOTA permitido o parametro vacio' FROM dual UNION ALL
    SELECT 3, 'PA_DETALLADO_DE08 en fecha corte/fuente PR/tipo credito' FROM dual UNION ALL
    SELECT 4, 'PR_TIPO_CREDITO_REPRESTAMO.CARGA = S' FROM dual UNION ALL
    SELECT 5, 'DIAS_ATRASO <= PRECAL_MORA_MAYOR_PR' FROM dual UNION ALL
    SELECT 6, 'CALIFICA_CLIENTE en CLASIFICACION_SIB' FROM dual UNION ALL
    SELECT 7, 'CAPITAL_PAGADO cumple parametro' FROM dual UNION ALL
    SELECT 8, 'CODIGO_EMPRESA = F_OBT_EMPRESA_REPRESTAMO' FROM dual UNION ALL
    SELECT 9, 'Sin otro prestamo desembolsado reciente' FROM dual UNION ALL
    SELECT 10, 'Sin otro credito estado E' FROM dual UNION ALL
    SELECT 11, 'Cliente persona fisica' FROM dual UNION ALL
    SELECT 12, 'Nacionalidad y tipo documento validos' FROM dual UNION ALL
    SELECT 13, 'Sin represtamo en estados no reproceso' FROM dual UNION ALL
    SELECT 14, 'No incumple regla de sola firma' FROM dual UNION ALL
    SELECT 15, 'F_TIENE_GARANTIA = 0' FROM dual UNION ALL
    SELECT 16, 'No esta en listas PEP' FROM dual UNION ALL
    SELECT 17, 'No esta en lista negra' FROM dual
)
SELECT 'Precalifica_Represtamo' proceso,
       p.orden,
       p.filtro,
       b.cantidad candidatos_antes,
       a.cantidad candidatos_pasan,
       b.cantidad - a.cantidad candidatos_descartados
  FROM pasos p
  JOIN conteos a ON a.orden = p.orden
  JOIN conteos b ON b.orden = CASE WHEN p.orden = 0 THEN 0 ELSE p.orden - 1 END
UNION ALL
SELECT 'Precalifica_Represtamo',
       99,
       'ROWNUM <= LOTE_DE_CARAGA_REPRESTAMO',
       c.cantidad,
       LEAST(c.cantidad, p.lote),
       GREATEST(c.cantidad - p.lote, 0)
  FROM conteos c
  CROSS JOIN params p
 WHERE c.orden = 17
 ORDER BY orden
