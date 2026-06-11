-- Entorno: QA02
-- Objetivo: sincronizar los nueve tipos con el baseline confirmado en QA.
--
-- IMPORTANTE:
-- - Usar una sesion dedicada de Toad conectada a QA02.
-- - Ejecutar cada paso por separado con F9 y en esta misma sesion.
-- - No ejecutar el archivo completo con F5.
-- - ALTER TRIGGER ejecuta COMMIT implicito.

--------------------------------------------------------------------------------
-- PASO 1. Deshabilitar el trigger.
-- Ejecutar solamente este ALTER con F9.
--------------------------------------------------------------------------------

ALTER TRIGGER PR.TRG_BUI_TIPO_CRED_REPRESTAMO DISABLE;

--------------------------------------------------------------------------------
-- PASO 2. Confirmar que quedo deshabilitado.
-- Ejecutar este SELECT con F9. Debe retornar DISABLED.
--------------------------------------------------------------------------------

SELECT OWNER,
       TRIGGER_NAME,
       STATUS
  FROM ALL_TRIGGERS
 WHERE OWNER = 'PR'
   AND TRIGGER_NAME = 'TRG_BUI_TIPO_CRED_REPRESTAMO';

--------------------------------------------------------------------------------
-- PASO 3. Bloquear la tabla en esta sesion.
-- Ejecutar este LOCK con F9. Debe terminar sin error.
--------------------------------------------------------------------------------

LOCK TABLE PR.PR_TIPO_CREDITO_REPRESTAMO IN EXCLUSIVE MODE NOWAIT;

--------------------------------------------------------------------------------
-- PASO 4. Sincronizar el tipo 164.
-- Ejecutar este UPDATE con F9.
-- Resultado esperado en Messages: 1 row updated.
-- Si retorna 0, ejecutar ROLLBACK y continuar con el PASO 7 para
-- reactivar el trigger; despues confirmar su estado en el PASO 8.
--------------------------------------------------------------------------------

UPDATE PR.PR_TIPO_CREDITO_REPRESTAMO D
   SET D.FECHA_MODIFICACION =
           TO_DATE('2025-09-30 22:48:31', 'YYYY-MM-DD HH24:MI:SS'),
       D.CREDITO_CAMPANA_ESPECIAL = 'N'
 WHERE D.CODIGO_EMPRESA = 1
   AND D.TIPO_CREDITO = 164
   AND D.ESTADO = 'A'
   AND D.ADICIONADO_POR = 'RSALGADO'
   AND D.FECHA_ADICION =
           TO_DATE('2024-01-11 08:47:43', 'YYYY-MM-DD HH24:MI:SS')
   AND D.MODIFICADO_POR IS NULL
   AND D.FECHA_MODIFICACION =
           TO_DATE('2026-06-11 09:25:22', 'YYYY-MM-DD HH24:MI:SS')
   AND D.OBSOLETO = 0
   AND D.CARGA = 'N'
   AND D.CREDITO_CAMPANA_ESPECIAL IS NULL
   AND D.CREDITO_FMO = 'N';

--------------------------------------------------------------------------------
-- PASO 5. Insertar los ocho tipos ausentes.
-- Ejecutar este INSERT con F9.
-- Resultado esperado en Messages: 8 rows inserted.
-- Si no retorna 8, ejecutar ROLLBACK y continuar con el PASO 7 para
-- reactivar el trigger; despues confirmar su estado en el PASO 8.
--------------------------------------------------------------------------------

