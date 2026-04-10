-------------------------------------------------------------------------------
-- Historia #442: Query optimizado pagina 21 (Solicitudes) - VERSION PARA PROD
-- Aplicacion APEX 106 - Canal Digital / Represtamo Digital
-- Region: Solicitudes (Interactive Report)
-------------------------------------------------------------------------------
-- IMPORTANTE: Esta version (v1) NO requiere los indices nuevos.
-- Es segura para desplegar a PROD sin crear los indices.
-- Cuando los indices se creen en PROD, cambiar al script 03 (v3) para mejor rendimiento.
-------------------------------------------------------------------------------
-- Cambios respecto al query original:
--   1. CTE v_empresa: F_Obt_Empresa_Represtamo se ejecuta 1 sola vez (no por fila)
--   2. Subquery correlacionado FECHA_BITACORA -> LEFT JOIN con GROUP BY (un solo scan)
--   3. Dos EXISTS para TIPOS_DESEMBOLSOS -> LEFT JOIN con MAX(CASE) (un solo scan)
--   4. Filtro WHERE reordenado: NULL check primero para short-circuit
--   5. Hint USE_CONCAT para OR-expansion de parametros opcionales
-- Configuracion APEX:
--   - Optimizer Hint: USE_CONCAT
--   - Page Items to Submit: P21_ID_REPRESTAMO,P21_ESTADO
--   - IMPORTANTE: No incluir punto y coma al final del query en APEX
-------------------------------------------------------------------------------

WITH v_empresa AS (
    SELECT PR.PR_PKG_REPRESTAMOS.F_Obt_Empresa_Represtamo AS cod FROM DUAL
)
SELECT /*+ USE_CONCAT */
    -- 1. Fecha
    CASE WHEN BF.ID_REPRESTAMO IS NOT NULL THEN
        CASE
            WHEN R.ESTADO = 'CRD' AND S.NO_CREDITO = C.NO_CREDITO AND C.ESTADO = 'D'
                THEN C.F_PRIMER_DESEMBOLSO
            WHEN R.ESTADO = 'CC'  AND R.NO_CREDITO = CA.NO_CREDITO AND CA.ESTADO = 'C'
                THEN CA.F_CANCELACION
            WHEN R.ESTADO = 'CRN' AND R.NO_CREDITO = CA.NO_CREDITO AND C.ESTADO = 'N' AND CA.FECHA_MODIFICACION IS NOT NULL
                THEN CA.FECHA_MODIFICACION
            WHEN R.ESTADO = 'CRN' AND R.NO_CREDITO = CA.NO_CREDITO AND C.ESTADO = 'N' AND CA.FECHA_MODIFICACION IS NULL
                THEN BF.FECHA_BITACORA
            ELSE BF.FECHA_BITACORA
        END
    END AS FECHA_BITACORA,

    -- 2. Estado
    PR.PR_PKG_REPRESTAMOS.F_Obt_Descripcion_Estado(S.ESTADO) AS DESC_ESTADO,

    -- 3. Id Represtamo
    S.ID_REPRESTAMO,

    -- 4. Nombre Completo
    S.NOMBRES || ' ' || S.APELLIDOS AS NOMBRE_COMPLETO,

    -- 5. Identificacion
    S.IDENTIFICACION,

    -- 6. Codigo Cliente
    R.CODIGO_CLIENTE,

    -- 7. Monto Credito
    OP.MTO_PRESTAMO,

    -- 8. No. Credito Nuevo
    S.NO_CREDITO,

    -- 9. Tipo de Credito
    TC.TIPO_CREDITO || ' - ' || TC.DESCRIPCION AS DESCRIPCON,

    -- 10. Oficina
    A.DESCRIPCION AS AGENCIA,

    -- 11. Oficial
    PA.OBT_NOMBRE_EMPLEADO(C.CODIGO_EMPRESA, CA.CODIGO_EJECUTIVO) AS NOMBRE_OFICIAL,

    -- 12. Zona
    PA.OBT_DESC_ZONA(1, A.COD_ZONA) AS ZONA,

    -- 13. Tipo Represtamo
    CASE
        WHEN R.ID_CARGA_DIRIGIDA IS NOT NULL THEN 'Carga Dirigida'
        WHEN R.ID_REPRE_CAMPANA_ESPECIALES IS NOT NULL THEN 'Campanas Especiales'
        ELSE 'Represtamo Digital'
    END AS TIPO_PRESTAMO,

    -- 14. Tipos Desembolsos
    CASE
        WHEN BT.tiene_cry = 1 THEN 'Desembolsado con firma'
        WHEN BT.tiene_crd = 1 THEN 'Desembolsado tradicional'
    END AS TIPOS_DESEMBOLSOS,

    -- 15. Correo (Si/No)
    CASE
        WHEN S.EMAIL IS NULL THEN 'No'
        ELSE 'Si'
    END AS CORREO,

    -- 16. Origen Fiador
    CASE
        WHEN R.ES_FIADOR = 'N' OR R.ES_FIADOR IS NULL THEN 'No'
        ELSE 'Si'
    END AS ORIGEN_FIADOR,

    CASE
        WHEN NVL(OP.MTO_SEGURO_MIPYME, 0) > 0 THEN 'Si'
        ELSE 'No'
    END AS SEGURO_MIPYME,

    CASE
        WHEN NVL(OP.MTO_SEGURO_DESEMPLEO, 0) > 0 THEN 'Si'
        ELSE 'No'
    END AS SEGURO_INCAPACIDAD,

    '<a title="Solicitud PIN" href="'||APEX_PAGE.GET_URL(p_page => 23, p_items => 'P23_ID_REPRESTAMO', p_values => S.ID_REPRESTAMO) ||'"> <span aria-hidden="true" class="fa fa-pragma"></span> </a> ' ||
    '<a title="Reenvio Link" href="'||APEX_PAGE.GET_URL(p_page => 50, p_items => 'P50_ID_REPRESTAMO', p_values => S.ID_REPRESTAMO) ||'"> <span aria-hidden="true" class="fa fa-link"></span> </a> ' ||
    CASE WHEN S.ESTADO IN ('BLI', 'BLP') THEN
         '<a title="Desbloquear" href="'||APEX_PAGE.GET_URL(p_page => 49, p_clear_cache => 49, p_items => 'P49_ID_REPRESTAMO,P49_CODIGO_ESTADO', p_values => S.ID_REPRESTAMO||','||S.ESTADO) ||'"> <span aria-hidden="true" class="fa fa-padlock-unlock"></span> </a>'
         WHEN S.ESTADO = 'AYS' THEN
         '<a title="Atender Ayuda" href="'||APEX_PAGE.GET_URL(p_page => 32, p_clear_cache => 32, p_items => 'P32_ID_REPRESTAMO', p_values => S.ID_REPRESTAMO||','||S.ESTADO) ||'"> <span aria-hidden="true" class="fa fa-headset"></span> </a>'
         ELSE NULL
    END AS Acciones,

    A.COD_AGENCIA,
    S.FEC_NACIMIENTO,
    S.SEXO,
    S.NACIONALIDAD,
    S.ESTADO_CIVIL,
    S.TELEFONO_CELULAR,
    S.TELEFONO_RESIDENCIA,
    S.TELEFONO_TRABAJO,
    S.EMAIL,
    S.DIRECCION,
    CASE
        WHEN S.ORIGEN = 'onboarding' THEN 'App'
        ELSE S.ORIGEN
    END AS "CANAL DE SOLICITUD"

