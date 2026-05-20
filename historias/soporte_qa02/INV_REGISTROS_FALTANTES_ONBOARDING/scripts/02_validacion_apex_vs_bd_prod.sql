-- =============================================================================
-- Historia: INV_REGISTROS_FALTANTES_ONBOARDING
-- Validacion APEX vs Base de Datos - Produccion
--
-- Proposito:
--   Comparar lo que debe devolver la SQL de la pagina 136 contra lo visible
--   en APEX Produccion, sin cambiar datos.
--
-- Uso:
--   1. Ejecutar en Toad conectado al mismo ambiente donde se revisa APEX.
--   2. En APEX pagina 136, usar Actions > Reset antes de comparar.
--   3. Exportar el reporte visible de APEX a CSV/Excel.
--   4. Comparar el total/export de APEX contra BLOQUE 2 y BLOQUE 3.
-- =============================================================================

-- BLOQUE 1: Distribucion completa por ORIGEN_PKM real.
-- Objetivo: confirmar si existen registros en Normal, Tarjeta o TarjetaPC
-- que negocio espere ver en la pagina de Onboarding.
SELECT
    NVL(R.ORIGEN_PKM, '<NULL>') AS ORIGEN_PKM,
    TRIM(R.ORIGEN_PKM) AS ORIGEN_TRIM,
    UPPER(TRIM(R.ORIGEN_PKM)) AS ORIGEN_NORMALIZADO,
    COUNT(*) AS CANTIDAD,
    MIN(R.FECHA_REPORTE) AS PRIMERA_FECHA,
    MAX(R.FECHA_REPORTE) AS ULTIMA_FECHA
FROM PA.PA_REPORTES_AUTOMATICOS R
GROUP BY
    NVL(R.ORIGEN_PKM, '<NULL>'),
    TRIM(R.ORIGEN_PKM),
    UPPER(TRIM(R.ORIGEN_PKM))
ORDER BY CANTIDAD DESC;

-- BLOQUE 2: Total exacto que debe devolver la pagina 136.
-- La pagina une registros con URL y sin URL; por eso URL_REPORTE no excluye.
WITH PAGINA_136 AS (
    SELECT R.CODIGO_REPORTE
    FROM PA.PA_REPORTES_AUTOMATICOS R
    WHERE R.ORIGEN_PKM = 'Onboarding'
)
SELECT
    COUNT(*) AS TOTAL_BD_PAGINA_136,
    MIN(R.FECHA_REPORTE) AS PRIMERA_FECHA,
    MAX(R.FECHA_REPORTE) AS ULTIMA_FECHA,
    SUM(CASE WHEN R.URL_REPORTE IS NULL THEN 1 ELSE 0 END) AS TOTAL_SIN_URL,
    SUM(CASE WHEN R.URL_REPORTE IS NOT NULL THEN 1 ELSE 0 END) AS TOTAL_CON_URL
FROM PA.PA_REPORTES_AUTOMATICOS R
WHERE R.CODIGO_REPORTE IN (SELECT P.CODIGO_REPORTE FROM PAGINA_136 P);

-- BLOQUE 3: Lista exacta de filas que debe mostrar APEX.
-- Exportar este resultado y compararlo contra el CSV/Excel de APEX.
SELECT
    R.CODIGO_REPORTE,
    R.ORIGEN_PKM,
    R.ID_TIPO_DOCUMENTO AS F_DOCUMENT_TYPE,
    R.ESTADO_REPORTE,
    CASE WHEN R.URL_REPORTE IS NULL THEN 'SIN_URL' ELSE 'CON_URL' END AS TIPO_URL,
    CASE
        WHEN INSTR(R.CODIGO_REFERENCIA, ':') = 0 THEN R.CODIGO_REFERENCIA
        ELSE IA.PKG_API_PKM.ObtieneParteReferencia(R.CODIGO_REFERENCIA, ':', 3)
    END AS F_NUM_CUENTA,
    R.CODIGO_REFERENCIA,
    REPLACE(R.NOMBRE_ARCHIVO, ':', '_') AS NOMBRE_ARCHIVO,
    R.FECHA_REPORTE
FROM PA.PA_REPORTES_AUTOMATICOS R
WHERE R.ORIGEN_PKM = 'Onboarding'
ORDER BY R.FECHA_REPORTE DESC, R.CODIGO_REPORTE DESC;

