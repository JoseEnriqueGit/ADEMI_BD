-- =============================================================
-- OPT-015 - Setup de prueba rigurosa de equivalencia
-- Entorno objetivo: DESARROLLO
-- Crea tablas auxiliares en el usuario actual y sube temporalmente
-- el parametro LOTE_DE_CARAGA_REPRESTAMO para reducir variabilidad.
-- =============================================================

DEFINE LOTE_PRUEBA = 500

SET SERVEROUTPUT ON SIZE UNLIMITED;

DECLARE
    v_exists NUMBER;

    PROCEDURE ensure_table(p_name VARCHAR2, p_sql CLOB) IS
    BEGIN
        SELECT COUNT(*)
          INTO v_exists
          FROM USER_TABLES
         WHERE TABLE_NAME = UPPER(p_name);

        IF v_exists = 0 THEN
            EXECUTE IMMEDIATE p_sql;
            DBMS_OUTPUT.PUT_LINE('Creada tabla auxiliar: ' || UPPER(p_name));
        ELSE
            DBMS_OUTPUT.PUT_LINE('Tabla auxiliar ya existe: ' || UPPER(p_name));
        END IF;
    END;
BEGIN
    ensure_table(
        'OPT015_PARAM_BACKUP',
        q'[
            CREATE TABLE OPT015_PARAM_BACKUP (
                CODIGO_EMPRESA    NUMBER(4),
                CODIGO_MVP        VARCHAR2(30),
                CODIGO_PARAMETRO  VARCHAR2(50),
                VALOR_ORIGINAL    VARCHAR2(4000),
                FECHA_RESPALDO    TIMESTAMP,
                TEST_USER         VARCHAR2(30)
            )
        ]'
    );

    ensure_table(
        'OPT015_RUN_CONTROL',
        q'[
            CREATE TABLE OPT015_RUN_CONTROL (
                RUN_LABEL        VARCHAR2(30),
                TEST_USER        VARCHAR2(30),
                STARTED_AT       TIMESTAMP,
                FINISHED_AT      TIMESTAMP,
                LOTE_ORIGINAL    VARCHAR2(4000),
                LOTE_PRUEBA      VARCHAR2(4000),
                RE_INSERTADOS    NUMBER,
                SOLICITUDES      NUMBER,
                CANALES          NUMBER,
                OPCIONES         NUMBER,
                BITACORA         NUMBER,
                NOTAS            VARCHAR2(4000)
            )
        ]'
    );

    ensure_table(
        'OPT015_RUN_IDS',
        q'[
            CREATE TABLE OPT015_RUN_IDS (
                RUN_LABEL        VARCHAR2(30),
                CODIGO_EMPRESA   NUMBER(4),
                ID_REPRESTAMO    NUMBER(14),
                CODIGO_CLIENTE   NUMBER(7),
                NO_CREDITO       NUMBER(7),
                FECHA_CORTE      DATE,
                ESTADO_CAPTURA   VARCHAR2(5),
                FECHA_ADICION    DATE
            )
        ]'
    );

    ensure_table(
        'OPT015_SNAP_REPRESTAMOS',
        q'[
            CREATE TABLE OPT015_SNAP_REPRESTAMOS AS
            SELECT
                CAST(NULL AS VARCHAR2(30)) RUN_LABEL,
                CAST(NULL AS TIMESTAMP)    CAPTURED_AT,
                R.*
            FROM PR.PR_REPRESTAMOS R
            WHERE 1 = 0
        ]'
    );

    ensure_table(
        'OPT015_SNAP_SOLICITUD',
        q'[
            CREATE TABLE OPT015_SNAP_SOLICITUD AS
            SELECT
                CAST(NULL AS VARCHAR2(30)) RUN_LABEL,
                CAST(NULL AS TIMESTAMP)    CAPTURED_AT,
                S.*
            FROM PR.PR_SOLICITUD_REPRESTAMO S
            WHERE 1 = 0
        ]'
    );

    ensure_table(
        'OPT015_SNAP_CANALES',
        q'[
            CREATE TABLE OPT015_SNAP_CANALES AS
            SELECT
                CAST(NULL AS VARCHAR2(30)) RUN_LABEL,
                CAST(NULL AS TIMESTAMP)    CAPTURED_AT,
                C.*
            FROM PR.PR_CANALES_REPRESTAMO C
            WHERE 1 = 0
        ]'
    );

    ensure_table(
        'OPT015_SNAP_OPCIONES',
        q'[
            CREATE TABLE OPT015_SNAP_OPCIONES AS
            SELECT
                CAST(NULL AS VARCHAR2(30)) RUN_LABEL,
                CAST(NULL AS TIMESTAMP)    CAPTURED_AT,
                O.*
            FROM PR.PR_OPCIONES_REPRESTAMO O
            WHERE 1 = 0
        ]'
    );

    ensure_table(
        'OPT015_SNAP_BITACORA',
        q'[
            CREATE TABLE OPT015_SNAP_BITACORA AS
            SELECT
                CAST(NULL AS VARCHAR2(30)) RUN_LABEL,
                CAST(NULL AS TIMESTAMP)    CAPTURED_AT,
                B.*
            FROM PR.PR_BITACORA_REPRESTAMO B
            WHERE 1 = 0
        ]'
    );
