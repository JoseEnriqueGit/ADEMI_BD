
  CREATE TABLE "PA"."PERSONAS_FISICAS" 
   (	"COD_PER_FISICA" VARCHAR2(15 BYTE), 
	"EST_CIVIL" VARCHAR2(1 BYTE), 
	"SEXO" VARCHAR2(1 BYTE) CONSTRAINT "NN_PERS_FIS_SEXO" NOT NULL ENABLE, 
	"FEC_NACIMIENTO" DATE, 
	"PRIMER_APELLIDO" VARCHAR2(25 BYTE) CONSTRAINT "NN_PERSONASFISICAS_PRIAPELLIDO" NOT NULL ENABLE, 
	"SEGUNDO_APELLIDO" VARCHAR2(25 BYTE), 
	"PRIMER_NOMBRE" VARCHAR2(25 BYTE) CONSTRAINT "NN_PERSONASFISICAS_PRINOMBRE" NOT NULL ENABLE, 
	"SEGUNDO_NOMBRE" VARCHAR2(30 BYTE), 
	"PROFESION" VARCHAR2(5 BYTE), 
	"IDIOMA_CORREO" VARCHAR2(4 BYTE), 
	"ES_MAL_DEUDOR" VARCHAR2(1 BYTE), 
	"CONYUGUE" VARCHAR2(15 BYTE), 
	"NACIONALIDAD" VARCHAR2(20 BYTE), 
	"COD_SECTOR" VARCHAR2(3 BYTE), 
	"ESTATAL" VARCHAR2(1 BYTE), 
	"EMAIL_USUARIO" VARCHAR2(80 BYTE), 
	"EMAIL_SERVIDOR" VARCHAR2(30 BYTE), 
	"NIVEL_ESTUDIOS" VARCHAR2(5 BYTE), 
	"TIPO_VIVIENDA" VARCHAR2(5 BYTE), 
	"NUM_HIJOS" NUMBER(3,0) CONSTRAINT "NN_PERS_FIS_NUM_HIJOS" NOT NULL ENABLE, 
	"NUM_DEPENDIENTES" NUMBER(3,0) CONSTRAINT "NN_PERS_FIS_NUM_DEPENDIENTES" NOT NULL ENABLE, 
	"ES_RESIDENTE" VARCHAR2(1 BYTE), 
	"TIEMPO_VIVIEN_ACT" NUMBER(4,0), 
	"EVAL_REF_BANCARIA" VARCHAR2(1 BYTE) CONSTRAINT "NN_PERS_FIS_EVAL_REF_BANCARIA" NOT NULL ENABLE, 
	"EVAL_REF_TARJETAS" VARCHAR2(1 BYTE) CONSTRAINT "NN_PERS_FIS_EVAL_REF_TARJETAS" NOT NULL ENABLE, 
	"EVAL_REF_LABORAL" VARCHAR2(1 BYTE) CONSTRAINT "NN_PERS_FIS_EVAL_REF_LABORAL" NOT NULL ENABLE, 
	"TOTAL_INGRESOS" NUMBER(18,2) CONSTRAINT "NN_PERS_FIS_TOTAL_INGRESOS" NOT NULL ENABLE, 
	"COD_PAIS" VARCHAR2(5 BYTE) CONSTRAINT "NN_PERS_FISICAS_COD_PAIS" NOT NULL ENABLE, 
	"INCLUIDO_POR" VARCHAR2(10 BYTE), 
	"FEC_INCLUSION" DATE CONSTRAINT "NN_PERS_FIS_FEC_INCLUSION" NOT NULL ENABLE, 
	"MODIFICADO_POR" VARCHAR2(10 BYTE), 
	"FEC_MODIFICACION" DATE, 
	"SCORING" NUMBER(6,0), 
	"ACTIVIDAD" VARCHAR2(200 BYTE), 
	"RANGO_INGRESOS" NUMBER(2,0), 
	"CASADA_APELLIDO" VARCHAR2(15 BYTE), 
	"ES_FUNCIONARIO" VARCHAR2(1 BYTE), 
	"ES_PEPS" VARCHAR2(1 BYTE), 
	"COD_ACTIVIDAD" VARCHAR2(6 BYTE), 
	"COD_SUBACTIVIDAD" NUMBER, 
	"TIPO_PERSONA" VARCHAR2(2 BYTE), 
	"TIPO_CLIENTE" NUMBER(18,0), 
	"COD_PAIS_PADRE" VARCHAR2(5 BYTE), 
	"COD_PAIS_MADRE" VARCHAR2(5 BYTE), 
	"COD_PAIS_CONYUGUE" VARCHAR2(5 BYTE), 
	"MAS_180_DIAS_EEUU" VARCHAR2(5 BYTE), 
	"COD_FINALIDAD" VARCHAR2(3 BYTE), 
	"PESO" NUMBER(3,0), 
	"ESTATURA" VARCHAR2(5 BYTE), 
	"ACTIVIDAD_POLIZAH" VARCHAR2(5 BYTE), 
	"DEPORTE_POLIZAH" VARCHAR2(5 BYTE), 
	"PESO_POLIZAH" NUMBER(3,0), 
	"ESTATURA_POLIZAH" VARCHAR2(5 BYTE), 
	"APELLIDO_CASADA" VARCHAR2(25 BYTE), 
	"TERCER_NOMBRE" VARCHAR2(25 BYTE), 
	"TIPO_SOC_CONYUGAL" VARCHAR2(10 BYTE) DEFAULT 'S', 
	"IND_FALLECIMIENTO" VARCHAR2(1 BYTE), 
	"FEC_FALLECIMIENTO" DATE, 
	"GPO_RIESGO" VARCHAR2(5 BYTE), 
	"NUM_EMPLEADOS" NUMBER(10,0), 
	"VENTAS_INGRESOS" NUMBER(22,2), 
	"CP_TOTAL_ACTIVO" NUMBER(22,2), 
	"IND_CLTE_VIP" VARCHAR2(1 BYTE), 
	"TIPO_GEN_DIVISAS" VARCHAR2(2 BYTE), 
	"OCUPACION_CLASIF_NAC" VARCHAR2(5 BYTE), 
	 CONSTRAINT "CK_PERS_FIS_EVAL_REF_TARJETAS" CHECK ( EVAL_REF_TARJETAS IN ('V','I','M','N','R')             ) ENABLE, 
	 CONSTRAINT "CK_PERSONASFISICAS_ESMALDEUDOR" CHECK ( ES_MAL_DEUDOR in ('S','N')             ) ENABLE, 
	 CONSTRAINT "CK_PERSONASFISICAS_ESTCIVIL" CHECK ( EST_CIVIL in ('S','V','D','C','U','O')             ) ENABLE, 
	 CONSTRAINT "CK_PERFIS_ESFUNCIONARIO" CHECK (ES_FUNCIONARIO IN ('S', 'N')) ENABLE, 
	 CONSTRAINT "CK_PERFIS_ESPEPS" CHECK (ES_PEPS IN ('S', 'N')) ENABLE, 
	 CONSTRAINT "CK_PERSFISICA_TIPSOCONY" CHECK (tipo_soc_conyugal IN ('S','C')) ENABLE, 
	 CONSTRAINT "CK_PERS_FIS_ES_RESIDENTE" CHECK ( ES_RESIDENTE IN ('S','N')             ) ENABLE, 
	 CONSTRAINT "CK_PERSONASFISICAS_SEXO" CHECK ( SEXO in ('F','M')             ) ENABLE, 
	 CONSTRAINT "CK_PERS_FIS_EVAL_REF_BANCARIA" CHECK ( EVAL_REF_BANCARIA IN ('V','I','M','N','R')             ) ENABLE, 
	 CONSTRAINT "CK_PERS_FIS_EVAL_REF_LABORAL" CHECK ( EVAL_REF_LABORAL IN ('C','D','E')             ) ENABLE, 
	 CONSTRAINT "FK_PERSONASFISICAS_IDIOMAS" FOREIGN KEY ("IDIOMA_CORREO")
	  REFERENCES "PA"."IDIOMAS" ("COD_IDIOMA") ENABLE, 
	 CONSTRAINT "FK_PERS_FIS_CAT_PROFESIONES" FOREIGN KEY ("PROFESION")
	  REFERENCES "PA"."CAT_PROFESIONES" ("COD_PROFESION") ENABLE, 
	 CONSTRAINT "FK_PERS_FIS_NIVEL_ESTUDIOS" FOREIGN KEY ("NIVEL_ESTUDIOS")
	  REFERENCES "PA"."NIVEL_ESTUDIOS" ("COD_NIVEL") ENABLE, 
	 CONSTRAINT "FK_PERS_FIS_TIPOS_VIVIENDA" FOREIGN KEY ("TIPO_VIVIENDA")
	  REFERENCES "PA"."TIPOS_VIVIENDA" ("TIPO_VIVIENDA") ENABLE, 
	 CONSTRAINT "FK_PERS_FIS_PERSONAS_FISICAS" FOREIGN KEY ("CONYUGUE")
	  REFERENCES "PA"."PERSONAS_FISICAS" ("COD_PER_FISICA") ENABLE, 
	 CONSTRAINT "FK_PERFIS_FINALIDAD" FOREIGN KEY ("COD_FINALIDAD")
	  REFERENCES "PA"."FINALIDAD_PERSONAS" ("COD_FINALIDAD") ENABLE, 
	 CONSTRAINT "FK_PERFIS_TIPOPERSONA" FOREIGN KEY ("TIPO_PERSONA")
	  REFERENCES "PA"."TIPO_PERSONA" ("CODIGO") ENABLE, 
	 CONSTRAINT "FK_PERFIS_TIPOCLIENTE" FOREIGN KEY ("TIPO_CLIENTE")
	  REFERENCES "PA"."TIPO_CLIENTE" ("CODIGO") ENABLE, 
	 CONSTRAINT "FK_PERFIS_PAIS" FOREIGN KEY ("COD_PAIS")
	  REFERENCES "PA"."PAIS" ("COD_PAIS") ENABLE, 
	 CONSTRAINT "FK_PERFIS_PAIS_CONYU" FOREIGN KEY ("COD_PAIS_CONYUGUE")
	  REFERENCES "PA"."PAIS" ("COD_PAIS") ENABLE, 
	 CONSTRAINT "FK_PERFIS_PAIS_MADRE" FOREIGN KEY ("COD_PAIS_MADRE")
	  REFERENCES "PA"."PAIS" ("COD_PAIS") ENABLE, 
	 CONSTRAINT "FK_PERFIS_PAIS_PADRE" FOREIGN KEY ("COD_PAIS_PADRE")
	  REFERENCES "PA"."PAIS" ("COD_PAIS") ENABLE
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 80 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 1048576 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "DATA_EFD" ;
  CREATE UNIQUE INDEX "PA"."PK_PERSONASFISICAS" ON "PA"."PERSONAS_FISICAS" ("COD_PER_FISICA") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 262144 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "IND_EFD" ;
ALTER TABLE "PA"."PERSONAS_FISICAS" ADD CONSTRAINT "PK_PERSONASFISICAS" PRIMARY KEY ("COD_PER_FISICA")
  USING INDEX "PA"."PK_PERSONASFISICAS"  ENABLE;

   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."COD_PER_FISICA" IS 'Codigo Identificador Persona Fisica';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."EST_CIVIL" IS 'Estado Civil de la Persona. C:Casado, S:Soltero';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."SEXO" IS 'Sexo de la persona. M:Masculino, F:Femenino';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."FEC_NACIMIENTO" IS 'Fecha de Nacimiento';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."PRIMER_APELLIDO" IS 'Tipo de Cliente.';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."SEGUNDO_APELLIDO" IS 'Descripcion Segundo Apellido.';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."PRIMER_NOMBRE" IS 'Descripcion del Primer Nombre de la Persona';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."SEGUNDO_NOMBRE" IS 'Descripcion del Segundo Nombre de la Persona';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."PROFESION" IS 'Codigo de la Profesion que ejerce.';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."IDIOMA_CORREO" IS 'Idioma del Corre';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."ES_MAL_DEUDOR" IS 'Indica si la Persona es Mal Deudor o No. S:Si, N:No.';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."CONYUGUE" IS 'Codigo Identificador del Coyugue .';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."NACIONALIDAD" IS 'Descripcion de la Nacionalidad de la Persona';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."COD_SECTOR" IS 'Codigo de sector';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."ESTATAL" IS 'Codigo del Sector Contable al que pertenece la Persona.';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."EMAIL_USUARIO" IS 'Email usuario';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."EMAIL_SERVIDOR" IS 'Descripcion del Email del Servidor.';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."NIVEL_ESTUDIOS" IS 'Codigo que identifica el tipo de Nivel de Estudios de la Persona. U:Universitario, MA:Maestria, P:';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."TIPO_VIVIENDA" IS 'Codigo del Tipo de Vivienda.';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."NUM_HIJOS" IS 'Cantidad de Hijos';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."NUM_DEPENDIENTES" IS 'Cantidad de personas dependientes';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."ES_RESIDENTE" IS 'Indica si es Residente o no. S:Si, N:No.';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."TIEMPO_VIVIEN_ACT" IS 'Indica la cantidad de tiempo viviendo es su residencia actual.';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."EVAL_REF_BANCARIA" IS 'Evaluar Referencia Bancaria';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."EVAL_REF_TARJETAS" IS 'Evaluacion Referencia Tarjetas';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."EVAL_REF_LABORAL" IS 'Evaluacion Referencia Laboral';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."TOTAL_INGRESOS" IS 'Total de Ingeresos de la Persona';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."COD_PAIS" IS 'Codigo del pais';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."INCLUIDO_POR" IS 'Usuario incluyo';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."FEC_INCLUSION" IS 'Fecha de inclusion';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."MODIFICADO_POR" IS 'Usuario modifico';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."FEC_MODIFICACION" IS 'Fecha de modificacion';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."SCORING" IS 'Codigo del Scoring de la Persona';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."ACTIVIDAD" IS 'Descripcion de la Actividad a la que se dedica la persona';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."RANGO_INGRESOS" IS 'Rango de Ingresos Anuales';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."CASADA_APELLIDO" IS 'Apellido de Casada de la Persona';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."ES_FUNCIONARIO" IS 'Almacena S si el cliente es o ha sido funcionario de gobierno';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."ES_PEPS" IS 'Almacena S si el cliente es PEP';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."COD_ACTIVIDAD" IS 'Codigo de activdad';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."COD_SUBACTIVIDAD" IS 'Codigo de SubActividad a la que pertenece la Persona.';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."TIPO_PERSONA" IS 'Es el Tipo de Persona que le corresponde dependiendo de la combinacioin que reuna segun los nuevos requerimientos de la SIB 06-06-2012.';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."TIPO_CLIENTE" IS 'Tipo de Cliente para la Persona Segun la tabla de Tipo de Persona de la SIB.';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."COD_PAIS_PADRE" IS 'Identifica el pais de nacionalidad del padre del cliente';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."COD_PAIS_MADRE" IS 'Identifica el pais de nacionalidad de la madre del cliente';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."COD_PAIS_CONYUGUE" IS 'Identifica el pais de nacionalidad del conyugue del cliente';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."MAS_180_DIAS_EEUU" IS 'identifica si el cliente ha estado mas de 180 dias en Estados Unidos si este no es norteamericano';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."COD_FINALIDAD" IS 'Finalidad de persona en la tabla de personas fisicas y FK a la tabla de catalogo';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."PESO" IS 'Tabla que almacena el paso de la persona.';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."ESTATURA" IS 'Tabla que almacena la estatura de la persona.';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."ACTIVIDAD_POLIZAH" IS 'Codigo de la Actividad a la que se dedica la persona para informar en la Poliza.';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."DEPORTE_POLIZAH" IS 'Codigo de deporte para informar en la poliza.';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."PESO_POLIZAH" IS 'Peso de la persona';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."ESTATURA_POLIZAH" IS 'Estatura de la Persona';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."APELLIDO_CASADA" IS 'Apellido de casada';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."TERCER_NOMBRE" IS 'Tercer nombre';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."TIPO_SOC_CONYUGAL" IS 'Tipo de sociedad conyugal con separacion de bienes : No (S), Si (C)';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."IND_FALLECIMIENTO" IS 'Indicador de fecha de fallecimiento, es usado para activar el campo de Fecha de Fallecimiento, tiene como valor S o N';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."FEC_FALLECIMIENTO" IS 'Fecha de fallecimiento, es usado para activar el campo de Fecha de Fallecimiento';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."NUM_EMPLEADOS" IS 'Número de empleados';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."VENTAS_INGRESOS" IS 'Ventas por ingresos';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."CP_TOTAL_ACTIVO" IS 'Capital Total';
   COMMENT ON COLUMN "PA"."PERSONAS_FISICAS"."IND_CLTE_VIP" IS 'Indica si el cliente es vip';
   COMMENT ON TABLE "PA"."PERSONAS_FISICAS"  IS ' Tabla utilizada para Registrar todas las personas de tipo Fisica del Sistema';

  CREATE INDEX "PA"."IDX_PERFIS_NOMCOMPLETO" ON "PA"."PERSONAS_FISICAS" ("PRIMER_APELLIDO", "SEGUNDO_APELLIDO", "PRIMER_NOMBRE", "SEGUNDO_NOMBRE") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 393216 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "IND_EFD" ;

  CREATE INDEX "PA"."IND_PERFISI_INCLUIDOPOR" ON "PA"."PERSONAS_FISICAS" ("INCLUIDO_POR") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 262144 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "IND_EFD" ;

  CREATE INDEX "PA"."IND_PERFISI_MODIFICAPOR" ON "PA"."PERSONAS_FISICAS" ("MODIFICADO_POR") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 196608 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "IND_EFD" ;

  CREATE INDEX "PA"."IND_PERSONASFISICAS_CONYUGUE" ON "PA"."PERSONAS_FISICAS" ("CONYUGUE") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "IND_EFD" ;

  CREATE INDEX "PA"."PERSONAS_FISICAS_FK1" ON "PA"."PERSONAS_FISICAS" ("NIVEL_ESTUDIOS") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "PA_IND" ;

  CREATE INDEX "PA"."PERSONAS_FISICAS_FK10" ON "PA"."PERSONAS_FISICAS" ("PROFESION") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "PA_IND" ;

  CREATE INDEX "PA"."PERSONAS_FISICAS_FK11" ON "PA"."PERSONAS_FISICAS" ("IDIOMA_CORREO") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "PA_IND" ;

  CREATE INDEX "PA"."PERSONAS_FISICAS_FK2" ON "PA"."PERSONAS_FISICAS" ("TIPO_PERSONA") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "PA_IND" ;

  CREATE INDEX "PA"."PERSONAS_FISICAS_FK3" ON "PA"."PERSONAS_FISICAS" ("TIPO_CLIENTE") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "PA_IND" ;

  CREATE INDEX "PA"."PERSONAS_FISICAS_FK4" ON "PA"."PERSONAS_FISICAS" ("COD_PAIS_PADRE") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "PA_IND" ;

  CREATE INDEX "PA"."PERSONAS_FISICAS_FK5" ON "PA"."PERSONAS_FISICAS" ("COD_PAIS") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "PA_IND" ;

  CREATE INDEX "PA"."PERSONAS_FISICAS_FK6" ON "PA"."PERSONAS_FISICAS" ("COD_PAIS_MADRE") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "PA_IND" ;

  CREATE INDEX "PA"."PERSONAS_FISICAS_FK7" ON "PA"."PERSONAS_FISICAS" ("COD_PAIS_CONYUGUE") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "PA_IND" ;

  CREATE INDEX "PA"."PERSONAS_FISICAS_FK8" ON "PA"."PERSONAS_FISICAS" ("TIPO_VIVIENDA") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "PA_IND" ;

  CREATE INDEX "PA"."PERSONAS_FISICAS_FK9" ON "PA"."PERSONAS_FISICAS" ("COD_FINALIDAD") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "PA_IND" ;

  CREATE OR REPLACE EDITIONABLE TRIGGER "PA"."ACTUALIZA_FEC_ING_PER_FIS" 
BEFORE UPDATE
ON PA.PERSONAS_FISICAS REFERENCING NEW AS New OLD AS Old
FOR EACH ROW
DECLARE
BEGIN

   IF (UPDATING) THEN
      IF NVL(:OLD.RANGO_INGRESOS,0) != NVL(:NEW.RANGO_INGRESOS,0) THEN
         Begin
            Update pa.cliente
               Set FEC_ACTUALIZA_INGRESOS = TRUNC(SYSDATE)
             Where cod_cliente = :new.cod_per_fisica;
         End;
      END IF;
   END IF;

   EXCEPTION
     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
       RAISE;
END ACTUALIZA_FEC_ING_PER_FIS; 





/
ALTER TRIGGER "PA"."ACTUALIZA_FEC_ING_PER_FIS" ENABLE;

  CREATE OR REPLACE EDITIONABLE TRIGGER "PA"."PERFISICAS_CLTES_PERSONAS" 
   After Update Of cod_per_fisica,
                   cod_sector,
                   est_civil,
                   fec_nacimiento,
                   idioma_correo,
                   primer_apellido,
                   primer_nombre,
                   segundo_apellido,
                   segundo_nombre,
                   sexo,
                   cod_pais   -- aogando 14.05.2008
   On pa.personas_fisicas
   Referencing New As New Old As Old
   For Each Row
Declare
   Cursor contactos(
      pcodcontacto                        Varchar2 ) Is
      Select cod_cliente,
             codigo_empresa
        From clientes_b2000
       Where cod_contacto = pcodcontacto;
   nombre                        Varchar2( 80 );
Begin
   --Verifica si cambio el nombre de la persona
   If    Nvl( :Old.primer_nombre, Chr( 1 )) != Nvl( :New.primer_nombre, Chr( 1 ))
      Or Nvl( :Old.primer_apellido, Chr( 1 )) != Nvl( :New.primer_apellido, Chr( 1 ))
      Or Nvl( :Old.segundo_nombre, Chr( 1 )) != Nvl( :New.segundo_nombre, Chr( 1 ))
      Or Nvl( :Old.segundo_apellido, Chr( 1 )) != Nvl( :New.segundo_apellido, Chr( 1 )) Then
      Update personas
         Set nombre =
                   :New.primer_nombre
                || ' '
                || :New.segundo_nombre
                || ' '
                || :New.primer_apellido
                || ' '
                || :New.segundo_apellido
       Where cod_persona = :New.cod_per_fisica;
      --Actualizacio del nombre del contacto
      For c In contactos( :New.cod_per_fisica ) Loop
         nombre                     :=
            Substr(    :New.primer_nombre
                    || ' '
                    || :New.segundo_nombre
                    || ' '
                    || :New.primer_apellido
                    || ' '
                    || :New.segundo_apellido,
                    1, 40 );
         Update clientes_b2000
            Set persona_a_contactar = nombre,
                representante_legal = nombre
          Where cod_cliente = c.cod_cliente
            And codigo_empresa = c.codigo_empresa;
      End Loop;
   End If;
   Update clientes_b2000
      Set idioma_correspondencia = Decode( :New.idioma_correo, 'ESPA', '1', '2' ),
          codigo_actividad_economica = To_number( :New.cod_sector ),
          nombres = Substr( :New.primer_nombre || ' ' || :New.segundo_nombre, 1, 30 ),
          primer_apellido = :New.primer_apellido,
          segundo_apellido = :New.segundo_apellido,
          estado_civil = :New.est_civil,
          sexo = :New.sexo,
          fecha_de_nacimiento = :New.fec_nacimiento,
          codigo_pais = :New.cod_pais   -- aogando -- 14.05.2008
    Where cod_cliente = :New.cod_per_fisica;
End; 



/
ALTER TRIGGER "PA"."PERFISICAS_CLTES_PERSONAS" ENABLE;

  CREATE OR REPLACE EDITIONABLE TRIGGER "PA"."EMAIL_NOTIFICACION_X_PERFIS" 
   before update
   on pa.personas_fisicas
   referencing new as new old as old
   for each row
declare
  -- 18-Apr-2023  Change bsc.com.do by bancoademi.com.do
   vdummy          boolean        := false;
   vservidorsmtp   varchar2 (150)
                   := param.parametro_x_empresa (param.parametro_general ('COD_EMPRESA_BANCO', 'PA'), 'SERVIDOR_SMTP', 'PA');
   vremitente      varchar2 (100) := 'NotificacionDB@bancoademi.com.do'; --bsc.com.do
   vreceptor       varchar2 (150)
                    := param.parametro_x_empresa (param.parametro_general ('COD_EMPRESA_BANCO', 'PA'), 'CORREO_SEGIT', 'PA');
   vtitulo         varchar2 (200) := null;
   vmensaje        varchar2 (400) := null;
   --
   vagenciausu     varchar2 (5)   := null;
   vnombreusu      varchar2 (500) := null;
begin
   vmensaje :=
         'Se han realizado los siguientes cambios en la cuenta de correo del cliente '
      || :old.cod_per_fisica
      || ' '
      || initcap (obt_nombre_persona (:old.cod_per_fisica))
      || chr (10)
      || chr (10);
   if (nvl (:old.email_servidor, ' ') != nvl (:new.email_servidor, ' '))
   then
      vdummy := true;
      vmensaje := vmensaje || nvl (:old.email_servidor, ' ') || ' ==> ' || nvl (:new.email_servidor, ' ') || chr (10);
   end if;
   if (nvl (:old.email_usuario, ' ') != nvl (:new.email_usuario, ' '))
   then
      vdummy := true;
      vmensaje := vmensaje || nvl (:old.email_usuario, ' ') || ' ==> ' || nvl (:new.email_usuario, ' ') || chr (10);
   end if;
   begin
      select cod_agencia_dflt,
             obt_nombre_persona (cod_per_fisica) nombre_usuario
        into vagenciausu,
             vnombreusu
        from usuarios
       where cod_usuario = user;
   exception
      when others
      then
         null;
   end;
   vtitulo := 'Se ha Realizado un cambio de correo cliente: ' || :old.cod_per_fisica;
   if vdummy
   then
      vmensaje := vmensaje || chr (10) || 'Modificacion realizada por: ' || chr (10);
      vmensaje := vmensaje || 'Usuario: ' || user || chr (10);
      vmensaje := vmensaje || 'Nombre: ' || vnombreusu || chr (10);
      vmensaje := vmensaje || 'Agencia: ' || vagenciausu || chr (10);
      vmensaje := vmensaje || 'Fecha: ' || to_char (sysdate, 'dd/mm/yyyy hh:mi:ss am');
      --
      vmensaje := vmensaje || chr (10) || chr (10) || 'Este mensaje es por notificacion no responder al remitente.';
      --
      -- Jsanchez (22/12/2015)
      -- Se comenta ejecución de envío de correo por error de permisos 
      -- send_mail (vservidorsmtp, vremitente, vreceptor, vtitulo, vmensaje);
   end if;
end;
/
ALTER TRIGGER "PA"."EMAIL_NOTIFICACION_X_PERFIS" ENABLE;

  CREATE OR REPLACE EDITIONABLE TRIGGER "PA"."PERSONAS_FISICAS_NOENTER" 
/*
Modificación:  Iván Bergés
Funcionalidad: Evitar la mala inserción de los correos de los usuarios
               utilizando la función Email_Validacion.
Fecha:         20/10/2021
*/
     before insert or update
       on PA.PERSONAS_FISICAS
       referencing new as new old as old
       for each row
BEGIN
  if (inserting) or (updating) then
    :new.primer_nombre := replace(:new.primer_nombre, chr(13), '');
    :new.primer_nombre := replace(:new.primer_nombre, chr(10), '');
    :new.primer_nombre := replace(:new.primer_nombre, chr(39), '');

    :new.segundo_nombre := replace(:new.segundo_nombre, chr(13), '');
    :new.segundo_nombre := replace(:new.segundo_nombre, chr(10), '');
    :new.segundo_nombre := replace(:new.segundo_nombre, chr(39), '');

    :new.primer_apellido := replace(:new.primer_apellido, chr(13), '');
    :new.primer_apellido := replace(:new.primer_apellido, chr(10), '');
    :new.primer_apellido := replace(:new.primer_apellido, chr(39), '');


    :new.segundo_apellido := replace(:new.segundo_apellido, chr(13), '');
    :new.segundo_apellido := replace(:new.segundo_apellido, chr(10), '');
    :new.segundo_apellido := replace(:new.segundo_apellido, chr(39), '');
        --
        -- Cuando el correo a insertar (EMAIL_USUARIO) es inválido, intenta 
        -- obtener uno válido a través de la función Email_Validacion.
        -- Primero se válida el campo EMAIL_USUARIO y si no funciona se valida
        -- el campo EMAIL_USUARIO || EMAIL_SERVIDOR.
        :new.email_usuario := NVL(Email_Validacion(:new.email_usuario), Email_Validacion(:new.email_usuario||:new.email_servidor));
        --
        -- Siempre anula el campo EMAIL_SERVIDOR después de corregir el campo
        -- EMAIL_USUARIO. Esto es para evitar concatenaciones innecesarias entre
        -- ambos campos.
        --        
        :new.email_servidor := null; 
        
        --malmanzar 14-02-2023 req. 644 Begin
        if :new.cod_finalidad is null then
           :new.cod_finalidad := '011';
        end if;
        --malmanzar 14-02-2023 req. 644 End
        
    end if;
END;
/
ALTER TRIGGER "PA"."PERSONAS_FISICAS_NOENTER" ENABLE;

  CREATE OR REPLACE EDITIONABLE TRIGGER "SROBLES"."PR_EMAIL_REPRESTAMOS" 
AFTER INSERT OR UPDATE
OF EMAIL_USUARIO
ON PA.PERSONAS_FISICAS
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE
    pMensaje         VARCHAR2 (32767);
    v_EsReprestamo   PLS_INTEGER := 0;
BEGIN
    -- Verificar si es de represtamo
    SELECT COUNT (1)
      INTO v_EsReprestamo
      FROM PR.PR_REPRESTAMOS RE
     WHERE RE.CODIGO_CLIENTE = :NEW.COD_PER_FISICA
       AND RE.ESTADO IN
                   (SELECT COLUMN_VALUE
                      FROM TABLE (PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ('ESTADOS_ACTUALIZAR_CANAL_REPRESTAMO')))
       OR RE.ESTADO IN (SELECT COLUMN_VALUE
                      FROM TABLE (PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ('ESTADOS_PARA_ACTUALIZACION_DE_EMAIL_TELEFONO')));
 
    pMensaje := NULL;
 
    IF v_EsReprestamo > 0 THEN
       BEGIN
        PR.PR_PKG_REPRESTAMOS.P_ACTUALIZAR_EMAIL_REPRESTAMO (
            :NEW.COD_PER_FISICA,
            :NEW.EMAIL_USUARIO,
            pMensaje);
                        EXCEPTION
                WHEN OTHERS THEN
                    NULL;
            END;
    END IF;
END;
/
ALTER TRIGGER "SROBLES"."PR_EMAIL_REPRESTAMOS" ENABLE;

  CREATE OR REPLACE EDITIONABLE TRIGGER "PA"."TRG_AIU_AUDIT_PERSONAS_FISICAS" 
   after INSERT OR update of cod_actividad
   on pa.personas_fisicas
   referencing new as new old as old
   for each row
declare
   vuser      varchar2 (30);
   vosuser    varchar2 (30);
   vmachine   varchar2 (64);
   vprogram   varchar2 (64);
begin
    begin
              select upper (user),
                     upper (osuser),
                     upper (machine),
                     module
                into vuser,
                     vosuser,
                     vmachine,
                     vprogram
                from v$session
               where sid = SYS_CONTEXT('USERENV','SID');
--               (select sid
--                              from v$mystat
--                             where rownum = 1);
           exception
              when others
              then
                 vuser := '';
                 vosuser := '';
                 vmachine := '';
                 vprogram := '';
           end;
          -- vprogram := 'PACAMCIU';
   IF f_Existe_CIIU(:new.cod_actividad) = 'S' THEN
       --
       IF nvl(:old.cod_actividad,'x')!=nvl(:new.cod_actividad,'x') THEN
           -- Identifico Usurio y Terminal que esta realizando el cambio
          
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
                           :new.cod_per_fisica,
                           vuser,
                           vosuser,
                           vmachine,
                           'PA',
                           'PERSONAS_FISICAS',
                           'COD_ACTIVIDAD',
                           :old.cod_actividad,
                           :new.cod_actividad,
                           vprogram);
           exception
              when others
              then
                 null;--raise_application_error (-20502, sqlerrm||'Error en trigger TRG_AIU_AUDIT_personas_fisicas.');
           end;
       END IF;
       -- Si actualiza el género (SEXO)
       IF nvl(:old.sexo,'x')!=nvl(:new.sexo,'x') THEN
           -- Auditando el Campo SEXO
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
                           :new.cod_per_fisica,
                           vuser,
                           vosuser,
                           vmachine,
                           'PA',
                           'PERSONAS_FISICAS',
                           'SEXO',
                           :old.SEXO,
                           :new.SEXO,
                           vprogram);
           exception
              when others
              then
                 null;--raise_application_error (-20502, sqlerrm||'Error en trigger TRG_AIU_AUDIT_personas_fisicas.');
           end;
       end if;
   ELSE
     f_log_procesoRR('PERSONAS_FISICA.COD_ACTIVIDAD','COD_PERSONA:'||:new.cod_per_fisica||' - vosuser:'||vosuser||' - vmachine:'||vmachine||' - cod_actividad(CIIU)'||:new.cod_actividad   ); 
     RAISE_application_error(-20001,'Código de actividad Económica(CIIU) {'||:new.cod_actividad ||'} No existe en la tabla PA.ACTIVIDADES_ECONOMICAS_BC_CIIU.');
   END IF;