-- BLOQUE 4: Buscar un registro reportado como faltante.
-- Reemplazar los bind variables segun la evidencia disponible.
-- Si no tiene CODIGO_REPORTE, buscar por numero de cuenta o nombre de archivo.
SELECT
    R.CODIGO_REPORTE,
    R.ORIGEN_PKM,
    R.ID_TIPO_DOCUMENTO,
    R.ESTADO_REPORTE,
    CASE WHEN R.URL_REPORTE IS NULL THEN 'SIN_URL' ELSE 'CON_URL' END AS TIPO_URL,
    CASE
        WHEN INSTR(R.CODIGO_REFERENCIA, ':') = 0 THEN R.CODIGO_REFERENCIA
        ELSE IA.PKG_API_PKM.ObtieneParteReferencia(R.CODIGO_REFERENCIA, ':', 3)
    END AS F_NUM_CUENTA,
    R.CODIGO_REFERENCIA,
    R.NOMBRE_ARCHIVO,
    R.FECHA_REPORTE,
    CASE
        WHEN R.ORIGEN_PKM = 'Onboarding' THEN 'DEBE_ENTRAR_A_PAGINA'
        ELSE 'NO_ENTRA_POR_ORIGEN'
    END AS DIAGNOSTICO
FROM PA.PA_REPORTES_AUTOMATICOS R
WHERE (:P_CODIGO_REPORTE IS NOT NULL AND R.CODIGO_REPORTE = :P_CODIGO_REPORTE)
   OR (:P_NUM_CUENTA IS NOT NULL AND R.CODIGO_REFERENCIA LIKE '%' || :P_NUM_CUENTA || '%')
   OR (:P_NUM_CUENTA IS NOT NULL AND R.NOMBRE_ARCHIVO LIKE '%' || :P_NUM_CUENTA || '%')
   OR (:P_NOMBRE_ARCHIVO IS NOT NULL AND R.NOMBRE_ARCHIVO = :P_NOMBRE_ARCHIVO)
ORDER BY R.FECHA_REPORTE DESC, R.CODIGO_REPORTE DESC;

-- BLOQUE 5: Candidatos relacionados que NO entran a la pagina actual.
-- Si aqui aparecen los faltantes, la diferencia es de alcance de ORIGEN_PKM.
SELECT
    R.CODIGO_REPORTE,
    R.ORIGEN_PKM,
    R.ID_TIPO_DOCUMENTO,
    R.ESTADO_REPORTE,
    CASE WHEN R.URL_REPORTE IS NULL THEN 'SIN_URL' ELSE 'CON_URL' END AS TIPO_URL,
    CASE
        WHEN INSTR(R.CODIGO_REFERENCIA, ':') = 0 THEN R.CODIGO_REFERENCIA
        ELSE IA.PKG_API_PKM.ObtieneParteReferencia(R.CODIGO_REFERENCIA, ':', 3)
    END AS F_NUM_CUENTA,
    R.CODIGO_REFERENCIA,
    R.NOMBRE_ARCHIVO,
    R.FECHA_REPORTE
FROM PA.PA_REPORTES_AUTOMATICOS R
WHERE UPPER(TRIM(R.ORIGEN_PKM)) IN ('ONBOARDING', 'TARJETA', 'TARJETAPC')
  AND NVL(R.ORIGEN_PKM, '<NULL>') <> 'Onboarding'
ORDER BY R.FECHA_REPORTE DESC, R.CODIGO_REPORTE DESC;

-- BLOQUE 6: Distribucion interna de lo que SI entra a la pagina.
-- Ayuda a responder si el faltante esta asociado a estado/tipo documento/URL.
SELECT
    R.ESTADO_REPORTE,
    R.ID_TIPO_DOCUMENTO,
    CASE WHEN R.URL_REPORTE IS NULL THEN 'SIN_URL' ELSE 'CON_URL' END AS TIPO_URL,
    COUNT(*) AS CANTIDAD,
    MIN(R.FECHA_REPORTE) AS PRIMERA_FECHA,
    MAX(R.FECHA_REPORTE) AS ULTIMA_FECHA
FROM PA.PA_REPORTES_AUTOMATICOS R
WHERE R.ORIGEN_PKM = 'Onboarding'
GROUP BY
    R.ESTADO_REPORTE,
    R.ID_TIPO_DOCUMENTO,
    CASE WHEN R.URL_REPORTE IS NULL THEN 'SIN_URL' ELSE 'CON_URL' END
ORDER BY R.ESTADO_REPORTE, R.ID_TIPO_DOCUMENTO, TIPO_URL;
