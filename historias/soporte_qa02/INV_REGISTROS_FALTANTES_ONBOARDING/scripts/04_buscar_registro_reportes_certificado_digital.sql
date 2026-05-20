-- =============================================================================
-- Historia: INV_REGISTROS_FALTANTES_ONBOARDING
-- Script: Buscar registro de reportes automaticos para certificados digitales
--
-- Proposito:
--   Identificar en Produccion/QA02 que objetos del schema CD generan o registran
--   documentos en PA.PA_REPORTES_AUTOMATICOS, especialmente certificados digitales.
--
-- Uso en Toad:
--   1. Ejecutar en el ambiente donde se investigan los faltantes.
--   2. No modifica datos.
--   3. Guardar resultados como evidencia.
-- =============================================================================

-- BLOQUE 1: Confirmar que las cuentas reportadas no existen en PA_REPORTES_AUTOMATICOS.
-- Reemplazar la lista por los F_NUM_CUENTA reportados por coordinacion.
WITH CUENTAS AS (
    SELECT '21055516645617' AS F_NUM_CUENTA FROM DUAL
)
SELECT
    C.F_NUM_CUENTA AS F_NUM_CUENTA_BUSCADO,
    R.CODIGO_REPORTE,
    R.ORIGEN_PKM,
    R.ID_TIPO_DOCUMENTO,
    R.ESTADO_REPORTE,
    R.CODIGO_REFERENCIA,
    R.NOMBRE_ARCHIVO,
    R.FECHA_REPORTE,
    CASE
        WHEN R.CODIGO_REPORTE IS NULL THEN 'NO_EXISTE_EN_PA_REPORTES_AUTOMATICOS'
        ELSE 'EXISTE_EN_PA_REPORTES_AUTOMATICOS'
    END AS DIAGNOSTICO
FROM CUENTAS C
LEFT JOIN PA.PA_REPORTES_AUTOMATICOS R
    ON R.CODIGO_REFERENCIA LIKE '%' || C.F_NUM_CUENTA || '%'
    OR R.NOMBRE_ARCHIVO LIKE '%' || C.F_NUM_CUENTA || '%'
ORDER BY
    C.F_NUM_CUENTA,
    R.FECHA_REPORTE DESC,
    R.CODIGO_REPORTE DESC;

-- BLOQUE 2: Buscar objetos de CD que llamen InsertUrlReporte.
SELECT
    S.OWNER,
    S.NAME,
    S.TYPE,
    MIN(S.LINE) AS PRIMERA_LINEA,
    COUNT(*) AS COINCIDENCIAS
FROM ALL_SOURCE S
WHERE S.OWNER = 'CD'
  AND UPPER(S.TEXT) LIKE '%INSERTURLREPORTE%'
GROUP BY
    S.OWNER,
    S.NAME,
    S.TYPE
ORDER BY
    S.NAME,
    S.TYPE;

-- BLOQUE 3: Ver las lineas exactas donde CD llama InsertUrlReporte.
SELECT
    S.OWNER,
    S.NAME,
    S.TYPE,
    S.LINE,
    S.TEXT
FROM ALL_SOURCE S
WHERE S.OWNER = 'CD'
  AND UPPER(S.TEXT) LIKE '%INSERTURLREPORTE%'
ORDER BY
    S.NAME,
    S.TYPE,
    S.LINE;

-- BLOQUE 4: Buscar objetos de CD que referencien PA_REPORTES_AUTOMATICOS directo.
SELECT
    S.OWNER,
    S.NAME,
    S.TYPE,
    S.LINE,
    S.TEXT
FROM ALL_SOURCE S
WHERE S.OWNER = 'CD'
  AND UPPER(S.TEXT) LIKE '%PA_REPORTES_AUTOMATICOS%'
ORDER BY
    S.NAME,
    S.TYPE,
    S.LINE;

-- BLOQUE 5: Buscar objetos de CD relacionados con nombres de documentos de certificados.
SELECT
    S.OWNER,
    S.NAME,
    S.TYPE,
    S.LINE,
    S.TEXT
FROM ALL_SOURCE S
WHERE S.OWNER = 'CD'
  AND (
        UPPER(S.TEXT) LIKE '%CERTIFICADO%'
     OR UPPER(S.TEXT) LIKE '%CERTIFIC%'
     OR UPPER(S.TEXT) LIKE '%DIGITAL%'
     OR UPPER(S.TEXT) LIKE '%NOMBRE_ARCHIVO%'
     OR UPPER(S.TEXT) LIKE '%ID_TIPO_DOCUMENTO%'
  )
