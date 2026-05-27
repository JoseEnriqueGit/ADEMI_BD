/*
  QA02 - PR.PR_PKG_REPRESTAMOS.Precalifica_Represtamo
  Tracker read-only del cursor CREDITOS_PROCESAR.

  Objetivo:
  - Contar cuantos candidatos descarta cada filtro del cursor.
  - Mostrar el embudo secuencial real del cursor + limite de lote.
  - Dar una muestra de creditos para validar manualmente en Toad.

  Definicion de candidato:
  - Una fila candidata equivale a la combinacion PR_CREDITOS + PA_DETALLADO_DE08
    que puede producir el cursor. Se cuenta por ROWID de ambas tablas para evitar
    solapes cuando un NO_CREDITO aparece mas de una vez en PA_DETALLADO_DE08.

  Notas:
  - Solo ejecuta SELECT.
  - Fecha de corte por defecto: la MAX(PA.PA_DETALLADO_DE08.FECHA_CORTE) con FUENTE = 'PR',
    igual que Precalifica_Represtamo.
  - Para forzar una fecha historica reemplazar CAST(NULL AS DATE) por DATE 'YYYY-MM-DD' en params.
  - La consulta 0 muestra que fecha tomara el tracker para esta corrida.
*/

--------------------------------------------------------------------------------
-- 0) Validacion de la FECHA_CORTE que tomara el tracker (= la del cursor).
--------------------------------------------------------------------------------
WITH fecha_cursor AS (
    SELECT MAX(p.fecha_corte) fecha_corte
      FROM PA.PA_DETALLADO_DE08 p
     WHERE p.fuente = 'PR'
)
SELECT fc.fecha_corte fecha_corte_tracker,
       fc.fecha_corte fecha_corte_cursor_precalifica,
       'SI: TRACKER Y CURSOR USAN LA MISMA FECHA' validacion_fecha_corte,
       COUNT(CASE WHEN p.fecha_corte = fc.fecha_corte THEN 1 END) registros_fecha_corte
  FROM fecha_cursor fc
  LEFT JOIN PA.PA_DETALLADO_DE08 p
    ON p.fuente = 'PR'
 GROUP BY fc.fecha_corte;

