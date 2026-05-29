/*
  Produccion - PR.PR_PKG_REPRESTAMOS.Precalifica_Represtamo
  Tracker read-only del cursor CREDITOS_PROCESAR y filtros post cursor.

  Uso recomendado:
  - Ejecutar como una sola sentencia en Toad/F9.
  - Colocar el cursor en la linea WITH params AS o seleccionar todo el SQL.
  - No tiene terminador final para evitar ORA-00911 invalid character.

  Alcance:
  - Solo SELECT.
  - No ejecuta INSERT, UPDATE, DELETE, COMMIT ni ROLLBACK.
  - Usa la MAX(PA.PA_DETALLADO_DE08.FECHA_CORTE) con FUENTE = PR, igual que el SP.
  - Los filtros post cursor son estimados sobre candidatos que pasan el cursor antes del ROWNUM.
*/

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
           TO_NUMBER(PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('PRECAL_DIA_ATRASO_TC')) atraso_tc,
           TO_NUMBER(PA.OBT_PARAMETROS('1', 'PR', 'PRECAL_DESEMBOLSO_PR')) desembolso_post,
           TO_NUMBER(PA.OBT_PARAMETROS('1', 'PR', 'PRECAL_MORA_MAYOR_PR')) mora_post,
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
),
cursor_ok AS (
    SELECT s.*
      FROM scored s
     WHERE s.paso_alcanzado = 18
),
post_flags AS (
    SELECT c.*,
           NVL((
               SELECT MAX(d.dias_atraso)
                 FROM PA.PA_DETALLADO_DE08 d
                WHERE d.fuente = 'PR'
                  AND d.fecha_corte >= ADD_MONTHS(c.fecha_corte_param, -6)
                  AND d.no_credito = c.no_credito
                  AND d.codigo_cliente = c.codigo_cliente
           ), 0) dias_atraso_6m,
           CASE
             WHEN EXISTS (
                    SELECT 1
                      FROM PA.PA_DETALLADO_DE08 d
                     WHERE d.fuente = 'TC'
                       AND d.fecha_corte = c.fecha_corte_param
                       AND d.no_credito != c.no_credito
                       AND d.codigo_cliente = c.codigo_cliente
                       AND d.codigo_empresa = c.codigo_empresa
                       AND d.dias_atraso >= p.atraso_tc
                  )
             THEN 1 ELSE 0
           END f_tc_atraso,
           CASE
             WHEN EXISTS (
                    SELECT 1
                      FROM PR.PR_CREDITOS pc
                     WHERE pc.codigo_empresa = c.codigo_empresa
                       AND pc.no_credito != c.no_credito
                       AND pc.codigo_cliente = c.codigo_cliente
                       AND pc.f_primer_desembolso > ADD_MONTHS(SYSDATE, - p.desembolso_post)
                       AND pc.estado IN (
                            SELECT column_value
                              FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('ESTADOS_CREDITOS'))
                       )
                  )
             THEN 1 ELSE 0
           END f_desembolso_post,
           CASE
             WHEN NVL((
                    SELECT MAX(d.dias_atraso)
                      FROM PA.PA_DETALLADO_DE08 d
                     WHERE d.fuente = 'PR'
                       AND d.fecha_corte >= ADD_MONTHS(c.fecha_corte_param, -6)
                       AND d.no_credito = c.no_credito
                       AND d.codigo_cliente = c.codigo_cliente
                  ), 0) > p.mora_post
             THEN 1 ELSE 0
           END f_mora_6m,
           CASE
             WHEN EXISTS (
                    SELECT 1
                      FROM PA.CUENTA_CLIENTE_RELACION rel
                     WHERE rel.cod_sistema = 'PR'
                       AND rel.num_cuenta = c.no_credito
                       AND NVL(rel.tipo_relacion, 'x') = 'O'
                  )
             THEN 1 ELSE 0
           END f_mancomunado,
           CASE
             WHEN PR.PR_PKG_REPRESTAMOS.F_VALIDAR_EDAD(c.codigo_cliente, 'CARGA') = 0 THEN 0
             ELSE 1
           END f_edad_valida
      FROM cursor_ok c
      CROSS JOIN params p
),
post_scored AS (
    SELECT pf.*,
           CASE
             WHEN pf.f_tc_atraso = 1 THEN 0
             WHEN pf.f_desembolso_post = 1 THEN 1
             WHEN pf.f_mora_6m = 1 THEN 2
             WHEN pf.f_mancomunado = 1 THEN 3
             WHEN pf.f_edad_valida = 0 THEN 4
             ELSE 5
           END paso_post_alcanzado
      FROM post_flags pf
),
post_pasos AS (
    SELECT 0 orden, 'BASE: candidatos insertados por el cursor' filtro FROM dual UNION ALL
    SELECT 1, 'X3: TC con atraso >= PRECAL_DIA_ATRASO_TC' FROM dual UNION ALL
    SELECT 2, 'X1: otro prestamo desembolsado en PRECAL_DESEMBOLSO_PR' FROM dual UNION ALL
    SELECT 3, 'X2: mora maxima ultimos 6 meses > PRECAL_MORA_MAYOR_PR' FROM dual UNION ALL
    SELECT 4, 'DELETE: credito mancomunado en CUENTA_CLIENTE_RELACION' FROM dual UNION ALL
    SELECT 5, 'DELETE: edad invalida para CARGA' FROM dual
),
resumen_post AS (
    SELECT 4 tipo_orden,
           'SECUENCIAL_POST_CURSOR' tipo_medicion,
           p.orden,
           p.filtro,
           COUNT(DISTINCT CASE WHEN p.orden = 0 OR ps.paso_post_alcanzado >= p.orden - 1 THEN ps.candidato_id END) candidatos_antes,
           COUNT(DISTINCT CASE WHEN p.orden = 0 OR ps.paso_post_alcanzado >= p.orden THEN ps.candidato_id END) candidatos_pasan,
           CASE
             WHEN p.orden = 0 THEN 0
             ELSE COUNT(DISTINCT CASE WHEN ps.paso_post_alcanzado = p.orden - 1 THEN ps.candidato_id END)
           END candidatos_descartados,
           CASE
             WHEN p.orden = 0 THEN 0
             ELSE COUNT(DISTINCT CASE WHEN ps.paso_post_alcanzado = p.orden - 1 THEN ps.no_credito END)
           END creditos_descartados,
           CASE
             WHEN p.orden = 0 THEN 0
             ELSE COUNT(DISTINCT CASE WHEN ps.paso_post_alcanzado = p.orden - 1 THEN ps.codigo_cliente END)
           END clientes_descartados,
           'Descartes posteriores respetando el orden de updates/deletes del SP' observacion
      FROM post_pasos p
      LEFT JOIN post_scored ps
        ON 1 = 1
     GROUP BY p.orden, p.filtro
),
resumen_cleanup AS (
    SELECT 5 tipo_orden,
           'POST_CLEANUP' tipo_medicion,
           98 orden,
           'DELETE PR_REPRESTAMOS WHERE ESTADO LIKE X%' filtro,
           COUNT(DISTINCT ps.candidato_id) candidatos_antes,
           COUNT(DISTINCT CASE WHEN ps.paso_post_alcanzado >= 3 THEN ps.candidato_id END) candidatos_pasan,
           COUNT(DISTINCT CASE WHEN ps.paso_post_alcanzado IN (0, 1, 2) THEN ps.candidato_id END) candidatos_descartados,
           COUNT(DISTINCT CASE WHEN ps.paso_post_alcanzado IN (0, 1, 2) THEN ps.no_credito END) creditos_descartados,
           COUNT(DISTINCT CASE WHEN ps.paso_post_alcanzado IN (0, 1, 2) THEN ps.codigo_cliente END) clientes_descartados,
           'Limpieza fisica de registros marcados X3/X1/X2; ya contados arriba' observacion
      FROM post_scored ps
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
        UNION ALL
        SELECT * FROM resumen_post
        UNION ALL
        SELECT * FROM resumen_cleanup
       )
 ORDER BY tipo_orden, orden
