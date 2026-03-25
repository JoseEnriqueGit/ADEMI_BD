-- ============================================================
-- OPT-009 BEFORE: Rama ELSE de F_Obtener_Nuevo_Credito
-- Paquete: PR_PKG_REPRESTAMOS (body.sql, QA)
-- Lineas originales: ~9720-9750
-- ============================================================

-- SELECT con scalar subquery que contiene 3 subqueries anidadas
SELECT (
    SELECT MIN(NT.TIPO_CREDITO)
    FROM   PR_TIPO_CREDITO                NT
    JOIN   PR_PLAZO_CREDITO_REPRESTAMO    P
         ON  P.TIPO_CREDITO = NT.TIPO_CREDITO
    WHERE R.MTO_PREAPROBADO BETWEEN P.MONTO_MIN AND P.MONTO_MAX
      AND NT.CODIGO_SUB_APLICACION = T.CODIGO_SUB_APLICACION
      AND NT.GRUPO_TIPO_CREDITO    = T.GRUPO_TIPO_CREDITO
      -- Subquery 1: Verificar si origen es FMO
      AND ( T.TIPO_CREDITO IN (SELECT TIPO_CREDITO
                               FROM   PR_TIPO_CREDITO_REPRESTAMO
                               WHERE  CREDITO_FMO = 'S')
            OR T.FACILIDAD_CREDITIC = NT.FACILIDAD_CREDITIC )
      -- Subquery 2: Excluir destinos FMO
      AND NT.TIPO_CREDITO NOT IN (SELECT TIPO_CREDITO
                                  FROM   PR_TIPO_CREDITO_REPRESTAMO
                                  WHERE  CREDITO_FMO = 'S')
      -- Subquery 3: Vigente y sin campana especial
      AND EXISTS ( SELECT 1
            FROM   PR_TIPO_CREDITO_REPRESTAMO R
            WHERE  R.TIPO_CREDITO = NT.TIPO_CREDITO
              AND  R.OBSOLETO = 0
              AND  NVL(R.CREDITO_CAMPANA_ESPECIAL,'N') <> 'S'
      )
) INTO NUEVO_TIPO
FROM PR_REPRESTAMOS   R
LEFT JOIN PR_CREDITOS      C ON C.NO_CREDITO = R.NO_CREDITO
LEFT JOIN PR_CREDITOS_HI   H ON H.NO_CREDITO = R.NO_CREDITO
LEFT JOIN PR_TIPO_CREDITO  T ON T.TIPO_CREDITO = COALESCE(C.TIPO_CREDITO, H.TIPO_CREDITO)
WHERE R.ID_REPRESTAMO = pIdReprestamo;
