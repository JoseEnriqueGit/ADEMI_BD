-- =============================================================================
-- Script de preparacion de datos de prueba - Pagina 136 Onboarding
-- Proposito: Actualizar registros existentes de Onboarding para tener
--            5 registros en cada estado reprocesable (E, D, S, H)
-- =============================================================================
-- INSTRUCCIONES:
--   1. Ejecutar el SELECT de diagnostico primero para ver registros disponibles
--   2. Ejecutar los UPDATEs segun los CODIGO_REPORTE reales de tu entorno
--   3. NO hacer COMMIT hasta validar en la pagina 136
--   4. Hacer ROLLBACK si algo sale mal
-- =============================================================================

-- =============================================================================
-- PASO 0: Diagnostico - Ver que registros Onboarding existen
-- =============================================================================
SELECT
    R.CODIGO_REPORTE,
    R.ID_TIPO_DOCUMENTO,
    R.ESTADO_REPORTE,
    R.ORIGEN_PKM,
    R.NOMBRE_ARCHIVO,
    CASE
        WHEN R.ID_TIPO_DOCUMENTO IN ('618', '429', '424', '809') THEN 'P (Pendiente)'
        ELSE 'R (Pendiente Robotizado)'
    END AS DESTINO_ESPERADO
FROM PA.PA_REPORTES_AUTOMATICOS R
WHERE R.ORIGEN_PKM = 'Onboarding'
ORDER BY R.ID_TIPO_DOCUMENTO, R.CODIGO_REPORTE;

-- =============================================================================
-- PASO 1: Guardar estados originales para ROLLBACK manual si es necesario
-- =============================================================================
-- Ejecutar ANTES de los updates para tener respaldo:
SELECT
    R.CODIGO_REPORTE,
    R.ESTADO_REPORTE AS ESTADO_ORIGINAL,
    R.ID_TIPO_DOCUMENTO
FROM PA.PA_REPORTES_AUTOMATICOS R
WHERE R.ORIGEN_PKM = 'Onboarding'
  AND R.ID_TIPO_DOCUMENTO IN ('618', '429', '424', '809', '810', '527', '621', '511', '762', '428')
ORDER BY R.ID_TIPO_DOCUMENTO;

-- =============================================================================
-- PASO 2: Preparar 5 registros en cada estado (E, D, S, H)
--         Mezclando tipos que van a P y tipos que van a R
-- =============================================================================
-- Estrategia: Usar subqueries con ROWNUM para tomar los primeros N registros
--             disponibles de cada tipo de documento.

-- ----- ESTADO E (Error) - 5 registros -----
-- 3 que deben ir a P (618, 429, 424) + 2 que deben ir a R (810, 621)
UPDATE PA.PA_REPORTES_AUTOMATICOS
SET ESTADO_REPORTE = 'E'
WHERE CODIGO_REPORTE IN (
    -- 1 registro tipo 618 (Conozca Su Cliente -> P)
    SELECT CODIGO_REPORTE FROM (
        SELECT CODIGO_REPORTE FROM PA.PA_REPORTES_AUTOMATICOS
        WHERE ORIGEN_PKM = 'Onboarding' AND ID_TIPO_DOCUMENTO = '618'
        ORDER BY CODIGO_REPORTE
    ) WHERE ROWNUM = 1
    UNION ALL
    -- 1 registro tipo 429 (Conozca Su Cliente -> P)
    SELECT CODIGO_REPORTE FROM (
        SELECT CODIGO_REPORTE FROM PA.PA_REPORTES_AUTOMATICOS
        WHERE ORIGEN_PKM = 'Onboarding' AND ID_TIPO_DOCUMENTO = '429'
        ORDER BY CODIGO_REPORTE
    ) WHERE ROWNUM = 1
    UNION ALL
    -- 1 registro tipo 424 (Solicitud Tarjeta -> P)
    SELECT CODIGO_REPORTE FROM (
        SELECT CODIGO_REPORTE FROM PA.PA_REPORTES_AUTOMATICOS
        WHERE ORIGEN_PKM = 'Onboarding' AND ID_TIPO_DOCUMENTO = '424'
        ORDER BY CODIGO_REPORTE
    ) WHERE ROWNUM = 1
    UNION ALL
    -- 1 registro tipo 810 (SIB -> R)
    SELECT CODIGO_REPORTE FROM (
        SELECT CODIGO_REPORTE FROM PA.PA_REPORTES_AUTOMATICOS
        WHERE ORIGEN_PKM = 'Onboarding' AND ID_TIPO_DOCUMENTO = '810'
        ORDER BY CODIGO_REPORTE
    ) WHERE ROWNUM = 1
    UNION ALL
    -- 1 registro tipo 621 (LexisNexis -> R)
    SELECT CODIGO_REPORTE FROM (
        SELECT CODIGO_REPORTE FROM PA.PA_REPORTES_AUTOMATICOS
        WHERE ORIGEN_PKM = 'Onboarding' AND ID_TIPO_DOCUMENTO = '621'
        ORDER BY CODIGO_REPORTE
    ) WHERE ROWNUM = 1
);