ORDER BY
    S.NAME,
    S.TYPE,
    S.LINE;

-- BLOQUE 6: Si aparece un package candidato, extraer el contexto alrededor de
-- InsertUrlReporte. Reemplazar :P_PACKAGE_NAME por el nombre del package.
SELECT
    S.OWNER,
    S.NAME,
    S.TYPE,
    S.LINE,
    S.TEXT
FROM ALL_SOURCE S
WHERE S.OWNER = 'CD'
  AND S.NAME = UPPER(:P_PACKAGE_NAME)
  AND S.LINE BETWEEN (
        SELECT MIN(S2.LINE) - 20
        FROM ALL_SOURCE S2
        WHERE S2.OWNER = 'CD'
          AND S2.NAME = UPPER(:P_PACKAGE_NAME)
          AND UPPER(S2.TEXT) LIKE '%INSERTURLREPORTE%'
      )
      AND (
        SELECT MAX(S3.LINE) + 40
        FROM ALL_SOURCE S3
        WHERE S3.OWNER = 'CD'
          AND S3.NAME = UPPER(:P_PACKAGE_NAME)
          AND UPPER(S3.TEXT) LIKE '%INSERTURLREPORTE%'
      )
ORDER BY
    S.TYPE,
    S.LINE;

-- BLOQUE 7: Busqueda ampliada en schemas frecuentes, por si certificado digital
-- no registra desde CD directamente.
SELECT
    S.OWNER,
    S.NAME,
    S.TYPE,
    MIN(S.LINE) AS PRIMERA_LINEA,
    COUNT(*) AS COINCIDENCIAS
FROM ALL_SOURCE S
WHERE S.OWNER IN ('CD', 'PR', 'PA', 'CC', 'IA')
  AND (
        UPPER(S.TEXT) LIKE '%INSERTURLREPORTE%'
     OR UPPER(S.TEXT) LIKE '%PA_REPORTES_AUTOMATICOS%'
     OR UPPER(S.TEXT) LIKE '%PKG_CD_DIGITAL%'
     OR UPPER(S.TEXT) LIKE '%DIGCERT%'
     OR UPPER(S.TEXT) LIKE '%CERTIFICADO DIGITAL%'
  )
GROUP BY
    S.OWNER,
    S.NAME,
    S.TYPE
ORDER BY
    S.OWNER,
    S.NAME,
    S.TYPE;

-- BLOQUE 8: Contexto ampliado para un objeto candidato de cualquier owner.
-- Reemplazar :P_OWNER y :P_OBJECT_NAME.
SELECT
    S.OWNER,
    S.NAME,
    S.TYPE,
    S.LINE,
    S.TEXT
FROM ALL_SOURCE S
WHERE S.OWNER = UPPER(:P_OWNER)
  AND S.NAME = UPPER(:P_OBJECT_NAME)
  AND S.LINE BETWEEN (
        SELECT MIN(S2.LINE) - 30
        FROM ALL_SOURCE S2
        WHERE S2.OWNER = UPPER(:P_OWNER)
          AND S2.NAME = UPPER(:P_OBJECT_NAME)
          AND (
                UPPER(S2.TEXT) LIKE '%INSERTURLREPORTE%'
             OR UPPER(S2.TEXT) LIKE '%PA_REPORTES_AUTOMATICOS%'
             OR UPPER(S2.TEXT) LIKE '%PKG_CD_DIGITAL%'
             OR UPPER(S2.TEXT) LIKE '%DIGCERT%'
             OR UPPER(S2.TEXT) LIKE '%CERTIFICADO DIGITAL%'
          )
      )
      AND (
        SELECT MAX(S3.LINE) + 60
        FROM ALL_SOURCE S3
        WHERE S3.OWNER = UPPER(:P_OWNER)
          AND S3.NAME = UPPER(:P_OBJECT_NAME)
          AND (
                UPPER(S3.TEXT) LIKE '%INSERTURLREPORTE%'
             OR UPPER(S3.TEXT) LIKE '%PA_REPORTES_AUTOMATICOS%'
             OR UPPER(S3.TEXT) LIKE '%PKG_CD_DIGITAL%'
             OR UPPER(S3.TEXT) LIKE '%DIGCERT%'
             OR UPPER(S3.TEXT) LIKE '%CERTIFICADO DIGITAL%'
          )
      )
ORDER BY
    S.TYPE,
    S.LINE;
