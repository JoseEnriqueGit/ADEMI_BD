DROP TABLE PA.TEL_PERSONAS CASCADE CONSTRAINTS;

CREATE TABLE PA.TEL_PERSONAS
(
  COD_PERSONA             VARCHAR2(15 BYTE),
  COD_AREA                VARCHAR2(10 BYTE),
  NUM_TELEFONO            VARCHAR2(10 BYTE),
  TIP_TELEFONO            VARCHAR2(1 BYTE) CONSTRAINT NN_TEL_PERSONAS_TIP_TELEFONO NOT NULL,
  TEL_UBICACION           VARCHAR2(1 BYTE) CONSTRAINT NN_TEL_PERSONAS_TEL_UBICACION NOT NULL,
  EXTENSION               NUMBER(4),
  NOTA                    VARCHAR2(80 BYTE),
  ES_DEFAULT              VARCHAR2(1 BYTE) CONSTRAINT NN_TEL_PERSONAS_ES_DEFAULT NOT NULL,
  POSICION                NUMBER(5),
  COD_DIRECCION           VARCHAR2(8 BYTE),
  COD_PAIS                VARCHAR2(5 BYTE),
  MODIFICADO_POR          VARCHAR2(10 BYTE)     DEFAULT trim(substr(nvl(sys_context('APEX$SESSION','APP_USER'),user),1,10)),
  FECHA_MODIFICACION      DATE,
  INCLUIDO_POR            VARCHAR2(10 BYTE)     DEFAULT trim(substr(nvl(sys_context('APEX$SESSION','APP_USER'),user),1,10)),
  FEC_INCLUSION           DATE                  DEFAULT sysdate,
  NOTIF_DIGITAL           VARCHAR2(1 BYTE),
  FECHA_NOTIF_DIGITAL     DATE,
  USUAARIO_NOTIF_DIGITAL  VARCHAR2(15 BYTE)
)
TABLESPACE DATA_EFD
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          576K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE;

COMMENT ON TABLE PA.TEL_PERSONAS IS ' Telefonos personas';

COMMENT ON COLUMN PA.TEL_PERSONAS.COD_PERSONA IS 'codigo de persona.';

COMMENT ON COLUMN PA.TEL_PERSONAS.COD_AREA IS 'Codigo de area';

COMMENT ON COLUMN PA.TEL_PERSONAS.NUM_TELEFONO IS 'Numero de telefono';

COMMENT ON COLUMN PA.TEL_PERSONAS.TIP_TELEFONO IS 'Tipo de telefono';

COMMENT ON COLUMN PA.TEL_PERSONAS.TEL_UBICACION IS 'Ubicacion del telefono';

COMMENT ON COLUMN PA.TEL_PERSONAS.EXTENSION IS 'Extension';

COMMENT ON COLUMN PA.TEL_PERSONAS.NOTA IS 'Nota';

COMMENT ON COLUMN PA.TEL_PERSONAS.ES_DEFAULT IS 'Es el telefono principal';

COMMENT ON COLUMN PA.TEL_PERSONAS.POSICION IS 'Posicion de orden';

COMMENT ON COLUMN PA.TEL_PERSONAS.COD_DIRECCION IS 'Codigo direccion';

COMMENT ON COLUMN PA.TEL_PERSONAS.COD_PAIS IS 'Pais del Telefono';

COMMENT ON COLUMN PA.TEL_PERSONAS.MODIFICADO_POR IS 'Usuario modifico';

COMMENT ON COLUMN PA.TEL_PERSONAS.FECHA_MODIFICACION IS 'Fecha de modificacion';

COMMENT ON COLUMN PA.TEL_PERSONAS.INCLUIDO_POR IS 'Usuario inserto';

COMMENT ON COLUMN PA.TEL_PERSONAS.FEC_INCLUSION IS 'Fecha de insercion';

COMMENT ON COLUMN PA.TEL_PERSONAS.NOTIF_DIGITAL IS 'Indicador de Notificaciones Digitales';

COMMENT ON COLUMN PA.TEL_PERSONAS.FECHA_NOTIF_DIGITAL IS 'Fecha en que se  marca/desmarca el indicadorNotif_Digital';

COMMENT ON COLUMN PA.TEL_PERSONAS.USUAARIO_NOTIF_DIGITAL IS 'Usuario que marca/desmarca el indicadorNotif_Digital';


