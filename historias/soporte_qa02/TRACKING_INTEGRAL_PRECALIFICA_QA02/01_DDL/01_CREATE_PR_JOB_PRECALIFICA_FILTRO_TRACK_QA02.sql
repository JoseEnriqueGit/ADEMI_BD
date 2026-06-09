-- =====================================================================
-- Capa B - Tabla agregada de filtros del tracking integral
-- Entorno: QA02
-- Objeto: PR.PR_JOB_PRECALIFICA_FILTRO_TRACK
-- Fecha: 2026-06-08
-- Idempotente. Ejecutar en Toad. No ejecuta DML funcional.
-- NOTA: nombre de 31 bytes; requiere Oracle 12.2+ (limite 128).
--       En 11g (limite 30) usar el alias corto de ./README.md.
-- Reversa: ../04_ROLLBACK/01_ROLLBACK_PR_JOB_PRECALIFICA_FILTRO_TRACK_QA02.sql
-- =====================================================================

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
      FROM all_tables
     WHERE owner = 'PR'
       AND table_name = 'PR_JOB_PRECALIFICA_FILTRO_TRACK';

    IF v_count = 0 THEN
        EXECUTE IMMEDIATE q'[
            CREATE TABLE PR.PR_JOB_PRECALIFICA_FILTRO_TRACK
            (
                ID_EJECUCION           VARCHAR2(32 BYTE)   NOT NULL,
                ID_DETALLE             NUMBER              NOT NULL,
                FLUJO                  VARCHAR2(120 BYTE),
                FASE                   VARCHAR2(30 BYTE),
                ORDEN_FILTRO           NUMBER(5),
                CODIGO_FILTRO          VARCHAR2(40 BYTE),
                DESCRIPCION            VARCHAR2(400 BYTE),
                TIPO_MEDICION          VARCHAR2(12 BYTE)   NOT NULL,
                CANDIDATOS_ANTES       NUMBER,
                CANDIDATOS_PASAN       NUMBER,
                CANDIDATOS_DESCARTADOS NUMBER,
                CREDITOS_DESCARTADOS   NUMBER,
                CLIENTES_DESCARTADOS   NUMBER,
                VALOR_LOTE             NUMBER,
                FECHA_CORTE            DATE,
                PARAMETROS             VARCHAR2(4000 BYTE),
                FECHA_REGISTRO         TIMESTAMP(6)       DEFAULT SYSTIMESTAMP NOT NULL,
                ADICIONADO_POR         VARCHAR2(30 BYTE)  DEFAULT USER         NOT NULL,
                FECHA_ADICION          DATE               DEFAULT SYSDATE      NOT NULL,
                CONSTRAINT PK_PR_JOB_PRECAL_FILTRO_TRACK
                    PRIMARY KEY (ID_EJECUCION, ID_DETALLE)
                    USING INDEX TABLESPACE PR_IDX,
                CONSTRAINT CK_PR_JOB_PRECAL_FIL_TIPMED
                    CHECK (TIPO_MEDICION IN ('REAL', 'DIAGNOSTICA'))
            )
        ]';
    END IF;
END;
/

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
      FROM all_sequences
     WHERE sequence_owner = 'PR'
       AND sequence_name = 'SEQ_PR_JOB_PRECAL_FILTRO';

    IF v_count = 0 THEN
        EXECUTE IMMEDIATE
            'CREATE SEQUENCE PR.SEQ_PR_JOB_PRECAL_FILTRO START WITH 1 INCREMENT BY 1 CACHE 20 NOORDER NOCYCLE';
    END IF;
END;
/

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
      FROM all_indexes
     WHERE owner = 'PR'
       AND index_name = 'IX_PRECAL_FILTRO_CONSULTA';

    IF v_count = 0 THEN
        EXECUTE IMMEDIATE
            'CREATE INDEX PR.IX_PRECAL_FILTRO_CONSULTA ON PR.PR_JOB_PRECALIFICA_FILTRO_TRACK (ID_EJECUCION, FLUJO, FASE, ORDEN_FILTRO) TABLESPACE PR_IDX';
    END IF;
END;
/

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
      FROM all_indexes
     WHERE owner = 'PR'
       AND index_name = 'IX_PRECAL_FILTRO_FECHA';

    IF v_count = 0 THEN
        EXECUTE IMMEDIATE
            'CREATE INDEX PR.IX_PRECAL_FILTRO_FECHA ON PR.PR_JOB_PRECALIFICA_FILTRO_TRACK (FECHA_REGISTRO) TABLESPACE PR_IDX';
    END IF;
END;
/

PROMPT Capa B creada/validada: PR.PR_JOB_PRECALIFICA_FILTRO_TRACK
