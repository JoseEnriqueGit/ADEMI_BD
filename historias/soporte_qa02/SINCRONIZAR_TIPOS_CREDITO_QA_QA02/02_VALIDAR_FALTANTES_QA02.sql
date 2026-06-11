-- Entorno de ejecucion: QA02
-- Objetivo: identificar faltantes o diferencias contra el baseline confirmado en QA.
-- Ejecutar este mismo script antes y despues de la insercion.
--
-- TOAD:
-- - Recomendado: colocar el cursor dentro de cada SELECT y ejecutar con F9.
-- - Con F5, los PROMPT aparecen en Script Output, pero los resultados de los
--   SELECT se consultan en la pestana Data Grid.

SET PAGESIZE 500
SET LINESIZE 320

PROMPT ============================================================
PROMPT 1. Estado de los nueve registros en QA02
PROMPT ============================================================

-- Colocar el cursor dentro de este WITH y presionar F9.
WITH ESPERADO AS
(
    SELECT 1 ORDEN, 1 CODIGO_EMPRESA, 164 TIPO_CREDITO, 'A' ESTADO,
           'RSALGADO' ADICIONADO_POR,
           TO_DATE('2024-01-11 08:47:43', 'YYYY-MM-DD HH24:MI:SS') FECHA_ADICION,
           CAST(NULL AS VARCHAR2(30)) MODIFICADO_POR,
           TO_DATE('2025-09-30 22:48:31', 'YYYY-MM-DD HH24:MI:SS') FECHA_MODIFICACION,
           0 OBSOLETO, 'N' CARGA, 'N' CREDITO_CAMPANA_ESPECIAL, 'N' CREDITO_FMO
      FROM DUAL
    UNION ALL
    SELECT 2, 1, 857, 'A', 'NOLIVO',
           TO_DATE('2025-08-27 10:24:09', 'YYYY-MM-DD HH24:MI:SS'), NULL,
           TO_DATE('2025-10-17 16:08:05', 'YYYY-MM-DD HH24:MI:SS'),
           0, 'N', 'S', 'S' FROM DUAL
    UNION ALL
    SELECT 3, 1, 752, 'A', 'NOLIVO',
           TO_DATE('2025-08-27 15:23:54', 'YYYY-MM-DD HH24:MI:SS'), NULL,
           TO_DATE('2025-10-16 14:45:31', 'YYYY-MM-DD HH24:MI:SS'),
           0, 'N', 'S', 'N' FROM DUAL
    UNION ALL
    SELECT 4, 1, 753, 'A', 'NOLIVO',
           TO_DATE('2025-08-27 15:24:57', 'YYYY-MM-DD HH24:MI:SS'), NULL,
           TO_DATE('2025-11-18 15:06:20', 'YYYY-MM-DD HH24:MI:SS'),
           0, 'N', 'N', 'S' FROM DUAL
    UNION ALL
    SELECT 5, 1, 883, 'A', 'NOLIVO',
           TO_DATE('2025-06-27 15:31:07', 'YYYY-MM-DD HH24:MI:SS'), NULL,
           TO_DATE('2025-07-17 11:19:19', 'YYYY-MM-DD HH24:MI:SS'),
           0, 'N', 'N', 'S' FROM DUAL
    UNION ALL
    SELECT 6, 1, 972, 'A', 'NOLIVO',
           TO_DATE('2025-07-02 15:19:59', 'YYYY-MM-DD HH24:MI:SS'), NULL,
           TO_DATE('2025-10-15 12:51:25', 'YYYY-MM-DD HH24:MI:SS'),
           0, 'N', 'S', 'S' FROM DUAL
    UNION ALL
    SELECT 7, 1, 854, 'A', 'NOLIVO',
           TO_DATE('2025-08-27 10:14:02', 'YYYY-MM-DD HH24:MI:SS'), NULL,
           TO_DATE('2025-10-17 10:33:43', 'YYYY-MM-DD HH24:MI:SS'),
           0, 'N', 'S', 'N' FROM DUAL
    UNION ALL
    SELECT 8, 1, 855, 'A', 'NOLIVO',
           TO_DATE('2025-08-27 10:23:15', 'YYYY-MM-DD HH24:MI:SS'), NULL,
           TO_DATE('2025-10-17 10:33:57', 'YYYY-MM-DD HH24:MI:SS'),
           0, 'N', 'S', 'N' FROM DUAL
    UNION ALL
    SELECT 9, 1, 751, 'A', 'NOLIVO',
           TO_DATE('2025-08-27 10:40:28', 'YYYY-MM-DD HH24:MI:SS'), NULL,
           TO_DATE('2025-11-18 15:05:49', 'YYYY-MM-DD HH24:MI:SS'),
           0, 'N', 'N', 'S' FROM DUAL
)
SELECT E.TIPO_CREDITO,
       CASE
           WHEN D.TIPO_CREDITO IS NULL THEN 'FALTA_EN_QA02'
           WHEN DECODE(D.ESTADO, E.ESTADO, 1, 0) = 1
            AND DECODE(D.ADICIONADO_POR, E.ADICIONADO_POR, 1, 0) = 1
            AND DECODE(D.FECHA_ADICION, E.FECHA_ADICION, 1, 0) = 1
            AND DECODE(D.MODIFICADO_POR, E.MODIFICADO_POR, 1, 0) = 1
            AND DECODE(D.FECHA_MODIFICACION, E.FECHA_MODIFICACION, 1, 0) = 1
            AND DECODE(D.OBSOLETO, E.OBSOLETO, 1, 0) = 1
            AND DECODE(D.CARGA, E.CARGA, 1, 0) = 1
            AND DECODE(D.CREDITO_CAMPANA_ESPECIAL, E.CREDITO_CAMPANA_ESPECIAL, 1, 0) = 1
            AND DECODE(D.CREDITO_FMO, E.CREDITO_FMO, 1, 0) = 1
           THEN 'OK_IGUAL_QA'
           ELSE 'ERROR_DIFERENTE_QA'
       END AS RESULTADO,
       CASE
           WHEN D.TIPO_CREDITO IS NULL THEN NULL
           ELSE RTRIM(
               CASE WHEN DECODE(D.ESTADO, E.ESTADO, 1, 0) = 0
                    THEN 'ESTADO, ' END ||
               CASE WHEN DECODE(D.ADICIONADO_POR, E.ADICIONADO_POR, 1, 0) = 0
                    THEN 'ADICIONADO_POR, ' END ||
               CASE WHEN DECODE(D.FECHA_ADICION, E.FECHA_ADICION, 1, 0) = 0
                    THEN 'FECHA_ADICION, ' END ||
               CASE WHEN DECODE(D.MODIFICADO_POR, E.MODIFICADO_POR, 1, 0) = 0
                    THEN 'MODIFICADO_POR, ' END ||
               CASE WHEN DECODE(D.FECHA_MODIFICACION, E.FECHA_MODIFICACION, 1, 0) = 0
                    THEN 'FECHA_MODIFICACION, ' END ||
               CASE WHEN DECODE(D.OBSOLETO, E.OBSOLETO, 1, 0) = 0
                    THEN 'OBSOLETO, ' END ||
               CASE WHEN DECODE(D.CARGA, E.CARGA, 1, 0) = 0
                    THEN 'CARGA, ' END ||
               CASE WHEN DECODE(D.CREDITO_CAMPANA_ESPECIAL, E.CREDITO_CAMPANA_ESPECIAL, 1, 0) = 0
                    THEN 'CREDITO_CAMPANA_ESPECIAL, ' END ||
               CASE WHEN DECODE(D.CREDITO_FMO, E.CREDITO_FMO, 1, 0) = 0
                    THEN 'CREDITO_FMO, ' END,
               ', '
           )
       END AS CAMPOS_DIFERENTES,
       D.CODIGO_EMPRESA,
       D.ESTADO,
       D.ADICIONADO_POR,
       TO_CHAR(D.FECHA_ADICION, 'YYYY-MM-DD HH24:MI:SS') AS FECHA_ADICION,
       D.MODIFICADO_POR,
       TO_CHAR(D.FECHA_MODIFICACION, 'YYYY-MM-DD HH24:MI:SS') AS FECHA_MODIFICACION,
       D.OBSOLETO,
       D.CARGA,
       D.CREDITO_CAMPANA_ESPECIAL,
       D.CREDITO_FMO
  FROM ESPERADO E
  LEFT JOIN PR.PR_TIPO_CREDITO_REPRESTAMO D
    ON D.CODIGO_EMPRESA = E.CODIGO_EMPRESA
   AND D.TIPO_CREDITO = E.TIPO_CREDITO
 ORDER BY E.ORDEN;