CREATE UNIQUE INDEX PA.PK_TEL_PERSONAS ON PA.TEL_PERSONAS
(COD_PERSONA, COD_AREA, NUM_TELEFONO)
LOGGING
TABLESPACE IND_EFD
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          640K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           );

ALTER TABLE PA.TEL_PERSONAS ADD (
  CONSTRAINT CK_TELPERSONAS_TIPTELEFONO
  CHECK ( TIP_TELEFONO IN ('C','D','T','F','X','R','O')             )
  ENABLE VALIDATE
,  CONSTRAINT CK_TELPERSONAS_TIPUBICACION
  CHECK ( TEL_UBICACION in ('C','T','O','I')             )
  ENABLE VALIDATE
,  CONSTRAINT CK_TEL_PERSONAS_ES_DEFAULT
  CHECK ( ES_DEFAULT IN ( 'S','N' )             )
  ENABLE VALIDATE
,  CONSTRAINT PK_TEL_PERSONAS
  PRIMARY KEY
  (COD_PERSONA, COD_AREA, NUM_TELEFONO)
  USING INDEX PA.PK_TEL_PERSONAS
  ENABLE VALIDATE);


CREATE INDEX PA.IDX_TEL_PERSONAS_TIPO ON PA.TEL_PERSONAS
(COD_PERSONA, TIP_TELEFONO)
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

CREATE INDEX PA.IDX_TELP_PER_DEF ON PA.TEL_PERSONAS
(COD_PERSONA, ES_DEFAULT)
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

CREATE INDEX PA.TEL_PERSONAS_FK10 ON PA.TEL_PERSONAS
(COD_PAIS)
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

CREATE INDEX PA.TEL_PERSONAS_FK9 ON PA.TEL_PERSONAS
(COD_PERSONA, COD_DIRECCION)
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

CREATE OR REPLACE TRIGGER pa.PR_CANALES_REPRESTAMOS
AFTER INSERT OR UPDATE
OF COD_AREA
  ,NUM_TELEFONO
ON PA.TEL_PERSONAS
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DISABLE
DECLARE
    pmensaje        VARCHAR2 (32767);
    v_EsReprestamo  PLS_INTEGER := 0;
BEGIN
    IF :new.TIP_TELEFONO = 'C' THEN
         -- Verificar si es de represtamo
         SELECT COUNT(1)
           INTO v_EsReprestamo
           FROM PR.PR_REPRESTAMOS RE 
          WHERE RE.CODIGO_CLIENTE   = :new.cod_persona 
            AND RE.ESTADO IN (SELECT COLUMN_VALUE 
                                FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'ESTADOS_ACTUALIZAR_CANAL_REPRESTAMO')))
            OR RE.ESTADO IN (SELECT COLUMN_VALUE
                      FROM TABLE (PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ('ESTADOS_PARA_ACTUALIZACION_DE_EMAIL_TELEFONO')));            
        pmensaje := NULL;
        IF v_EsReprestamo > 0 THEN
            BEGIN
                PR.PR_PKG_REPRESTAMOS.P_ACTUALIZAR_CANAL_REPRESTAMO (
                    :new.cod_persona,
                    :new.cod_area,
                    :new.num_telefono,
                    pmensaje);
            EXCEPTION
                WHEN OTHERS THEN
                    NULL;
            END;
        END IF;
    END IF;
END;
/


CREATE OR REPLACE TRIGGER PA.TEL_PERSONAS_TRG01
   Before Insert Or Update
   On pa.tel_personas
   Referencing New As New Old As Old
   For Each Row
Begin
   If Inserting Then
      :New.incluido_por          := trim(substr(nvl(sys_context('APEX$SESSION','APP_USER'),user),1,10));
      :New.fec_inclusion         := Sysdate;
   Elsif Updating Then
      :New.modificado_por        := trim(substr(nvl(sys_context('APEX$SESSION','APP_USER'),user),1,10));
      :New.fecha_modificacion    := Sysdate;
      If :New.incluido_por != :Old.incluido_por Then
         :New.incluido_por          := :Old.incluido_por;
      End If;
      If :New.fec_inclusion != :Old.fec_inclusion Then
         :New.fec_inclusion         := :Old.fec_inclusion;
      End If;
   End If;
End;
/


