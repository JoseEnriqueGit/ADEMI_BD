WITH params AS (
    SELECT (SELECT MAX(p.fecha_corte)
              FROM PA.PA_DETALLADO_DE08 p
             WHERE p.fuente = 'PR') fecha_corte,
           TO_NUMBER(PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('LOTE_DE_CARAGA_REPRESTAMO')) lote,
           TO_NUMBER(PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('DIAS_CANCELACION')) dias_cancelacion,
           TO_NUMBER(PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('MESES_MAX_X_DESEMBOLSO')) meses_desembolso,
           TO_NUMBER(PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('PRECAL_DIA_ATRASO_TC')) atraso_tc,
           TO_NUMBER(PA.OBT_PARAMETROS('1', 'PR', 'PRECAL_DESEMBOLSO_PR')) desembolso_post,
           TO_NUMBER(PA.OBT_PARAMETROS('1', 'PR', 'PRECAL_MORA_MAYOR_PR')) mora_post,
           PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO empresa,
           PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('PERSONA_FISICA') persona_fisica,
           PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('CLIENTES_A_SOLA_FIRMA') clientes_a_sola_firma
      FROM dual
),
base_creditos AS (
    SELECT a.*
      FROM PR.PR_CREDITOS_HI a
),
con_tipo_represtamo AS (
    SELECT a.*, c.carga carga_represtamo
      FROM base_creditos a
      JOIN PR.PR_TIPO_CREDITO_REPRESTAMO c
        ON c.tipo_credito = a.tipo_credito
),
periodo_cuota_ok AS (
    SELECT a.*
      FROM con_tipo_represtamo a
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
cancelacion_reciente AS (
    SELECT ROWNUM candidato_id,
           a.codigo_empresa,
           a.codigo_cliente,
           a.no_credito,
           a.tipo_credito,
           a.codigo_periodo_cuota,
           a.f_primer_desembolso,
           a.f_cancelacion,
           a.estado estado_credito,
           p.fecha_corte fecha_corte_param,
           a.carga_represtamo
      FROM periodo_cuota_ok a
      CROSS JOIN params p
     WHERE EXISTS (
              SELECT 1
                FROM PR.PR_CREDITOS_HI d
               WHERE d.no_credito = a.no_credito
                 AND d.estado = 'C'
                 AND d.f_cancelacion = a.f_cancelacion
                 AND d.f_cancelacion >= SYSDATE - p.dias_cancelacion
                 AND d.f_cancelacion <= SYSDATE
           )
),
carga_si AS (
    SELECT a.*
      FROM cancelacion_reciente a
     WHERE a.carga_represtamo = 'S'
),
empresa_ok AS (
    SELECT a.*
      FROM carga_si a
      CROSS JOIN params p
     WHERE a.codigo_empresa = p.empresa
),
sin_desembolso_reciente AS (
    SELECT a.*
      FROM empresa_ok a
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
sin_credito_estado_e AS (
    SELECT a.*
      FROM sin_desembolso_reciente a
     WHERE NOT EXISTS (
              SELECT 1
                FROM PR.PR_CREDITOS c
               WHERE c.codigo_empresa = a.codigo_empresa
                 AND c.no_credito != a.no_credito
                 AND c.codigo_cliente = a.codigo_cliente
                 AND c.estado = 'E'
           )
),
persona_fisica_ok AS (
    SELECT a.*
      FROM sin_credito_estado_e a
      CROSS JOIN params p
     WHERE EXISTS (
              SELECT 1
                FROM PA.PERSONAS per
               WHERE per.cod_persona = CAST(a.codigo_cliente AS VARCHAR2(15))
                 AND per.es_fisica = p.persona_fisica
           )
),
nacionalidad_documento_ok AS (
    SELECT a.*
      FROM persona_fisica_ok a
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
sin_represtamo_en_proceso AS (
    SELECT a.*
      FROM nacionalidad_documento_ok a
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
sola_firma_ok AS (
    SELECT a.*
      FROM sin_represtamo_en_proceso a
      CROSS JOIN params p
     WHERE NOT EXISTS (
              SELECT 1
                FROM PR.PR_CREDITOS_HI a1
                JOIN PR.PR_AVAL_REPRE_X_CREDITO aval
                  ON aval.codigo_empresa = a1.codigo_empresa
                 AND aval.no_credito = a1.no_credito
               WHERE a1.codigo_empresa = 1
                 AND a1.no_credito = a.no_credito
                 AND aval.codigo_aval_repre != a1.codigo_cliente
                 AND p.clientes_a_sola_firma = 'S'
           )
),
sin_garantia AS (
    SELECT a.*
      FROM sola_firma_ok a
     WHERE PR.PR_PKG_REPRESTAMOS.F_TIENE_GARANTIA_HISTORICO(a.no_credito) = 0
),
no_pep AS (
    SELECT a.*
      FROM sin_garantia a
     WHERE PR.PR_PKG_REPRESTAMOS.F_VALIDAR_LISTAS_PEP(1, a.codigo_cliente) = 0
),
no_lista_negra AS (
    SELECT a.*
      FROM no_pep a
     WHERE PR.PR_PKG_REPRESTAMOS.F_VALIDAR_LISTA_NEGRA(1, a.codigo_cliente) = 0
),
lote_cursor AS (
    SELECT q.*
      FROM no_lista_negra q
      CROSS JOIN params p
     WHERE ROWNUM <= p.lote
),
mora_6m AS (
    SELECT l.candidato_id,
           NVL(MAX(d.dias_atraso), 0) dias_atraso_6m
      FROM lote_cursor l
      LEFT JOIN PA.PA_DETALLADO_DE08 d
        ON d.fuente = 'PR'
       AND d.fecha_corte >= ADD_MONTHS(l.fecha_corte_param, -6)
       AND d.no_credito = l.no_credito
       AND d.codigo_cliente = l.codigo_cliente
     GROUP BY l.candidato_id
),
tc_atraso AS (
    SELECT DISTINCT l.candidato_id
      FROM lote_cursor l
      CROSS JOIN params p
      JOIN PA.PA_DETALLADO_DE08 d
        ON d.fuente = 'TC'
       AND d.fecha_corte = l.fecha_corte_param
       AND d.no_credito != l.no_credito
       AND d.codigo_cliente = l.codigo_cliente
       AND d.codigo_empresa = l.codigo_empresa
       AND d.dias_atraso >= p.atraso_tc
),
desembolso_reciente AS (
    SELECT DISTINCT l.candidato_id
      FROM lote_cursor l
      CROSS JOIN params p
      JOIN PR.PR_CREDITOS pc
        ON pc.codigo_empresa = l.codigo_empresa
       AND pc.no_credito != l.no_credito
       AND pc.codigo_cliente = l.codigo_cliente
       AND pc.f_primer_desembolso > ADD_MONTHS(SYSDATE, - p.desembolso_post)
       AND pc.estado IN (
            SELECT column_value
              FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('ESTADOS_CREDITOS'))
       )
),
mancomunado AS (
    SELECT DISTINCT l.candidato_id
      FROM lote_cursor l
      JOIN PA.CUENTA_CLIENTE_RELACION rel
        ON rel.cod_sistema = 'PR'
       AND rel.num_cuenta = l.no_credito
       AND NVL(rel.tipo_relacion, 'x') = 'O'
),
edad AS (
    SELECT l.candidato_id,
           CASE
             WHEN PR.PR_PKG_REPRESTAMOS.F_VALIDAR_EDAD(l.codigo_cliente, 'CARGA') = 0 THEN 0
             ELSE 1
           END f_edad_valida
      FROM lote_cursor l
),
post_flags AS (
    SELECT l.*,
           m.dias_atraso_6m,
           CASE WHEN tc.candidato_id IS NOT NULL THEN 1 ELSE 0 END f_tc_atraso,
           CASE WHEN dr.candidato_id IS NOT NULL THEN 1 ELSE 0 END f_desembolso_post,
           CASE WHEN m.dias_atraso_6m > p.mora_post THEN 1 ELSE 0 END f_mora_6m,
           CASE WHEN man.candidato_id IS NOT NULL THEN 1 ELSE 0 END f_mancomunado,
           e.f_edad_valida
      FROM lote_cursor l
      CROSS JOIN params p
      LEFT JOIN mora_6m m
        ON m.candidato_id = l.candidato_id
      LEFT JOIN tc_atraso tc
        ON tc.candidato_id = l.candidato_id
      LEFT JOIN desembolso_reciente dr
        ON dr.candidato_id = l.candidato_id
      LEFT JOIN mancomunado man
        ON man.candidato_id = l.candidato_id
      LEFT JOIN edad e
        ON e.candidato_id = l.candidato_id
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
conteos_cursor AS (
    SELECT 0 orden, COUNT(*) cantidad FROM base_creditos UNION ALL
    SELECT 1, COUNT(*) FROM con_tipo_represtamo UNION ALL
    SELECT 2, COUNT(*) FROM periodo_cuota_ok UNION ALL
    SELECT 3, COUNT(*) FROM cancelacion_reciente UNION ALL
    SELECT 4, COUNT(*) FROM carga_si UNION ALL
    SELECT 5, COUNT(*) FROM empresa_ok UNION ALL
    SELECT 6, COUNT(*) FROM sin_desembolso_reciente UNION ALL
    SELECT 7, COUNT(*) FROM sin_credito_estado_e UNION ALL
    SELECT 8, COUNT(*) FROM persona_fisica_ok UNION ALL
    SELECT 9, COUNT(*) FROM nacionalidad_documento_ok UNION ALL
    SELECT 10, COUNT(*) FROM sin_represtamo_en_proceso UNION ALL
    SELECT 11, COUNT(*) FROM sola_firma_ok UNION ALL
    SELECT 12, COUNT(*) FROM sin_garantia UNION ALL
    SELECT 13, COUNT(*) FROM no_pep UNION ALL
    SELECT 14, COUNT(*) FROM no_lista_negra
),
pasos_cursor AS (
    SELECT 0 orden, 'BASE: PR_CREDITOS_HI' filtro FROM dual UNION ALL
    SELECT 1, 'TIPO_CREDITO existe en PR_TIPO_CREDITO_REPRESTAMO' FROM dual UNION ALL
    SELECT 2, 'PERIODOS_CUOTA permitido o parametro vacio' FROM dual UNION ALL
    SELECT 3, 'F_CANCELACION dentro de DIAS_CANCELACION y estado C' FROM dual UNION ALL
    SELECT 4, 'PR_TIPO_CREDITO_REPRESTAMO.CARGA = S' FROM dual UNION ALL
    SELECT 5, 'CODIGO_EMPRESA = F_OBT_EMPRESA_REPRESTAMO' FROM dual UNION ALL
    SELECT 6, 'Sin otro prestamo desembolsado reciente' FROM dual UNION ALL
    SELECT 7, 'Sin otro credito estado E' FROM dual UNION ALL
    SELECT 8, 'Cliente persona fisica' FROM dual UNION ALL
    SELECT 9, 'Nacionalidad y tipo documento validos' FROM dual UNION ALL
    SELECT 10, 'Sin represtamo en estados no reproceso' FROM dual UNION ALL
    SELECT 11, 'No incumple regla de sola firma historica' FROM dual UNION ALL
    SELECT 12, 'F_TIENE_GARANTIA_HISTORICO = 0' FROM dual UNION ALL
    SELECT 13, 'No esta en listas PEP' FROM dual UNION ALL
    SELECT 14, 'No esta en lista negra' FROM dual
),
resumen_cursor AS (
    SELECT 1 tipo_orden,
           'SECUENCIAL_CURSOR' tipo_medicion,
           p.orden,
           p.filtro,
           b.cantidad candidatos_antes,
           a.cantidad candidatos_pasan,
           b.cantidad - a.cantidad candidatos_descartados,
           CAST(NULL AS NUMBER) creditos_descartados,
           CAST(NULL AS NUMBER) clientes_descartados,
           'Conteo rapido por filas candidatas del cursor' observacion
      FROM pasos_cursor p
      JOIN conteos_cursor a ON a.orden = p.orden
      JOIN conteos_cursor b ON b.orden = CASE WHEN p.orden = 0 THEN 0 ELSE p.orden - 1 END
),
resumen_lote AS (
    SELECT 2 tipo_orden,
           'LIMITE_LOTE' tipo_medicion,
           99 orden,
           'ROWNUM <= LOTE_DE_CARAGA_REPRESTAMO aplicado antes del post cursor' filtro,
           (SELECT COUNT(*) FROM no_lista_negra) candidatos_antes,
           (SELECT COUNT(*) FROM lote_cursor) candidatos_pasan,
           (SELECT COUNT(*) FROM no_lista_negra) - (SELECT COUNT(*) FROM lote_cursor) candidatos_descartados,
           CAST(NULL AS NUMBER) creditos_descartados,
           CAST(NULL AS NUMBER) clientes_descartados,
           'Simula el lote que el cursor insertaria antes de updates/deletes posteriores' observacion
      FROM dual
),
post_pasos AS (
    SELECT 0 orden, 'BASE: candidatos del lote' filtro FROM dual UNION ALL
    SELECT 1, 'X3: TC con atraso >= PRECAL_DIA_ATRASO_TC' FROM dual UNION ALL
    SELECT 2, 'X1: otro prestamo desembolsado en PRECAL_DESEMBOLSO_PR' FROM dual UNION ALL
    SELECT 3, 'X2: mora maxima ultimos 6 meses > PRECAL_MORA_MAYOR_PR' FROM dual UNION ALL
    SELECT 4, 'DELETE: credito mancomunado en CUENTA_CLIENTE_RELACION' FROM dual UNION ALL
    SELECT 5, 'DELETE: edad invalida para CARGA' FROM dual
),
resumen_post AS (
    SELECT 3 tipo_orden,
           'SECUENCIAL_POST_CURSOR' tipo_medicion,
           p.orden,
           p.filtro,
           COUNT(CASE WHEN ps.candidato_id IS NOT NULL
                        AND (p.orden = 0 OR ps.paso_post_alcanzado >= p.orden - 1) THEN 1 END) candidatos_antes,
           COUNT(CASE WHEN ps.candidato_id IS NOT NULL
                        AND (p.orden = 0 OR ps.paso_post_alcanzado >= p.orden) THEN 1 END) candidatos_pasan,
           CASE
             WHEN p.orden = 0 THEN 0
             ELSE COUNT(CASE WHEN ps.paso_post_alcanzado = p.orden - 1 THEN 1 END)
           END candidatos_descartados,
           CASE
             WHEN p.orden = 0 THEN 0
             ELSE COUNT(DISTINCT CASE WHEN ps.paso_post_alcanzado = p.orden - 1 THEN ps.no_credito END)
           END creditos_descartados,
           CASE
             WHEN p.orden = 0 THEN 0
             ELSE COUNT(DISTINCT CASE WHEN ps.paso_post_alcanzado = p.orden - 1 THEN ps.codigo_cliente END)
           END clientes_descartados,
           'Post cursor calculado solo sobre el lote' observacion
      FROM post_pasos p
      LEFT JOIN post_scored ps
        ON 1 = 1
     GROUP BY p.orden, p.filtro
),
resumen_cleanup AS (
    SELECT 4 tipo_orden,
           'POST_CLEANUP' tipo_medicion,
           98 orden,
           'DELETE PR_REPRESTAMOS WHERE ESTADO LIKE X%' filtro,
           COUNT(CASE WHEN ps.paso_post_alcanzado IN (0, 1, 2, 5) THEN 1 END) candidatos_antes,
           COUNT(CASE WHEN ps.paso_post_alcanzado = 5 THEN 1 END) candidatos_pasan,
           COUNT(CASE WHEN ps.paso_post_alcanzado IN (0, 1, 2) THEN 1 END) candidatos_descartados,
           COUNT(DISTINCT CASE WHEN ps.paso_post_alcanzado IN (0, 1, 2) THEN ps.no_credito END) creditos_descartados,
           COUNT(DISTINCT CASE WHEN ps.paso_post_alcanzado IN (0, 1, 2) THEN ps.codigo_cliente END) clientes_descartados,
           'Limpieza fisica de registros marcados X3/X1/X2; mancomunado y edad ya fueron DELETE previos' observacion
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
        SELECT * FROM resumen_cursor
        UNION ALL
        SELECT * FROM resumen_lote
        UNION ALL
        SELECT * FROM resumen_post
        UNION ALL
        SELECT * FROM resumen_cleanup
       )
 ORDER BY tipo_orden, orden