-- ----- ESTADO D (Descargado) - 5 registros -----
-- 2 que deben ir a P (809, 618) + 3 que deben ir a R (527, 511, 762)
UPDATE PA.PA_REPORTES_AUTOMATICOS
SET ESTADO_REPORTE = 'D'
WHERE CODIGO_REPORTE IN (
    -- 1 registro tipo 809 (Matriz Riesgo -> P)
    SELECT CODIGO_REPORTE FROM (
        SELECT CODIGO_REPORTE FROM PA.PA_REPORTES_AUTOMATICOS
        WHERE ORIGEN_PKM = 'Onboarding' AND ID_TIPO_DOCUMENTO = '809'
        ORDER BY CODIGO_REPORTE
    ) WHERE ROWNUM = 1
    UNION ALL
    -- 1 registro tipo 618 (Conozca Su Cliente -> P) - tomar el 2do
    SELECT CODIGO_REPORTE FROM (
        SELECT CODIGO_REPORTE, ROW_NUMBER() OVER (ORDER BY CODIGO_REPORTE) RN
        FROM PA.PA_REPORTES_AUTOMATICOS
        WHERE ORIGEN_PKM = 'Onboarding' AND ID_TIPO_DOCUMENTO = '618'
    ) WHERE RN = 2
    UNION ALL
    -- 1 registro tipo 527 (SIB -> R)
    SELECT CODIGO_REPORTE FROM (
        SELECT CODIGO_REPORTE FROM PA.PA_REPORTES_AUTOMATICOS
        WHERE ORIGEN_PKM = 'Onboarding' AND ID_TIPO_DOCUMENTO = '527'
        ORDER BY CODIGO_REPORTE
    ) WHERE ROWNUM = 1
    UNION ALL
    -- 1 registro tipo 511 (LexisNexis -> R)
    SELECT CODIGO_REPORTE FROM (
        SELECT CODIGO_REPORTE FROM PA.PA_REPORTES_AUTOMATICOS
        WHERE ORIGEN_PKM = 'Onboarding' AND ID_TIPO_DOCUMENTO = '511'
        ORDER BY CODIGO_REPORTE
    ) WHERE ROWNUM = 1
    UNION ALL
    -- 1 registro tipo 762 (Buro de Credito -> R)
    SELECT CODIGO_REPORTE FROM (
        SELECT CODIGO_REPORTE FROM PA.PA_REPORTES_AUTOMATICOS
        WHERE ORIGEN_PKM = 'Onboarding' AND ID_TIPO_DOCUMENTO = '762'
        ORDER BY CODIGO_REPORTE
    ) WHERE ROWNUM = 1
);