CREATE OR REPLACE TRIGGER PA."TELPERSONAS_CLIENTES" 
       after insert or delete or update
       of COD_AREA                         ,
          COD_PERSONA                      ,
          NUM_TELEFONO                     ,
          TEL_UBICACION                    ,
          TIP_TELEFONO
       on PA.TEL_PERSONAS
       referencing new as new old as old
       for each row
declare
      vCodCliente  varchar2(15);
      vNumCliente  number(8);
      esFax        boolean := FALSE;
begin
    if DELETING then
        vCodCliente := :old.cod_persona;
        if :old.tip_telefono = 'F' then --Si es fax
           esFax := TRUE;
        end if;
    else
        vCodCliente := :new.cod_persona;
        if :new.tip_telefono = 'F' then --Si es fax
           esFax := TRUE;
        end if;
    end if;
    if esFax then --Si se trata de un numero de telefono de fax
       if INSERTING then
          BEGIN
             --Verificar si el cliente SI tiene asociado un numero de fax
             select codigo_cliente
             into   vNumCliente
             from   CLIENTES_B2000
             where  cod_cliente = vCodCliente
               and  cod_area is not null;
          EXCEPTION
             --Si el cliente NO tiene asociado un numero fax
             when NO_DATA_FOUND then
                update CLIENTES_B2000
                set    cod_area = :new.cod_area,
                       fax      = :new.num_telefono
                where  cod_cliente    = vCodCliente;
             when OTHERS then
                null;
          END;
      else   --UPDATING or DELETING
           BEGIN
            --Verificar si el cliente tiene asociado ESTE numero de fax
              select codigo_cliente
              into   vNumCliente
              from   CLIENTES_B2000
              where    cod_cliente      = vCodCliente
                and  ((cod_area         = :old.cod_area
                and    fax             = :old.num_telefono)
                or    (cod_area is null));
             if (DELETING) then
                update CLIENTES_B2000
                set    cod_area = null,
                       fax      = null
                where  cod_cliente    = vCodCliente;
             else --UPDATING
                update CLIENTES_B2000
                set   cod_area         = :new.cod_area,
                      fax              = :new.num_telefono
                where  cod_cliente    = vCodCliente;
             end if;
           EXCEPTION
              when OTHERS then
                null;
           END;
      end if;
        if INSERTING then
           update DIRECCIONES_B2000
           set    cod_area_fax  = :new.cod_area,
                  fax           = :new.num_telefono
           where  cod_cliente = :new.cod_persona
             and  cod_area_fax is null;
        elsif DELETING then
           update DIRECCIONES_B2000
           set    cod_area_fax = null,
                  fax          = null
           where  cod_cliente  = :old.cod_persona
             and  cod_area_fax = :old.cod_area
             and  fax          = :old.num_telefono;
        else --UPDATING
           update DIRECCIONES_B2000
           set    cod_area_fax  = :new.cod_area,
                  fax           = :new.num_telefono
           where  cod_cliente  = :old.cod_persona
             and  ((cod_area_fax = :old.cod_area
             and    fax          = :old.num_telefono)
              or   (cod_area_fax is null));
        end if;
     else --Si no es FAX
        if INSERTING then
           update DIRECCIONES_B2000
           set    cod_area_telefono = :new.cod_area,
                  telefonos         = :new.num_telefono,
                  es_de_trabajo     = decode(:new.tel_ubicacion, 'T','S','N')
           where  cod_cliente = :new.cod_persona
             and  cod_area_telefono is null;
        elsif DELETING then
           update DIRECCIONES_B2000
           set    cod_area_telefono = null,
                  telefonos         = null,
                  es_de_trabajo     = null
           where  cod_cliente       = :old.cod_persona
             and  cod_area_telefono = :old.cod_area
             and  telefonos         = :old.num_telefono;
        else --UPDATING
           update DIRECCIONES_B2000
           set    cod_area_telefono = :new.cod_area,
                  telefonos         = :new.num_telefono,
                  es_de_trabajo     = decode(:new.tel_ubicacion, 'T','S','N')
           where  cod_cliente       = :old.cod_persona
             and  ((cod_area_telefono = :old.cod_area
             and    telefonos         = :old.num_telefono)
              or   (cod_area_telefono is null));
        end if;
     end if;
end;
/