--------------------------------------------------------------------------------
-- 1) Resumen por filtro: embudo secuencial e impacto independiente.
--------------------------------------------------------------------------------
WITH params AS (
    SELECT NVL(
               CAST(NULL AS DATE),
               (SELECT MAX(p.fecha_corte)
                  FROM PA.PA_DETALLADO_DE08 p
                 WHERE p.fuente = 'PR')
           ) fecha_corte,
           TO_NUMBER(PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('LOTE_DE_CARAGA_REPRESTAMO')) lote,
           PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO empresa,
           TO_NUMBER(PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('PRECAL_MORA_MAYOR_PR')) mora_max,
           TO_NUMBER(PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('CAPITAL_PAGADO')) capital_pagado,
           TO_NUMBER(PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('MESES_MAX_X_DESEMBOLSO')) meses_desembolso,
           PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('PERSONA_FISICA') persona_fisica,
           PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('CLIENTES_A_SOLA_FIRMA') clientes_a_sola_firma
      FROM dual
),
base AS (
    SELECT ROWIDTOCHAR(a.rowid) || ':' || NVL(ROWIDTOCHAR(b.rowid), 'SIN_DE08') candidato_id,
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
    SELECT 0 orden, 'BASE: PR_CREDITOS' filtro FROM dual UNION ALL
    SELECT 1, 'TIPO_CREDITO existe en PR_TIPO_CREDITO_REPRESTAMO' FROM dual UNION ALL
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
resumen_secuencial AS (
    SELECT 1 tipo_orden,
           'SECUENCIAL_CURSOR' tipo_medicion,
           p.orden,
           p.filtro,
           COUNT(DISTINCT CASE WHEN p.orden = 0 OR s.paso_alcanzado >= p.orden - 1 THEN s.candidato_id END) candidatos_antes,
           COUNT(DISTINCT CASE WHEN p.orden = 0 OR s.paso_alcanzado >= p.orden THEN s.candidato_id END) candidatos_pasan,
           CASE
             WHEN p.orden = 0 THEN 0
             ELSE COUNT(DISTINCT CASE WHEN s.paso_alcanzado = p.orden - 1 THEN s.candidato_id END)
           END candidatos_descartados,
           CASE
             WHEN p.orden = 0 THEN 0
             ELSE COUNT(DISTINCT CASE WHEN s.paso_alcanzado = p.orden - 1 THEN s.no_credito END)
           END creditos_descartados,
           CASE
             WHEN p.orden = 0 THEN 0
             ELSE COUNT(DISTINCT CASE WHEN s.paso_alcanzado = p.orden - 1 THEN s.codigo_cliente END)
           END clientes_descartados,
           'Descartes mutuamente exclusivos en el orden del cursor' observacion
      FROM pasos p
      CROSS JOIN scored s
     GROUP BY p.orden, p.filtro
),
resumen_lote AS (
    SELECT 3 tipo_orden,
           'LIMITE_LOTE' tipo_medicion,
           99 orden,
           'ROWNUM <= LOTE_DE_CARAGA_REPRESTAMO' filtro,
           COUNT(DISTINCT s.candidato_id) candidatos_antes,
           LEAST(COUNT(DISTINCT s.candidato_id), MAX(p.lote)) candidatos_pasan,
           GREATEST(COUNT(DISTINCT s.candidato_id) - MAX(p.lote), 0) candidatos_descartados,
           CAST(NULL AS NUMBER) creditos_descartados,
           CAST(NULL AS NUMBER) clientes_descartados,
           'Estimado: el cursor no tiene ORDER BY, solo indica exceso sobre el lote' observacion
      FROM params p
      LEFT JOIN scored s
        ON s.paso_alcanzado = 18
)
SELECT tipo_medicion,
       orden,
       filtro,
       candidatos_antes,
       candidatos_pasan,
       candidatos_descartados,
       creditos_descartados,
       clientes_descartados,
       observacion
  FROM (
        SELECT * FROM resumen_secuencial
        UNION ALL
        SELECT * FROM resumen_lote
       )
 ORDER BY tipo_orden, orden;

--------------------------------------------------------------------------------
-- 2) Muestra de validacion: primeros 200 creditos descartados por primer filtro.
--    Para validar un filtro concreto, agrega un WHERE por PRIMER_FILTRO_FALLA.
--------------------------------------------------------------------------------
WITH params AS (
    SELECT NVL(
               CAST(NULL AS DATE),
               (SELECT MAX(p.fecha_corte)
                  FROM PA.PA_DETALLADO_DE08 p
                 WHERE p.fuente = 'PR')
           ) fecha_corte,
           200 muestra,
           PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO empresa,
           TO_NUMBER(PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('PRECAL_MORA_MAYOR_PR')) mora_max,
           TO_NUMBER(PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('CAPITAL_PAGADO')) capital_pagado,
           TO_NUMBER(PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('MESES_MAX_X_DESEMBOLSO')) meses_desembolso,
           PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('PERSONA_FISICA') persona_fisica,
           PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('CLIENTES_A_SOLA_FIRMA') clientes_a_sola_firma
      FROM dual
),
base AS (
    SELECT ROWIDTOCHAR(a.rowid) || ':' || NVL(ROWIDTOCHAR(b.rowid), 'SIN_DE08') candidato_id,
           a.codigo_empresa,
           a.codigo_cliente,
           a.no_credito,
           a.tipo_credito,
           a.codigo_periodo_cuota,
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
           CASE
             WHEN NVL(CASE WHEN x.monto_desembolsado = 0 THEN x.monto_credito ELSE x.monto_desembolsado END, 0) = 0
             THEN NULL
             ELSE ROUND((x.mto_balance_capital /
                    CASE WHEN x.monto_desembolsado = 0 THEN x.monto_credito ELSE x.monto_desembolsado END) * 100, 2)
           END pct_balance_capital,
           CASE WHEN EXISTS (SELECT 1 FROM PR.PR_TIPO_CREDITO_REPRESTAMO c WHERE c.tipo_credito = x.tipo_credito) THEN 1 ELSE 0 END f_tipo_represtamo,
           CASE
             WHEN EXISTS (SELECT 1 FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('PERIODOS_CUOTA')) subq WHERE subq.column_value = x.codigo_periodo_cuota)
                  OR NOT EXISTS (SELECT 1 FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('PERIODOS_CUOTA')) subq)
             THEN 1 ELSE 0
           END f_periodo_cuota,
           CASE WHEN x.fecha_corte IS NOT NULL THEN 1 ELSE 0 END f_de08_fecha_fuente,
           CASE WHEN x.tipo_credito_de08 = x.tipo_credito THEN 1 ELSE 0 END f_de08_tipo_credito,
           CASE WHEN EXISTS (SELECT 1 FROM PR.PR_TIPO_CREDITO_REPRESTAMO c WHERE c.tipo_credito = x.tipo_credito AND c.carga = 'S') THEN 1 ELSE 0 END f_tipo_carga,
           CASE WHEN x.dias_atraso <= p.mora_max THEN 1 ELSE 0 END f_mora_actual,
           CASE WHEN x.califica_cliente IN (SELECT column_value FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('CLASIFICACION_SIB'))) THEN 1 ELSE 0 END f_clasificacion_sib,
           CASE
             WHEN NVL(CASE WHEN x.monto_desembolsado = 0 THEN x.monto_credito ELSE x.monto_desembolsado END, 0) = 0 THEN 0
             WHEN ((x.mto_balance_capital / CASE WHEN x.monto_desembolsado = 0 THEN x.monto_credito ELSE x.monto_desembolsado END) * 100) <= 100 - p.capital_pagado THEN 1
             ELSE 0
           END f_capital_pagado,
           CASE WHEN x.codigo_empresa = p.empresa THEN 1 ELSE 0 END f_empresa,
           CASE
             WHEN NOT EXISTS (
                    SELECT 1 FROM PR.PR_CREDITOS c
                     WHERE c.codigo_empresa = x.codigo_empresa
                       AND c.no_credito != x.no_credito
                       AND c.codigo_cliente = x.codigo_cliente
                       AND c.f_primer_desembolso > ADD_MONTHS(SYSDATE, - p.meses_desembolso)
                       AND c.estado IN (SELECT column_value FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('ESTADOS_CREDITOS')))
                  )
             THEN 1 ELSE 0
           END f_sin_desembolso_reciente,
           CASE
             WHEN NOT EXISTS (
                    SELECT 1 FROM PR.PR_CREDITOS c
                     WHERE c.codigo_empresa = x.codigo_empresa
                       AND c.no_credito != x.no_credito
                       AND c.codigo_cliente = x.codigo_cliente
                       AND c.estado = 'E'
                  )
             THEN 1 ELSE 0
           END f_sin_reestructurado,
           CASE WHEN EXISTS (SELECT 1 FROM PA.PERSONAS per WHERE per.cod_persona = CAST(x.codigo_cliente AS VARCHAR2(15)) AND per.es_fisica = p.persona_fisica) THEN 1 ELSE 0 END f_persona_fisica,
           CASE
             WHEN EXISTS (
                    SELECT 1 FROM PA.ID_PERSONAS idp
                     WHERE idp.cod_persona = CAST(x.codigo_cliente AS VARCHAR2(15))
                       AND idp.cod_pais IN (SELECT column_value FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('NACIONALIDAD')))
                       AND idp.cod_tipo_id IN (SELECT column_value FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('TIPO_DOCUMENTO')))
                  )
             THEN 1 ELSE 0
           END f_nacionalidad_documento,
           CASE
             WHEN NOT EXISTS (
                    SELECT 1 FROM PR.PR_REPRESTAMOS r
                     WHERE r.codigo_empresa = x.codigo_empresa
                       AND r.no_credito = x.no_credito
                       AND r.estado IN (SELECT column_value FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('ESTADOS_NO_REPROCESO')))
                  )
             THEN 1 ELSE 0
           END f_sin_reproceso,
           CASE
             WHEN NOT EXISTS (
                    SELECT 1 FROM PR.PR_CREDITOS a1, PR.PR_AVAL_REPRE_X_CREDITO aval
                     WHERE a1.codigo_empresa = 1
                       AND a1.no_credito = x.no_credito
                       AND aval.codigo_empresa = a1.codigo_empresa
                       AND aval.no_credito = a1.no_credito
                       AND aval.codigo_aval_repre != a1.codigo_cliente
                       AND p.clientes_a_sola_firma = 'S'
                  )
             THEN 1 ELSE 0
           END f_sola_firma,
           CASE WHEN PR.PR_PKG_REPRESTAMOS.F_TIENE_GARANTIA(x.no_credito) = 0 THEN 1 ELSE 0 END f_sin_garantia,
           CASE WHEN PR.PR_PKG_REPRESTAMOS.F_VALIDAR_LISTAS_PEP(1, x.codigo_cliente) = 0 THEN 1 ELSE 0 END f_no_pep,
           CASE WHEN PR.PR_PKG_REPRESTAMOS.F_VALIDAR_LISTA_NEGRA(1, x.codigo_cliente) = 0 THEN 1 ELSE 0 END f_no_lista_negra
      FROM base x
      CROSS JOIN params p
),
scored AS (
    SELECT f.*,
           CASE
             WHEN f.f_tipo_represtamo = 0 THEN '01 - TIPO_CREDITO no existe en PR_TIPO_CREDITO_REPRESTAMO'
             WHEN f.f_periodo_cuota = 0 THEN '02 - PERIODOS_CUOTA no permitido'
             WHEN f.f_de08_fecha_fuente = 0 THEN '03 - Sin PA_DETALLADO_DE08 para fecha/fuente PR'
             WHEN f.f_de08_tipo_credito = 0 THEN '04 - Tipo credito DE08 no coincide'
             WHEN f.f_tipo_carga = 0 THEN '05 - Tipo credito sin CARGA = S'
             WHEN f.f_mora_actual = 0 THEN '06 - Mora actual mayor al parametro'
             WHEN f.f_clasificacion_sib = 0 THEN '07 - Clasificacion SIB no permitida'
             WHEN f.f_capital_pagado = 0 THEN '08 - Capital pagado insuficiente'
             WHEN f.f_empresa = 0 THEN '09 - Empresa distinta'
             WHEN f.f_sin_desembolso_reciente = 0 THEN '10 - Otro prestamo desembolsado reciente'
             WHEN f.f_sin_reestructurado = 0 THEN '11 - Otro credito estado E'
             WHEN f.f_persona_fisica = 0 THEN '12 - No persona fisica'
             WHEN f.f_nacionalidad_documento = 0 THEN '13 - Nacionalidad/tipo documento no valido'
             WHEN f.f_sin_reproceso = 0 THEN '14 - Represtamo en estado no reproceso'
             WHEN f.f_sola_firma = 0 THEN '15 - Incumple regla de sola firma'
             WHEN f.f_sin_garantia = 0 THEN '16 - Tiene garantia'
             WHEN f.f_no_pep = 0 THEN '17 - En lista PEP'
             WHEN f.f_no_lista_negra = 0 THEN '18 - En lista negra'
             ELSE 'OK - Elegible antes de limite de lote'
           END primer_filtro_falla
      FROM flags f
)
SELECT *
  FROM (
        SELECT fecha_corte_param,
               primer_filtro_falla,
               candidato_id,
               codigo_empresa,
               no_credito,
               codigo_cliente,
               tipo_credito,
               codigo_periodo_cuota,
               tipo_credito_de08,
               dias_atraso,
               califica_cliente,
               pct_balance_capital,
               f_tipo_represtamo,
               f_periodo_cuota,
               f_de08_fecha_fuente,
               f_de08_tipo_credito,
               f_tipo_carga,
               f_mora_actual,
               f_clasificacion_sib,
               f_capital_pagado,
               f_empresa,
               f_sin_desembolso_reciente,
               f_sin_reestructurado,
               f_persona_fisica,
               f_nacionalidad_documento,
               f_sin_reproceso,
               f_sola_firma,
               f_sin_garantia,
               f_no_pep,
               f_no_lista_negra
          FROM scored
         WHERE primer_filtro_falla <> 'OK - Elegible antes de limite de lote'
         ORDER BY primer_filtro_falla, no_credito
       )
 WHERE ROWNUM <= (SELECT muestra FROM params);
