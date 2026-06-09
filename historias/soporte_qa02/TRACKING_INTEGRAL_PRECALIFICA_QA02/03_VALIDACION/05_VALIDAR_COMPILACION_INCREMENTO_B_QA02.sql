-- =====================================================================
-- Validacion de compilacion del Incremento B
-- Entorno: QA02
--
-- Antes de ejecutar este archivo:
-- 1. Ejecutar ../01_DDL/04_ALTER_PR_JOB_PRECALIFICA_CANDIDATO_TRACK_QA02.sql
--    (el MERGE de track_candidato referencia las columnas nuevas; sin el
--    ALTER el body NO compila).
-- 2. Abrir y ejecutar como script el body canonico modificado:
--    ENTORNOS_ORACLE/QA02/schemas/PR/packages/
--    PR_PKG_REPRESTAMOS/body.sql
-- 3. No ejecutar ni recompilar la spec.
-- =====================================================================

PROMPT 1. Recompilar exclusivamente el package body

ALTER PACKAGE PR.PR_PKG_REPRESTAMOS COMPILE BODY;

PROMPT 2. Estado del package (esperado: SPEC y BODY en VALID - LAST_DDL_TIME de la spec sin cambios)

SELECT owner,
       object_name,
       object_type,
       status,
       last_ddl_time
  FROM all_objects
 WHERE owner = 'PR'
   AND object_name = 'PR_PKG_REPRESTAMOS'
 ORDER BY object_type;

PROMPT 3. Errores del package body (esperado: cero filas)

SELECT type,
       line,
       position,
       text
  FROM all_errors
 WHERE owner = 'PR'
   AND name = 'PR_PKG_REPRESTAMOS'
 ORDER BY sequence;

PROMPT 4. El body compilado contiene el helper del Incremento B (esperado: filas con track_candidato)

SELECT COUNT(*) AS lineas_track_candidato
  FROM all_source
 WHERE owner = 'PR'
   AND name = 'PR_PKG_REPRESTAMOS'
   AND type = 'PACKAGE BODY'
   AND LOWER(text) LIKE '%track_candidato%';

PROMPT Resultado esperado: PACKAGE BODY VALID, cero errores y lineas_track_candidato > 0
