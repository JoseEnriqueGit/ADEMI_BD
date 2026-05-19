-- OPT-020 - Validar y preparar ajuste de PRECAL_MORA_MAYOR_PR
-- Entorno: QA02 / QADEMI02_19C
-- Objeto: PR.PR_PKG_REPRESTAMOS
-- Objetivo: confirmar que el valor usado por el cursor y el valor usado por X2
--           apuntan al mismo umbral antes de probar 45 o 60 dias.

SET LINESIZE 220
SET PAGESIZE 500
SET SERVEROUTPUT ON
SET TIMING ON

DEFINE P_NUEVO_VALOR = 45
DEFINE P_VALOR_ROLLBACK = 30

PROMPT ============================================================================
PROMPT Q01 - Comparar valor del cursor vs valor usado por X2
PROMPT ============================================================================

SELECT PR.PR_PKG_REPRESTAMOS.f_obt_parametro_represtamo('PRECAL_MORA_MAYOR_PR') AS valor_cursor,
       OBT_PARAMETROS('1', 'PR', 'PRECAL_MORA_MAYOR_PR')                         AS valor_x2
  FROM dual;

PROMPT ============================================================================
PROMPT Q02 - Ubicar objeto/sinonimo OBT_PARAMETROS
PROMPT ============================================================================

SELECT owner,
       object_name,
       object_type,
       status
  FROM all_objects
 WHERE object_name = 'OBT_PARAMETROS'
 ORDER BY owner, object_type;

SELECT owner,
       synonym_name,
       table_owner,
       table_name,
       db_link
  FROM all_synonyms
 WHERE synonym_name = 'OBT_PARAMETROS'
 ORDER BY owner, table_owner, table_name;

PROMPT ============================================================================
PROMPT Q03 - Fuente de OBT_PARAMETROS, si el usuario tiene privilegios
PROMPT ============================================================================

SELECT owner,
       name,
       type,
       line,
       text
  FROM all_source
 WHERE name = 'OBT_PARAMETROS'
 ORDER BY owner, type, line;

PROMPT ============================================================================
PROMPT Q04 - Valor confirmado en PA.PA_PARAMETROS_MVP
PROMPT ============================================================================

SELECT rowid AS rid,
       codigo_mvp,
       codigo_parametro,
       valor
  FROM PA.PA_PARAMETROS_MVP
 WHERE codigo_mvp = 'REPRESTAMOS'
   AND codigo_parametro = 'PRECAL_MORA_MAYOR_PR'
 ORDER BY rowid;

PROMPT ============================================================================
PROMPT Q04B - Valor confirmado en PA.PARAMETROS_X_EMPRESA usado por OBT_PARAMETROS
PROMPT ============================================================================

SELECT rowid AS rid,
       cod_empresa,
       cod_sistema,
       abrev_parametro,
       valor
  FROM PA.PARAMETROS_X_EMPRESA
 WHERE cod_empresa = '1'
   AND cod_sistema = 'PR'
   AND abrev_parametro = 'PRECAL_MORA_MAYOR_PR'
 ORDER BY rowid;

PROMPT ============================================================================
PROMPT Q05 - Buscar tablas candidatas que podrian alimentar OBT_PARAMETROS
PROMPT Copiar/ejecutar los SELECT_GENERADO que apliquen si Q03 no muestra la fuente.
PROMPT ============================================================================

WITH cols AS (
    SELECT owner,
           table_name,
           MAX(CASE WHEN column_name IN ('CODIGO_PARAMETRO', 'COD_PARAMETRO', 'PARAMETRO') THEN column_name END) col_parametro,
           MAX(CASE WHEN column_name IN ('VALOR', 'VALOR_PARAMETRO', 'DESCRIPCION') THEN column_name END) col_valor,
           MAX(CASE WHEN column_name IN ('CODIGO_SISTEMA', 'COD_SISTEMA', 'SISTEMA', 'CODIGO_MODULO', 'CODIGO_MVP') THEN column_name END) col_sistema,
           MAX(CASE WHEN column_name IN ('CODIGO_EMPRESA', 'COD_EMPRESA', 'EMPRESA') THEN column_name END) col_empresa
      FROM all_tab_columns
     WHERE owner IN ('PA', 'PR')
       AND column_name IN (
           'CODIGO_PARAMETRO', 'COD_PARAMETRO', 'PARAMETRO',
           'VALOR', 'VALOR_PARAMETRO', 'DESCRIPCION',
           'CODIGO_SISTEMA', 'COD_SISTEMA', 'SISTEMA', 'CODIGO_MODULO', 'CODIGO_MVP',
           'CODIGO_EMPRESA', 'COD_EMPRESA', 'EMPRESA'
       )
     GROUP BY owner, table_name
)
SELECT owner,
       table_name,
       col_empresa,
       col_sistema,
       col_parametro,
       col_valor,
       'SELECT * FROM ' || owner || '.' || table_name ||
       ' WHERE ' || col_parametro || ' = ''PRECAL_MORA_MAYOR_PR'';' AS select_generado
  FROM cols
 WHERE col_parametro IS NOT NULL
   AND col_valor IS NOT NULL
 ORDER BY owner, table_name;

