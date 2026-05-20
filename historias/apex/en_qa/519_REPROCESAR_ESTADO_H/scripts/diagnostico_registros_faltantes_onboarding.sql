-- =============================================================================
-- Diagnostico - Registros faltantes en Pagina 136 Onboarding
-- Proposito:
--   Determinar si los registros faltantes estan fuera de la SQL fuente,
--   fuera de ORIGEN_PKM = 'Onboarding', o filtrados por configuracion APEX.
--
-- Uso sugerido:
--   1. Ejecutar cada bloque en Toad en el mismo entorno donde se revisa APEX.
--   2. Si el BLOQUE 2 coincide con la pagina pero el usuario no los ve,
--      revisar filtros/saved report/paginacion/orden del Interactive Report.
--   3. Si aparecen filas en BLOQUE 3, decidir si la pagina debe incluir
--      tambien Tarjeta/TarjetaPC u otros valores de ORIGEN_PKM.
-- =============================================================================

-- BLOQUE 1: Conteo general por origen real.
-- Busca variantes como espacios, mayusculas/minusculas o origenes hermanos.
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

-- BLOQUE 2: Lo que la query actual de la pagina 136 debe devolver.
-- Si este conteo es igual al esperado, el faltante puede estar en APEX
-- (filtro guardado, search, paginacion, orden, columnas calculadas, etc.).
WITH PAGINA_136 AS (
    SELECT
        R.CODIGO_REPORTE,
        R.FECHA_REPORTE
    FROM PA.PA_REPORTES_AUTOMATICOS R
    WHERE R.URL_REPORTE IS NOT NULL
      AND R.ORIGEN_PKM = 'Onboarding'

    UNION ALL

    SELECT
        R.CODIGO_REPORTE,
        R.FECHA_REPORTE
    FROM PA.PA_REPORTES_AUTOMATICOS R
    WHERE R.URL_REPORTE IS NULL
      AND R.ORIGEN_PKM = 'Onboarding'
)
SELECT
    COUNT(*) AS TOTAL_PAGINA_136,
    MIN(FECHA_REPORTE) AS PRIMERA_FECHA,
    MAX(FECHA_REPORTE) AS ULTIMA_FECHA
FROM PAGINA_136;

-- BLOQUE 3: Registros que parecen del flujo, pero quedan fuera por ORIGEN_PKM.
-- Estos no entran a la pagina actual si ORIGEN_PKM no es exactamente 'Onboarding'.
SELECT
    R.CODIGO_REPORTE,
    R.ORIGEN_PKM,
    R.ID_TIPO_DOCUMENTO,
    R.ESTADO_REPORTE,
    CASE WHEN R.URL_REPORTE IS NULL THEN 'SIN_URL' ELSE 'CON_URL' END AS TIPO_URL,
    R.CODIGO_REFERENCIA,
    R.NOMBRE_ARCHIVO,
    R.FECHA_REPORTE
FROM PA.PA_REPORTES_AUTOMATICOS R
WHERE UPPER(TRIM(R.ORIGEN_PKM)) IN ('ONBOARDING', 'TARJETA', 'TARJETAPC')
  AND NVL(R.ORIGEN_PKM, '<NULL>') <> 'Onboarding'
ORDER BY R.FECHA_REPORTE DESC, R.CODIGO_REPORTE DESC;

-- BLOQUE 4: Distribucion de lo que si entra a la pagina por estado/tipo.
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

-- BLOQUE 5: Tipos de documento Onboarding no contemplados en el mapeo actual.
-- No excluyen filas, pero pueden explicar ausencia de boton Reprocesar esperado.
SELECT
    R.ID_TIPO_DOCUMENTO,
    COUNT(*) AS CANTIDAD,
    MIN(R.FECHA_REPORTE) AS PRIMERA_FECHA,
    MAX(R.FECHA_REPORTE) AS ULTIMA_FECHA
FROM PA.PA_REPORTES_AUTOMATICOS R
WHERE R.ORIGEN_PKM = 'Onboarding'
  AND R.ID_TIPO_DOCUMENTO NOT IN ('618', '429', '424', '809', '810', '527', '621', '511', '762', '428')
GROUP BY R.ID_TIPO_DOCUMENTO
ORDER BY R.ID_TIPO_DOCUMENTO;

-- BLOQUE 6: Muestra ordenada de los registros que entran a la pagina.
-- Util para confirmar si "faltan" o si estan en otra pagina por falta de ORDER BY.
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
WHERE R.ORIGEN_PKM = 'Onboarding'
ORDER BY R.FECHA_REPORTE DESC, R.CODIGO_REPORTE DESC;