CREATE OR REPLACE TRIGGER PA."TRG_ACT_TELEFONOS" 
AFTER UPDATE
OF FECHA_MODIFICACION
ON PA.TEL_PERSONAS 
REFERENCING NEW AS New OLD AS Old
FOR EACH ROW
/******************************************************************************
   NAME:       
   PURPOSE:    

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        4/10/2014      enfrancisco       1. Creacion de Trigger.

   NOTES:

   Automatically available Auto Replace Keywords:
      Object Name:     
      Sysdate:         4/10/2014
      Date and Time:   4/10/2014, 9:32:19 AM, and 4/10/2014 9:32:19 AM
      Username:        enfrancisco (set in TOAD Options, Proc Templates)
      Table Name:      PERSONAS PARA LA VERIFICACION DE LOS CAMBIOS DE TELEFONOS
      Trigger Options:  (set in the "New PL/SQL Object" dialog)
******************************************************************************/
BEGIN
    
    UPDATE PA.PERSONAS
    SET tel_verificado = 'V'
    WHERE COD_PERSONA = :NEW.COD_PERSONA;

   EXCEPTION
     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
       RAISE;
END ;
/


CREATE OR REPLACE TRIGGER PA.TRG_AUDITA_CAMBIO_TEL 
-- OBJETIVO     : Guardar auditoria para MONITOR
-- DESCRIPCION  : Utiliza el procedimiento AUDITA_TRANSACCION para guardar una auditoria
--                en la tabla de MONITOR de los cambios realizados los telefono de las personas.
-- HISTORIA     : aogando 15.02.2008 -- creacion
AFTER
UPDATE OR
DELETE
OF
 COD_AREA
,COD_PERSONA
,NUM_TELEFONO
,TEL_UBICACION
,TIP_TELEFONO
ON PA.TEL_PERSONAS referencing new as new old as old
FOR EACH ROW
DECLARE
vDatosAntes   Varchar2(200) := null;
vDatosDespues Varchar2(200) := null;
vError        Varchar2(500) := null;
vEstCliente   Varchar2(1) := null; --Asigna el valor del estado del cliente
BEGIN
     -- Datos antes de los cambios
     vDatosAntes := substr(ltrim(rtrim( 'COD_PERSONA : '  || :old.COD_PERSONA   ||
                                        ' COD_AREA: '     || :old.COD_AREA      ||
                                        ' NUM_TELEFONO: ' || :old.NUM_TELEFONO  ||
                                        ' TEL_UBICACION: '|| :old.TEL_UBICACION ||
                                        ' TIP_TELEFONO: ' || :old.TIP_TELEFONO)),1,200);
    -- Datos despues de los cambios
    if NOT DELETING then
        vDatosDespues := substr(ltrim(rtrim( 'COD_PERSONA : '  || :old.COD_PERSONA   ||
                                            ' COD_AREA: '     || :new.COD_AREA      ||
                                            ' NUM_TELEFONO: ' || :new.NUM_TELEFONO  ||
                                            ' TEL_UBICACION: '|| :new.TEL_UBICACION ||
                                            ' TIP_TELEFONO: ' || :new.TIP_TELEFONO)),1,200);
    end if;
    -- ------------------------------------------------------------------------ --
    -- Se Busca el estado del cliente de la transaccion para enviarlo a monitor --
    -- RCEBALLOS 13-04-2010 [Proyecto Inactivacion de Clientes]                 --
    -- ------------------------------------------------------------------------ --
    Begin
       Select Estado_Persona
         Into vEstCliente
         From Pa.Personas
        Where Cod_Persona = :old.cod_persona;
    Exception when others then
              Null;
    End;
    --
    PA.AUDITA_TRANSACCION
    (pTipoRegistro     => '3' -- modificacion
    ,pCodSistema       => 'PA'
    ,pOrigenTx         => null
    ,pTipoTx           => null
    ,pSubTipoTx        => null
    ,pFechaTx          => to_char(sysdate, 'YYYYMMDD')
    ,pHoraTx           => to_char(sysdate, 'HH24MISS')
    ,pUsuarioTx        => nvl(sys_context('APEX$SESSION','APP_USER'),user)
    ,pUsuarioMod       => nvl(sys_context('APEX$SESSION','APP_USER'),user)
    ,pUsuarioRev       => null
    ,pUsuarioAut       => null
    ,pFechaMod         => to_char(sysdate,'YYYYMMDD')
    ,pFechaRev         => null
    ,pFechaAut         => null
    ,pAgencia          => null
    ,pReferencia       => null
    ,pNumCuenta        => null
    ,pMontoTx          => null
    ,pMontoEfectivo    => null
    ,pMontoDocumento   => null
    ,pMontoCkPropio    => null
    ,pMontoCkOtros     => null
    ,pReverso          => null
    ,pMonedaTx         => null
    ,pCodCliente       => :old.cod_persona
    ,pNumeroDocumento  => null
    ,pCodCajero        => null
    ,pTasaCambio       => null
    ,pEstadoMovimiento => null
    ,pDescripcionTx    => 'Modificacion de Telefono'
    ,pNumAutorizacion  => null
    ,pNumTarjeta       => null
    ,pDatosAntes       => vDatosAntes
    ,pDatosDespues     => vDatosDespues
    ,pEstadoCliente    => vEstCliente
    );
