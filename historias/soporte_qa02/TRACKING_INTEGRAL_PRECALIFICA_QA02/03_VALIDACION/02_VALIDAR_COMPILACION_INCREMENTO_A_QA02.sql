-- =====================================================================
-- Validacion de compilacion del Incremento A
-- Entorno: QA02
--
-- Antes de ejecutar este archivo:
-- 1. Abrir y ejecutar como script el body canonico modificado:
--    ENTORNOS_ORACLE/QA02/schemas/PR/packages/
--    PR_PKG_REPRESTAMOS/body.sql
-- 2. No ejecutar ni recompilar la spec.
-- =====================================================================

PROMPT 1. Recompilar exclusivamente el package body

ALTER PACKAGE PR.PR_PKG_REPRESTAMOS COMPILE BODY;

PROMPT 2. Estado del package

SELECT owner,
       object_name,
       object_type,
       status,
       last_ddl_time
  FROM all_objects
 WHERE owner = 'PR'
   AND object_name = 'PR_PKG_REPRESTAMOS'
 ORDER BY object_type;

PROMPT 3. Errores del package body

SELECT type,
       line,
       position,
       text
  FROM all_errors
 WHERE owner = 'PR'
   AND name = 'PR_PKG_REPRESTAMOS'
 ORDER BY sequence;

PROMPT Resultado esperado: PACKAGE BODY VALID y cero filas en ALL_ERRORS
