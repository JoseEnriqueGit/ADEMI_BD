DROP TABLE PR.PR_CANALES_REPRESTAMO CASCADE CONSTRAINTS;

CREATE TABLE PR.PR_CANALES_REPRESTAMO
(
  CODIGO_EMPRESA      NUMBER(4)                 NOT NULL,
  ID_REPRESTAMO       NUMBER(14)                NOT NULL,
  CANAL               VARCHAR2(2 BYTE)          NOT NULL,
  VALOR               VARCHAR2(250 BYTE)        NOT NULL,
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

COMMENT ON TABLE PR.PR_CANALES_REPRESTAMO IS 'Tabla para almacenar los datos relacionados a los créditos que aplican para los represtamos';

COMMENT ON COLUMN PR.PR_CANALES_REPRESTAMO.CODIGO_EMPRESA IS 'Codigo de la Empresa asociada al respréstamo.';

COMMENT ON COLUMN PR.PR_CANALES_REPRESTAMO.ID_REPRESTAMO IS 'Identificador único para registrar el crédito que aplica al représtamo. Se genera mediante la formula YYMM+Consecutivo';


CREATE UNIQUE INDEX PR.PK_CANALES_REPRESTAMO ON PR.PR_CANALES_REPRESTAMO
(CODIGO_EMPRESA, ID_REPRESTAMO, CANAL)
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

ALTER TABLE PR.PR_CANALES_REPRESTAMO ADD (
  CONSTRAINT PK_CANALES_REPRESTAMO
  PRIMARY KEY
  (CODIGO_EMPRESA, ID_REPRESTAMO, CANAL)
  USING INDEX PR.PK_CANALES_REPRESTAMO
  ENABLE VALIDATE);


CREATE OR REPLACE TRIGGER "PR"."TRG_BUI_PR_CANALES_REPRESTAMO" 
BEFORE INSERT OR UPDATE
ON pr.PR_CANALES_REPRESTAMO REFERENCING NEW AS New OLD AS Old
FOR EACH ROW
BEGIN
  IF INSERTING THEN
     :new.fecha_adicion := sysdate; 
     if :new.adicionado_por is null THEN
        :new.adicionado_por := user;
     end if;
     -- Registra en la bitacora
--     PR.PR_PKG_REPRESTAMOS.p_generar_bitacora(:new.id_represtamo,
--                                             :new.canal,
--                                             'NP',
--                                             NULL,
--                                             'Preparado para la notificacion',
--                                             :new.adicionado_por
--                                             );
--                                             
--
--     -- Actualiza el estado del represtamo
--     PR_PKG_REPRESTAMOS.p_validar_Cambio_Estado(:new.id_represtamo, 'NP');     
                                             
  ELSE 
     :new.fecha_modificacion := sysdate;
     if :new.modificado_por is null THEN
        :new.modificado_por := user;
     end if;
  END IF;
END;
/


CREATE OR REPLACE TRIGGER "PR"."TRG_PR_CANAL_REPRESTAMOS" 
   BEFORE INSERT OR UPDATE
   ON PR.PR_CANALES_REPRESTAMO
   REFERENCING NEW AS New OLD AS Old
   FOR EACH ROW
DISABLE
DECLARE
   vSMS     NUMBER := NVL (PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo ('CANAL_SMS'), 1);
   vEMAIL   NUMBER := NVL (PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo ('CANAL_EMAIL'), 2);
BEGIN
   IF :NEW.CANAL = vSMS
   THEN
      UPDATE PR.PR_SOLICITUD_REPRESTAMO S
         SET S.TELEFONO_CELULAR = NVL (:NEW.VALOR, :OLD.VALOR)
       WHERE     S.CODIGO_EMPRESA = :NEW.CODIGO_EMPRESA
             AND S.ID_REPRESTAMO = :NEW.ID_REPRESTAMO;
   ELSIF :NEW.CANAL = vEMAIL
   THEN
      UPDATE PR.PR_SOLICITUD_REPRESTAMO S
         SET S.EMAIL = NVL (:NEW.VALOR, :OLD.VALOR)
       WHERE     S.CODIGO_EMPRESA = :NEW.CODIGO_EMPRESA
             AND S.ID_REPRESTAMO = :NEW.ID_REPRESTAMO;
   END IF;
END;
/


CREATE OR REPLACE PUBLIC SYNONYM PR_CANALES_REPRESTAMO FOR PR.PR_CANALES_REPRESTAMO;


ALTER TABLE PR.PR_CANALES_REPRESTAMO ADD (
  CONSTRAINT FK01_PR_CANALES_REPRESTAMO 
  FOREIGN KEY (CODIGO_EMPRESA, ID_REPRESTAMO) 
  REFERENCES PR.PR_REPRESTAMOS (CODIGO_EMPRESA, ID_REPRESTAMO)
  ENABLE VALIDATE);

GRANT SELECT ON PR.PR_CANALES_REPRESTAMO TO BPR;