-- ----- ESTADO S (Subido) - 5 registros -----
-- 2 que deben ir a P (424, 429) + 3 que deben ir a R (428, 810, 621)
UPDATE PA.PA_REPORTES_AUTOMATICOS
SET ESTADO_REPORTE = 'S'
WHERE CODIGO_REPORTE IN (
    -- 1 registro tipo 424 (Solicitud Tarjeta -> P) - tomar el 2do
    SELECT CODIGO_REPORTE FROM (
        SELECT CODIGO_REPORTE, ROW_NUMBER() OVER (ORDER BY CODIGO_REPORTE) RN
        FROM PA.PA_REPORTES_AUTOMATICOS
        WHERE ORIGEN_PKM = 'Onboarding' AND ID_TIPO_DOCUMENTO = '424'
    ) WHERE RN = 2
    UNION ALL
    -- 1 registro tipo 429 (Conozca Su Cliente -> P) - tomar el 2do
    SELECT CODIGO_REPORTE FROM (
        SELECT CODIGO_REPORTE, ROW_NUMBER() OVER (ORDER BY CODIGO_REPORTE) RN
        FROM PA.PA_REPORTES_AUTOMATICOS
        WHERE ORIGEN_PKM = 'Onboarding' AND ID_TIPO_DOCUMENTO = '429'
    ) WHERE RN = 2
    UNION ALL
    -- 1 registro tipo 428 (Buro de Credito -> R)
    SELECT CODIGO_REPORTE FROM (
        SELECT CODIGO_REPORTE FROM PA.PA_REPORTES_AUTOMATICOS
        WHERE ORIGEN_PKM = 'Onboarding' AND ID_TIPO_DOCUMENTO = '428'
        ORDER BY CODIGO_REPORTE
    ) WHERE ROWNUM = 1
    UNION ALL
    -- 1 registro tipo 810 (SIB -> R) - tomar el 2do
    SELECT CODIGO_REPORTE FROM (
        SELECT CODIGO_REPORTE, ROW_NUMBER() OVER (ORDER BY CODIGO_REPORTE) RN
        FROM PA.PA_REPORTES_AUTOMATICOS
        WHERE ORIGEN_PKM = 'Onboarding' AND ID_TIPO_DOCUMENTO = '810'
    ) WHERE RN = 2
    UNION ALL
    -- 1 registro tipo 621 (LexisNexis -> R) - tomar el 2do
    SELECT CODIGO_REPORTE FROM (
        SELECT CODIGO_REPORTE, ROW_NUMBER() OVER (ORDER BY CODIGO_REPORTE) RN
        FROM PA.PA_REPORTES_AUTOMATICOS
        WHERE ORIGEN_PKM = 'Onboarding' AND ID_TIPO_DOCUMENTO = '621'
    ) WHERE RN = 2
);

