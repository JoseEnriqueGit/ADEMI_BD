/*
  Produccion - PR.PR_PKG_REPRESTAMOS.Precalifica_Represtamo
  Detalle read-only de candidatos por filtro del cursor CREDITOS_PROCESAR.

  Uso recomendado:
  - Ejecutar cada bloque por separado en Toad/F9.
  - En el bloque 2 cambiar filtro_objetivo por el numero de filtro a validar.
  - modo_resultado:
      DESCARTADOS = candidatos que llegan al filtro y se descartan ahi
      PASAN       = candidatos que llegan al filtro y lo pasan
      LLEGAN      = todos los candidatos que llegan al filtro
  - No tiene terminador final para evitar ORA-00911 invalid character.
*/

--------------------------------------------------------------------------------
-- 1) Catalogo de filtros del cursor.
--------------------------------------------------------------------------------
WITH pasos AS (
    SELECT 1 orden, 'TIPO_CREDITO existe en PR_TIPO_CREDITO_REPRESTAMO' filtro FROM dual UNION ALL
    SELECT 2, 'PERIODOS_CUOTA permitido o parametro vacio' FROM dual UNION ALL
    SELECT 3, 'PA_DETALLADO_DE08 en fecha corte y fuente PR' FROM dual UNION ALL
    SELECT 4, 'PA_DETALLADO_DE08.TIPO_CREDITO coincide' FROM dual UNION ALL
    SELECT 5, 'PR_TIPO_CREDITO_REPRESTAMO.CARGA = S' FROM dual UNION ALL
    SELECT 6, 'DIAS_ATRASO <= PRECAL_MORA_MAYOR_PR' FROM dual UNION ALL
    SELECT 7, 'CALIFICA_CLIENTE en CLASIFICACION_SIB' FROM dual UNION ALL
    SELECT 8, 'CAPITAL_PAGADO cumple parametro' FROM dual UNION ALL
    SELECT 9, 'CODIGO_EMPRESA = F_OBT_EMPRESA_REPRESTAMO' FROM dual UNION ALL
    SELECT 10, 'Sin otro prestamo desembolsado reciente' FROM dual UNION ALL
    SELECT 11, 'Sin otro credito estado E' FROM dual UNION ALL
    SELECT 12, 'Cliente persona fisica' FROM dual UNION ALL
    SELECT 13, 'Nacionalidad y tipo documento validos' FROM dual UNION ALL
    SELECT 14, 'Sin represtamo en estados no reproceso' FROM dual UNION ALL
    SELECT 15, 'No incumple regla de sola firma' FROM dual UNION ALL
    SELECT 16, 'F_TIENE_GARANTIA = 0' FROM dual UNION ALL
    SELECT 17, 'No esta en listas PEP' FROM dual UNION ALL
    SELECT 18, 'No esta en lista negra' FROM dual
)
SELECT orden,
       filtro
  FROM pasos
 ORDER BY orden

