-- ============================================================
-- Tabla: PA.BITACORA_REP_AUTOMATICOS
-- Schema: PA (Personas/Admin)
-- Entorno: QA02
--
-- Proposito:
--   Registra el historial de cada cambio de estado en los
--   reportes automaticos (PA_REPORTES_AUTOMATICOS).
--   Cada vez que un reporte se inserta o cambia de estado
--   (Pendiente, En Proceso, Enviado, Error, etc.), el trigger
--   TRG_REP_AUTOMATICOS de PA_REPORTES_AUTOMATICOS invoca
--   el procedimiento PA.Bitacora_Reportes_Automaticos que
--   inserta un registro aqui.
--
-- Relaciones:
--   FK -> PA.PA_REPORTES_AUTOMATICOS (CODIGO_REPORTE)
--
-- Columnas clave:
--   CODIGO_BITACORA  - PK, generada por SEQ_BIT_REP_AUTOM
--   CODIGO_REPORTE   - FK al reporte que cambio de estado
--   ESTADO_REPORTE   - Estado al momento del registro
--                      (P=Pendiente, R=Requiere Generar,
--                       SP=Siendo Procesado, S=Enviado/Success,
--                       E=Error, D=Descargado)
--   MENSAJE          - Detalle o error del procesamiento
--   IDPROCESO        - Identificador del hilo/job que proceso
-- ============================================================

CREATE TABLE PA.BITACORA_REP_AUTOMATICOS
(
  CODIGO_BITACORA     NUMBER,
  CODIGO_REPORTE      NUMBER,
  NOMBRE_ARCHIVO      VARCHAR2(300 BYTE),
  FECHA_BITACORA      DATE,
  ESTADO_REPORTE      VARCHAR2(5 BYTE),
  IDPROCESO           VARCHAR2(150 BYTE),
  MENSAJE             VARCHAR2(4000 BYTE),
  ADICIONADO_POR      VARCHAR2(30 BYTE),
  FECHA_ADICION       DATE,
  MODIFICADO_POR      VARCHAR2(30 BYTE),
  FECHA_MODIFICACION  DATE
)
TABLESPACE PA_DAT
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING
NOCOMPRESS
NOCACHE;


CREATE UNIQUE INDEX PA.PK_BITACORA_REP_AUTOMATIC ON PA.BITACORA_REP_AUTOMATICOS
(CODIGO_BITACORA)
LOGGING
TABLESPACE PA_DAT
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           );

ALTER TABLE PA.BITACORA_REP_AUTOMATICOS ADD (
  CONSTRAINT PK_BITACORA_REP_AUTOMATIC
  PRIMARY KEY
  (CODIGO_BITACORA)
  USING INDEX PA.PK_BITACORA_REP_AUTOMATIC
  ENABLE VALIDATE);


CREATE INDEX PA.COD_REP_EST_REP_IDX ON PA.BITACORA_REP_AUTOMATICOS
(CODIGO_REPORTE, ESTADO_REPORTE)
LOGGING
TABLESPACE PA_IDX
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           );

CREATE INDEX PA.IDX_BITACORA_REP_AUTO_1 ON PA.BITACORA_REP_AUTOMATICOS
(CODIGO_REPORTE)
LOGGING
TABLESPACE PA_IDX
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           );

CREATE SEQUENCE PA.SEQ_BIT_REP_AUTOM
  START WITH 1
  INCREMENT BY 10
  MAXVALUE 999999999999999999999999999
  MINVALUE 1
  NOCYCLE
  NOCACHE
  NOORDER
  NOKEEP
  NOSCALE
  GLOBAL;


CREATE OR REPLACE TRIGGER PA.TRG_BIT_REP_AUTOMATICOS
    BEFORE INSERT OR UPDATE
    ON PA.BITACORA_REP_AUTOMATICOS
    REFERENCING NEW AS NEW OLD AS OLD
    FOR EACH ROW
BEGIN
    IF (INSERTING) THEN
        :NEW.ADICIONADO_POR := NVL (SYS_CONTEXT ('APEX$SESSION', 'APP_USER'), USER);
        :NEW.FECHA_ADICION := SYSDATE;

        IF :NEW.CODIGO_BITACORA IS NULL THEN
           :NEW.CODIGO_BITACORA := PA.SEQ_BIT_REP_AUTOM.NEXTVAL;
        END IF;

        :NEW.FECHA_BITACORA := SYSDATE;
    ELSIF (UPDATING) THEN
        :NEW.MODIFICADO_POR := NVL (SYS_CONTEXT ('APEX$SESSION', 'APP_USER'), USER);
        :NEW.FECHA_MODIFICACION := SYSDATE;
    END IF;
END;
/


ALTER TABLE PA.BITACORA_REP_AUTOMATICOS ADD (
  CONSTRAINT FK_BITACORA_REP_AUTOMATIC
  FOREIGN KEY (CODIGO_REPORTE)
  REFERENCES PA.PA_REPORTES_AUTOMATICOS (CODIGO_REPORTE)
  ENABLE VALIDATE);
