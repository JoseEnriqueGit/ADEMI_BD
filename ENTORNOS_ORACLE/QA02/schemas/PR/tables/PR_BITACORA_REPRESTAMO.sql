-- ============================================================
-- Tabla: PR.PR_BITACORA_REPRESTAMO
-- Schema: PR (Prestamos)
-- Entorno: QA02
--
-- Proposito:
--   Registra el historial completo de cambios de estado de cada
--   represtamo digital. Cada transicion de estado (RE->NP->SC->
--   CRS->CRD, o rechazos como RSB, RXC, AN, etc.) genera un
--   registro en esta tabla.
--
-- Relaciones:
--   FK -> PR.PR_REPRESTAMOS (CODIGO_EMPRESA, ID_REPRESTAMO)
--
-- Columnas clave:
--   CODIGO_EMPRESA   - Empresa (1 = ADEMI)
--   ID_REPRESTAMO    - FK al represtamo
--   ID_BITACORA      - Secuencial por represtamo (1,2,3...)
--   CODIGO_ESTADO    - Estado registrado en ese momento:
--                      RE=Registrado, NP=Notificacion Pendiente,
--                      SC=Solicitud Confirmada, CRS=Credito Solicitado,
--                      CRD=Credito Desembolsado, AN=Anulado,
--                      RSB=Rechazo SIB, RXC=Rechazo Xcore,
--                      BLI=Bloqueado Identificacion,
--                      BLP=Bloqueado PIN, etc.
--   STEP             - Paso del flujo frontend (1,2,3...)
--   OBSERVACIONES    - Detalle del cambio
--   CANAL            - Canal de notificacion (1=SMS, 2=Email)
-- ============================================================

CREATE TABLE PR.PR_BITACORA_REPRESTAMO
(
  CODIGO_EMPRESA      NUMBER(4)                 NOT NULL,
  ID_REPRESTAMO       NUMBER(14)                NOT NULL,
  ID_BITACORA         NUMBER(10)                NOT NULL,
  FECHA_BITACORA      DATE                      NOT NULL,
  CODIGO_ESTADO       VARCHAR2(5 BYTE)          NOT NULL,
  STEP                VARCHAR2(2 BYTE),
  OBSERVACIONES       VARCHAR2(500 BYTE),
  CANAL               VARCHAR2(2 BYTE),
  ADICIONADO_POR      VARCHAR2(30 BYTE)         NOT NULL,
  FECHA_ADICION       DATE                      NOT NULL,
  MODIFICADO_POR      VARCHAR2(30 BYTE),
  FECHA_MODIFICACION  DATE
)
TABLESPACE PR_DAT
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


CREATE UNIQUE INDEX PR.PK_BITACORA_REPRESTAMO ON PR.PR_BITACORA_REPRESTAMO
(CODIGO_EMPRESA, ID_REPRESTAMO, ID_BITACORA)
LOGGING
TABLESPACE PR_DAT
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

ALTER TABLE PR.PR_BITACORA_REPRESTAMO ADD (
  CONSTRAINT PK_BITACORA_REPRESTAMO
  PRIMARY KEY
  (CODIGO_EMPRESA, ID_REPRESTAMO, ID_BITACORA)
  USING INDEX PR.PK_BITACORA_REPRESTAMO
  ENABLE VALIDATE);


CREATE INDEX PR.IDX_BITREPRE_CODESTADO_ID ON PR.PR_BITACORA_REPRESTAMO
(CODIGO_ESTADO, ID_REPRESTAMO)
LOGGING
TABLESPACE PR_DAT
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

CREATE INDEX PR.IDX_BITREPRE_ID_IDBIT_FEC ON PR.PR_BITACORA_REPRESTAMO
(ID_REPRESTAMO, ID_BITACORA DESC, FECHA_ADICION DESC)
LOGGING
TABLESPACE PR_DAT
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


CREATE OR REPLACE TRIGGER PR.TRG_BUI_PR_BITACORA_REPRESTAMO
BEFORE INSERT OR UPDATE
ON PR.PR_BITACORA_REPRESTAMO REFERENCING NEW AS New OLD AS Old
FOR EACH ROW
BEGIN
  IF INSERTING THEN
     :new.fecha_adicion := sysdate;
     if :new.adicionado_por is null THEN
        :new.adicionado_por := user;
     end if;
  ELSE
     :new.fecha_modificacion := sysdate;
     if :new.modificado_por is null THEN
        :new.modificado_por := user;
     end if;
  END IF;
END;
/


CREATE OR REPLACE PUBLIC SYNONYM PR_BITACORA_REPRESTAMO FOR PR.PR_BITACORA_REPRESTAMO;


ALTER TABLE PR.PR_BITACORA_REPRESTAMO ADD (
  CONSTRAINT FK_BITACORA_REPRESTAMO
  FOREIGN KEY (CODIGO_EMPRESA, ID_REPRESTAMO)
  REFERENCES PR.PR_REPRESTAMOS (CODIGO_EMPRESA, ID_REPRESTAMO)
  ENABLE VALIDATE);

GRANT SELECT ON PR.PR_BITACORA_REPRESTAMO TO BPR;
