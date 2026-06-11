-- Entorno de ejecucion: QA02
-- Objetivo: validar conexion, estructura y trigger antes de la carga.

SET PAGESIZE 200
SET LINESIZE 240

PROMPT ============================================================
PROMPT 1. Conexion local: debe ser QA02
PROMPT ============================================================

SELECT SYS_CONTEXT('USERENV', 'DB_NAME')        AS DB_NAME,
       SYS_CONTEXT('USERENV', 'SERVICE_NAME')   AS SERVICE_NAME,
       SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') AS CURRENT_SCHEMA,
       USER                                      AS USUARIO
  FROM DUAL;

PROMPT ============================================================
PROMPT 2. Columnas requeridas
PROMPT    Resultado esperado: 11 filas
PROMPT ============================================================

SELECT COLUMN_ID,
       COLUMN_NAME,
       DATA_TYPE,
       DATA_LENGTH,
       DATA_PRECISION,
       DATA_SCALE,
       NULLABLE
  FROM ALL_TAB_COLUMNS
 WHERE OWNER = 'PR'
   AND TABLE_NAME = 'PR_TIPO_CREDITO_REPRESTAMO'
 ORDER BY COLUMN_ID;

PROMPT ============================================================
PROMPT 3. Trigger que reemplaza FECHA_ADICION durante INSERT
PROMPT    Resultado esperado: una fila con STATUS = ENABLED
PROMPT ============================================================

SELECT OWNER,
       TRIGGER_NAME,
       STATUS,
       TRIGGERING_EVENT
  FROM ALL_TRIGGERS
 WHERE OWNER = 'PR'
   AND TRIGGER_NAME = 'TRG_BUI_TIPO_CRED_REPRESTAMO';

PROMPT ============================================================
PROMPT 4. Clave primaria y llave foranea
PROMPT    Resultado esperado: PK01_TIPO_CRED_REPRESTAMO y FK01_TIPO_CREDITO_REPRESTAMO
PROMPT ============================================================

SELECT CONSTRAINT_NAME,
       CONSTRAINT_TYPE,
       STATUS,
       VALIDATED
  FROM ALL_CONSTRAINTS
 WHERE OWNER = 'PR'
   AND TABLE_NAME = 'PR_TIPO_CREDITO_REPRESTAMO'
   AND CONSTRAINT_NAME IN
       (
           'PK01_TIPO_CRED_REPRESTAMO',
           'FK01_TIPO_CREDITO_REPRESTAMO'
       )
 ORDER BY CONSTRAINT_TYPE DESC;