END;
/

MERGE INTO OPT015_PARAM_BACKUP B
USING (
    SELECT CODIGO_EMPRESA,
           CODIGO_MVP,
           CODIGO_PARAMETRO,
           VALOR
      FROM PA.PA_PARAMETROS_MVP
     WHERE CODIGO_EMPRESA = PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
       AND CODIGO_MVP = 'REPRESTAMOS'
       AND CODIGO_PARAMETRO = 'LOTE_DE_CARAGA_REPRESTAMO'
) S
ON (
       B.CODIGO_EMPRESA = S.CODIGO_EMPRESA
   AND B.CODIGO_MVP = S.CODIGO_MVP
   AND B.CODIGO_PARAMETRO = S.CODIGO_PARAMETRO
)
WHEN MATCHED THEN
    UPDATE
       SET B.VALOR_ORIGINAL = S.VALOR,
           B.FECHA_RESPALDO = SYSTIMESTAMP,
           B.TEST_USER = USER
WHEN NOT MATCHED THEN
    INSERT (
        CODIGO_EMPRESA,
        CODIGO_MVP,
        CODIGO_PARAMETRO,
        VALOR_ORIGINAL,
        FECHA_RESPALDO,
        TEST_USER
    )
    VALUES (
        S.CODIGO_EMPRESA,
        S.CODIGO_MVP,
        S.CODIGO_PARAMETRO,
        S.VALOR,
        SYSTIMESTAMP,
        USER
    );

UPDATE PA.PA_PARAMETROS_MVP
   SET VALOR = '&LOTE_PRUEBA',
       MODIFICADO_POR = USER
 WHERE CODIGO_EMPRESA = PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
   AND CODIGO_MVP = 'REPRESTAMOS'
   AND CODIGO_PARAMETRO = 'LOTE_DE_CARAGA_REPRESTAMO';

COMMIT;

PROMPT
PROMPT === PRECHECK BASICO ===

SELECT INDEX_NAME, STATUS
  FROM ALL_INDEXES
 WHERE OWNER = 'PR'
   AND INDEX_NAME = 'IDX_GARANTIAS_TIPO_SB';

SELECT CODIGO_EMPRESA,
       CODIGO_MVP,
       CODIGO_PARAMETRO,
       VALOR
  FROM PA.PA_PARAMETROS_MVP
 WHERE CODIGO_EMPRESA = PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
   AND CODIGO_MVP = 'REPRESTAMOS'
   AND CODIGO_PARAMETRO IN (
       'LOTE_DE_CARAGA_REPRESTAMO',
       'PRECAL_DIAS_PROCESAR',
       'PRECAL_DIA_ATRASO_TC',
       'PRECAL_MORA_MAYOR_PR',
       'PRECAL_DESEMBOLSO_PR'
   )
 ORDER BY CODIGO_PARAMETRO;

SELECT CODIGO_PARAMETRO,
       VALOR_ORIGINAL,
       FECHA_RESPALDO,
       TEST_USER
  FROM OPT015_PARAM_BACKUP
 WHERE CODIGO_PARAMETRO = 'LOTE_DE_CARAGA_REPRESTAMO';

SELECT COUNT(*) AS RE_HOY_USUARIO
  FROM PR.PR_REPRESTAMOS
 WHERE ADICIONADO_POR = USER
   AND FECHA_ADICION >= TRUNC(SYSDATE);

PROMPT
PROMPT Setup completado. Si el indice no existe o RE_HOY_USUARIO > 0, limpiar antes de correr ANTES.
