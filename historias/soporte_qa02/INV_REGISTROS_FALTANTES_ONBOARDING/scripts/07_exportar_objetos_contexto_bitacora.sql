-- =============================================================================
-- Historia: INV_REGISTROS_FALTANTES_ONBOARDING
-- Script: Exportar objetos de contexto para bitacora/reportes automaticos
--
-- Proposito:
--   Ayudar a incorporar al repo los objetos Oracle que explican:
--   1. Como se llena PA.BITACORA_REP_AUTOMATICOS.
--   2. Que proceso archiva la bitacora hacia historico.
--   3. Que job/procedure/package actualiza PA.PA_REPORTES_AUTOMATICOS.
--
-- Uso en Toad:
--   1. Ejecutar bloque por bloque.
--   2. Usar el BLOQUE 1 para decidir que objetos exportar.
--   3. Usar BLOQUE 2/3 para exportar packages/procedures/triggers.
--   4. Guardar cada objeto en su ruta real del repo:
--      ENTORNOS_ORACLE/QA02/schemas/{SCHEMA}/{tipo_objeto}/...
--   5. No modifica datos.
-- =============================================================================

-- BLOQUE 1: Resumen de objetos candidatos, sin traer todo el codigo.
SELECT
    S.OWNER,
    S.NAME,
    S.TYPE,
    MIN(S.LINE) AS LINEA_INICIAL,
    MAX(S.LINE) AS LINEA_FINAL,
    COUNT(*) AS TOTAL_LINEAS
FROM ALL_SOURCE S
WHERE S.OWNER IN ('PA', 'IA')
  AND S.NAME IN (
        'PKG_MANT_TBL_HELADO',
        'BITACORA_REPORTES_AUTOMATICOS',
        'CAMBIAR_MULTIESTADO_REP_AUTO',
        'MARK_ERROR_STATUS_AUTOMATICO',
        'CHECK_ESTADO_REPORTE',
        'CHECK_ESTADO_REPORTE_TEST',
        'CHECK_ESTADO_REPORTE_V1'
  )
GROUP BY
    S.OWNER,
    S.NAME,
    S.TYPE
ORDER BY
    S.OWNER,
    S.NAME,
    S.TYPE;

-- BLOQUE 2: Exportar source lineal de un objeto puntual.
-- Reemplazar :P_OWNER, :P_OBJECT_NAME y :P_OBJECT_TYPE.
-- Valores de ejemplo:
--   :P_OWNER       = 'PA'
--   :P_OBJECT_NAME = 'PKG_MANT_TBL_HELADO'
--   :P_OBJECT_TYPE = 'PACKAGE BODY'
SELECT
    S.LINE,
    S.TEXT
FROM ALL_SOURCE S
WHERE S.OWNER = UPPER(:P_OWNER)
  AND S.NAME = UPPER(:P_OBJECT_NAME)
  AND S.TYPE = UPPER(:P_OBJECT_TYPE)
ORDER BY S.LINE;

-- BLOQUE 3: Exportar DDL completo con DBMS_METADATA.
-- Para packages:
--   :P_METADATA_TYPE = 'PACKAGE' o 'PACKAGE_BODY'
-- Para procedures:
--   :P_METADATA_TYPE = 'PROCEDURE'
-- Para triggers:
--   :P_METADATA_TYPE = 'TRIGGER'
SELECT
    DBMS_METADATA.GET_DDL(
        object_type => UPPER(:P_METADATA_TYPE),
        name        => UPPER(:P_OBJECT_NAME),
        schema      => UPPER(:P_OWNER)
    ) AS DDL_OBJECT
FROM DUAL;

-- BLOQUE 4: Exportar ambos lados de un package.
-- Usar cuando el candidato sea package, porque para analisis completo se
-- necesita spec y body.
SELECT
    'PACKAGE' AS METADATA_TYPE,
    DBMS_METADATA.GET_DDL('PACKAGE', UPPER(:P_PACKAGE_NAME), UPPER(:P_OWNER)) AS DDL_OBJECT
FROM DUAL
UNION ALL
SELECT
    'PACKAGE_BODY' AS METADATA_TYPE,
    DBMS_METADATA.GET_DDL('PACKAGE_BODY', UPPER(:P_PACKAGE_NAME), UPPER(:P_OWNER)) AS DDL_OBJECT
FROM DUAL;

