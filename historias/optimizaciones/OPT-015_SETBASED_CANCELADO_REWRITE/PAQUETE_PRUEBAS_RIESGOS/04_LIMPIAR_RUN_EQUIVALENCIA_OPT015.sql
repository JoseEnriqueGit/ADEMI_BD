-- =============================================================
-- OPT-015 - Limpia los datos generados por un run de equivalencia
-- Borra tablas hijas y luego PR_REPRESTAMOS solo para los IDs del run.
-- No borra snapshots; esos se conservan para comparar.
-- =============================================================

DEFINE RUN_LABEL = ANTES

SET SERVEROUTPUT ON SIZE UNLIMITED;

DECLARE
    v_run_label VARCHAR2(30) := UPPER('&RUN_LABEL');
    v_count     NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_count
      FROM OPT015_RUN_IDS
     WHERE RUN_LABEL = v_run_label;

    DBMS_OUTPUT.PUT_LINE('RUN_LABEL: ' || v_run_label);
    DBMS_OUTPUT.PUT_LINE('IDs a limpiar: ' || v_count);

    DELETE FROM PR.PR_BITACORA_REPRESTAMO B
     WHERE EXISTS (
         SELECT 1
           FROM OPT015_RUN_IDS X
          WHERE X.RUN_LABEL = v_run_label
            AND X.CODIGO_EMPRESA = B.CODIGO_EMPRESA
            AND X.ID_REPRESTAMO = B.ID_REPRESTAMO
     );

    DBMS_OUTPUT.PUT_LINE('Bitacora borrada: ' || SQL%ROWCOUNT);

    DELETE FROM PR.PR_CANALES_REPRESTAMO C
     WHERE EXISTS (
         SELECT 1
           FROM OPT015_RUN_IDS X
          WHERE X.RUN_LABEL = v_run_label
            AND X.CODIGO_EMPRESA = C.CODIGO_EMPRESA
            AND X.ID_REPRESTAMO = C.ID_REPRESTAMO
     );

    DBMS_OUTPUT.PUT_LINE('Canales borrados: ' || SQL%ROWCOUNT);

    DELETE FROM PR.PR_OPCIONES_REPRESTAMO O
     WHERE EXISTS (
         SELECT 1
           FROM OPT015_RUN_IDS X
          WHERE X.RUN_LABEL = v_run_label
            AND X.CODIGO_EMPRESA = O.CODIGO_EMPRESA
            AND X.ID_REPRESTAMO = O.ID_REPRESTAMO
     );

    DBMS_OUTPUT.PUT_LINE('Opciones borradas: ' || SQL%ROWCOUNT);

    DELETE FROM PR.PR_SOLICITUD_REPRESTAMO S
     WHERE EXISTS (
         SELECT 1
           FROM OPT015_RUN_IDS X
          WHERE X.RUN_LABEL = v_run_label
            AND X.CODIGO_EMPRESA = S.CODIGO_EMPRESA
            AND X.ID_REPRESTAMO = S.ID_REPRESTAMO
     );

    DBMS_OUTPUT.PUT_LINE('Solicitudes borradas: ' || SQL%ROWCOUNT);

    DELETE FROM PR.PR_REPRESTAMOS R
     WHERE EXISTS (
         SELECT 1
           FROM OPT015_RUN_IDS X
          WHERE X.RUN_LABEL = v_run_label
            AND X.CODIGO_EMPRESA = R.CODIGO_EMPRESA
            AND X.ID_REPRESTAMO = R.ID_REPRESTAMO
     );

    DBMS_OUTPUT.PUT_LINE('Represtamos borrados: ' || SQL%ROWCOUNT);

    COMMIT;
END;
/