PROMPT Antes: revisar FALTA_EN_QA02 y detenerse ante ERROR_DIFERENTE_QA.
PROMPT Despues: resultado esperado de las 9 filas = OK_IGUAL_QA.

PROMPT ============================================================
PROMPT 2. Padres ausentes en PR.PR_TIPO_CREDITO de QA02
PROMPT    Resultado esperado: ninguna fila
PROMPT ============================================================

-- Colocar el cursor dentro de este WITH y presionar F9.
WITH TIPOS AS
(
    SELECT 164 TIPO_CREDITO FROM DUAL UNION ALL
    SELECT 857 FROM DUAL UNION ALL
    SELECT 752 FROM DUAL UNION ALL
    SELECT 753 FROM DUAL UNION ALL
    SELECT 883 FROM DUAL UNION ALL
    SELECT 972 FROM DUAL UNION ALL
    SELECT 854 FROM DUAL UNION ALL
    SELECT 855 FROM DUAL UNION ALL
    SELECT 751 FROM DUAL
)
SELECT T.TIPO_CREDITO,
       'FALTA_PADRE_EN_PR_TIPO_CREDITO_QA02' AS HALLAZGO
  FROM TIPOS T
 WHERE NOT EXISTS
       (
           SELECT 1
             FROM PR.PR_TIPO_CREDITO P
            WHERE P.CODIGO_EMPRESA = 1
              AND P.TIPO_CREDITO = T.TIPO_CREDITO
       )
 ORDER BY T.TIPO_CREDITO;

PROMPT ============================================================
PROMPT 3. Estado final del trigger
PROMPT    Resultado esperado: ENABLED
PROMPT ============================================================

-- Colocar el cursor dentro de este SELECT y presionar F9.
SELECT OWNER,
       TRIGGER_NAME,
       STATUS
  FROM ALL_TRIGGERS
 WHERE OWNER = 'PR'
   AND TRIGGER_NAME = 'TRG_BUI_TIPO_CRED_REPRESTAMO';