-- BLOQUE 5: Identificar jobs scheduler candidatos sin traer todo el DDL.
SELECT
    J.OWNER,
    J.JOB_NAME,
    J.ENABLED,
    J.STATE,
    J.JOB_TYPE,
    J.JOB_ACTION,
    J.PROGRAM_OWNER,
    J.PROGRAM_NAME,
    J.SCHEDULE_OWNER,
    J.SCHEDULE_NAME,
    J.REPEAT_INTERVAL,
    J.START_DATE,
    J.LAST_START_DATE,
    J.NEXT_RUN_DATE,
    J.RUN_COUNT,
    J.FAILURE_COUNT
FROM ALL_SCHEDULER_JOBS J
WHERE UPPER(NVL(J.JOB_ACTION, ' ')) LIKE '%PKG_MANT_TBL_HELADO%'
   OR UPPER(NVL(J.JOB_ACTION, ' ')) LIKE '%MANT_TBL_HELADO%'
   OR UPPER(NVL(J.JOB_ACTION, ' ')) LIKE '%BITACORA%'
   OR UPPER(NVL(J.JOB_ACTION, ' ')) LIKE '%REPORTE%'
   OR UPPER(NVL(J.JOB_ACTION, ' ')) LIKE '%REPORT%'
   OR UPPER(NVL(J.JOB_NAME, ' ')) LIKE '%HELADO%'
   OR UPPER(NVL(J.JOB_NAME, ' ')) LIKE '%BITACORA%'
   OR UPPER(NVL(J.JOB_NAME, ' ')) LIKE '%REPORTE%'
   OR UPPER(NVL(J.JOB_NAME, ' ')) LIKE '%REPORT%'
ORDER BY
    J.OWNER,
    J.JOB_NAME;

-- BLOQUE 6: Exportar DDL de un scheduler job.
-- DBMS_METADATA usa PROCOBJ para objetos scheduler en muchos ambientes.
-- Si falla por privilegios, exportar el job desde Schema Browser de Toad.
-- Si Toad retorna ORA-31600 con parametro NAME NULL, significa que no se
-- suministro valor para :P_JOB_NAME. Usar el BLOQUE 6A para este caso puntual.
SELECT
    DBMS_METADATA.GET_DDL(
        object_type => 'PROCOBJ',
        name        => UPPER(:P_JOB_NAME),
        schema      => UPPER(:P_OWNER)
    ) AS DDL_JOB
FROM DUAL;

-- BLOQUE 6A: Exportar DDL del job identificado sin variables bind.
SELECT
    DBMS_METADATA.GET_DDL(
        object_type => 'PROCOBJ',
        name        => 'JOB_PA_MANT_TBL_HELADO',
        schema      => 'PA'
    ) AS DDL_JOB
FROM DUAL;

-- BLOQUE 6B: Fallback si DBMS_METADATA falla por permisos.
-- No es DDL completo, pero documenta la configuracion operativa del job.
SELECT
    J.OWNER,
    J.JOB_NAME,
    J.ENABLED,
    J.STATE,
    J.JOB_TYPE,
    J.JOB_ACTION,
    J.PROGRAM_OWNER,
    J.PROGRAM_NAME,
    J.SCHEDULE_OWNER,
    J.SCHEDULE_NAME,
    J.REPEAT_INTERVAL,
    J.START_DATE,
    J.LAST_START_DATE,
    J.NEXT_RUN_DATE,
    J.RUN_COUNT,
    J.FAILURE_COUNT
FROM ALL_SCHEDULER_JOBS J
WHERE J.OWNER = 'PA'
  AND J.JOB_NAME = 'JOB_PA_MANT_TBL_HELADO';

-- BLOQUE 7: Plantilla de cabecera para pegar al inicio del archivo incorporado.
SELECT
    '-- =============================================================================' || CHR(10) ||
    '-- Entorno: QA02' || CHR(10) ||
    '-- Schema: ' || UPPER(:P_OWNER) || CHR(10) ||
    '-- Fecha incorporacion: ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD') || CHR(10) ||
    '-- Origen: Toad / ALL_SOURCE / DBMS_METADATA' || CHR(10) ||
    '-- Motivo: Investigacion registros faltantes en Reportes Onboarding' || CHR(10) ||
    '-- Observacion: Objeto incorporado como referencia, sin alterar logica.' || CHR(10) ||
    '-- =============================================================================' AS CABECERA
FROM DUAL;
