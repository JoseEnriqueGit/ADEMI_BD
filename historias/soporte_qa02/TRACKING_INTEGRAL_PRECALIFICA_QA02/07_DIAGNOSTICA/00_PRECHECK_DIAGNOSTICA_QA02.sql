-- =====================================================================
-- Precheck de ejecucion para la capa DIAGNOSTICA
-- Entorno: QA02. Solo lectura. Ejecutar como script (F5).
-- Debe terminar en segundos y mostrar el avance por pasos en Script Output.
-- No ejecuta los conteos pesados ni inserta datos.
-- =====================================================================

SET ECHO ON
SET FEEDBACK ON
SET TIMING ON

PROMPT ===== PRECHECK DIAGNOSTICA QA02 INICIADO =====

PROMPT PASO 1 - Conexion y SELECT desde DUAL

SELECT SYSTIMESTAMP fecha_precheck,
       SYS_CONTEXT('USERENV', 'DB_NAME') base_datos,
       SYS_CONTEXT('USERENV', 'SESSION_USER') usuario
  FROM dual;

PROMPT PASO 1 FINALIZADO
PROMPT PASO 2 - Gate directo en PA_PARAMETROS_MVP

SELECT MAX(valor) gate_detalle_cursor
  FROM PA.PA_PARAMETROS_MVP
 WHERE codigo_empresa = 1
   AND codigo_mvp = 'REPRESTAMOS'
   AND codigo_parametro = 'TRACK_PRECALIFICA_DETALLE_CURSOR';

PROMPT PASO 2 FINALIZADO
PROMPT PASO 3 - Lote directo en PA_PARAMETROS_MVP

SELECT MAX(valor) valor_lote_directo
  FROM PA.PA_PARAMETROS_MVP
 WHERE codigo_empresa = 1
   AND codigo_mvp = 'REPRESTAMOS'
   AND codigo_parametro = 'LOTE_DE_CARAGA_REPRESTAMO';

PROMPT PASO 3 FINALIZADO
PROMPT PASO 4 - Ultima ejecucion de PR_JOB_PRECALIFICA_TRACK

SELECT id_ejecucion ultima_ejecucion,
       fecha_inicio
  FROM (
        SELECT id_ejecucion,
               fecha_inicio
          FROM PR.PR_JOB_PRECALIFICA_TRACK
         WHERE id_paso = 0
         ORDER BY fecha_inicio DESC
       )
 WHERE ROWNUM = 1;

PROMPT PASO 4 FINALIZADO
PROMPT PASO 5 - Funcion F_OBT_PARAMETRO_REPRESTAMO
PROMPT Si se detiene aqui, cancelar y reportar espera en la funcion del package

SELECT PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO(
           'LOTE_DE_CARAGA_REPRESTAMO'
       ) valor_lote_package
  FROM dual;

PROMPT PASO 5 FINALIZADO
PROMPT ===== PRECHECK DIAGNOSTICA QA02 FINALIZADO =====
