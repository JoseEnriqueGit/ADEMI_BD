-- =====================================================================
-- OPT-020 - Validacion de equivalencia funcion vs vistas
-- Entorno objetivo: QA02
--
-- Ejecutar despues de 01_CREATE_VIEWS.sql.
--
-- Criterio:
--   - F_TIENE_GARANTIA(no_credito) debe ser igual a CANTIDAD_GARANTIAS
--     para la empresa de represtamos.
--   - Si la funcion retorna 0, no debe existir fila en la vista.
--   - Si la funcion retorna > 0, debe existir fila en la vista.
-- =====================================================================

SET SERVEROUTPUT ON

PROMPT ================================================================
PROMPT OPT-020 Q00 - Verificar vistas requeridas
PROMPT ================================================================

SELECT owner, object_name, object_type, status
  FROM all_objects
 WHERE owner = 'PR'
   AND object_name IN ('V_REPRE_CREDITOS_GAR',
                       'V_REPRE_CREDITOS_HI_GAR')
 ORDER BY object_name;

PROMPT Debe retornar 2 filas con STATUS = VALID.
PROMPT Si retorna 0 filas o falta una vista, ejecutar primero 01_CREATE_VIEWS.sql conectado como PR o con privilegio CREATE ANY VIEW.

PROMPT ================================================================
PROMPT OPT-020 Q00B - Prueba de acceso directo a vistas
PROMPT ================================================================

SELECT 'V_REPRE_CREDITOS_GAR' vista, COUNT(*) cantidad
  FROM PR.V_REPRE_CREDITOS_GAR
UNION ALL
SELECT 'V_REPRE_CREDITOS_HI_GAR' vista, COUNT(*) cantidad
  FROM PR.V_REPRE_CREDITOS_HI_GAR;

PROMPT Si aqui ocurre ORA-00942, la vista no existe en PR o falta permiso SELECT al usuario actual.

PROMPT ================================================================
PROMPT OPT-020 Q01 - Equivalencia exacta F_TIENE_GARANTIA vs vista actual
PROMPT ================================================================

WITH base AS (
    SELECT DISTINCT c.codigo_empresa, c.no_credito
      FROM PR.PR_CREDITOS c
     WHERE c.codigo_empresa = PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
       AND c.estado IN ('D', 'V', 'M', 'E', 'J')
),
comparacion AS (
    SELECT b.codigo_empresa,
           b.no_credito,
           PR.PR_PKG_REPRESTAMOS.F_TIENE_GARANTIA(b.no_credito) valor_funcion,
           NVL(v.cantidad_garantias, 0) valor_vista
      FROM base b
      LEFT JOIN PR.V_REPRE_CREDITOS_GAR v
        ON v.codigo_empresa = b.codigo_empresa
       AND v.no_credito = b.no_credito
)
SELECT *
  FROM comparacion
 WHERE valor_funcion != valor_vista
 ORDER BY no_credito;

PROMPT Debe retornar 0 filas.

PROMPT ================================================================
PROMPT OPT-020 Q02 - Equivalencia exacta F_TIENE_GARANTIA_HISTORICO vs vista HI
PROMPT ================================================================

WITH base AS (
    SELECT DISTINCT c.codigo_empresa, c.no_credito
      FROM PR.PR_CREDITOS_HI c
     WHERE c.codigo_empresa = PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
       AND c.estado IN ('D', 'V', 'M', 'E', 'J')
),
comparacion AS (
    SELECT b.codigo_empresa,
           b.no_credito,
           PR.PR_PKG_REPRESTAMOS.F_TIENE_GARANTIA_HISTORICO(b.no_credito) valor_funcion,
           NVL(v.cantidad_garantias, 0) valor_vista
      FROM base b
      LEFT JOIN PR.V_REPRE_CREDITOS_HI_GAR v
        ON v.codigo_empresa = b.codigo_empresa
       AND v.no_credito = b.no_credito
)
SELECT *
  FROM comparacion
 WHERE valor_funcion != valor_vista
 ORDER BY no_credito;

PROMPT Debe retornar 0 filas.

PROMPT ================================================================
PROMPT OPT-020 Q03 - Casos de uso booleano para cursores masivos
PROMPT ================================================================

SELECT 'FUNC_ACTUAL_GT0' fuente, COUNT(*) cantidad
  FROM PR.PR_CREDITOS c
 WHERE c.codigo_empresa = PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
   AND c.estado IN ('D', 'V', 'M', 'E', 'J')
   AND PR.PR_PKG_REPRESTAMOS.F_TIENE_GARANTIA(c.no_credito) > 0
UNION ALL
SELECT 'VISTA_ACTUAL_EXISTS' fuente, COUNT(*) cantidad
  FROM PR.PR_CREDITOS c
 WHERE c.codigo_empresa = PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
   AND c.estado IN ('D', 'V', 'M', 'E', 'J')
   AND EXISTS (
          SELECT 1
            FROM PR.V_REPRE_CREDITOS_GAR v
           WHERE v.codigo_empresa = c.codigo_empresa
             AND v.no_credito = c.no_credito
       );

PROMPT Las 2 filas deben tener la misma cantidad.

PROMPT ================================================================
PROMPT OPT-020 Q04 - Casos de uso booleano historico para cursores masivos
PROMPT ================================================================

SELECT 'FUNC_HI_GT0' fuente, COUNT(*) cantidad
  FROM PR.PR_CREDITOS_HI c
 WHERE c.codigo_empresa = PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
   AND c.estado IN ('D', 'V', 'M', 'E', 'J')
   AND PR.PR_PKG_REPRESTAMOS.F_TIENE_GARANTIA_HISTORICO(c.no_credito) > 0
UNION ALL
SELECT 'VISTA_HI_EXISTS' fuente, COUNT(*) cantidad
  FROM PR.PR_CREDITOS_HI c
 WHERE c.codigo_empresa = PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
   AND c.estado IN ('D', 'V', 'M', 'E', 'J')
   AND EXISTS (
          SELECT 1
            FROM PR.V_REPRE_CREDITOS_HI_GAR v
           WHERE v.codigo_empresa = c.codigo_empresa
             AND v.no_credito = c.no_credito
       );

PROMPT Las 2 filas deben tener la misma cantidad.
