-- Entorno de ejecucion: QA02
-- Objetivo: eliminar los tipos insertados y restaurar el 164 observado antes.
-- Copiar TIPOS_INSERTADOS y TIPOS_ACTUALIZADOS desde la salida de 03_SINCRONIZAR.
-- El valor anterior del 164 proviene de la evidencia QA02 del 2026-06-11.

SET DEFINE ON
SET VERIFY OFF
SET SERVEROUTPUT ON SIZE UNLIMITED

DEFINE TIPOS_INSERTADOS = REEMPLAZAR
DEFINE TIPOS_ACTUALIZADOS = REEMPLAZAR
DEFINE CONFIRMAR_ROLLBACK = NO

PROMPT ============================================================
PROMPT Tipos insertados : &&TIPOS_INSERTADOS
PROMPT Tipos actualizados: &&TIPOS_ACTUALIZADOS
PROMPT Ejecutar rollback: &&CONFIRMAR_ROLLBACK
PROMPT ============================================================

PROMPT Filas que serian eliminadas

SELECT D.CODIGO_EMPRESA,
       D.TIPO_CREDITO,
       D.ESTADO,
       D.ADICIONADO_POR,
       TO_CHAR(D.FECHA_ADICION, 'YYYY-MM-DD HH24:MI:SS') AS FECHA_ADICION,
       D.MODIFICADO_POR,
       TO_CHAR(D.FECHA_MODIFICACION, 'YYYY-MM-DD HH24:MI:SS') AS FECHA_MODIFICACION,
       D.OBSOLETO,
       D.CARGA,
       D.CREDITO_CAMPANA_ESPECIAL,
       D.CREDITO_FMO
  FROM PR.PR_TIPO_CREDITO_REPRESTAMO D
 WHERE D.CODIGO_EMPRESA = 1
   AND INSTR(
           ',' || REPLACE('&&TIPOS_INSERTADOS', ' ', '') || ',',
           ',' || TO_CHAR(D.TIPO_CREDITO, 'FM9999999990') || ','
       ) > 0
 ORDER BY D.TIPO_CREDITO;

DECLARE
    V_ELIMINADOS PLS_INTEGER;
    V_RESTAURADOS PLS_INTEGER := 0;
    V_TIPOS_NO_PERMITIDOS PLS_INTEGER;
    V_TRIGGER_DESACTIVADO BOOLEAN := FALSE;
    V_ROLLBACK_VALIDADO BOOLEAN := FALSE;
    V_ERROR_ORIGINAL VARCHAR2(4000);
