-- Rollback PROD - 2026-05-21
-- Pase: PR_PKG_REPRESTAMOS, PR_V_ENVIO_REPRESTAMOS e indice PA_PARAMETROS_MVP
-- Ambiente destino: Produccion
-- Ejecutar desde Toad/SQL*Plus con permisos suficientes.
--
-- IMPORTANTE:
-- 1. Antes de ejecutar rollback, confirmar con DBA si PR.PR_V_ENVIO_REPRESTAMOS
--    y el sinonimo publico existian antes del pase.
-- 2. La version previa de PR.PR_PKG_REPRESTAMOS para rollback queda incluida en:
--    historias/_promociones/2026-05-21_REPRESTAMOS_PACKAGE_VIEW_INDEX_ROLLBACK/
--    Origen entregado para rollback: PR_PKG_REPRESTAMOS 1 21-5.pks/.pkb.

DEFINE REPO_ROOT = C:\Users\joogando\Desktop\ADEMI_BD

PROMPT ============================================================
PROMPT ROLLBACK 2026-05-21 - PR_PKG_REPRESTAMOS / VISTA / INDICE
PROMPT ============================================================

PROMPT Paso 1 - Recompilar package anterior incluido en este rollback
PROMPT Ejecutar primero el spec anterior de PR.PR_PKG_REPRESTAMOS
PROMPT Ejecutar luego el body anterior de PR.PR_PKG_REPRESTAMOS

@&REPO_ROOT\historias\_promociones\2026-05-21_REPRESTAMOS_PACKAGE_VIEW_INDEX_ROLLBACK\PR_PKG_REPRESTAMOS_spec_anterior.sql
SHOW ERRORS PACKAGE PR.PR_PKG_REPRESTAMOS;

@&REPO_ROOT\historias\_promociones\2026-05-21_REPRESTAMOS_PACKAGE_VIEW_INDEX_ROLLBACK\PR_PKG_REPRESTAMOS_body_anterior.sql
SHOW ERRORS PACKAGE BODY PR.PR_PKG_REPRESTAMOS;

PROMPT Paso 2 - Recompilar vista anterior si existia antes del pase

-- Si PR.PR_V_ENVIO_REPRESTAMOS existia antes del pase, ejecutar aqui el DDL
-- anterior de la vista desde el respaldo DBA y validar errores:
--
-- @<RUTA_RESPALDO_DBA>\PR_V_ENVIO_REPRESTAMOS_anterior.sql
-- SHOW ERRORS VIEW PR.PR_V_ENVIO_REPRESTAMOS;

PROMPT Paso 3 - Retirar sinonimo publico si fue creado nuevo por este pase

-- Ejecutar este bloque solo si el sinonimo publico NO existia antes del pase
-- o si el rollback requiere retirarlo.
DECLARE
   v_existe NUMBER;
BEGIN
   SELECT COUNT(*)
     INTO v_existe
     FROM ALL_SYNONYMS
    WHERE OWNER = 'PUBLIC'
      AND SYNONYM_NAME = 'PR_V_ENVIO_REPRESTAMOS';

   IF v_existe > 0 THEN
      EXECUTE IMMEDIATE 'DROP PUBLIC SYNONYM PR_V_ENVIO_REPRESTAMOS';
   END IF;
END;
/

PROMPT Paso 4 - Retirar indice PA.IDX_PARAM_MVP_EMP_MVP_PARAM si debe revertirse

DECLARE
   v_existe NUMBER;
BEGIN
   SELECT COUNT(*)
     INTO v_existe
     FROM ALL_INDEXES
    WHERE OWNER = 'PA'
      AND INDEX_NAME = 'IDX_PARAM_MVP_EMP_MVP_PARAM';

   IF v_existe > 0 THEN
      EXECUTE IMMEDIATE 'DROP INDEX PA.IDX_PARAM_MVP_EMP_MVP_PARAM';
   END IF;
END;
/

PROMPT Paso 5 - Retirar vista si fue creada nueva por este pase

-- Descomentar solo si PR.PR_V_ENVIO_REPRESTAMOS NO existia antes del pase.
/*
DECLARE
   v_existe NUMBER;
BEGIN
   SELECT COUNT(*)
     INTO v_existe
     FROM ALL_OBJECTS
    WHERE OWNER = 'PR'
      AND OBJECT_NAME = 'PR_V_ENVIO_REPRESTAMOS'
      AND OBJECT_TYPE = 'VIEW';

   IF v_existe > 0 THEN
      EXECUTE IMMEDIATE 'DROP VIEW PR.PR_V_ENVIO_REPRESTAMOS';
   END IF;
END;
/
*/

PROMPT Paso 6 - Validacion post rollback

SELECT owner, object_name, object_type, status
  FROM all_objects
 WHERE (owner = 'PR' AND object_name IN ('PR_PKG_REPRESTAMOS', 'PR_V_ENVIO_REPRESTAMOS'))
    OR (owner = 'PUBLIC' AND object_name = 'PR_V_ENVIO_REPRESTAMOS')
 ORDER BY owner, object_type, object_name;

SELECT owner, index_name, table_name, tablespace_name, status
  FROM all_indexes
 WHERE owner = 'PA'
   AND index_name = 'IDX_PARAM_MVP_EMP_MVP_PARAM';

PROMPT Fin rollback 2026-05-21