FROM v_empresa E
JOIN PR.PR_SOLICITUD_REPRESTAMO S ON S.CODIGO_EMPRESA = E.cod
LEFT JOIN PR.PR_REPRESTAMOS R     ON R.ID_REPRESTAMO = S.ID_REPRESTAMO AND R.CODIGO_EMPRESA = S.CODIGO_EMPRESA
LEFT JOIN PR.PR_CREDITOS C        ON C.CODIGO_EMPRESA = R.CODIGO_EMPRESA AND C.NO_CREDITO = S.NO_CREDITO
LEFT JOIN PR.PR_CREDITOS CA       ON CA.CODIGO_EMPRESA = R.CODIGO_EMPRESA AND CA.NO_CREDITO = R.NO_CREDITO
LEFT JOIN PA.AGENCIA A            ON A.COD_EMPRESA = R.CODIGO_EMPRESA AND A.COD_AGENCIA = C.CODIGO_AGENCIA
LEFT JOIN PR.PR_OPCIONES_REPRESTAMO OP ON OP.ID_REPRESTAMO = S.ID_REPRESTAMO AND OP.PLAZO = S.PLAZO
LEFT JOIN PR.PR_TIPO_CREDITO TC   ON TC.TIPO_CREDITO = C.TIPO_CREDITO
LEFT JOIN (
    SELECT
        B.ID_REPRESTAMO,
        B.CODIGO_ESTADO,
        MAX(B.FECHA_BITACORA) AS FECHA_BITACORA
    FROM PR.PR_BITACORA_REPRESTAMO B
    GROUP BY B.ID_REPRESTAMO, B.CODIGO_ESTADO
) BF ON BF.ID_REPRESTAMO = S.ID_REPRESTAMO AND BF.CODIGO_ESTADO = R.ESTADO
LEFT JOIN (
    SELECT
        B.ID_REPRESTAMO,
        MAX(CASE WHEN B.CODIGO_ESTADO = 'CRY' THEN 1 ELSE 0 END) AS tiene_cry,
        MAX(CASE WHEN B.CODIGO_ESTADO = 'CRD' THEN 1 ELSE 0 END) AS tiene_crd
    FROM PR.PR_BITACORA_REPRESTAMO B
    WHERE B.CODIGO_ESTADO IN ('CRY', 'CRD')
    GROUP BY B.ID_REPRESTAMO
) BT ON BT.ID_REPRESTAMO = S.ID_REPRESTAMO
WHERE (:P21_ID_REPRESTAMO IS NULL OR S.ID_REPRESTAMO = :P21_ID_REPRESTAMO)
  AND (:P21_ESTADO IS NULL OR S.ESTADO = :P21_ESTADO)
ORDER BY S.ID_REPRESTAMO ASC
