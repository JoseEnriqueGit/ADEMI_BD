-------------------------------------------------------------------------------
-- Historia #442: Indices para optimizar query de pagina 21 (Solicitudes)
-------------------------------------------------------------------------------
-- ESTADO: PENDIENTE - NO INCLUIR EN ESTE PASE A PROD
-- Razon: La creacion de indices se difiere a un pase posterior
-- Estado actual:
--   - QA (QAORACEL19C): YA CREADOS
--   - PROD: PENDIENTE
-- Cuando se ejecuten en PROD, sustituir el query de la region por
-- el script 03_query_v3_post_indices.sql para aprovechar los indices.
-------------------------------------------------------------------------------
-- Ejecutar en el schema PR
-------------------------------------------------------------------------------
-- Indices existentes (verificados 2026-04-09):
--   PR_BITACORA_REPRESTAMO:
--     PK_BITACORA_REPRESTAMO (CODIGO_EMPRESA, ID_REPRESTAMO, ID_BITACORA)
--   PR_SOLICITUD_REPRESTAMO:
--     PK_SOLICITUD_REPRESTAMO (CODIGO_EMPRESA, ID_REPRESTAMO)
--     PR_SOLICITUD_REPRESTAMO_IDX (CODIGO_EMPRESA, NO_CREDITO)
--   PR_OPCIONES_REPRESTAMO:
--     PK_PR_OPCIONES_REPRESTAMOS (CODIGO_EMPRESA, ID_REPRESTAMO, PLAZO)
--   PR_REPRESTAMOS:
--     PK_REPRESTAMOS (CODIGO_EMPRESA, ID_REPRESTAMO)
--     IDX_REPRESTAMOS_EMP_EST_NOCRED (CODIGO_EMPRESA, ESTADO, NO_CREDITO, ID_REPRESTAMO)
--     IND01_PR_REPRESTAMOS (CODIGO_EMPRESA, NO_CREDITO)
--     IND02_PR_REPRESTAMOS (CODIGO_EMPRESA, ESTADO)
--     IND3_PR_REPRESTAMO (CODIGO_CLIENTE, ESTADO)
-------------------------------------------------------------------------------

-- 1. Indice para PR_BITACORA_REPRESTAMO
--    Cubre: subquery correlacionado por ID_REPRESTAMO + CODIGO_ESTADO + MAX(FECHA_BITACORA)
--    La PK existente no sirve porque CODIGO_ESTADO no esta indexado
CREATE INDEX PR.IDX_BITACORA_REPRST_EST
ON PR.PR_BITACORA_REPRESTAMO(ID_REPRESTAMO, CODIGO_ESTADO, FECHA_BITACORA)
TABLESPACE PR_IDX
NOLOGGING
PARALLEL 4;

ALTER INDEX PR.IDX_BITACORA_REPRST_EST NOPARALLEL;

-- 2. Indice para PR_SOLICITUD_REPRESTAMO
--    Cubre: filtro WHERE por CODIGO_EMPRESA + ESTADO + ID_REPRESTAMO
--    La PK tiene (CODIGO_EMPRESA, ID_REPRESTAMO) pero no ESTADO
CREATE INDEX PR.IDX_SOL_REPRST_EMP_EST
ON PR.PR_SOLICITUD_REPRESTAMO(CODIGO_EMPRESA, ESTADO, ID_REPRESTAMO)
TABLESPACE PR_IDX
NOLOGGING
PARALLEL 4;

ALTER INDEX PR.IDX_SOL_REPRST_EMP_EST NOPARALLEL;

-- 3. Indice para PR_OPCIONES_REPRESTAMO
--    Cubre: JOIN por ID_REPRESTAMO + PLAZO (elimina Full Table Scan)
--    La PK empieza por CODIGO_EMPRESA pero el JOIN usa ID_REPRESTAMO + PLAZO
CREATE INDEX PR.IDX_OPC_REPRST_ID_PLAZO
ON PR.PR_OPCIONES_REPRESTAMO(ID_REPRESTAMO, PLAZO)
TABLESPACE PR_IDX
NOLOGGING
PARALLEL 4;

ALTER INDEX PR.IDX_OPC_REPRST_ID_PLAZO NOPARALLEL;

-------------------------------------------------------------------------------
-- Verificar que los indices se crearon correctamente:
-------------------------------------------------------------------------------
-- SELECT index_name, column_name, column_position
-- FROM all_ind_columns
-- WHERE table_owner = 'PR'
-- AND index_name IN ('IDX_BITACORA_REPRST_EST', 'IDX_SOL_REPRST_EMP_EST', 'IDX_OPC_REPRST_ID_PLAZO')
-- ORDER BY index_name, column_position;
