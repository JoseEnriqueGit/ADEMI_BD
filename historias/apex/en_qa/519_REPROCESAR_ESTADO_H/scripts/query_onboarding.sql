-- =============================================================================
-- Vista Onboarding - Reportes Generados Automaticamente
-- Basada en la vista de Represtamos (pagina 63) adaptada para Onboarding
-- =============================================================================
-- Diferencias vs Represtamo:
--   - Sin JOIN a PR_SOLICITUD_REPRESTAMO (no existe tabla equivalente)
--   - Codigo cliente se extrae del NOMBRE_ARCHIVO (3er segmento: TIPO_NUMCUENTA_CODCLIENTE.pdf)
--   - Identificacion se obtiene de CLIENTES_B2000 via codigo_cliente
--   - Nombre del cliente via PA.OBT_NOMBRE_PERSONA(codigo_cliente)
--   - Tipos de documento (fuente: JSON DocumentService Onboarding):
--     P: 618/429 (FCSCPF), 424 (SolicitudTarjeta), 809 (MRAVPF/MatrizRiesgo)
--     R: 810/527 (SIB), 621/511 (LEXISNEXIS), 762/428 (BURO)
--   - Mapeo Reprocesar (todos los estados): 618,429,424,809 -> P | 810,527,621,511,762,428 -> R
-- =============================================================================
WITH
  CONFIG AS (
    SELECT VALOR AS URL_BASE
    FROM PA.PA_PARAMETROS_MVP
    WHERE CODIGO_PARAMETRO = 'URL_DIGITAL_DOCUMENTS'
  )
SELECT
    T1.F_NUM_CUENTA,
    T1.TIPO_ARCHIVO,
    T1.F_DOCUMENT_TYPE,
    T1.IDENTIFICACION,
    T1.CLIENTE,
    T1.URL_REPORTE,
    T1.NOMBRE_ARCHIVO,
    T1.FECHA_REPORTE,
    T1.ESTADO_REPORTE,
    T1.REIMPRIMIR
FROM (
    -- =============================================================================
    -- BLOQUE 1: Registros CON URL (Archivos existentes)
    -- =============================================================================
    SELECT
        CASE
            WHEN R.ESTADO_REPORTE IN ('E', 'D', 'S', 'H') THEN
                '<a href="' || APEX_PAGE.GET_URL(
                    p_page   => 66,
                    p_items  => 'P66_CODIGO_REPORTE,P66_ESTADO_REPORTE',
                    p_values => R.CODIGO_REPORTE || ',' ||
                                CASE
                                    WHEN R.ID_TIPO_DOCUMENTO IN ('618', '429', '424', '809') THEN 'P'
                                    ELSE 'R'
                                END
                ) || '">Reprocesar</a>'
            ELSE NULL
        END AS REIMPRIMIR,
        -- Numero de cuenta (formato corto = CODIGO_REFERENCIA, formato largo = PARTE3)
        CASE
            WHEN INSTR(R.CODIGO_REFERENCIA, ':') = 0 THEN R.CODIGO_REFERENCIA
            ELSE IA.PKG_API_PKM.ObtieneParteReferencia(R.CODIGO_REFERENCIA, ':', 3)
        END AS F_NUM_CUENTA,
        NVL(
            SUBSTR(R.NOMBRE_ARCHIVO, 1, INSTRB(R.NOMBRE_ARCHIVO, '_') - 1),
            'N/A'
        ) AS TIPO_ARCHIVO,
        R.ID_TIPO_DOCUMENTO AS F_DOCUMENT_TYPE,
        -- Identificacion: buscar via codigo_cliente extraido del nombre_archivo
        (SELECT C.NUMERO_IDENTIFICACION
         FROM PA.CLIENTES_B2000 C
         WHERE C.CODIGO_EMPRESA = '1'
           AND C.CODIGO_CLIENTE = REGEXP_SUBSTR(REPLACE(R.NOMBRE_ARCHIVO, '.pdf', ''), '[^_]+', 1, 3)
           AND ROWNUM = 1) AS IDENTIFICACION,
        -- Nombre del cliente via codigo_cliente del nombre_archivo
        PA.OBT_NOMBRE_PERSONA(
            REGEXP_SUBSTR(REPLACE(R.NOMBRE_ARCHIVO, '.pdf', ''), '[^_]+', 1, 3)
        ) AS CLIENTE,
        '<a href="' || APEX_UTIL.PREPARE_URL(p_url => R.URL_REPORTE, p_checksum_type => 'PUBLIC_BOOKMARK') || '" target="_blank">Descargar</a>' AS URL_REPORTE,
        REPLACE(R.NOMBRE_ARCHIVO, ':', '_') AS NOMBRE_ARCHIVO,
        R.CODIGO_REPORTE,
        R.FECHA_REPORTE,
        R.ESTADO_REPORTE
    FROM
        PA.PA_REPORTES_AUTOMATICOS R
    WHERE
        R.URL_REPORTE IS NOT NULL
        AND R.ORIGEN_PKM = 'Onboarding'

    UNION ALL

    -- =============================================================================
    -- BLOQUE 2: Registros SIN URL (Archivos pendientes o fallidos)
    -- =============================================================================
    SELECT
        CASE
            WHEN R.ESTADO_REPORTE IN ('E', 'D', 'S', 'H') THEN
                '<a href="' || APEX_PAGE.GET_URL(
                    p_page   => 66,
                    p_items  => 'P66_CODIGO_REPORTE,P66_ESTADO_REPORTE',
                    p_values => R.CODIGO_REPORTE || ',' ||
                                CASE
                                    WHEN R.ID_TIPO_DOCUMENTO IN ('618', '429', '424', '809') THEN 'P'
                                    ELSE 'R'
                                END
                ) || '">Reprocesar</a>'
            ELSE NULL
        END AS REIMPRIMIR,
        CASE
            WHEN INSTR(R.CODIGO_REFERENCIA, ':') = 0 THEN R.CODIGO_REFERENCIA
            ELSE IA.PKG_API_PKM.ObtieneParteReferencia(R.CODIGO_REFERENCIA, ':', 3)
        END AS F_NUM_CUENTA,
        NVL(
            SUBSTR(R.NOMBRE_ARCHIVO, 1, INSTRB(R.NOMBRE_ARCHIVO, '_') - 1),
            'N/A'
        ) AS TIPO_ARCHIVO,
        R.ID_TIPO_DOCUMENTO AS F_DOCUMENT_TYPE,
        (SELECT C.NUMERO_IDENTIFICACION
         FROM PA.CLIENTES_B2000 C
         WHERE C.CODIGO_EMPRESA = '1'
           AND C.CODIGO_CLIENTE = REGEXP_SUBSTR(REPLACE(R.NOMBRE_ARCHIVO, '.pdf', ''), '[^_]+', 1, 3)
           AND ROWNUM = 1) AS IDENTIFICACION,
        PA.OBT_NOMBRE_PERSONA(
            REGEXP_SUBSTR(REPLACE(R.NOMBRE_ARCHIVO, '.pdf', ''), '[^_]+', 1, 3)
        ) AS CLIENTE,
        -- Para registros sin URL, no hay link de descarga
        NULL AS URL_REPORTE,
        REPLACE(R.NOMBRE_ARCHIVO, ':', '_') AS NOMBRE_ARCHIVO,
        R.CODIGO_REPORTE,
        R.FECHA_REPORTE,
        R.ESTADO_REPORTE
    FROM
        PA.PA_REPORTES_AUTOMATICOS R
    WHERE
        R.URL_REPORTE IS NULL
        AND R.ORIGEN_PKM = 'Onboarding'
) T1;
