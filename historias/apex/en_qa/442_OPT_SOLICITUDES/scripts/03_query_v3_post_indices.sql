-------------------------------------------------------------------------------
-- Historia #442: Query optimizado v3 - APLICAR DESPUES DE CREAR LOS INDICES
-- Aplicacion APEX 106 - Canal Digital / Represtamo Digital
-- Region: Solicitudes (Interactive Report)
-------------------------------------------------------------------------------
-- IMPORTANTE: Esta version (v3) REQUIERE los indices del script 02.
-- NO usar en PROD hasta que los indices esten creados.
-- Si se usa sin indices, el rendimiento sera PEOR que el query original
-- porque los EXISTS y subqueries correlacionados haran Full Table Scans por fila.
-------------------------------------------------------------------------------
-- Diferencia respecto al script 01 (v1):
--   - FECHA_BITACORA: subquery correlacionado (en lugar de LEFT JOIN GROUP BY)
--   - TIPOS_DESEMBOLSOS: 2 EXISTS correlacionados (en lugar de LEFT JOIN GROUP BY)
--   - Hint adicional USE_NL(R) para forzar NESTED LOOPS en PR_REPRESTAMOS
--   - JOIN PR_REPRESTAMOS reordenado: CODIGO_EMPRESA primero
-- Beneficio: usa indices puntuales en lugar de escanear toda la bitacora
-- Costo Explain Plan: 4,688 (vs 5,566 original = -16%)
-- Configuracion APEX al activar:
--   - Optimizer Hint: USE_CONCAT USE_NL(R)
--   - Page Items to Submit: P21_ID_REPRESTAMO,P21_ESTADO
--   - IMPORTANTE: No incluir punto y coma al final del query en APEX
-------------------------------------------------------------------------------

