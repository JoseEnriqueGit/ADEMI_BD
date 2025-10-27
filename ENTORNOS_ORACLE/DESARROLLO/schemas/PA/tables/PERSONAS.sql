
  CREATE TABLE "PA"."PERSONAS" 
   (	"COD_PERSONA" VARCHAR2(15 BYTE), 
	"COD_PER_FISICA" VARCHAR2(15 BYTE), 
	"COD_PER_JURIDICA" VARCHAR2(15 BYTE), 
	"ES_FISICA" VARCHAR2(1 BYTE), 
	"NOMBRE" VARCHAR2(65 BYTE) CONSTRAINT "NN_PERSONAS_NOMBRE" NOT NULL ENABLE, 
	"IND_CLTE_I2000" VARCHAR2(1 BYTE), 
	"PAGA_IMP_LEY288" VARCHAR2(1 BYTE) DEFAULT 'S', 
	"BENEF_PAG_LEY288" VARCHAR2(1 BYTE) DEFAULT 'S', 
	"COD_VINCULACION" VARCHAR2(2 BYTE), 
	"COD_SEC_CONTABLE" VARCHAR2(6 BYTE), 
	"ADICIONADO_POR" VARCHAR2(10 BYTE), 
	"FECHA_ADICION" DATE, 
	"MODIFICADO_POR" VARCHAR2(10 BYTE), 
	"FECHA_MODIFICACION" DATE, 
	"CODIGO_SUSTITUTO" VARCHAR2(15 BYTE), 
	"ESTADO_PERSONA" VARCHAR2(1 BYTE) DEFAULT 'A', 
	"COBR_NODGII_132011" VARCHAR2(1 BYTE) DEFAULT 'S', 
	"LLENO_FATCA" VARCHAR2(1 BYTE), 
	"IMPRIMIO_FATCA" VARCHAR2(1 BYTE), 
	"ES_FATCA" VARCHAR2(1 BYTE), 
	"FEC_ACTUALIZACION" DATE, 
	"TEL_VERIFICADO" VARCHAR2(1 BYTE) DEFAULT 'N', 
	 CONSTRAINT "CK_PERSONAS_ESFISICA" CHECK ( ES_FISICA in ('S','N')             ) ENABLE, 
	 CONSTRAINT "CK_PERSONAS_INDCLTEI2000" CHECK (IND_CLTE_I2000 IN ('S', 'N')) ENABLE, 
	 CONSTRAINT "CK_PERSONAS_BENEFPAGLEY288" CHECK (BENEF_PAG_LEY288 IN ('S', 'N')) ENABLE, 
	 CONSTRAINT "CK_PERSONAS_COBRNODGII" CHECK (COBR_NODGII_132011 IN ('S', 'N')) ENABLE, 
	 CONSTRAINT "CK_PERSONAS_LLENOFATCA" CHECK (LLENO_FATCA IN ('S', 'N')) ENABLE, 
	 CONSTRAINT "CK_PERSONAS_IMPRIMIOFATCA" CHECK (IMPRIMIO_FATCA IN ('S', 'N')) ENABLE, 
	 CONSTRAINT "CK_PERSONAS_ESFATCA" CHECK (ES_FATCA IN ('S', 'N')) ENABLE, 
	 CONSTRAINT "CK_PERSONAS_PAGAIMPLEY288" CHECK (PAGA_IMP_LEY288 IN ('S', 'N')) ENABLE, 
	 CONSTRAINT "CK_ESTADO_PERSONAS" CHECK ("ESTADO_PERSONA"='A' OR "ESTADO_PERSONA"='R' OR "ESTADO_PERSONA"='I' OR "ESTADO_PERSONA"='N') ENABLE, 
	 CONSTRAINT "FK_PERS_PERFISICAS" FOREIGN KEY ("COD_PER_FISICA")
	  REFERENCES "PA"."PERSONAS_FISICAS" ("COD_PER_FISICA") ENABLE, 
	 CONSTRAINT "FK_PERS_PERJURID" FOREIGN KEY ("COD_PER_JURIDICA")
	  REFERENCES "PA"."PERSONAS_JURIDICAS" ("COD_PER_JURIDICA") ENABLE, 
	 CONSTRAINT "FK_PERSONAS_CODVINCULACION" FOREIGN KEY ("COD_VINCULACION")
	  REFERENCES "PA"."TIPOS_VINCULACION" ("COD_VINCULACION") ENABLE
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 80 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 589824 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "DATA_EFD" ;
  CREATE UNIQUE INDEX "PA"."PK_PERSONAS" ON "PA"."PERSONAS" ("COD_PERSONA") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 262144 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "IND_EFD" ;
ALTER TABLE "PA"."PERSONAS" ADD CONSTRAINT "PK_PERSONAS" PRIMARY KEY ("COD_PERSONA")
  USING INDEX "PA"."PK_PERSONAS"  ENABLE;

   COMMENT ON COLUMN "PA"."PERSONAS"."COD_PERSONA" IS 'codigo de persona.';
   COMMENT ON COLUMN "PA"."PERSONAS"."COD_PER_FISICA" IS 'Codigo Identificador si la Persona es Fisica';
   COMMENT ON COLUMN "PA"."PERSONAS"."COD_PER_JURIDICA" IS 'Codigo Identificador si la Persona es Juridica.';
   COMMENT ON COLUMN "PA"."PERSONAS"."ES_FISICA" IS 'Identifica si la persona es Fisica o no. S:Si, N:No.';
   COMMENT ON COLUMN "PA"."PERSONAS"."NOMBRE" IS 'Nombre de la Persona';
   COMMENT ON COLUMN "PA"."PERSONAS"."IND_CLTE_I2000" IS 'Indica si el cliente esta registrado en I2000';
   COMMENT ON COLUMN "PA"."PERSONAS"."PAGA_IMP_LEY288" IS 'Este campo Indica si el cliente paga o no Impuestos.';
   COMMENT ON COLUMN "PA"."PERSONAS"."BENEF_PAG_LEY288" IS 'Indica si la persona obtendra beneficios por ley.';
   COMMENT ON COLUMN "PA"."PERSONAS"."COD_VINCULACION" IS 'Codigo de Vinculacion';
   COMMENT ON COLUMN "PA"."PERSONAS"."COD_SEC_CONTABLE" IS 'Codigo del Sector Contable';
   COMMENT ON COLUMN "PA"."PERSONAS"."ADICIONADO_POR" IS 'Usuario agrego';
   COMMENT ON COLUMN "PA"."PERSONAS"."FECHA_ADICION" IS 'Fecha de adicion';
   COMMENT ON COLUMN "PA"."PERSONAS"."MODIFICADO_POR" IS 'Usuario modifico';
   COMMENT ON COLUMN "PA"."PERSONAS"."FECHA_MODIFICACION" IS 'Fecha de modificacion';
   COMMENT ON COLUMN "PA"."PERSONAS"."CODIGO_SUSTITUTO" IS 'Este campo indica si el Cliente es duplicado, por cual es sustituido.';
   COMMENT ON COLUMN "PA"."PERSONAS"."ESTADO_PERSONA" IS 'Indica el estado de la persona en el sistema [N=Nomina  R=Restringido  o Bloqueado A=Activo]';
   COMMENT ON COLUMN "PA"."PERSONAS"."COBR_NODGII_132011" IS 'Este campo es para el cobro del Descuento del 1% de Interes de la norma de la DGII 13-2011. (S) Se cobra impuesto (N) No se cobra';
   COMMENT ON COLUMN "PA"."PERSONAS"."LLENO_FATCA" IS 'S = si lleno FATCA, N= si no lleno FATCA.';
   COMMENT ON COLUMN "PA"."PERSONAS"."IMPRIMIO_FATCA" IS 'S = si imprimio formulario w9/w8 o si N = No imprimio.';
   COMMENT ON COLUMN "PA"."PERSONAS"."ES_FATCA" IS 'S = si es FATCA o si N = No es FATCA.';
   COMMENT ON COLUMN "PA"."PERSONAS"."FEC_ACTUALIZACION" IS 'La fecha de actualizacion de FATCA';
   COMMENT ON COLUMN "PA"."PERSONAS"."TEL_VERIFICADO" IS 'Telefono verificado para notificaciones, V = verificado, N = No verificado';
   COMMENT ON TABLE "PA"."PERSONAS"  IS ' Esta tabla es utilizada para registrar todas las Persona Fisicas y Juridicas del Sistema';

  CREATE INDEX "PA"."IDX01_PERSONAS" ON "PA"."PERSONAS" (TO_NUMBER("COD_PERSONA"), "ESTADO_PERSONA") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "PA_IDX" ;

  CREATE INDEX "PA"."IDX_COBR_NODGII" ON "PA"."PERSONAS" ("COBR_NODGII_132011", "COD_PER_JURIDICA", "ES_FISICA") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "PA_IND" ;

  CREATE INDEX "PA"."IDX_PERSONAS_NOMBRE" ON "PA"."PERSONAS" ("NOMBRE") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 458752 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "IND_EFD" ;

  CREATE INDEX "PA"."IND_PERSONAS_CODPERFISICA" ON "PA"."PERSONAS" ("COD_PER_FISICA") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 262144 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "IND_EFD" ;

  CREATE INDEX "PA"."IND_PERSONAS_CODPERJURIDICA" ON "PA"."PERSONAS" ("COD_PER_JURIDICA") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "IND_EFD" ;

  CREATE INDEX "PA"."PERSONAS_FK2" ON "PA"."PERSONAS" ("COD_VINCULACION") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "PA_IDX" ;

  CREATE OR REPLACE EDITIONABLE TRIGGER "PA"."AUDITORIA_PERSONAS" 
    BEFORE INSERT OR UPDATE
    ON pa.personas
    REFERENCING NEW AS new OLD AS old
    FOR EACH ROW
BEGIN
    IF (INSERTING)
    THEN
        :new.adicionado_por :=
            NVL (SYS_CONTEXT ('APEX$SESSION', 'APP_USER'), USER);
        :new.fecha_adicion := SYSDATE;

        --09-07-2025 Begin
        IF :new.es_fisica = 'S' AND :new.cod_per_fisica IS NULL
        THEN
            :new.cod_per_fisica := :new.cod_persona;
        END IF;
         --09-07-2025 End

    ELSIF (UPDATING)
    THEN
        :new.modificado_por :=
            NVL (SYS_CONTEXT ('APEX$SESSION', 'APP_USER'), USER);
        :new.fecha_modificacion := SYSDATE;
    END IF;

    -- 14/09/2016  jose diaz - Sysde. por tema de regulatorios.
    IF     (   :new.cod_Sec_contable IS NULL
            OR LENGTH (:new.cod_Sec_contable) = 2)
       AND :new.es_fisica = 'S'
    THEN
        :new.cod_Sec_contable := '030202';
    END IF;
END;
/
ALTER TRIGGER "PA"."AUDITORIA_PERSONAS" ENABLE;

  CREATE OR REPLACE EDITIONABLE TRIGGER "PA"."TRG_CODIGO_SUSTITUTO" 
   after update of codigo_sustituto
   on pa.personas
   referencing new as new old as old
   for each row
declare
   vuser      varchar2 (30);
   vosuser    varchar2 (30);
   vmachine   varchar2 (64);
   vprogram   varchar2 (64);
begin
   -- Identifico Usurio y Terminal que esta realizando el cambio
   begin
      select upper (nvl(sys_context('APEX$SESSION','APP_USER'),user)),
             upper (osuser),
             upper (machine),
             program
        into vuser,
             vosuser,
             vmachine,
             vprogram
        from v$session
       where sid = (select sid
                      from v$mystat
                     where rownum = 1);
   exception
      when others
      then
         vuser := '';
         vosuser := '';
         vmachine := '';
         vprogram := '';
   end;
   vprogram := 'PACAMCLI';
   -- Auditando el Campo COD_CLIENTE_CAMBIO
   begin
      insert into bitacora_maestros
                  (fecha,
                   cuenta,
                   usuario_oracle,
                   usuario_os,
                   terminal,
                   sistema,
                   tabla,
                   campo,
                   valor_anterior,
                   valor_nuevo,
                   programa)
           values (sysdate,
                   :old.cod_persona,
                   vuser,
                   vosuser,
                   vmachine,
                   'PA',
                   'PERSONAS',
                   'COD_PERSONA',
                   :old.cod_persona,
                   :new.codigo_sustituto,
                   vprogram);
   exception
      when others
      then
         raise_application_error (-20502, 'Error en trigger CODIGO_SUSTITUTO_CLIENTE, Favor Revisar.');
   end;
end;
/
ALTER TRIGGER "PA"."TRG_CODIGO_SUSTITUTO" ENABLE;

  CREATE OR REPLACE EDITIONABLE TRIGGER "PA"."PERSONAS_PERS_I2000" 
   after update of ind_clte_i2000
   on pa.personas
   referencing new as new old as old
   for each row
begin
   if :new.ind_clte_i2000 = 'S'
      and nvl (:old.ind_clte_i2000, 'N') = 'N'
   then
      personas_i2000 (:new.cod_persona, null, null, :new.es_fisica, :new.nombre, :new.ind_clte_i2000);
   end if;
end; 



/
ALTER TRIGGER "PA"."PERSONAS_PERS_I2000" ENABLE;

  CREATE OR REPLACE EDITIONABLE TRIGGER "PA"."PERSONAS_NOENTER" 
   before insert or update
   on pa.personas
   referencing new as new old as old
   for each row
-- Efectua: Quita los enter a los nombre
-- Requiere:
-- Hisoria: Eblanco: 10-01-2013: Se colocar por defecto 'S' al cobro de la norma 13 de la DGII
--             a las personas juridicas
begin
   if (inserting)
      or (updating)
   then
      :new.nombre := replace (:new.nombre, chr (13), '');
      :new.nombre := replace (:new.nombre, chr (10), '');
      :new.nombre := replace (:new.nombre, chr (39), '');
      -------------
      -- EBlanco: Se coloca por defecto 'S' para personas juridica.
      if (inserting)
         and nvl (:new.es_fisica, 'S') = 'N'
      then                                                                                                   --Si es juridico
         :new.cobr_nodgii_132011 := 'S';                                                                     --Paga impuesto
      end if;
   -------------
   end if;
end; 



/
ALTER TRIGGER "PA"."PERSONAS_NOENTER" ENABLE;

  CREATE OR REPLACE EDITIONABLE TRIGGER "PA"."ESTADO_CLIENTES" 
   after update
   on pa.personas
   referencing new as new old as old
   for each row
begin
   if :old.estado_persona != :new.estado_persona
   then
      begin
         update cliente
            set estado_cliente = :new.estado_persona
          where cod_cliente = :new.cod_persona;
      end;
      begin
         update clientes_b2000
            set estado_cliente = :new.estado_persona
          where cod_cliente = :new.cod_persona;
      end;
   end if;
end; 



/
ALTER TRIGGER "PA"."ESTADO_CLIENTES" ENABLE;

  CREATE OR REPLACE EDITIONABLE TRIGGER "PA"."TRG_AUD_PERSONAS" 
   after insert or update or delete
   on pa.personas
   for each row
declare
   x   varchar2 (512);
begin
   begin
/*      select program
        into x
        from v$session
       where audsid = (select userenv ('sessionid')
                         from dual);*/
                         
       x:= 'WEBLOGIC';                  
   exception
      when no_data_found
      then
         x := 'PROGRAMA DESCONOCIDO';
      when others
      then
         x := 'PROGRAMA DESCONOCIDO';
   end;
   if inserting
   then
      insert into pa_audit_dml
                  (consecutivo,
                   fyh_movimiento,
                   usuario,
                   tipo_mov,
                   hilera_anterior,
                   hilera_nueva,
                   ip_address,
                   terminal,
                   os_user_name,
                   program_name)
           values (168,
                   systimestamp,
                   nvl(sys_context('APEX$SESSION','APP_USER'),user),
                   'I',
                   null,
                   '|',
                   'WEBLOGIC', -- sys_context ('USERENV', 'IP_ADDRESS'),
                   'WEBLOGIC', --sys_context ('USERENV', 'TERMINAL'),
                   nvl(sys_context('APEX$SESSION','APP_USER'),user), --sys_context ('USERENV', 'OS_USER'),
                   x);
   end if;
   if updating
   then
      insert into pa_audit_dml
                  (consecutivo,
                   fyh_movimiento,
                   usuario,
                   tipo_mov,
                   hilera_anterior,
                   hilera_nueva,
                   ip_address,
                   terminal,
                   os_user_name,
                   program_name)
           values (168,
                   systimestamp,
                   nvl(sys_context('APEX$SESSION','APP_USER'),user),
                   'U',
                   '|',
                   '|',
                   'WEBLOGIC', --sys_context ('USERENV', 'IP_ADDRESS'),
                   nvl(sys_context('APEX$SESSION','APP_USER'),user), --sys_context ('USERENV', 'TERMINAL'),
                   'WEBLOGIC', --sys_context ('USERENV', 'OS_USER'),
                   x);
   end if;
   if deleting
   then
      insert into pa_audit_dml
                  (consecutivo,
                   fyh_movimiento,
                   usuario,
                   tipo_mov,
                   hilera_anterior,
                   hilera_nueva,
                   ip_address,
                   terminal,
                   os_user_name,
                   program_name)
           values (168,
                   systimestamp,
                   nvl(sys_context('APEX$SESSION','APP_USER'),user),
                   'D',
                   '|',
                   null,
                   'WEBLOGIC', --sys_context ('USERENV', 'IP_ADDRESS'),
                   nvl(sys_context('APEX$SESSION','APP_USER'),user), --sys_context ('USERENV', 'TERMINAL'),
                   'WEBLOGIC', --sys_context ('USERENV', 'OS_USER'),
                   x);
   end if;
end;
/
ALTER TRIGGER "PA"."TRG_AUD_PERSONAS" ENABLE;


  GRANT ALTER ON "PA"."PERSONAS" TO "BPR";
  GRANT DELETE ON "PA"."PERSONAS" TO "BPR";
  GRANT INSERT ON "PA"."PERSONAS" TO "BPR";
  GRANT SELECT ON "PA"."PERSONAS" TO "BPR";
  GRANT UPDATE ON "PA"."PERSONAS" TO "BPR";
  GRANT ON COMMIT REFRESH ON "PA"."PERSONAS" TO "BPR";
  GRANT QUERY REWRITE ON "PA"."PERSONAS" TO "BPR";
  GRANT DEBUG ON "PA"."PERSONAS" TO "BPR";
  GRANT FLASHBACK ON "PA"."PERSONAS" TO "BPR";
  GRANT SELECT ON "PA"."PERSONAS" TO "ICUEVAS";
  GRANT SELECT ON "PA"."PERSONAS" TO "TCVERIFFIN";
  GRANT SELECT ON "PA"."PERSONAS" TO "TCVERIFINI";
  GRANT SELECT ON "PA"."PERSONAS" TO "BFERNANDEZ";
  GRANT SELECT ON "PA"."PERSONAS" TO "JSANCHEZ";
  GRANT SELECT ON "PA"."PERSONAS" TO "B2000";
  GRANT SELECT ON "PA"."PERSONAS" TO "DI" WITH GRANT OPTION;
  GRANT REFERENCES ON "PA"."PERSONAS" TO PUBLIC;
  GRANT SELECT ON "PA"."PERSONAS" TO "B2000TX";
  GRANT SELECT ON "PA"."PERSONAS" TO "IVR";
  GRANT SELECT ON "PA"."PERSONAS" TO "DY";
  GRANT SELECT ON "PA"."PERSONAS" TO "CONGEN";
  GRANT SELECT ON "PA"."PERSONAS" TO "BCJ";
  GRANT SELECT ON "PA"."PERSONAS" TO "CJ";
  GRANT SELECT ON "PA"."PERSONAS" TO "MK";
  GRANT ALTER ON "PA"."PERSONAS" TO "CC";
  GRANT DELETE ON "PA"."PERSONAS" TO "CC";
  GRANT INDEX ON "PA"."PERSONAS" TO "CC";
  GRANT INSERT ON "PA"."PERSONAS" TO "CC";
  GRANT SELECT ON "PA"."PERSONAS" TO "CC";
  GRANT UPDATE ON "PA"."PERSONAS" TO "CC";
  GRANT REFERENCES ON "PA"."PERSONAS" TO "CC";
  GRANT ON COMMIT REFRESH ON "PA"."PERSONAS" TO "CC";
  GRANT QUERY REWRITE ON "PA"."PERSONAS" TO "CC";
  GRANT DEBUG ON "PA"."PERSONAS" TO "CC";
  GRANT FLASHBACK ON "PA"."PERSONAS" TO "CC";
  GRANT SELECT ON "PA"."PERSONAS" TO "PR";
  GRANT SELECT ON "PA"."PERSONAS" TO "CD";
  GRANT SELECT ON "PA"."PERSONAS" TO "CG";
  GRANT ALTER ON "PA"."PERSONAS" TO "CL";
  GRANT DELETE ON "PA"."PERSONAS" TO "CL";
  GRANT INDEX ON "PA"."PERSONAS" TO "CL";
  GRANT INSERT ON "PA"."PERSONAS" TO "CL";
  GRANT SELECT ON "PA"."PERSONAS" TO "CL";
  GRANT UPDATE ON "PA"."PERSONAS" TO "CL";
  GRANT REFERENCES ON "PA"."PERSONAS" TO "CL";
  GRANT ON COMMIT REFRESH ON "PA"."PERSONAS" TO "CL";
  GRANT QUERY REWRITE ON "PA"."PERSONAS" TO "CL";
  GRANT DEBUG ON "PA"."PERSONAS" TO "CL";
  GRANT FLASHBACK ON "PA"."PERSONAS" TO "CL";
  GRANT SELECT ON "PA"."PERSONAS" TO "SB";
  GRANT SELECT ON "PA"."PERSONAS" TO "TF";
  GRANT SELECT ON "PA"."PERSONAS" TO "FC";
  GRANT DELETE ON "PA"."PERSONAS" TO "BPA";
  GRANT INSERT ON "PA"."PERSONAS" TO "BPA";
  GRANT SELECT ON "PA"."PERSONAS" TO "BPA";
  GRANT UPDATE ON "PA"."PERSONAS" TO "BPA";
  GRANT ALTER ON "PA"."PERSONAS" TO PUBLIC;
  GRANT DELETE ON "PA"."PERSONAS" TO PUBLIC;
  GRANT INSERT ON "PA"."PERSONAS" TO PUBLIC;
  GRANT SELECT ON "PA"."PERSONAS" TO PUBLIC;
  GRANT UPDATE ON "PA"."PERSONAS" TO PUBLIC;
  GRANT ALTER ON "PA"."PERSONAS" TO "BPA";
  GRANT ALTER ON "PA"."PERSONAS" TO "BCJ";
  GRANT DELETE ON "PA"."PERSONAS" TO "BCJ";
  GRANT INSERT ON "PA"."PERSONAS" TO "BCJ";
  GRANT UPDATE ON "PA"."PERSONAS" TO "BCJ";
  GRANT ALTER ON "PA"."PERSONAS" TO "CONGEN";
  GRANT DELETE ON "PA"."PERSONAS" TO "CONGEN";
  GRANT INSERT ON "PA"."PERSONAS" TO "CONGEN";
  GRANT UPDATE ON "PA"."PERSONAS" TO "CONGEN";
  GRANT SELECT ON "PA"."PERSONAS" TO "ASEGURA";
  GRANT SELECT ON "PA"."PERSONAS" TO "PS";
  GRANT SELECT ON "PA"."PERSONAS" TO "TCAPROBAD1";
  GRANT SELECT ON "PA"."PERSONAS" TO "ICUEVA";
  GRANT SELECT ON "PA"."PERSONAS" TO "JEGARCIA";
  GRANT SELECT ON "PA"."PERSONAS" TO "OCASTRO";
  GRANT SELECT ON "PA"."PERSONAS" TO "TCAPROBAD2";
  GRANT SELECT ON "PA"."PERSONAS" TO "TCDIGITADO";
  GRANT SELECT ON "PA"."PERSONAS" TO "SII";
  GRANT SELECT ON "PA"."PERSONAS" TO "FERMINR";
  GRANT SELECT ON "PA"."PERSONAS" TO "GASANCHEZ";
  GRANT SELECT ON "PA"."PERSONAS" TO "CDG";
