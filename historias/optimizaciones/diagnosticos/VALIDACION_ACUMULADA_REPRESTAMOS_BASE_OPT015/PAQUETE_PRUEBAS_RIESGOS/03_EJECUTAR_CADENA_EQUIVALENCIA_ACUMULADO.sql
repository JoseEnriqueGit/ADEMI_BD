-- =============================================================
-- ACUMULADO - Ejecuta cadena deterministica para equivalencia
-- Cadena incluida:
--   1. Precalifica_Represtamo
--   2. Precalifica_Represtamo_fiadores
--   3. Precalifica_Represtamo_fiadores_hi
--   4. Precalifica_Repre_Cancelado
--   5. Precalifica_Repre_Cancelado_hi
--   6. Actualiza_Precalificacion
--   7. Registro de solicitud y bitacora inicial por ID del run
--   8. Loop final de bitacora/validaciones solo para IDs del run
--
-- NO incluye WORLD_COMPLIANCE, PVALIDA_XCORE ni Actualiza_XCORE_CUSTOM
-- como gate de equivalencia para evitar ruido externo y porque OPT-005
-- sigue pendiente de confirmacion sobre esta base.
-- =============================================================

DEFINE RUN_LABEL = DESPUES

SET SERVEROUTPUT ON SIZE UNLIMITED;

DECLARE
    v_run_label    VARCHAR2(30) := UPPER('&RUN_LABEL');
    v_start_ts     TIMESTAMP := SYSTIMESTAMP;
    v_now_ts       TIMESTAMP;
    v_mensaje      VARCHAR2(32767);
    v_usuario      VARCHAR2(30) := NVL(SYS_CONTEXT('APEX$SESSION', 'APP_USER'), USER);
    v_re_insert    NUMBER := 0;
    v_solicitudes  NUMBER := 0;
    v_canales      NUMBER := 0;
    v_opciones     NUMBER := 0;
    v_bitacora     NUMBER := 0;
    v_lote_actual  VARCHAR2(4000);
