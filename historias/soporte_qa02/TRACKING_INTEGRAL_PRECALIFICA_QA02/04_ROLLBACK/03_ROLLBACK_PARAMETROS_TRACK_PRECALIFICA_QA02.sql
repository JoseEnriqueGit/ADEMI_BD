-- =====================================================================
-- ROLLBACK parametros TRACK_PRECALIFICA_* en QA02
-- Entorno: QA02
-- Tabla: PA.PA_PARAMETROS_MVP  (CODIGO_MVP = 'REPRESTAMOS')
-- Fecha: 2026-06-08
-- Elimina las 3 filas (CODIGO_EMPRESA = 1) creadas por
--   ../01_DDL/03_PARAMETROS_TRACK_PRECALIFICA_QA02.sql
-- Si el paso 7 del script 00 reporto filas TRACK_PRECALIFICA_* preexistentes
-- (no creadas por esta historia), NO ejecutar este DELETE: usar el UPDATE a
-- VALOR='N' de abajo para no borrar evidencia ajena.
--
-- Para solo DESACTIVAR sin borrar (paso intermedio de reversa del body),
-- usar en su lugar:
--   UPDATE PA.PA_PARAMETROS_MVP SET VALOR = 'N'
--    WHERE CODIGO_MVP = 'REPRESTAMOS'
--      AND CODIGO_PARAMETRO IN ('TRACK_PRECALIFICA_ACTIVO',
--                               'TRACK_PRECALIFICA_DETALLE_CURSOR');
--   COMMIT;
-- =====================================================================

DELETE FROM PA.PA_PARAMETROS_MVP
 WHERE CODIGO_EMPRESA = 1
   AND CODIGO_MVP = 'REPRESTAMOS'
   AND CODIGO_PARAMETRO IN (
       'TRACK_PRECALIFICA_ACTIVO',
       'TRACK_PRECALIFICA_DETALLE_CURSOR',
       'TRACK_PRECALIFICA_RETENCION_DIAS'
   );

COMMIT;

PROMPT Parametros TRACK_PRECALIFICA_* eliminados de QA02
