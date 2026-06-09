-- =====================================================================
-- Validacion de compilacion del Incremento C
-- Entorno: QA02
--
-- Antes de ejecutar este archivo:
-- 1. Abrir y ejecutar como script el body canonico modificado:
--    ENTORNOS_ORACLE/QA02/schemas/PR/packages/
--    PR_PKG_REPRESTAMOS/body.sql
-- 2. No ejecutar ni recompilar la spec.
-- 3. No requiere DDL nuevo (la Capa C ya tiene todas las columnas).
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

PROMPT 4. El body contiene el helper y las 5 llamadas del Incremento C (esperado: 7 lineas con track_candidatos_flujo y 10 con g_track_cand_activo)

SELECT COUNT(CASE WHEN LOWER(text) LIKE '%track_candidatos_flujo%'
                  THEN 1 END) AS lineas_helper,
       COUNT(CASE WHEN LOWER(text) LIKE '%g_track_cand_activo%'
                  THEN 1 END) AS lineas_flag
  FROM all_source
 WHERE owner = 'PR'
   AND name = 'PR_PKG_REPRESTAMOS'
   AND type = 'PACKAGE BODY';

PROMPT Resultado esperado: PACKAGE BODY VALID, cero errores, lineas_helper = 7 y lineas_flag = 10