--------------------------------------------------------------------------------
-- 2) Detalle individual de candidatos por filtro.
--    Cambia filtro_objetivo y modo_resultado segun lo que quieras ver.
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
           PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('CLIENTES_A_SOLA_FIRMA') clientes_a_sola_firma,
           3 filtro_objetivo,
           'DESCARTADOS' modo_resultado,
           200 muestra
      FROM dual
),
base AS (
    SELECT ROWNUM candidato_id,
           a.codigo_empresa,
           a.codigo_cliente,
           a.no_credito,
           a.tipo_credito,
           a.codigo_periodo_cuota,
           a.f_primer_desembolso,
           a.estado estado_credito,
           b.fecha_corte,
           b.fuente,
           b.tipo_credito tipo_credito_de08,
           b.dias_atraso,
           b.califica_cliente,
           b.mto_balance_capital,
           b.monto_desembolsado,
           b.monto_credito
      FROM PR.PR_CREDITOS a
      CROSS JOIN params p
      LEFT JOIN PA.PA_DETALLADO_DE08 b
        ON b.no_credito = a.no_credito
       AND b.fecha_corte = p.fecha_corte
       AND b.fuente = 'PR'
),
flags AS (
    SELECT x.*,
           p.fecha_corte fecha_corte_param,
           p.lote,
           p.empresa,
           p.mora_max,
           p.capital_pagado,
           p.meses_desembolso,
           p.persona_fisica,
           p.clientes_a_sola_firma,
           CASE
             WHEN NVL(CASE WHEN x.monto_desembolsado = 0 THEN x.monto_credito ELSE x.monto_desembolsado END, 0) = 0
             THEN NULL
             ELSE ROUND((x.mto_balance_capital /
                    CASE WHEN x.monto_desembolsado = 0 THEN x.monto_credito ELSE x.monto_desembolsado END) * 100, 2)
           END pct_balance_capital,
           CASE
             WHEN EXISTS (
                    SELECT 1
                      FROM PR.PR_TIPO_CREDITO_REPRESTAMO c
                     WHERE c.tipo_credito = x.tipo_credito
                  )
             THEN 1 ELSE 0
           END f_tipo_represtamo,
           CASE
             WHEN EXISTS (
                    SELECT 1
                      FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('PERIODOS_CUOTA')) subq
                     WHERE subq.column_value = x.codigo_periodo_cuota
                  )
                  OR NOT EXISTS (
                    SELECT 1
                      FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('PERIODOS_CUOTA')) subq
                  )
             THEN 1 ELSE 0
           END f_periodo_cuota,
           CASE
             WHEN x.fecha_corte IS NOT NULL THEN 1 ELSE 0
           END f_de08_fecha_fuente,
           CASE
             WHEN x.tipo_credito_de08 = x.tipo_credito THEN 1 ELSE 0
           END f_de08_tipo_credito,
           CASE
             WHEN EXISTS (
                    SELECT 1
                      FROM PR.PR_TIPO_CREDITO_REPRESTAMO c
                     WHERE c.tipo_credito = x.tipo_credito
                       AND c.carga = 'S'
                  )
             THEN 1 ELSE 0
           END f_tipo_carga,
           CASE
             WHEN x.dias_atraso <= p.mora_max THEN 1 ELSE 0
           END f_mora_actual,
           CASE
             WHEN x.califica_cliente IN (
                    SELECT column_value
                      FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('CLASIFICACION_SIB'))
                  )
             THEN 1 ELSE 0
           END f_clasificacion_sib,
           CASE
             WHEN NVL(CASE WHEN x.monto_desembolsado = 0 THEN x.monto_credito ELSE x.monto_desembolsado END, 0) = 0
             THEN 0
             WHEN ((x.mto_balance_capital /
                    CASE WHEN x.monto_desembolsado = 0 THEN x.monto_credito ELSE x.monto_desembolsado END) * 100)
                    <= 100 - p.capital_pagado
             THEN 1 ELSE 0
           END f_capital_pagado,
           CASE
             WHEN x.codigo_empresa = p.empresa THEN 1 ELSE 0
           END f_empresa,
           CASE
             WHEN NOT EXISTS (
                    SELECT 1
                      FROM PR.PR_CREDITOS c
                     WHERE c.codigo_empresa = x.codigo_empresa
                       AND c.no_credito != x.no_credito
                       AND c.codigo_cliente = x.codigo_cliente
                       AND c.f_primer_desembolso > ADD_MONTHS(SYSDATE, - p.meses_desembolso)
                       AND c.estado IN (
                            SELECT column_value
                              FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('ESTADOS_CREDITOS'))
                       )
                  )
             THEN 1 ELSE 0
           END f_sin_desembolso_reciente,
           CASE
             WHEN NOT EXISTS (
                    SELECT 1
                      FROM PR.PR_CREDITOS c
                     WHERE c.codigo_empresa = x.codigo_empresa
                       AND c.no_credito != x.no_credito
                       AND c.codigo_cliente = x.codigo_cliente
                       AND c.estado = 'E'
                  )
             THEN 1 ELSE 0
           END f_sin_reestructurado,
           CASE
             WHEN EXISTS (
                    SELECT 1
                      FROM PA.PERSONAS per
                     WHERE per.cod_persona = CAST(x.codigo_cliente AS VARCHAR2(15))
                       AND per.es_fisica = p.persona_fisica
                  )
             THEN 1 ELSE 0
           END f_persona_fisica,
           CASE
             WHEN EXISTS (
                    SELECT 1
                      FROM PA.ID_PERSONAS idp
                     WHERE idp.cod_persona = CAST(x.codigo_cliente AS VARCHAR2(15))
                       AND idp.cod_pais IN (
                            SELECT column_value
                              FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('NACIONALIDAD'))
                       )
                       AND idp.cod_tipo_id IN (
                            SELECT column_value
                              FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('TIPO_DOCUMENTO'))
                       )
                  )
             THEN 1 ELSE 0
           END f_nacionalidad_documento,
           CASE
             WHEN NOT EXISTS (
                    SELECT 1
                      FROM PR.PR_REPRESTAMOS r
                     WHERE r.codigo_empresa = x.codigo_empresa
                       AND r.no_credito = x.no_credito
                       AND r.estado IN (
                            SELECT column_value
                              FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('ESTADOS_NO_REPROCESO'))
                       )
                  )
             THEN 1 ELSE 0
           END f_sin_reproceso,
           CASE
             WHEN NOT EXISTS (
                    SELECT 1
                      FROM PR.PR_CREDITOS a1,
                           PR.PR_AVAL_REPRE_X_CREDITO aval
                     WHERE a1.codigo_empresa = 1
                       AND a1.no_credito = x.no_credito
                       AND aval.codigo_empresa = a1.codigo_empresa
                       AND aval.no_credito = a1.no_credito
                       AND aval.codigo_aval_repre != a1.codigo_cliente
                       AND p.clientes_a_sola_firma = 'S'
                  )
             THEN 1 ELSE 0
           END f_sola_firma,
           CASE
             WHEN PR.PR_PKG_REPRESTAMOS.F_TIENE_GARANTIA(x.no_credito) = 0 THEN 1 ELSE 0
           END f_sin_garantia,
           CASE
             WHEN PR.PR_PKG_REPRESTAMOS.F_VALIDAR_LISTAS_PEP(1, x.codigo_cliente) = 0 THEN 1 ELSE 0
           END f_no_pep,
           CASE
             WHEN PR.PR_PKG_REPRESTAMOS.F_VALIDAR_LISTA_NEGRA(1, x.codigo_cliente) = 0 THEN 1 ELSE 0
           END f_no_lista_negra
      FROM base x
      CROSS JOIN params p
),
scored AS (
    SELECT f.*,
           CASE
             WHEN f.f_tipo_represtamo = 0 THEN 0
             WHEN f.f_periodo_cuota = 0 THEN 1
             WHEN f.f_de08_fecha_fuente = 0 THEN 2
             WHEN f.f_de08_tipo_credito = 0 THEN 3
             WHEN f.f_tipo_carga = 0 THEN 4
             WHEN f.f_mora_actual = 0 THEN 5
             WHEN f.f_clasificacion_sib = 0 THEN 6
             WHEN f.f_capital_pagado = 0 THEN 7
             WHEN f.f_empresa = 0 THEN 8
             WHEN f.f_sin_desembolso_reciente = 0 THEN 9
             WHEN f.f_sin_reestructurado = 0 THEN 10
             WHEN f.f_persona_fisica = 0 THEN 11
             WHEN f.f_nacionalidad_documento = 0 THEN 12
             WHEN f.f_sin_reproceso = 0 THEN 13
             WHEN f.f_sola_firma = 0 THEN 14
             WHEN f.f_sin_garantia = 0 THEN 15
             WHEN f.f_no_pep = 0 THEN 16
             WHEN f.f_no_lista_negra = 0 THEN 17
             ELSE 18
           END paso_alcanzado
      FROM flags f
),
pasos AS (
    SELECT 1 orden, 'TIPO_CREDITO existe en PR_TIPO_CREDITO_REPRESTAMO' filtro FROM dual UNION ALL
    SELECT 2, 'PERIODOS_CUOTA permitido o parametro vacio' FROM dual UNION ALL
    SELECT 3, 'PA_DETALLADO_DE08 en fecha corte y fuente PR' FROM dual UNION ALL
    SELECT 4, 'PA_DETALLADO_DE08.TIPO_CREDITO coincide' FROM dual UNION ALL
    SELECT 5, 'PR_TIPO_CREDITO_REPRESTAMO.CARGA = S' FROM dual UNION ALL
    SELECT 6, 'DIAS_ATRASO <= PRECAL_MORA_MAYOR_PR' FROM dual UNION ALL
    SELECT 7, 'CALIFICA_CLIENTE en CLASIFICACION_SIB' FROM dual UNION ALL
    SELECT 8, 'CAPITAL_PAGADO cumple parametro' FROM dual UNION ALL
    SELECT 9, 'CODIGO_EMPRESA = F_OBT_EMPRESA_REPRESTAMO' FROM dual UNION ALL
    SELECT 10, 'Sin otro prestamo desembolsado reciente' FROM dual UNION ALL
    SELECT 11, 'Sin otro credito estado E' FROM dual UNION ALL
    SELECT 12, 'Cliente persona fisica' FROM dual UNION ALL
    SELECT 13, 'Nacionalidad y tipo documento validos' FROM dual UNION ALL
    SELECT 14, 'Sin represtamo en estados no reproceso' FROM dual UNION ALL
    SELECT 15, 'No incumple regla de sola firma' FROM dual UNION ALL
    SELECT 16, 'F_TIENE_GARANTIA = 0' FROM dual UNION ALL
    SELECT 17, 'No esta en listas PEP' FROM dual UNION ALL
    SELECT 18, 'No esta en lista negra' FROM dual
),
pasos_objetivo AS (
    SELECT ps.*
      FROM pasos ps
      CROSS JOIN params p
     WHERE p.filtro_objetivo IS NULL
        OR ps.orden = p.filtro_objetivo
),
detalle AS (
    SELECT po.orden,
           po.filtro,
           s.candidato_id,
           s.paso_alcanzado,
           CASE po.orden
             WHEN 1 THEN s.f_tipo_represtamo
             WHEN 2 THEN s.f_periodo_cuota
             WHEN 3 THEN s.f_de08_fecha_fuente
             WHEN 4 THEN s.f_de08_tipo_credito
             WHEN 5 THEN s.f_tipo_carga
             WHEN 6 THEN s.f_mora_actual
             WHEN 7 THEN s.f_clasificacion_sib
             WHEN 8 THEN s.f_capital_pagado
             WHEN 9 THEN s.f_empresa
             WHEN 10 THEN s.f_sin_desembolso_reciente
             WHEN 11 THEN s.f_sin_reestructurado
             WHEN 12 THEN s.f_persona_fisica
             WHEN 13 THEN s.f_nacionalidad_documento
             WHEN 14 THEN s.f_sin_reproceso
             WHEN 15 THEN s.f_sola_firma
             WHEN 16 THEN s.f_sin_garantia
             WHEN 17 THEN s.f_no_pep
             WHEN 18 THEN s.f_no_lista_negra
           END flag_ok,
           s.fecha_corte_param,
           s.codigo_empresa,
           s.no_credito,
           s.codigo_cliente,
           s.tipo_credito,
           s.codigo_periodo_cuota,
           s.estado_credito,
           s.fecha_corte fecha_corte_de08,
           s.fuente fuente_de08,
           s.tipo_credito_de08,
           s.dias_atraso,
           s.califica_cliente,
           s.pct_balance_capital,
           s.monto_desembolsado,
           s.monto_credito,
           s.mto_balance_capital,
           CASE po.orden
             WHEN 1 THEN 'TIPO_CREDITO=' || NVL(TO_CHAR(s.tipo_credito), 'NULL')
             WHEN 2 THEN 'CODIGO_PERIODO_CUOTA=' || NVL(TO_CHAR(s.codigo_periodo_cuota), 'NULL')
             WHEN 3 THEN 'FECHA_DE08=' || NVL(TO_CHAR(s.fecha_corte, 'YYYY-MM-DD'), 'SIN_DE08') || ', FUENTE=' || NVL(s.fuente, 'NULL')
             WHEN 4 THEN 'TIPO_CREDITO=' || NVL(TO_CHAR(s.tipo_credito), 'NULL') || ', TIPO_DE08=' || NVL(TO_CHAR(s.tipo_credito_de08), 'NULL')
             WHEN 5 THEN 'TIPO_CREDITO=' || NVL(TO_CHAR(s.tipo_credito), 'NULL') || ', REQUIERE CARGA=S'
             WHEN 6 THEN 'DIAS_ATRASO=' || NVL(TO_CHAR(s.dias_atraso), 'NULL') || ', MAX=' || TO_CHAR(s.mora_max)
             WHEN 7 THEN 'CALIFICA_CLIENTE=' || NVL(TO_CHAR(s.califica_cliente), 'NULL')
             WHEN 8 THEN 'PCT_BALANCE_CAPITAL=' || NVL(TO_CHAR(s.pct_balance_capital), 'NULL') || ', CAPITAL_PAGADO=' || TO_CHAR(s.capital_pagado)
             WHEN 9 THEN 'CODIGO_EMPRESA=' || TO_CHAR(s.codigo_empresa) || ', EMPRESA_PARAM=' || TO_CHAR(s.empresa)
             WHEN 10 THEN 'CLIENTE=' || TO_CHAR(s.codigo_cliente) || ', MESES=' || TO_CHAR(s.meses_desembolso)
             WHEN 11 THEN 'CLIENTE=' || TO_CHAR(s.codigo_cliente) || ', OTRO ESTADO E'
             WHEN 12 THEN 'CLIENTE=' || TO_CHAR(s.codigo_cliente) || ', PERSONA_FISICA=' || s.persona_fisica
             WHEN 13 THEN 'CLIENTE=' || TO_CHAR(s.codigo_cliente) || ', NACIONALIDAD/TIPO_DOCUMENTO'
             WHEN 14 THEN 'NO_CREDITO=' || TO_CHAR(s.no_credito) || ', ESTADOS_NO_REPROCESO'
             WHEN 15 THEN 'NO_CREDITO=' || TO_CHAR(s.no_credito) || ', CLIENTES_A_SOLA_FIRMA=' || s.clientes_a_sola_firma
             WHEN 16 THEN 'NO_CREDITO=' || TO_CHAR(s.no_credito) || ', F_TIENE_GARANTIA'
             WHEN 17 THEN 'CLIENTE=' || TO_CHAR(s.codigo_cliente) || ', LISTAS_PEP'
             WHEN 18 THEN 'CLIENTE=' || TO_CHAR(s.codigo_cliente) || ', LISTA_NEGRA'
           END valores_validacion
      FROM pasos_objetivo po
      CROSS JOIN scored s
     WHERE s.paso_alcanzado >= po.orden - 1
),
detalle_estado AS (
    SELECT d.*,
           CASE
             WHEN d.paso_alcanzado = d.orden - 1 THEN 'DESCARTADO_EN_ESTE_FILTRO'
             WHEN d.paso_alcanzado >= d.orden THEN 'PASA_ESTE_FILTRO'
             ELSE 'NO_LLEGA_AL_FILTRO'
           END estado_en_filtro
      FROM detalle d
)
SELECT *
  FROM (
        SELECT d.orden filtro_orden,
               d.filtro,
               d.estado_en_filtro,
               CASE
                 WHEN d.paso_alcanzado = 18 THEN 'OK: PASA TODO EL CURSOR'
                 ELSE TO_CHAR(pf.orden) || ' - ' || pf.filtro
               END primer_filtro_que_lo_descarta,
               d.flag_ok,
               d.candidato_id,
               d.fecha_corte_param,
               d.codigo_empresa,
               d.no_credito,
               d.codigo_cliente,
               d.tipo_credito,
               d.codigo_periodo_cuota,
               d.estado_credito,
               d.fecha_corte_de08,
               d.fuente_de08,
               d.tipo_credito_de08,
               d.dias_atraso,
               d.califica_cliente,
               d.pct_balance_capital,
               d.monto_desembolsado,
               d.monto_credito,
               d.mto_balance_capital,
               d.valores_validacion
          FROM detalle_estado d
          CROSS JOIN params p
          LEFT JOIN pasos pf
            ON pf.orden = d.paso_alcanzado + 1
         WHERE (
                  p.modo_resultado = 'LLEGAN'
               OR (p.modo_resultado = 'DESCARTADOS' AND d.estado_en_filtro = 'DESCARTADO_EN_ESTE_FILTRO')
               OR (p.modo_resultado = 'PASAN' AND d.estado_en_filtro = 'PASA_ESTE_FILTRO')
               )
         ORDER BY d.orden,
                  d.estado_en_filtro,
                  d.no_credito,
                  d.codigo_cliente
       )
 WHERE ROWNUM <= (SELECT muestra FROM params)
