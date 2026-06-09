-- =====================================================================
-- Validacion base antes del tracking integral
-- Entorno: QA02
-- Objeto: PR.PR_PKG_REPRESTAMOS
-- Fecha: 2026-06-08
-- Solo lectura. Ejecutar en Toad antes de aplicar cambios.
-- =====================================================================

PROMPT 1. Estado del package

SELECT owner,
       object_name,
       object_type,
       status,
       last_ddl_time
  FROM all_objects
 WHERE owner = 'PR'
   AND object_name = 'PR_PKG_REPRESTAMOS'
 ORDER BY object_type;

PROMPT 2. Errores de compilacion existentes

SELECT type,
       line,
       position,
       text
  FROM all_errors
 WHERE owner = 'PR'
   AND name = 'PR_PKG_REPRESTAMOS'
 ORDER BY sequence;

PROMPT 3. Objetos de tracking existentes

SELECT owner,
       object_name,
       object_type,
       status
  FROM all_objects
 WHERE owner = 'PR'
   AND object_name IN (
       'PR_JOB_PRECALIFICA_TRACK',
       'PR_JOB_PRECALIFICA_FILTRO_TRACK',
       'PR_JOB_PRECALIFICA_CANDIDATO_TRACK'
   )
 ORDER BY object_name, object_type;

PROMPT 4. Parametros relevantes

SELECT 'LOTE_DE_CARAGA_REPRESTAMO' codigo,
       PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO(
           'LOTE_DE_CARAGA_REPRESTAMO'
       ) valor
  FROM dual
UNION ALL
SELECT 'PRECAL_MORA_MAYOR_PR',
       PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO(
           'PRECAL_MORA_MAYOR_PR'
       )
  FROM dual
UNION ALL
SELECT 'PRECAL_DIA_ATRASO_TC',
       PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO(
           'PRECAL_DIA_ATRASO_TC'
       )
  FROM dual;

PROMPT 5. Ultimas ejecuciones del tracking actual

SELECT *
  FROM (
        SELECT id_ejecucion,
               id_paso,
               proceso,
               estado,
               fecha_inicio,
               fecha_fin,
               duracion_segundos,
               registros_re,
               error_code
          FROM PR.PR_JOB_PRECALIFICA_TRACK
         ORDER BY fecha_inicio DESC, id_paso
       )
 WHERE ROWNUM <= 50;

PROMPT 6. Conteo funcional previo

SELECT estado,
       COUNT(*) cantidad
  FROM PR.PR_REPRESTAMOS
 GROUP BY estado
 ORDER BY estado;