INSERT INTO PR.PR_TIPO_CREDITO_REPRESTAMO
(
    CODIGO_EMPRESA,
    TIPO_CREDITO,
    ESTADO,
    ADICIONADO_POR,
    FECHA_ADICION,
    MODIFICADO_POR,
    FECHA_MODIFICACION,
    OBSOLETO,
    CARGA,
    CREDITO_CAMPANA_ESPECIAL,
    CREDITO_FMO
)
SELECT E.CODIGO_EMPRESA,
       E.TIPO_CREDITO,
       E.ESTADO,
       E.ADICIONADO_POR,
       E.FECHA_ADICION,
       E.MODIFICADO_POR,
       E.FECHA_MODIFICACION,
       E.OBSOLETO,
       E.CARGA,
       E.CREDITO_CAMPANA_ESPECIAL,
       E.CREDITO_FMO
  FROM
       (
           SELECT 1 CODIGO_EMPRESA, 857 TIPO_CREDITO, 'A' ESTADO,
                  'NOLIVO' ADICIONADO_POR,
                  TO_DATE('2025-08-27 10:24:09', 'YYYY-MM-DD HH24:MI:SS') FECHA_ADICION,
                  CAST(NULL AS VARCHAR2(30)) MODIFICADO_POR,
                  TO_DATE('2025-10-17 16:08:05', 'YYYY-MM-DD HH24:MI:SS') FECHA_MODIFICACION,
                  0 OBSOLETO, 'N' CARGA, 'S' CREDITO_CAMPANA_ESPECIAL,
                  'S' CREDITO_FMO
             FROM DUAL
           UNION ALL
           SELECT 1, 752, 'A', 'NOLIVO',
                  TO_DATE('2025-08-27 15:23:54', 'YYYY-MM-DD HH24:MI:SS'), NULL,
                  TO_DATE('2025-10-16 14:45:31', 'YYYY-MM-DD HH24:MI:SS'),
                  0, 'N', 'S', 'N' FROM DUAL
           UNION ALL
           SELECT 1, 753, 'A', 'NOLIVO',
                  TO_DATE('2025-08-27 15:24:57', 'YYYY-MM-DD HH24:MI:SS'), NULL,
                  TO_DATE('2025-11-18 15:06:20', 'YYYY-MM-DD HH24:MI:SS'),
                  0, 'N', 'N', 'S' FROM DUAL
           UNION ALL
           SELECT 1, 883, 'A', 'NOLIVO',
                  TO_DATE('2025-06-27 15:31:07', 'YYYY-MM-DD HH24:MI:SS'), NULL,
                  TO_DATE('2025-07-17 11:19:19', 'YYYY-MM-DD HH24:MI:SS'),
                  0, 'N', 'N', 'S' FROM DUAL
           UNION ALL
           SELECT 1, 972, 'A', 'NOLIVO',
                  TO_DATE('2025-07-02 15:19:59', 'YYYY-MM-DD HH24:MI:SS'), NULL,
                  TO_DATE('2025-10-15 12:51:25', 'YYYY-MM-DD HH24:MI:SS'),
                  0, 'N', 'S', 'S' FROM DUAL
           UNION ALL
           SELECT 1, 854, 'A', 'NOLIVO',
                  TO_DATE('2025-08-27 10:14:02', 'YYYY-MM-DD HH24:MI:SS'), NULL,
                  TO_DATE('2025-10-17 10:33:43', 'YYYY-MM-DD HH24:MI:SS'),
                  0, 'N', 'S', 'N' FROM DUAL
           UNION ALL
           SELECT 1, 855, 'A', 'NOLIVO',
                  TO_DATE('2025-08-27 10:23:15', 'YYYY-MM-DD HH24:MI:SS'), NULL,
                  TO_DATE('2025-10-17 10:33:57', 'YYYY-MM-DD HH24:MI:SS'),
                  0, 'N', 'S', 'N' FROM DUAL
           UNION ALL
           SELECT 1, 751, 'A', 'NOLIVO',
                  TO_DATE('2025-08-27 10:40:28', 'YYYY-MM-DD HH24:MI:SS'), NULL,
                  TO_DATE('2025-11-18 15:05:49', 'YYYY-MM-DD HH24:MI:SS'),
                  0, 'N', 'N', 'S' FROM DUAL
       ) E
 WHERE NOT EXISTS
       (
           SELECT 1
             FROM PR.PR_TIPO_CREDITO_REPRESTAMO D
            WHERE D.CODIGO_EMPRESA = E.CODIGO_EMPRESA
              AND D.TIPO_CREDITO = E.TIPO_CREDITO
       );

--------------------------------------------------------------------------------
-- PASO 6. Validar dentro de la misma transaccion.
-- Volver a 02_VALIDAR_FALTANTES_QA02.sql y ejecutar su primer WITH con F9.
-- Resultado esperado: las nueve filas deben ser OK_IGUAL_QA.
--
-- Si las nueve filas son correctas, continuar con el PASO 7.
-- Si hay cualquier diferencia, ejecutar:
--
-- ROLLBACK;
--
-- y despues continuar con el PASO 7 para reactivar el trigger.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- PASO 7. Confirmar los cambios y habilitar el trigger.
-- Ejecutar solamente este ALTER con F9.
-- El COMMIT ocurre implicitamente antes del ALTER.
--------------------------------------------------------------------------------

ALTER TRIGGER PR.TRG_BUI_TIPO_CRED_REPRESTAMO ENABLE;

--------------------------------------------------------------------------------
-- PASO 8. Confirmar el estado final del trigger.
-- Ejecutar este SELECT con F9. Debe retornar ENABLED.
--------------------------------------------------------------------------------

SELECT OWNER,
       TRIGGER_NAME,
       STATUS
  FROM ALL_TRIGGERS
 WHERE OWNER = 'PR'
   AND TRIGGER_NAME = 'TRG_BUI_TIPO_CRED_REPRESTAMO';
