-- =====================================================================
-- Precheck de ejecucion para la capa DIAGNOSTICA
-- Entorno: QA02. Solo lectura. Ejecutar como script (F5).
-- Debe terminar en segundos y mostrar una fila en Script Output.
-- No ejecuta los conteos pesados ni inserta datos.
-- =====================================================================

SET ECHO ON
SET FEEDBACK ON
SET TIMING ON

PROMPT ===== PRECHECK DIAGNOSTICA QA02 INICIADO =====

SELECT SYSTIMESTAMP fecha_precheck,
       SYS_CONTEXT('USERENV', 'DB_NAME') base_datos,
       SYS_CONTEXT('USERENV', 'SESSION_USER') usuario,
       (SELECT MAX(valor)
          FROM PA.PA_PARAMETROS_MVP
         WHERE codigo_empresa = 1
           AND codigo_mvp = 'REPRESTAMOS'
           AND codigo_parametro = 'TRACK_PRECALIFICA_DETALLE_CURSOR')
           gate_detalle_cursor,
       PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO(
           'LOTE_DE_CARAGA_REPRESTAMO'
       ) valor_lote,
       (SELECT MAX(id_ejecucion)
               KEEP (DENSE_RANK LAST ORDER BY fecha_inicio)
          FROM PR.PR_JOB_PRECALIFICA_TRACK
         WHERE id_paso = 0)
           ultima_ejecucion
  FROM dual;

PROMPT ===== PRECHECK DIAGNOSTICA QA02 FINALIZADO =====