PROMPT ============================================================================
PROMPT Q06 - DML PROPUESTO para PA.PA_PARAMETROS_MVP
PROMPT Revisar Q01/Q04/Q04B antes. Descomentar solo para la prueba controlada.
PROMPT ============================================================================

-- UPDATE PA.PA_PARAMETROS_MVP
--    SET valor = '&P_NUEVO_VALOR'
--  WHERE codigo_mvp = 'REPRESTAMOS'
--    AND codigo_parametro = 'PRECAL_MORA_MAYOR_PR';
--
-- COMMIT;
--
-- SELECT PR.PR_PKG_REPRESTAMOS.f_obt_parametro_represtamo('PRECAL_MORA_MAYOR_PR') AS valor_cursor,
--        OBT_PARAMETROS('1', 'PR', 'PRECAL_MORA_MAYOR_PR')                         AS valor_x2
--   FROM dual;

PROMPT ============================================================================
PROMPT Q06B - DML PROPUESTO para PA.PARAMETROS_X_EMPRESA usado por X2
PROMPT Revisar Q01/Q04/Q04B antes. Descomentar solo para la prueba controlada.
PROMPT ============================================================================

-- UPDATE PA.PARAMETROS_X_EMPRESA
--    SET valor = '&P_NUEVO_VALOR'
--  WHERE cod_empresa = '1'
--    AND cod_sistema = 'PR'
--    AND abrev_parametro = 'PRECAL_MORA_MAYOR_PR';
--
-- COMMIT;
--
-- SELECT PR.PR_PKG_REPRESTAMOS.f_obt_parametro_represtamo('PRECAL_MORA_MAYOR_PR') AS valor_cursor,
--        OBT_PARAMETROS('1', 'PR', 'PRECAL_MORA_MAYOR_PR')                         AS valor_x2
--   FROM dual;

PROMPT ============================================================================
PROMPT Q07 - ROLLBACK PROPUESTO para PA.PA_PARAMETROS_MVP
PROMPT Descomentar para volver al valor inicial.
PROMPT ============================================================================

-- UPDATE PA.PA_PARAMETROS_MVP
--    SET valor = '&P_VALOR_ROLLBACK'
--  WHERE codigo_mvp = 'REPRESTAMOS'
--    AND codigo_parametro = 'PRECAL_MORA_MAYOR_PR';
--
-- COMMIT;
--
-- SELECT PR.PR_PKG_REPRESTAMOS.f_obt_parametro_represtamo('PRECAL_MORA_MAYOR_PR') AS valor_cursor,
--        OBT_PARAMETROS('1', 'PR', 'PRECAL_MORA_MAYOR_PR')                         AS valor_x2
--   FROM dual;

PROMPT ============================================================================
PROMPT Q07B - ROLLBACK PROPUESTO para PA.PARAMETROS_X_EMPRESA usado por X2
PROMPT Descomentar para volver al valor inicial.
PROMPT ============================================================================

-- UPDATE PA.PARAMETROS_X_EMPRESA
--    SET valor = '&P_VALOR_ROLLBACK'
--  WHERE cod_empresa = '1'
--    AND cod_sistema = 'PR'
--    AND abrev_parametro = 'PRECAL_MORA_MAYOR_PR';
--
-- COMMIT;
--
-- SELECT PR.PR_PKG_REPRESTAMOS.f_obt_parametro_represtamo('PRECAL_MORA_MAYOR_PR') AS valor_cursor,
--        OBT_PARAMETROS('1', 'PR', 'PRECAL_MORA_MAYOR_PR')                         AS valor_x2
--   FROM dual;
