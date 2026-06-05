-- QA02 - Diagnostico: cancelados recientes en PR_CREDITOS sin espejo reciente en PR_CREDITOS_HI, evaluados contra Precalifica_Repre_Cancelado
WITH params AS (
    SELECT TO_NUMBER(PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('DIAS_CANCELACION')) dias_cancelacion,
           TO_NUMBER(PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('MESES_MAX_X_DESEMBOLSO')) meses_desembolso,
           PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO empresa,
           PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('PERSONA_FISICA') persona_fisica,
           PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('CLIENTES_A_SOLA_FIRMA') clientes_a_sola_firma
      FROM dual
),
base_cancelados AS (
    SELECT a.codigo_empresa,
           a.codigo_cliente,
           a.no_credito,
           a.tipo_credito,
           a.codigo_periodo_cuota,
           a.f_cancelacion,
           a.estado,
           a.f_primer_desembolso
      FROM PR.PR_CREDITOS a
      CROSS JOIN params p
     WHERE a.estado = 'C'
       AND a.f_cancelacion >= SYSDATE - p.dias_cancelacion
       AND a.f_cancelacion <= SYSDATE
),
diagnostico AS (
    SELECT b.*,
           (SELECT MAX(h.f_cancelacion)
              FROM PR.PR_CREDITOS_HI h
             WHERE h.no_credito = b.no_credito
               AND h.estado = 'C') ultima_cancelacion_hi,
           CASE
             WHEN EXISTS (
                    SELECT 1
                      FROM PR.PR_CREDITOS_HI h
                      CROSS JOIN params p
                     WHERE h.no_credito = b.no_credito
                       AND h.estado = 'C'
                       AND h.f_cancelacion >= SYSDATE - p.dias_cancelacion
                       AND h.f_cancelacion <= SYSDATE
                  ) THEN 'S'
             ELSE 'N'
           END existe_en_hi_reciente,
           CASE
             WHEN EXISTS (
                    SELECT 1
                      FROM PR.PR_TIPO_CREDITO_REPRESTAMO t
                     WHERE t.tipo_credito = b.tipo_credito
                  ) THEN 'S'
             ELSE 'N'
           END f_tipo_credito,
           CASE
             WHEN EXISTS (
                    SELECT 1
                      FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('PERIODOS_CUOTA')) pc
                     WHERE pc.column_value = b.codigo_periodo_cuota
                  )
               OR NOT EXISTS (
                    SELECT 1
                      FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('PERIODOS_CUOTA')) pc
                  ) THEN 'S'
             ELSE 'N'
           END f_periodo_cuota,
           CASE
             WHEN EXISTS (
                    SELECT 1
                      FROM PR.PR_TIPO_CREDITO_REPRESTAMO t
                     WHERE t.tipo_credito = b.tipo_credito
                       AND t.carga = 'S'
                  ) THEN 'S'
             ELSE 'N'
           END f_carga,
           CASE WHEN b.codigo_empresa = (SELECT empresa FROM params) THEN 'S' ELSE 'N' END f_empresa,
           CASE
             WHEN NOT EXISTS (
                    SELECT 1
                      FROM PR.PR_CREDITOS c
                      CROSS JOIN params p
                     WHERE c.codigo_empresa = b.codigo_empresa
                       AND c.no_credito != b.no_credito
                       AND c.codigo_cliente = b.codigo_cliente
                       AND c.f_primer_desembolso > ADD_MONTHS(SYSDATE, - p.meses_desembolso)
                       AND c.estado IN (
                            SELECT column_value
                              FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('ESTADOS_CREDITOS'))
                       )
                  ) THEN 'S'
             ELSE 'N'
           END f_sin_desembolso_reciente,
           CASE
             WHEN NOT EXISTS (
                    SELECT 1
                      FROM PR.PR_CREDITOS c
                     WHERE c.codigo_empresa = b.codigo_empresa
                       AND c.no_credito != b.no_credito
                       AND c.codigo_cliente = b.codigo_cliente
                       AND c.estado = 'E'
                  ) THEN 'S'
             ELSE 'N'
           END f_sin_estado_e,
           CASE
             WHEN EXISTS (
                    SELECT 1
                      FROM PA.PERSONAS per
                      CROSS JOIN params p
                     WHERE per.cod_persona = CAST(b.codigo_cliente AS VARCHAR2(15))
                       AND per.es_fisica = p.persona_fisica
                  ) THEN 'S'
             ELSE 'N'
           END f_persona_fisica,
           CASE
             WHEN EXISTS (
                    SELECT 1
                      FROM PA.ID_PERSONAS idp
                     WHERE idp.cod_persona = CAST(b.codigo_cliente AS VARCHAR2(15))
                       AND idp.cod_pais IN (
                            SELECT column_value
                              FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('NACIONALIDAD'))
                       )
                       AND idp.cod_tipo_id IN (
                            SELECT column_value
                              FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('TIPO_DOCUMENTO'))
                       )
                  ) THEN 'S'
             ELSE 'N'
           END f_documento,
           CASE
             WHEN NOT EXISTS (
                    SELECT 1
                      FROM PR.PR_REPRESTAMOS r
                     WHERE r.codigo_empresa = b.codigo_empresa
                       AND r.no_credito = b.no_credito
                       AND r.estado IN (
                            SELECT column_value
                              FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('ESTADOS_NO_REPROCESO'))
                       )
                  ) THEN 'S'
             ELSE 'N'
           END f_sin_represtamo_en_proceso,
           CASE
             WHEN NOT EXISTS (
                    SELECT 1
                      FROM PR.PR_CREDITOS a1
                      JOIN PR.PR_AVAL_REPRE_X_CREDITO aval
                        ON aval.codigo_empresa = a1.codigo_empresa
                       AND aval.no_credito = a1.no_credito
                      CROSS JOIN params p
                     WHERE a1.codigo_empresa = 1
                       AND a1.no_credito = b.no_credito
                       AND aval.codigo_aval_repre != a1.codigo_cliente
                       AND p.clientes_a_sola_firma = 'S'
                  ) THEN 'S'
             ELSE 'N'
           END f_sola_firma,
           CASE WHEN PR.PR_PKG_REPRESTAMOS.F_TIENE_GARANTIA(b.no_credito) = 0 THEN 'S' ELSE 'N' END f_sin_garantia,
           CASE WHEN PR.PR_PKG_REPRESTAMOS.F_VALIDAR_LISTAS_PEP(1, b.codigo_cliente) = 0 THEN 'S' ELSE 'N' END f_no_pep,
           CASE WHEN PR.PR_PKG_REPRESTAMOS.F_VALIDAR_LISTA_NEGRA(1, b.codigo_cliente) = 0 THEN 'S' ELSE 'N' END f_no_lista_negra
      FROM base_cancelados b
)
SELECT d.codigo_empresa,
       d.codigo_cliente,
       d.no_credito,
       d.tipo_credito,
       d.codigo_periodo_cuota,
       d.estado,
       d.f_cancelacion,
       TRUNC(SYSDATE) - TRUNC(d.f_cancelacion) dias_desde_cancelacion,
       d.ultima_cancelacion_hi,
       d.existe_en_hi_reciente,
       CASE
         WHEN d.f_tipo_credito = 'S'
          AND d.f_periodo_cuota = 'S'
          AND d.f_carga = 'S'
          AND d.f_empresa = 'S'
          AND d.f_sin_desembolso_reciente = 'S'
          AND d.f_sin_estado_e = 'S'
          AND d.f_persona_fisica = 'S'
          AND d.f_documento = 'S'
          AND d.f_sin_represtamo_en_proceso = 'S'
          AND d.f_sola_firma = 'S'
          AND d.f_sin_garantia = 'S'
          AND d.f_no_pep = 'S'
          AND d.f_no_lista_negra = 'S'
         THEN 'SI_PASARIA_CANCELADO_NORMAL'
         ELSE 'NO_PASARIA_CANCELADO_NORMAL'
       END resultado_filtros,
       CASE
         WHEN d.f_tipo_credito = 'N' THEN 'TIPO_CREDITO no parametrizado'
         WHEN d.f_periodo_cuota = 'N' THEN 'PERIODOS_CUOTA no permitido'
         WHEN d.f_carga = 'N' THEN 'Tipo credito no tiene CARGA = S'
         WHEN d.f_empresa = 'N' THEN 'Empresa no coincide'
         WHEN d.f_sin_desembolso_reciente = 'N' THEN 'Tiene otro prestamo reciente'
         WHEN d.f_sin_estado_e = 'N' THEN 'Tiene otro credito estado E'
         WHEN d.f_persona_fisica = 'N' THEN 'No cumple persona fisica'
         WHEN d.f_documento = 'N' THEN 'Nacionalidad o documento no valido'
         WHEN d.f_sin_represtamo_en_proceso = 'N' THEN 'Ya tiene represtamo en estado no reproceso'
         WHEN d.f_sola_firma = 'N' THEN 'Incumple regla sola firma'
         WHEN d.f_sin_garantia = 'N' THEN 'Tiene garantia'
         WHEN d.f_no_pep = 'N' THEN 'Esta en PEP'
         WHEN d.f_no_lista_negra = 'N' THEN 'Esta en lista negra'
         ELSE 'Pasa filtros principales'
       END primer_filtro_que_lo_detiene,
       d.f_tipo_credito,
       d.f_periodo_cuota,
       d.f_carga,
       d.f_empresa,
       d.f_sin_desembolso_reciente,
       d.f_sin_estado_e,
       d.f_persona_fisica,
       d.f_documento,
       d.f_sin_represtamo_en_proceso,
       d.f_sola_firma,
       d.f_sin_garantia,
       d.f_no_pep,
       d.f_no_lista_negra
  FROM diagnostico d
 WHERE d.existe_en_hi_reciente = 'N'
 ORDER BY d.f_cancelacion DESC,
          d.codigo_cliente,
          d.no_credito