BEGIN
    IF UPPER(TRIM('&&TIPOS_INSERTADOS')) = 'REEMPLAZAR' THEN
        RAISE_APPLICATION_ERROR(
            -20011,
            'Pegue en TIPOS_INSERTADOS la lista exacta reportada por la carga.'
        );
    END IF;

    IF UPPER(TRIM('&&TIPOS_ACTUALIZADOS')) = 'REEMPLAZAR' THEN
        RAISE_APPLICATION_ERROR(
            -20012,
            'Pegue en TIPOS_ACTUALIZADOS la lista exacta reportada por la carga.'
        );
    END IF;

    IF UPPER(TRIM('&&CONFIRMAR_ROLLBACK')) <> 'SI' THEN
        RAISE_APPLICATION_ERROR(
            -20013,
            'Rollback bloqueado. Revise las filas y cambie CONFIRMAR_ROLLBACK a SI.'
        );
    END IF;

    SELECT COUNT(*)
      INTO V_TIPOS_NO_PERMITIDOS
      FROM PR.PR_TIPO_CREDITO_REPRESTAMO D
     WHERE D.CODIGO_EMPRESA = 1
       AND UPPER(TRIM('&&TIPOS_INSERTADOS')) <> 'NINGUNO'
       AND INSTR(
               ',' || REPLACE('&&TIPOS_INSERTADOS', ' ', '') || ',',
               ',' || TO_CHAR(D.TIPO_CREDITO, 'FM9999999990') || ','
           ) > 0
       AND D.TIPO_CREDITO NOT IN (857, 752, 753, 883, 972, 854, 855, 751);

    IF V_TIPOS_NO_PERMITIDOS > 0 THEN
        RAISE_APPLICATION_ERROR(
            -20014,
            'TIPOS_INSERTADOS contiene filas fuera de los ocho tipos autorizados.'
        );
    END IF;

    IF UPPER(TRIM('&&TIPOS_ACTUALIZADOS')) = '164' THEN
        EXECUTE IMMEDIATE
            'ALTER TRIGGER PR.TRG_BUI_TIPO_CRED_REPRESTAMO DISABLE';
        V_TRIGGER_DESACTIVADO := TRUE;

        EXECUTE IMMEDIATE
            'LOCK TABLE PR.PR_TIPO_CREDITO_REPRESTAMO IN EXCLUSIVE MODE NOWAIT';

        UPDATE PR.PR_TIPO_CREDITO_REPRESTAMO D
           SET D.FECHA_MODIFICACION =
                   TO_DATE('2026-06-11 09:25:22', 'YYYY-MM-DD HH24:MI:SS'),
               D.CREDITO_CAMPANA_ESPECIAL = NULL
         WHERE D.CODIGO_EMPRESA = 1
           AND D.TIPO_CREDITO = 164
           AND D.ESTADO = 'A'
           AND D.ADICIONADO_POR = 'RSALGADO'
           AND D.FECHA_ADICION =
                   TO_DATE('2024-01-11 08:47:43', 'YYYY-MM-DD HH24:MI:SS')
           AND D.MODIFICADO_POR IS NULL
           AND D.FECHA_MODIFICACION =
                   TO_DATE('2025-09-30 22:48:31', 'YYYY-MM-DD HH24:MI:SS')
           AND D.OBSOLETO = 0
           AND D.CARGA = 'N'
           AND D.CREDITO_CAMPANA_ESPECIAL = 'N'
           AND D.CREDITO_FMO = 'N';

        V_RESTAURADOS := SQL%ROWCOUNT;

        IF V_RESTAURADOS <> 1 THEN
            RAISE_APPLICATION_ERROR(
                -20015,
                'No se pudo restaurar el 164: su estado actual ya no coincide con la sincronizacion.'
            );
        END IF;
    ELSIF UPPER(TRIM('&&TIPOS_ACTUALIZADOS')) <> 'NINGUNO' THEN
        RAISE_APPLICATION_ERROR(
            -20016,
            'TIPOS_ACTUALIZADOS solo puede ser 164 o NINGUNO para esta ejecucion.'
        );
    END IF;

    DELETE FROM PR.PR_TIPO_CREDITO_REPRESTAMO D
     WHERE D.CODIGO_EMPRESA = 1
       AND UPPER(TRIM('&&TIPOS_INSERTADOS')) <> 'NINGUNO'
       AND INSTR(
               ',' || REPLACE('&&TIPOS_INSERTADOS', ' ', '') || ',',
               ',' || TO_CHAR(D.TIPO_CREDITO, 'FM9999999990') || ','
           ) > 0;

    V_ELIMINADOS := SQL%ROWCOUNT;
    DBMS_OUTPUT.PUT_LINE('TOTAL_ELIMINADO=' || V_ELIMINADOS);
    DBMS_OUTPUT.PUT_LINE('TOTAL_RESTAURADO=' || V_RESTAURADOS);
    V_ROLLBACK_VALIDADO := TRUE;

    IF V_TRIGGER_DESACTIVADO THEN
        EXECUTE IMMEDIATE
            'ALTER TRIGGER PR.TRG_BUI_TIPO_CRED_REPRESTAMO ENABLE';
        V_TRIGGER_DESACTIVADO := FALSE;
        DBMS_OUTPUT.PUT_LINE('Rollback confirmado al reactivar el trigger.');
    ELSE
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Rollback confirmado.');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        V_ERROR_ORIGINAL := SQLERRM;

        IF NOT V_ROLLBACK_VALIDADO THEN
            ROLLBACK;
        END IF;

        IF V_TRIGGER_DESACTIVADO THEN
            BEGIN
                EXECUTE IMMEDIATE
                    'ALTER TRIGGER PR.TRG_BUI_TIPO_CRED_REPRESTAMO ENABLE';
                V_TRIGGER_DESACTIVADO := FALSE;
                DBMS_OUTPUT.PUT_LINE('Trigger reactivado despues del error.');
            EXCEPTION
                WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE(
                        'ALERTA CRITICA: reactivar manualmente PR.TRG_BUI_TIPO_CRED_REPRESTAMO.'
                    );
                    RAISE_APPLICATION_ERROR(
                        -20017,
                        'Revise inmediatamente el trigger. Error original: ' ||
                        V_ERROR_ORIGINAL
                    );
            END;
        END IF;

        IF V_ROLLBACK_VALIDADO THEN
            DBMS_OUTPUT.PUT_LINE(
                'Rollback confirmado; el trigger fue reactivado en el manejo de error.'
            );
            DBMS_OUTPUT.PUT_LINE(
                'Error original del primer ENABLE: ' || V_ERROR_ORIGINAL
            );
        ELSE
            DBMS_OUTPUT.PUT_LINE('Rollback cancelado: ' || V_ERROR_ORIGINAL);
            RAISE;
        END IF;
END;
/