EXCEPTION
    WHEN OTHERS THEN
       vError    := sqlcode || '>>' || sqlerrm;
       insert into error_bitacora_monitor values(sysdate,vError);
END;
/


CREATE OR REPLACE TRIGGER PA.TRG_NOTIF_DIGITAL_AUDT
Before Update Of   Notif_Digital
On Pa.Tel_Personas
Referencing New As New Old As Old
For Each Row
Begin
                :New.Fecha_Notif_Digital        :=  Sysdate;
                :New.Usuaario_Notif_Digital    := nvl(sys_context('APEX$SESSION','APP_USER'),user);
                
                --- Inserta en Tabla Historica  ---
                Insert Into Tel_Personas_NDigital_H
                (   Cod_Persona         ,
                    Cod_Area                ,
                    Num_Telefono         ,      
                    Notif_Digital              , 
                    Modificado_Por          ,
                    Fecha_Modificacion 
                )
                Values
                (   :New.Cod_Persona         ,
                     :New.Cod_Area                ,
                     :New.Num_Telefono         ,      
                     :New.Notif_Digital              ,
                     nvl(sys_context('APEX$SESSION','APP_USER'),user),
                     Sysdate
                );     
End;
/


CREATE OR REPLACE PUBLIC SYNONYM TEL_PERSONAS FOR PA.TEL_PERSONAS;


ALTER TABLE PA.TEL_PERSONAS ADD (
  CONSTRAINT FK_TELPERSONAS_DIRPERSONAS 
  FOREIGN KEY (COD_PERSONA, COD_DIRECCION) 
  REFERENCES PA.DIR_PERSONAS (COD_PERSONA, COD_DIRECCION)
  ENABLE VALIDATE
,  CONSTRAINT FK_TELPERSONAS_PAIS 
  FOREIGN KEY (COD_PAIS) 
  REFERENCES PA.PAIS (COD_PAIS)
  ENABLE VALIDATE
,  CONSTRAINT FK_TELPERSONAS_PERSONAS 
  FOREIGN KEY (COD_PERSONA) 
  REFERENCES PA.PERSONAS (COD_PERSONA)
  ENABLE VALIDATE);

GRANT SELECT ON PA.TEL_PERSONAS TO B2000TX;

GRANT DELETE, INSERT, SELECT, UPDATE ON PA.TEL_PERSONAS TO BGE;

GRANT ALTER, DELETE, INSERT, SELECT, UPDATE ON PA.TEL_PERSONAS TO BPA;

GRANT ALTER, DELETE, INSERT, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON PA.TEL_PERSONAS TO BPR;

GRANT ALTER, DELETE, INDEX, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON PA.TEL_PERSONAS TO CC;

GRANT ALTER, DELETE, INSERT, SELECT, UPDATE ON PA.TEL_PERSONAS TO CONGEN;

GRANT SELECT ON PA.TEL_PERSONAS TO DY;

GRANT SELECT ON PA.TEL_PERSONAS TO FC;

GRANT SELECT ON PA.TEL_PERSONAS TO IVR;

GRANT ALTER, DELETE, INDEX, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON PA.TEL_PERSONAS TO PR;

GRANT ALTER, DELETE, INDEX, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON PA.TEL_PERSONAS TO PS;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE ON PA.TEL_PERSONAS TO PUBLIC;

GRANT ALTER, DELETE, INDEX, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON PA.TEL_PERSONAS TO RH;

GRANT SELECT ON PA.TEL_PERSONAS TO SB WITH GRANT OPTION;

GRANT SELECT ON PA.TEL_PERSONAS TO SII;
