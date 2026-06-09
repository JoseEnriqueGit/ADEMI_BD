-- =====================================================================
-- Parametros de activacion del tracking integral
-- Entorno: QA02
-- Tabla: PA.PA_PARAMETROS_MVP  (CODIGO_MVP = 'REPRESTAMOS')
-- Fecha: 2026-06-08
-- Idempotente. Inserta CODIGO_EMPRESA = 1 y CODIGO_MVP = 'REPRESTAMOS'
-- explicitos, iguales a las constantes vCodigoEmpresa=1 / vTipo_parametro=
-- 'REPRESTAMOS' del package (spec.sql:2-3) que usa F_Obt_Parametro_Represtamo
-- para leerlos. Inserta exactamente 3 filas (empresa 1).
-- PA_PARAMETROS_MVP exige (validado en QA02 2026-06-08), ademas de VALOR:
-- DES_PARAMETRO, ADICIONADO_POR y FECHA_ADICION (NOT NULL sin DEFAULT);
-- se cargan con descripcion / USER / SYSDATE.
-- Reversa: ../04_ROLLBACK/03_ROLLBACK_PARAMETROS_TRACK_PRECALIFICA_QA02.sql
-- =====================================================================

INSERT INTO PA.PA_PARAMETROS_MVP
    (CODIGO_EMPRESA, CODIGO_MVP, CODIGO_PARAMETRO, VALOR,
     DES_PARAMETRO, ADICIONADO_POR, FECHA_ADICION)
SELECT 1, 'REPRESTAMOS', v.CODIGO_PARAMETRO, v.VALOR,
       v.DES_PARAMETRO, USER, SYSDATE
  FROM (
        SELECT 'TRACK_PRECALIFICA_ACTIVO'         AS CODIGO_PARAMETRO, 'S'  AS VALOR, 'Tracking precalifica activo'  AS DES_PARAMETRO FROM dual UNION ALL
        SELECT 'TRACK_PRECALIFICA_DETALLE_CURSOR',                     'S',           'Tracking precalifica cursor'                   FROM dual UNION ALL
        SELECT 'TRACK_PRECALIFICA_RETENCION_DIAS',                     '90',          'Tracking precalifica dias'                     FROM dual
       ) v
 WHERE NOT EXISTS (
        SELECT 1
          FROM PA.PA_PARAMETROS_MVP x
         WHERE x.CODIGO_EMPRESA   = 1
           AND x.CODIGO_MVP       = 'REPRESTAMOS'
           AND x.CODIGO_PARAMETRO = v.CODIGO_PARAMETRO
       );

COMMIT;

PROMPT Parametros TRACK_PRECALIFICA_* cargados/validados en QA02
PROMPT   TRACK_PRECALIFICA_ACTIVO         = S
PROMPT   TRACK_PRECALIFICA_DETALLE_CURSOR = S
PROMPT   TRACK_PRECALIFICA_RETENCION_DIAS = 90