BEGIN
    DELETE FROM OPTACUM_RUN_IDS WHERE RUN_LABEL = v_run_label;
    DELETE FROM OPTACUM_SNAP_REPRESTAMOS WHERE RUN_LABEL = v_run_label;
    DELETE FROM OPTACUM_SNAP_SOLICITUD WHERE RUN_LABEL = v_run_label;
    DELETE FROM OPTACUM_SNAP_CANALES WHERE RUN_LABEL = v_run_label;
    DELETE FROM OPTACUM_SNAP_OPCIONES WHERE RUN_LABEL = v_run_label;
    DELETE FROM OPTACUM_SNAP_BITACORA WHERE RUN_LABEL = v_run_label;
    DELETE FROM OPTACUM_RUN_CONTROL WHERE RUN_LABEL = v_run_label;
    COMMIT;

    SELECT VALOR
      INTO v_lote_actual
      FROM PA.PA_PARAMETROS_MVP
     WHERE CODIGO_EMPRESA = PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
       AND CODIGO_MVP = 'REPRESTAMOS'
       AND CODIGO_PARAMETRO = 'LOTE_DE_CARAGA_REPRESTAMO';

    INSERT INTO OPTACUM_RUN_CONTROL (
        RUN_LABEL,
        TEST_USER,
        STARTED_AT,
        LOTE_ORIGINAL,
        LOTE_PRUEBA,
        NOTAS
    )
    SELECT v_run_label,
           USER,
           v_start_ts,
           B.VALOR_ORIGINAL,
           v_lote_actual,
           'Cadena deterministica acumulada sin WORLD_COMPLIANCE ni XCORE'
      FROM OPTACUM_PARAM_BACKUP B
     WHERE B.CODIGO_PARAMETRO = 'LOTE_DE_CARAGA_REPRESTAMO';

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('==============================================');
    DBMS_OUTPUT.PUT_LINE('RUN_LABEL   : ' || v_run_label);
    DBMS_OUTPUT.PUT_LINE('TEST_USER   : ' || USER);
    DBMS_OUTPUT.PUT_LINE('START_TS    : ' || TO_CHAR(v_start_ts, 'YYYY-MM-DD HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('LOTE_ACTUAL : ' || v_lote_actual);
    DBMS_OUTPUT.PUT_LINE('==============================================');

    PR.PR_PKG_REPRESTAMOS.Precalifica_Represtamo();
    COMMIT;

    PR.PR_PKG_REPRESTAMOS.Precalifica_Represtamo_fiadores();
    COMMIT;

    PR.PR_PKG_REPRESTAMOS.Precalifica_Represtamo_fiadores_hi();
    COMMIT;

    PR.PR_PKG_REPRESTAMOS.Precalifica_Repre_Cancelado();
    COMMIT;

    PR.PR_PKG_REPRESTAMOS.Precalifica_Repre_Cancelado_hi();
    COMMIT;

    INSERT INTO OPTACUM_RUN_IDS (
        RUN_LABEL,
        CODIGO_EMPRESA,
        ID_REPRESTAMO,
        CODIGO_CLIENTE,
        NO_CREDITO,
        FECHA_CORTE,
        ESTADO_CAPTURA,
        FECHA_ADICION
    )
    SELECT v_run_label,
           R.CODIGO_EMPRESA,
           R.ID_REPRESTAMO,
           R.CODIGO_CLIENTE,
           R.NO_CREDITO,
           R.FECHA_CORTE,
           R.ESTADO,
           R.FECHA_ADICION
      FROM PR.PR_REPRESTAMOS R
     WHERE R.ADICIONADO_POR = USER
       AND R.FECHA_ADICION >= CAST(v_start_ts AS DATE);

    v_re_insert := SQL%ROWCOUNT;
    COMMIT;

    DBMS_OUTPUT.PUT_LINE('RE insertados por cadena acumulada: ' || v_re_insert);

    IF v_re_insert = 0 THEN
        UPDATE OPTACUM_RUN_CONTROL
           SET FINISHED_AT = SYSTIMESTAMP,
               RE_INSERTADOS = 0,
               NOTAS = NOTAS || ' | No se insertaron RE; revisar PRECAL_DIAS_PROCESAR / datos fuente'
         WHERE RUN_LABEL = v_run_label;
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('No se insertaron filas. Run finalizado sin snapshots.');
        RETURN;
    END IF;

    PR.PR_PKG_REPRESTAMOS.Actualiza_Precalificacion();
    COMMIT;

    FOR A IN (
        SELECT ID_REPRESTAMO
          FROM OPTACUM_RUN_IDS
         WHERE RUN_LABEL = v_run_label
         ORDER BY ID_REPRESTAMO
    ) LOOP
        v_mensaje := NULL;

        PR.PR_PKG_REPRESTAMOS.P_Registrar_Solicitud(
            A.ID_REPRESTAMO,
            v_usuario,
            v_mensaje
        );

        PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(
            A.ID_REPRESTAMO,
            NULL,
            'RE',
            NULL,
            '',
            v_usuario
        );
    END LOOP;

    COMMIT;

    FOR A IN (
        SELECT R.ID_REPRESTAMO, R.ESTADO, R.XCORE_GLOBAL
          FROM PR.PR_REPRESTAMOS R
          JOIN OPTACUM_RUN_IDS X
            ON X.RUN_LABEL = v_run_label
           AND X.CODIGO_EMPRESA = R.CODIGO_EMPRESA
           AND X.ID_REPRESTAMO = R.ID_REPRESTAMO
         WHERE R.ESTADO = 'RE'
    ) LOOP
        IF PR.PR_PKG_REPRESTAMOS.F_Existe_Solicitudes(A.ID_REPRESTAMO)
           AND PR.PR_PKG_REPRESTAMOS.F_Existe_Canales(A.ID_REPRESTAMO)
           AND PR.PR_PKG_REPRESTAMOS.F_EXISTE_CREDITO(A.ID_REPRESTAMO) THEN
            PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(
                A.ID_REPRESTAMO,
                NULL,
                'NP',
                NULL,
                'Notificacion Pendiente',
                USER
            );
        ELSE
            IF PR.PR_PKG_REPRESTAMOS.F_EXISTE_CREDITO(A.ID_REPRESTAMO) = FALSE THEN
                PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(
                    A.ID_REPRESTAMO,
                    NULL,
                    'RXT',
                    NULL,
                    'No cumple: Tipo de Credito',
                    USER
                );
            ELSE
                IF PR.PR_PKG_REPRESTAMOS.F_Existe_Solicitudes(A.ID_REPRESTAMO)
                   AND PR.PR_PKG_REPRESTAMOS.F_Existe_Canales(A.ID_REPRESTAMO) = FALSE
                   AND PR.PR_PKG_REPRESTAMOS.F_EXISTE_CREDITO(A.ID_REPRESTAMO) THEN
                    PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(
                        A.ID_REPRESTAMO,
                        NULL,
                        'CP',
                        NULL,
                        'Solicitud Pendiente de Canal',
                        USER
                    );
                ELSE
                    PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(
                        A.ID_REPRESTAMO,
                        NULL,
                        'AN',
                        NULL,
                        'No cumple: Solicitudes,Opciones',
                        USER
                    );
                END IF;
            END IF;
        END IF;
    END LOOP;

    COMMIT;

    v_now_ts := SYSTIMESTAMP;

    INSERT INTO OPTACUM_SNAP_REPRESTAMOS
    SELECT v_run_label, v_now_ts, R.*
      FROM PR.PR_REPRESTAMOS R
      JOIN OPTACUM_RUN_IDS X
        ON X.RUN_LABEL = v_run_label
       AND X.CODIGO_EMPRESA = R.CODIGO_EMPRESA
       AND X.ID_REPRESTAMO = R.ID_REPRESTAMO;

    INSERT INTO OPTACUM_SNAP_SOLICITUD
    SELECT v_run_label, v_now_ts, S.*
      FROM PR.PR_SOLICITUD_REPRESTAMO S
      JOIN OPTACUM_RUN_IDS X
        ON X.RUN_LABEL = v_run_label
       AND X.CODIGO_EMPRESA = S.CODIGO_EMPRESA
       AND X.ID_REPRESTAMO = S.ID_REPRESTAMO;

    INSERT INTO OPTACUM_SNAP_CANALES
    SELECT v_run_label, v_now_ts, C.*
      FROM PR.PR_CANALES_REPRESTAMO C
      JOIN OPTACUM_RUN_IDS X
        ON X.RUN_LABEL = v_run_label
       AND X.CODIGO_EMPRESA = C.CODIGO_EMPRESA
       AND X.ID_REPRESTAMO = C.ID_REPRESTAMO;

    INSERT INTO OPTACUM_SNAP_OPCIONES
    SELECT v_run_label, v_now_ts, O.*
      FROM PR.PR_OPCIONES_REPRESTAMO O
      JOIN OPTACUM_RUN_IDS X
        ON X.RUN_LABEL = v_run_label
       AND X.CODIGO_EMPRESA = O.CODIGO_EMPRESA
       AND X.ID_REPRESTAMO = O.ID_REPRESTAMO;

    INSERT INTO OPTACUM_SNAP_BITACORA
    SELECT v_run_label, v_now_ts, B.*
      FROM PR.PR_BITACORA_REPRESTAMO B
      JOIN OPTACUM_RUN_IDS X
        ON X.RUN_LABEL = v_run_label
       AND X.CODIGO_EMPRESA = B.CODIGO_EMPRESA
       AND X.ID_REPRESTAMO = B.ID_REPRESTAMO;

    COMMIT;

    SELECT COUNT(*) INTO v_solicitudes FROM OPTACUM_SNAP_SOLICITUD WHERE RUN_LABEL = v_run_label;
    SELECT COUNT(*) INTO v_canales FROM OPTACUM_SNAP_CANALES WHERE RUN_LABEL = v_run_label;
    SELECT COUNT(*) INTO v_opciones FROM OPTACUM_SNAP_OPCIONES WHERE RUN_LABEL = v_run_label;
    SELECT COUNT(*) INTO v_bitacora FROM OPTACUM_SNAP_BITACORA WHERE RUN_LABEL = v_run_label;

    UPDATE OPTACUM_RUN_CONTROL
       SET FINISHED_AT = SYSTIMESTAMP,
           RE_INSERTADOS = v_re_insert,
           SOLICITUDES = v_solicitudes,
           CANALES = v_canales,
           OPCIONES = v_opciones,
           BITACORA = v_bitacora
     WHERE RUN_LABEL = v_run_label;

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Snapshots guardados para ' || v_run_label);
    DBMS_OUTPUT.PUT_LINE('  RE        : ' || v_re_insert);
    DBMS_OUTPUT.PUT_LINE('  SOLICITUD : ' || v_solicitudes);
    DBMS_OUTPUT.PUT_LINE('  CANALES   : ' || v_canales);
    DBMS_OUTPUT.PUT_LINE('  OPCIONES  : ' || v_opciones);
    DBMS_OUTPUT.PUT_LINE('  BITACORA  : ' || v_bitacora);
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error en run ' || UPPER('&RUN_LABEL') || ': ' || SQLERRM);
        RAISE;
END;
/

PROMPT
PROMPT === RESUMEN DEL RUN ===
SELECT *
  FROM OPTACUM_RUN_CONTROL
 WHERE RUN_LABEL = UPPER('&RUN_LABEL');