WITH v_empresa AS (
    SELECT PR.PR_PKG_REPRESTAMOS.F_Obt_Empresa_Represtamo AS cod FROM DUAL
)
SELECT /*+ USE_CONCAT USE_NL(R) */
    -- 1. Fecha
    (SELECT MAX(
            CASE
                WHEN R.ESTADO = 'CRD' AND S.NO_CREDITO = C.NO_CREDITO AND C.ESTADO = 'D'
                    THEN C.F_PRIMER_DESEMBOLSO
                WHEN R.ESTADO = 'CC'  AND R.NO_CREDITO = CA.NO_CREDITO AND CA.ESTADO = 'C'
                    THEN CA.F_CANCELACION
                WHEN R.ESTADO = 'CRN' AND R.NO_CREDITO = CA.NO_CREDITO AND C.ESTADO = 'N' AND CA.FECHA_MODIFICACION IS NOT NULL
                    THEN CA.FECHA_MODIFICACION
                WHEN R.ESTADO = 'CRN' AND R.NO_CREDITO = CA.NO_CREDITO AND C.ESTADO = 'N' AND CA.FECHA_MODIFICACION IS NULL
                    THEN B.FECHA_BITACORA
                ELSE B.FECHA_BITACORA
            END
        )
    FROM PR.PR_BITACORA_REPRESTAMO B
    WHERE B.ID_REPRESTAMO = S.ID_REPRESTAMO AND B.CODIGO_ESTADO = R.ESTADO
    ) AS FECHA_BITACORA,

    PR.PR_PKG_REPRESTAMOS.F_Obt_Descripcion_Estado(S.ESTADO) AS DESC_ESTADO,
    S.ID_REPRESTAMO,
    S.NOMBRES || ' ' || S.APELLIDOS AS NOMBRE_COMPLETO,
    S.IDENTIFICACION,
    R.CODIGO_CLIENTE,
    OP.MTO_PRESTAMO,
    S.NO_CREDITO,
    TC.TIPO_CREDITO || ' - ' || TC.DESCRIPCION AS DESCRIPCON,
    A.DESCRIPCION AS AGENCIA,
    PA.OBT_NOMBRE_EMPLEADO(C.CODIGO_EMPRESA, CA.CODIGO_EJECUTIVO) AS NOMBRE_OFICIAL,
    PA.OBT_DESC_ZONA(1, A.COD_ZONA) AS ZONA,
    CASE
        WHEN R.ID_CARGA_DIRIGIDA IS NOT NULL THEN 'Carga Dirigida'
        WHEN R.ID_REPRE_CAMPANA_ESPECIALES IS NOT NULL THEN 'Campanas Especiales'
        ELSE 'Represtamo Digital'
    END AS TIPO_PRESTAMO,
    CASE
        WHEN EXISTS (
            SELECT 1 FROM PR.PR_BITACORA_REPRESTAMO B
            WHERE B.ID_REPRESTAMO = S.ID_REPRESTAMO AND B.CODIGO_ESTADO = 'CRY'
        ) THEN 'Desembolsado con firma'
        WHEN EXISTS (
            SELECT 1 FROM PR.PR_BITACORA_REPRESTAMO B
            WHERE B.ID_REPRESTAMO = S.ID_REPRESTAMO AND B.CODIGO_ESTADO = 'CRD'
        ) THEN 'Desembolsado tradicional'
    END AS TIPOS_DESEMBOLSOS,
    CASE WHEN S.EMAIL IS NULL THEN 'No' ELSE 'Si' END AS CORREO,
    CASE WHEN R.ES_FIADOR = 'N' OR R.ES_FIADOR IS NULL THEN 'No' ELSE 'Si' END AS ORIGEN_FIADOR,
    CASE WHEN NVL(OP.MTO_SEGURO_MIPYME, 0) > 0 THEN 'Si' ELSE 'No' END AS SEGURO_MIPYME,
    CASE WHEN NVL(OP.MTO_SEGURO_DESEMPLEO, 0) > 0 THEN 'Si' ELSE 'No' END AS SEGURO_INCAPACIDAD,

    '<a title="Solicitud PIN" href="'||APEX_PAGE.GET_URL(p_page => 23, p_items => 'P23_ID_REPRESTAMO', p_values => S.ID_REPRESTAMO) ||'"> <span aria-hidden="true" class="fa fa-pragma"></span> </a> ' ||
    '<a title="Reenvio Link" href="'||APEX_PAGE.GET_URL(p_page => 50, p_items => 'P50_ID_REPRESTAMO', p_values => S.ID_REPRESTAMO) ||'"> <span aria-hidden="true" class="fa fa-link"></span> </a> ' ||
    CASE WHEN S.ESTADO IN ('BLI', 'BLP') THEN
         '<a title="Desbloquear" href="'||APEX_PAGE.GET_URL(p_page => 49, p_clear_cache => 49, p_items => 'P49_ID_REPRESTAMO,P49_CODIGO_ESTADO', p_values => S.ID_REPRESTAMO||','||S.ESTADO) ||'"> <span aria-hidden="true" class="fa fa-padlock-unlock"></span> </a>'
         WHEN S.ESTADO = 'AYS' THEN
         '<a title="Atender Ayuda" href="'||APEX_PAGE.GET_URL(p_page => 32, p_clear_cache => 32, p_items => 'P32_ID_REPRESTAMO', p_values => S.ID_REPRESTAMO||','||S.ESTADO) ||'"> <span aria-hidden="true" class="fa fa-headset"></span> </a>'
         ELSE NULL
    END AS Acciones,

    A.COD_AGENCIA, S.FEC_NACIMIENTO, S.SEXO, S.NACIONALIDAD, S.ESTADO_CIVIL,
    S.TELEFONO_CELULAR, S.TELEFONO_RESIDENCIA, S.TELEFONO_TRABAJO,
    S.EMAIL, S.DIRECCION,
    CASE WHEN S.ORIGEN = 'onboarding' THEN 'App' ELSE S.ORIGEN END AS "CANAL DE SOLICITUD"

FROM v_empresa E
JOIN PR.PR_SOLICITUD_REPRESTAMO S ON S.CODIGO_EMPRESA = E.cod
LEFT JOIN PR.PR_REPRESTAMOS R     ON R.CODIGO_EMPRESA = S.CODIGO_EMPRESA AND R.ID_REPRESTAMO = S.ID_REPRESTAMO
LEFT JOIN PR.PR_CREDITOS C        ON C.CODIGO_EMPRESA = R.CODIGO_EMPRESA AND C.NO_CREDITO = S.NO_CREDITO
LEFT JOIN PR.PR_CREDITOS CA       ON CA.CODIGO_EMPRESA = R.CODIGO_EMPRESA AND CA.NO_CREDITO = R.NO_CREDITO
LEFT JOIN PA.AGENCIA A            ON A.COD_EMPRESA = R.CODIGO_EMPRESA AND A.COD_AGENCIA = C.CODIGO_AGENCIA
LEFT JOIN PR.PR_OPCIONES_REPRESTAMO OP ON OP.ID_REPRESTAMO = S.ID_REPRESTAMO AND OP.PLAZO = S.PLAZO
LEFT JOIN PR.PR_TIPO_CREDITO TC   ON TC.TIPO_CREDITO = C.TIPO_CREDITO
WHERE (:P21_ID_REPRESTAMO IS NULL OR S.ID_REPRESTAMO = :P21_ID_REPRESTAMO)
  AND (:P21_ESTADO IS NULL OR S.ESTADO = :P21_ESTADO)
ORDER BY S.ID_REPRESTAMO ASC
