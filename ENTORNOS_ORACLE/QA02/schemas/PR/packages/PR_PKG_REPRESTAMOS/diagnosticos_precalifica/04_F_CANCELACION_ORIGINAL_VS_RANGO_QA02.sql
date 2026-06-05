-- QA02 - Diagnostico: compara condicion original de F_CANCELACION contra rango directo
WITH params AS (
    SELECT TO_NUMBER(PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('DIAS_CANCELACION')) dias_cancelacion
      FROM dual
),
evaluacion AS (
    SELECT a.codigo_empresa,
           a.codigo_cliente,
           a.no_credito,
           a.tipo_credito,
           a.estado,
           a.f_cancelacion,
           CASE
             WHEN EXISTS (
                    SELECT 1
                      FROM PR.PR_CREDITOS d
                      CROSS JOIN params p
                     WHERE d.no_credito = a.no_credito
                       AND d.f_cancelacion >= SYSDATE - p.dias_cancelacion
                       AND d.f_cancelacion <= SYSDATE
                       AND d.f_cancelacion = a.f_cancelacion
                       AND d.estado = 'C'
                  ) THEN 1
             ELSE 0
           END pasa_original,
           CASE
             WHEN a.estado = 'C'
              AND a.f_cancelacion BETWEEN SYSDATE - p.dias_cancelacion AND SYSDATE
             THEN 1
             ELSE 0
           END pasa_rango,
           CASE
             WHEN EXISTS (
                    SELECT 1
                      FROM PR.PR_CREDITOS d
                      CROSS JOIN params p
                     WHERE d.no_credito = a.no_credito
                       AND d.f_cancelacion >= SYSDATE - p.dias_cancelacion
                       AND d.f_cancelacion <= SYSDATE
                       AND d.f_cancelacion = a.f_cancelacion
                       AND d.estado = 'C'
                  ) THEN 1
             ELSE 0
           END pasa_original,
           CASE
             WHEN a.estado = 'C'
              AND a.f_cancelacion BETWEEN SYSDATE - p.dias_cancelacion AND SYSDATE
             THEN 1
             ELSE 0
           END pasa_rango
      FROM PR.PR_CREDITOS a
      CROSS JOIN params p
)
SELECT COUNT(*) total_creditos,
       COUNT(CASE WHEN pasa_original = 1 THEN 1 END) pasan_original,
       COUNT(CASE WHEN pasa_rango = 1 THEN 1 END) pasan_rango,
       COUNT(CASE WHEN pasa_original = 1 AND pasa_rango = 1 THEN 1 END) pasan_ambos,
       COUNT(CASE WHEN pasa_original = 1 AND pasa_rango = 0 THEN 1 END) solo_original,
       COUNT(CASE WHEN pasa_original = 0 AND pasa_rango = 1 THEN 1 END) solo_rango
  FROM evaluacion;

WITH params AS (
    SELECT TO_NUMBER(PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('DIAS_CANCELACION')) dias_cancelacion
      FROM dual
),
evaluacion AS (
    SELECT a.codigo_empresa,
           a.codigo_cliente,
           a.no_credito,
           a.tipo_credito,
           a.estado,
           a.f_cancelacion,
           CASE
             WHEN EXISTS (
                    SELECT 1
                      FROM PR.PR_CREDITOS d
                      CROSS JOIN params p
                     WHERE d.no_credito = a.no_credito
                       AND d.f_cancelacion >= SYSDATE - p.dias_cancelacion
                       AND d.f_cancelacion <= SYSDATE
                       AND d.f_cancelacion = a.f_cancelacion
                       AND d.estado = 'C'
                  ) THEN 'SI_PASA_ORIGINAL'
             ELSE 'NO_PASA_ORIGINAL'
           END resultado_original,
           CASE
             WHEN a.estado = 'C'
              AND a.f_cancelacion BETWEEN SYSDATE - p.dias_cancelacion AND SYSDATE
             THEN 'SI_PASA_RANGO'
             ELSE 'NO_PASA_RANGO'
           END resultado_rango
      FROM PR.PR_CREDITOS a
      CROSS JOIN params p
)
SELECT codigo_empresa,
       codigo_cliente,
       no_credito,
       tipo_credito,
       estado,
       f_cancelacion,
       resultado_original,
       resultado_rango
  FROM evaluacion
 WHERE pasa_original != pasa_rango
 ORDER BY f_cancelacion DESC,
          codigo_cliente,
          no_credito
