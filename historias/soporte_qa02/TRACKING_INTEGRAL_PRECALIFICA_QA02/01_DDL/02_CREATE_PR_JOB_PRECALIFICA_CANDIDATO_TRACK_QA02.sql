-- =====================================================================
-- Capa C - Pertenencia real de candidatos al lote
-- Entorno: QA02
-- Objeto: PR.PR_JOB_PRECALIFICA_CANDIDATO_TRACK
-- Fecha: 2026-06-08
-- Idempotente. Ejecutar en Toad. No ejecuta DML funcional.
-- ID_REPRESTAMO = NUMBER(14), segun el DDL del repo
--   (ENTORNOS_ORACLE/QA02/schemas/PR/tables/PR_REPRESTAMOS.sql:6).
--   El paso 5 del script 00 reconfirma el tipo vivo en QA02.
-- NOTA: nombre de 34 bytes; requiere Oracle 12.2+ (limite 128).
--       En 11g (limite 30) usar el alias corto de ./README.md.
-- Reversa: ../04_ROLLBACK/02_ROLLBACK_PR_JOB_PRECALIFICA_CANDIDATO_TRACK_QA02.sql
-- =====================================================================

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
      FROM all_tables
     WHERE owner = 'PR'
       AND table_name = 'PR_JOB_PRECALIFICA_CANDIDATO_TRACK';

    IF v_count = 0 THEN
        EXECUTE IMMEDIATE q'[
            CREATE TABLE PR.PR_JOB_PRECALIFICA_CANDIDATO_TRACK
            (
                ID_EJECUCION     VARCHAR2(32 BYTE)  NOT NULL,
                FLUJO            VARCHAR2(120 BYTE) NOT NULL,
                ID_REPRESTAMO    NUMBER(14)         NOT NULL,
                RESULTADO_ULTIMO VARCHAR2(20 BYTE),
                FECHA_REGISTRO   TIMESTAMP(6)       DEFAULT SYSTIMESTAMP NOT NULL,
                ADICIONADO_POR   VARCHAR2(30 BYTE)  DEFAULT USER         NOT NULL,
                FECHA_ADICION    DATE               DEFAULT SYSDATE      NOT NULL,
                CONSTRAINT PK_PR_JOB_PRECAL_CAND_TRACK
                    PRIMARY KEY (ID_EJECUCION, FLUJO, ID_REPRESTAMO)
                    USING INDEX TABLESPACE PR_IDX
            )
        ]';
    END IF;
END;
/

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
      FROM all_indexes
     WHERE owner = 'PR'
       AND index_name = 'IX_PRECAL_CAND_FECHA';

    IF v_count = 0 THEN
        EXECUTE IMMEDIATE
            'CREATE INDEX PR.IX_PRECAL_CAND_FECHA ON PR.PR_JOB_PRECALIFICA_CANDIDATO_TRACK (FECHA_REGISTRO) TABLESPACE PR_IDX';
    END IF;
END;
/

PROMPT Capa C creada/validada: PR.PR_JOB_PRECALIFICA_CANDIDATO_TRACK