-- ----- ESTADO H (Reservado para Descarga) - 5 registros -----
-- 2 que deben ir a P (618, 809) + 3 que deben ir a R (762, 527, 511)
UPDATE PA.PA_REPORTES_AUTOMATICOS
SET ESTADO_REPORTE = 'H'
WHERE CODIGO_REPORTE IN (
    -- 1 registro tipo 618 (Conozca Su Cliente -> P) - tomar el 3ro
    SELECT CODIGO_REPORTE FROM (
        SELECT CODIGO_REPORTE, ROW_NUMBER() OVER (ORDER BY CODIGO_REPORTE) RN
        FROM PA.PA_REPORTES_AUTOMATICOS
        WHERE ORIGEN_PKM = 'Onboarding' AND ID_TIPO_DOCUMENTO = '618'
    ) WHERE RN = 3
    UNION ALL
    -- 1 registro tipo 809 (Matriz Riesgo -> P) - tomar el 2do
    SELECT CODIGO_REPORTE FROM (
        SELECT CODIGO_REPORTE, ROW_NUMBER() OVER (ORDER BY CODIGO_REPORTE) RN
        FROM PA.PA_REPORTES_AUTOMATICOS
        WHERE ORIGEN_PKM = 'Onboarding' AND ID_TIPO_DOCUMENTO = '809'
    ) WHERE RN = 2
    UNION ALL
    -- 1 registro tipo 762 (Buro -> R) - tomar el 2do
    SELECT CODIGO_REPORTE FROM (
        SELECT CODIGO_REPORTE, ROW_NUMBER() OVER (ORDER BY CODIGO_REPORTE) RN
        FROM PA.PA_REPORTES_AUTOMATICOS
        WHERE ORIGEN_PKM = 'Onboarding' AND ID_TIPO_DOCUMENTO = '762'
    ) WHERE RN = 2
    UNION ALL
    -- 1 registro tipo 527 (SIB -> R) - tomar el 2do
    SELECT CODIGO_REPORTE FROM (
        SELECT CODIGO_REPORTE, ROW_NUMBER() OVER (ORDER BY CODIGO_REPORTE) RN
        FROM PA.PA_REPORTES_AUTOMATICOS
        WHERE ORIGEN_PKM = 'Onboarding' AND ID_TIPO_DOCUMENTO = '527'
    ) WHERE RN = 2
    UNION ALL
    -- 1 registro tipo 511 (LexisNexis -> R) - tomar el 2do
    SELECT CODIGO_REPORTE FROM (
        SELECT CODIGO_REPORTE, ROW_NUMBER() OVER (ORDER BY CODIGO_REPORTE) RN
        FROM PA.PA_REPORTES_AUTOMATICOS
        WHERE ORIGEN_PKM = 'Onboarding' AND ID_TIPO_DOCUMENTO = '511'
    ) WHERE RN = 2
);

-- =============================================================================
-- PASO 3: Verificar resultado - deben aparecer 5 por estado
-- =============================================================================
-- Logica de transicion (segun criterios de aceptacion IRD-519):
--   TODOS los estados (E, D, S, H) -> segun tipo de documento
--   618, 429, 424, 809 -> P (Pendiente)
--   810, 527, 621, 511, 762, 428 -> R (Pendiente Robotizado)
SELECT
    R.ESTADO_REPORTE,
    R.CODIGO_REPORTE,
    R.ID_TIPO_DOCUMENTO,
    CASE
        WHEN R.ID_TIPO_DOCUMENTO IN ('618', '429', '424', '809') THEN 'P (Pendiente)'
        ELSE 'R (Pendiente Robotizado)'
    END AS DESTINO_ESPERADO,
    CASE
        WHEN R.ID_TIPO_DOCUMENTO IN ('618', '429') THEN 'Conozca Su Cliente / FCSCPF'
        WHEN R.ID_TIPO_DOCUMENTO = '424' THEN 'Solicitud Tarjeta'
        WHEN R.ID_TIPO_DOCUMENTO = '809' THEN 'Matriz Riesgo / MRAVPF'
        WHEN R.ID_TIPO_DOCUMENTO IN ('810', '527') THEN 'Consulta SIB'
        WHEN R.ID_TIPO_DOCUMENTO IN ('621', '511') THEN 'LexisNexis'
        WHEN R.ID_TIPO_DOCUMENTO IN ('762', '428') THEN 'Buro de Credito'
        ELSE 'Otro (' || R.ID_TIPO_DOCUMENTO || ')'
    END AS SERVICIO
FROM PA.PA_REPORTES_AUTOMATICOS R
WHERE R.ORIGEN_PKM = 'Onboarding'
  AND R.ESTADO_REPORTE IN ('E', 'D', 'S', 'H')
ORDER BY R.ESTADO_REPORTE, R.ID_TIPO_DOCUMENTO;

-- =============================================================================
-- PASO 4: Validar en la pagina 136 de APEX
--         Verificar que el link "Reprocesar" aparece y que al hacer clic
--         la pagina 66 recibe el estado correcto (P o R segun tipo documento)
-- =============================================================================
-- NO HACER COMMIT HASTA VALIDAR

-- Si todo esta bien:
-- COMMIT;

-- Si algo salio mal:
-- ROLLBACK;
