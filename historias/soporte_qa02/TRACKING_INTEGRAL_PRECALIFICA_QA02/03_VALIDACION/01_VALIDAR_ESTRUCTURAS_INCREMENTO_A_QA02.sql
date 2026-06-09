-- =====================================================================
-- Validacion de estructuras usadas por el Incremento A
-- Entorno: QA02
-- Solo lectura. Ejecutar en Toad antes de compilar el body.
-- =====================================================================

PROMPT 1. Columnas requeridas por solicitud, canal y bitacora

SELECT owner,
       table_name,
       column_id,
       column_name,
       data_type,
       data_length,
       nullable
  FROM all_tab_columns
 WHERE owner = 'PR'
   AND table_name IN (
       'PR_SOLICITUD_REPRESTAMO',
       'PR_CANALES_REPRESTAMO',
       'PR_BITACORA_REPRESTAMO'
   )
   AND column_name IN (
       'CODIGO_EMPRESA',
       'ID_REPRESTAMO',
       'ESTADO',
       'CANAL',
       'VALOR',
       'CODIGO_ESTADO',
       'FECHA_BITACORA',
       'FECHA_ADICION'
   )
 ORDER BY table_name, column_id;

PROMPT 2. Objetos requeridos por el body instrumentado

SELECT owner,
       object_name,
       object_type,
       status
  FROM all_objects
 WHERE owner = 'PR'
   AND object_name IN (
       'PR_JOB_PRECALIFICA_TRACK',
       'PR_JOB_PRECALIFICA_FILTRO_TRACK',
       'SEQ_PR_JOB_PRECAL_FILTRO',
       'PR_SOLICITUD_REPRESTAMO',
       'PR_CANALES_REPRESTAMO',
       'PR_REPRESTAMOS'
   )
 ORDER BY object_name, object_type;

PROMPT 3. Parametros requeridos

SELECT codigo_empresa,
       codigo_mvp,
       codigo_parametro,
       valor
  FROM PA.PA_PARAMETROS_MVP
 WHERE codigo_empresa = 1
   AND codigo_mvp = 'REPRESTAMOS'
   AND codigo_parametro IN (
       'TRACK_PRECALIFICA_ACTIVO',
       'LOTE_DE_CARAGA_REPRESTAMO'
   )
 ORDER BY codigo_parametro;