end;
/
ALTER TRIGGER "PA"."TRG_AIU_AUDIT_PERSONAS_FISICAS" ENABLE;


  GRANT SELECT ON "PA"."PERSONAS_FISICAS" TO "B2000";
  GRANT REFERENCES ON "PA"."PERSONAS_FISICAS" TO PUBLIC;
  GRANT SELECT ON "PA"."PERSONAS_FISICAS" TO "B2000TX";
  GRANT SELECT ON "PA"."PERSONAS_FISICAS" TO "IVR";
  GRANT SELECT ON "PA"."PERSONAS_FISICAS" TO "DY";
  GRANT SELECT ON "PA"."PERSONAS_FISICAS" TO "CONGEN";
  GRANT ALTER ON "PA"."PERSONAS_FISICAS" TO "MK";
  GRANT DELETE ON "PA"."PERSONAS_FISICAS" TO "MK";
  GRANT INDEX ON "PA"."PERSONAS_FISICAS" TO "MK";
  GRANT INSERT ON "PA"."PERSONAS_FISICAS" TO "MK";
  GRANT SELECT ON "PA"."PERSONAS_FISICAS" TO "MK";
  GRANT UPDATE ON "PA"."PERSONAS_FISICAS" TO "MK";
  GRANT REFERENCES ON "PA"."PERSONAS_FISICAS" TO "MK";
  GRANT SELECT ON "PA"."PERSONAS_FISICAS" TO "CC";
  GRANT ALTER ON "PA"."PERSONAS_FISICAS" TO "PR";
  GRANT DELETE ON "PA"."PERSONAS_FISICAS" TO "PR";
  GRANT INDEX ON "PA"."PERSONAS_FISICAS" TO "PR";
  GRANT INSERT ON "PA"."PERSONAS_FISICAS" TO "PR";
  GRANT SELECT ON "PA"."PERSONAS_FISICAS" TO "PR";
  GRANT UPDATE ON "PA"."PERSONAS_FISICAS" TO "PR";
  GRANT REFERENCES ON "PA"."PERSONAS_FISICAS" TO "PR";
  GRANT ON COMMIT REFRESH ON "PA"."PERSONAS_FISICAS" TO "PR";
  GRANT QUERY REWRITE ON "PA"."PERSONAS_FISICAS" TO "PR";
  GRANT DEBUG ON "PA"."PERSONAS_FISICAS" TO "PR";
  GRANT FLASHBACK ON "PA"."PERSONAS_FISICAS" TO "PR";
  GRANT SELECT ON "PA"."PERSONAS_FISICAS" TO "CD";
  GRANT SELECT ON "PA"."PERSONAS_FISICAS" TO "SB";
  GRANT REFERENCES ON "PA"."PERSONAS_FISICAS" TO "SB";
  GRANT SELECT ON "PA"."PERSONAS_FISICAS" TO "TF";
  GRANT SELECT ON "PA"."PERSONAS_FISICAS" TO "FC";
  GRANT ALTER ON "PA"."PERSONAS_FISICAS" TO "RH";
  GRANT DELETE ON "PA"."PERSONAS_FISICAS" TO "RH";
  GRANT INDEX ON "PA"."PERSONAS_FISICAS" TO "RH";
  GRANT INSERT ON "PA"."PERSONAS_FISICAS" TO "RH";
  GRANT SELECT ON "PA"."PERSONAS_FISICAS" TO "RH";
  GRANT UPDATE ON "PA"."PERSONAS_FISICAS" TO "RH";
  GRANT REFERENCES ON "PA"."PERSONAS_FISICAS" TO "RH";
  GRANT ON COMMIT REFRESH ON "PA"."PERSONAS_FISICAS" TO "RH";
  GRANT QUERY REWRITE ON "PA"."PERSONAS_FISICAS" TO "RH";
  GRANT DEBUG ON "PA"."PERSONAS_FISICAS" TO "RH";
  GRANT FLASHBACK ON "PA"."PERSONAS_FISICAS" TO "RH";
  GRANT DELETE ON "PA"."PERSONAS_FISICAS" TO "BPA";
  GRANT INSERT ON "PA"."PERSONAS_FISICAS" TO "BPA";
  GRANT SELECT ON "PA"."PERSONAS_FISICAS" TO "BPA";
  GRANT UPDATE ON "PA"."PERSONAS_FISICAS" TO "BPA";
  GRANT ALTER ON "PA"."PERSONAS_FISICAS" TO "CONGEN";
  GRANT DELETE ON "PA"."PERSONAS_FISICAS" TO "CONGEN";
  GRANT INSERT ON "PA"."PERSONAS_FISICAS" TO "CONGEN";
  GRANT UPDATE ON "PA"."PERSONAS_FISICAS" TO "CONGEN";
  GRANT ALTER ON "PA"."PERSONAS_FISICAS" TO "BPA";
  GRANT ALTER ON "PA"."PERSONAS_FISICAS" TO PUBLIC;
  GRANT DELETE ON "PA"."PERSONAS_FISICAS" TO PUBLIC;
  GRANT INSERT ON "PA"."PERSONAS_FISICAS" TO PUBLIC;
  GRANT SELECT ON "PA"."PERSONAS_FISICAS" TO PUBLIC;
  GRANT UPDATE ON "PA"."PERSONAS_FISICAS" TO PUBLIC;
  GRANT SELECT ON "PA"."PERSONAS_FISICAS" TO "ASEGURA";
  GRANT ALTER ON "PA"."PERSONAS_FISICAS" TO "PS";
  GRANT DELETE ON "PA"."PERSONAS_FISICAS" TO "PS";
  GRANT INDEX ON "PA"."PERSONAS_FISICAS" TO "PS";
  GRANT INSERT ON "PA"."PERSONAS_FISICAS" TO "PS";
  GRANT SELECT ON "PA"."PERSONAS_FISICAS" TO "PS";
  GRANT UPDATE ON "PA"."PERSONAS_FISICAS" TO "PS";
  GRANT REFERENCES ON "PA"."PERSONAS_FISICAS" TO "PS";
  GRANT ON COMMIT REFRESH ON "PA"."PERSONAS_FISICAS" TO "PS";
  GRANT QUERY REWRITE ON "PA"."PERSONAS_FISICAS" TO "PS";
  GRANT DEBUG ON "PA"."PERSONAS_FISICAS" TO "PS";
  GRANT FLASHBACK ON "PA"."PERSONAS_FISICAS" TO "PS";
  GRANT SELECT ON "PA"."PERSONAS_FISICAS" TO "TCAPROBAD1";
  GRANT SELECT ON "PA"."PERSONAS_FISICAS" TO "ICUEVA";
  GRANT SELECT ON "PA"."PERSONAS_FISICAS" TO "JEGARCIA";
  GRANT SELECT ON "PA"."PERSONAS_FISICAS" TO "OCASTRO";
  GRANT SELECT ON "PA"."PERSONAS_FISICAS" TO "TCAPROBAD2";
  GRANT SELECT ON "PA"."PERSONAS_FISICAS" TO "TCDIGITADO";
  GRANT ALTER ON "PA"."PERSONAS_FISICAS" TO "BPR";
  GRANT DELETE ON "PA"."PERSONAS_FISICAS" TO "BPR";
  GRANT INSERT ON "PA"."PERSONAS_FISICAS" TO "BPR";
  GRANT SELECT ON "PA"."PERSONAS_FISICAS" TO "BPR";
  GRANT UPDATE ON "PA"."PERSONAS_FISICAS" TO "BPR";
  GRANT ON COMMIT REFRESH ON "PA"."PERSONAS_FISICAS" TO "BPR";
  GRANT QUERY REWRITE ON "PA"."PERSONAS_FISICAS" TO "BPR";
  GRANT DEBUG ON "PA"."PERSONAS_FISICAS" TO "BPR";
  GRANT FLASHBACK ON "PA"."PERSONAS_FISICAS" TO "BPR";
  GRANT SELECT ON "PA"."PERSONAS_FISICAS" TO "ICUEVAS";
  GRANT SELECT ON "PA"."PERSONAS_FISICAS" TO "TCVERIFFIN";
  GRANT SELECT ON "PA"."PERSONAS_FISICAS" TO "TCVERIFINI";
  GRANT SELECT ON "PA"."PERSONAS_FISICAS" TO "BFERNANDEZ";
  GRANT SELECT ON "PA"."PERSONAS_FISICAS" TO "JSANCHEZ";
  GRANT SELECT ON "PA"."PERSONAS_FISICAS" TO "SII";
  GRANT SELECT ON "PA"."PERSONAS_FISICAS" TO "FERMINR";
  GRANT SELECT ON "PA"."PERSONAS_FISICAS" TO "GASANCHEZ";
