-- ============================================================
-- OPT-009 AFTER: Rama ELSE de F_Obtener_Nuevo_Credito
-- Paquete: PR_PKG_REPRESTAMOS (body.sql, QA)
-- ============================================================

-- Scalar subquery eliminado. 3 subqueries IN/NOT IN/EXISTS reemplazadas con JOINs.
SELECT MIN(NT.TIPO_CREDITO) INTO NUEVO_TIPO
FROM PR_REPRESTAMOS   R
LEFT JOIN PR_CREDITOS      C ON C.NO_CREDITO = R.NO_CREDITO
LEFT JOIN PR_CREDITOS_HI   H ON H.NO_CREDITO = R.NO_CREDITO
LEFT JOIN PR_TIPO_CREDITO  T ON T.TIPO_CREDITO = COALESCE(C.TIPO_CREDITO, H.TIPO_CREDITO)
-- JOIN al tipo credito destino con rango de plazo
JOIN PR_TIPO_CREDITO             NT ON NT.CODIGO_SUB_APLICACION = T.CODIGO_SUB_APLICACION
                                    AND NT.GRUPO_TIPO_CREDITO    = T.GRUPO_TIPO_CREDITO
JOIN PR_PLAZO_CREDITO_REPRESTAMO P  ON P.TIPO_CREDITO = NT.TIPO_CREDITO
-- Reemplaza subqueries 2 y 3: Vigente, sin campana especial, no FMO
JOIN PR_TIPO_CREDITO_REPRESTAMO  RV ON RV.TIPO_CREDITO = NT.TIPO_CREDITO
                                    AND RV.OBSOLETO = 0
                                    AND NVL(RV.CREDITO_CAMPANA_ESPECIAL,'N') <> 'S'
                                    AND NVL(RV.CREDITO_FMO,'N') <> 'S'
-- Reemplaza subquery 1: Verificar si origen es FMO para regla de facilidad
LEFT JOIN PR_TIPO_CREDITO_REPRESTAMO FMO ON FMO.TIPO_CREDITO = T.TIPO_CREDITO
                                         AND FMO.CREDITO_FMO = 'S'
WHERE R.ID_REPRESTAMO = pIdReprestamo
  AND R.MTO_PREAPROBADO BETWEEN P.MONTO_MIN AND P.MONTO_MAX
  -- Regla FACILIDAD: Si origen es FMO se ignora, si no debe coincidir
  AND (FMO.TIPO_CREDITO IS NOT NULL OR T.FACILIDAD_CREDITIC = NT.FACILIDAD_CREDITIC);
