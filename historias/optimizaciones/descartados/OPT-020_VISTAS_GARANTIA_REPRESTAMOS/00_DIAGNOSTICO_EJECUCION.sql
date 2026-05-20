-- =====================================================================
-- OPT-020 - Diagnostico de ejecucion antes de crear vistas
--
-- Usar cuando Toad no muestra la ejecucion completa de 01_CREATE_VIEWS.sql
-- o cuando se necesita confirmar usuario, schema, privilegios y existencia
-- previa de las vistas.
-- =====================================================================

PROMPT ================================================================
PROMPT OPT-020 D00 - Marca de inicio
PROMPT ================================================================

SELECT 'INICIO_OPT020_DIAGNOSTICO' marca
  FROM dual;

PROMPT ================================================================
PROMPT OPT-020 D01 - Usuario, schema y sesion
PROMPT ================================================================

SELECT USER usuario_conectado,
       SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') schema_actual,
       SYS_CONTEXT('USERENV', 'SESSION_USER') session_user
  FROM dual;

PROMPT ================================================================
PROMPT OPT-020 D02 - Privilegios de creacion de vistas
PROMPT ================================================================

SELECT privilege
  FROM session_privs
 WHERE privilege IN ('CREATE VIEW', 'CREATE ANY VIEW')
 ORDER BY privilege;

PROMPT Si no retorna filas, el usuario actual no puede crear vistas.
PROMPT Si USUARIO_CONECTADO no es PR, se requiere CREATE ANY VIEW.

PROMPT ================================================================
PROMPT OPT-020 D03 - Columnas requeridas
PROMPT ================================================================

SELECT owner, table_name, column_name
  FROM all_tab_columns
 WHERE owner = 'PR'
   AND (
        (table_name = 'PR_CREDITOS'
         AND column_name IN ('CODIGO_EMPRESA', 'NO_CREDITO', 'ESTADO'))
     OR (table_name = 'PR_CREDITOS_HI'
         AND column_name IN ('CODIGO_EMPRESA', 'NO_CREDITO', 'ESTADO'))
     OR (table_name = 'PR_GARANTIAS_X_CREDITO'
         AND column_name IN ('CODIGO_EMPRESA', 'NO_CREDITO', 'NUMERO_GARANTIA'))
     OR (table_name = 'PR_GARANTIAS'
         AND column_name IN ('CODIGO_EMPRESA', 'NUMERO_GARANTIA', 'CODIGO_TIPO_GARANTIA_SB'))
       )
 ORDER BY table_name, column_name;

PROMPT Deben retornar 12 filas.

PROMPT ================================================================
PROMPT OPT-020 D04 - Vistas existentes
PROMPT ================================================================

SELECT owner, object_name, object_type, status
  FROM all_objects
 WHERE owner = 'PR'
   AND object_name IN ('V_REPRE_CREDITOS_GAR',
                       'V_REPRE_CREDITOS_HI_GAR')
 ORDER BY object_name;

PROMPT Si no retorna filas, las vistas aun no existen en PR.

PROMPT ================================================================
PROMPT OPT-020 D99 - Marca de fin
PROMPT ================================================================

SELECT 'FIN_OPT020_DIAGNOSTICO' marca
  FROM dual;
