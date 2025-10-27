
  CREATE TABLE "PA"."PA_DETALLADO_DE08" 
   (	"FUENTE" VARCHAR2(2 BYTE), 
	"FECHA_CORTE" DATE, 
	"NO_CREDITO" NUMBER(16,0), 
	"ESTADO" VARCHAR2(2 BYTE), 
	"CODIGO_CLIENTE" NUMBER(15,0), 
	"CODIGO_MONEDA" NUMBER(2,0), 
	"IDENTIFICA_DEUDOR" VARCHAR2(25 BYTE), 
	"TIPO_PERSONA" VARCHAR2(2 BYTE), 
	"NOMBRE_RAZON_SOCIAL" VARCHAR2(50 BYTE), 
	"APELLIDOS_SIGLAS" VARCHAR2(50 BYTE), 
	"ACTIVIDAD" VARCHAR2(6 BYTE), 
	"TIPO_CLIENTE" NUMBER, 
	"TIPO_CREDITO_COMERCIAL" VARCHAR2(1 BYTE), 
	"MTO_CONTING_COMERCIAL" NUMBER(18,2), 
	"MTO_ADEUDADO_COMERCIAL" NUMBER(18,2), 
	"MTO_ADEUDADO_CONSUMO" NUMBER(18,2), 
	"MTO_ADEUDADO_TC_PERSONAL" NUMBER(18,2), 
	"MTO_ADEUDADO_HIPOTECARIO" NUMBER(18,2), 
	"FEC_ADICION" DATE DEFAULT SYSDATE, 
	"ADICIONADO_POR" VARCHAR2(25 BYTE) DEFAULT USER, 
	"DIAS_ATRASO" NUMBER(10,0) DEFAULT 0, 
	"COD_SECTOR_CONTABLE" VARCHAR2(10 BYTE), 
	"TIPO_CREDITO" NUMBER(3,0), 
	"F_ULTIMA_REVISION" DATE, 
	"CODIGO_AGENCIA" NUMBER(5,0), 
	"CIUU_OPERACION" VARCHAR2(6 BYTE), 
	"LOCALIDAD" VARCHAR2(6 BYTE), 
	"F_RESTRUC_A_VIGENTE" DATE, 
	"F_RESTRUCTURACION" DATE, 
	"COD_VINCULACION" VARCHAR2(2 BYTE), 
	"CODIGO_ORIGEN" VARCHAR2(2 BYTE), 
	"CODIGO_CALIFICACION_SISTEMA" VARCHAR2(2 BYTE), 
	"TASA_INTERES" NUMBER(6,2), 
	"PERIODOS_GRACIA_PRINCIPAL" NUMBER(5,0), 
	"CODIGO_PERIODO_INTERESES" VARCHAR2(1 BYTE), 
	"CODIGO_PERIODO_CUOTA" VARCHAR2(1 BYTE), 
	"CUOTA" NUMBER(15,2), 
	"F_VENCIMIENTO" DATE, 
	"MONTO_DESEMBOLSADO" NUMBER(15,2), 
	"F_PRIMER_DESEMBOLSO" DATE, 
	"MONTO_CREDITO" NUMBER(15,2), 
	"F_APROBACION" DATE, 
	"COD_FACILIDAD" VARCHAR2(27 BYTE), 
	"FEC_PRIMER_PAGO" DATE, 
	"FACILIDAD_CREDITIC" NUMBER(3,0), 
	"CANT_PLASTICOS" NUMBER(3,0), 
	"COD_SUBRPRODUCTO" NUMBER(6,0), 
	"BALAN_PROM_CAPITAL" NUMBER(15,2), 
	"INTERES_DEVENG_CORTE" NUMBER(15,2), 
	"COMIS_DEVENG_CORTE" NUMBER(15,2), 
	"CODIGO_EMPRESA" NUMBER(5,0) DEFAULT 1, 
	"MONTO_PAGADO_INTERESES" NUMBER(18,2), 
	"INTERESES_ACUMULADOS" NUMBER(18,2), 
	"MONTO_PAGADO_PRINCIPAL" NUMBER(18,2), 
	"TIPO_INTERESES" VARCHAR2(1 BYTE), 
	"TIPO_CALENDARIO" NUMBER(1,0), 
	"ID_SISTEMA_EXTERNO" VARCHAR2(15 BYTE), 
	"MONTO_GARANTIA" NUMBER(18,2), 
	"MON_CAPITAL_PROVI" NUMBER(18,2), 
	"PROVIS_CAPITAL_CREDITO" NUMBER(18,2), 
	"PROVIS_RENDIMIENTOS" NUMBER(18,2), 
	"PROVIS_CONTIG" NUMBER(18,2) DEFAULT 0, 
	"TIPO_CREDITO_CLIENTE" VARCHAR2(1 BYTE), 
	"TCC_CLIENTE" VARCHAR2(1 BYTE), 
	"MTO_BALANCE_CAPITAL" NUMBER(18,2) DEFAULT 0, 
	"NUM_TARJETA_DE" VARCHAR2(27 BYTE), 
	"COBRANZA_JUDICIAL" VARCHAR2(1 BYTE), 
	"OPCION_CANCELA_ANTICIP" VARCHAR2(2 BYTE), 
	"PENALIZA_CANCELANTICIP" NUMBER(6,2), 
	"FEC_PAGO_EXTRAORD" VARCHAR2(10 BYTE), 
	"MNTO_PAGO_EXTRAORD" NUMBER(15,2), 
	"REESTRUCTURADO" VARCHAR2(2 BYTE), 
	"TIPO_TASA" VARCHAR2(1 BYTE), 
	"ORIGEN_CREDITO" VARCHAR2(2 BYTE), 
	"FORMA_PAGO_CAPITAL" VARCHAR2(1 BYTE), 
	"FORMA_PAGO_INT_COMI" VARCHAR2(1 BYTE), 
	"ORIGEN_DEL_CREDITO" VARCHAR2(2 BYTE), 
	"CALIFICA_CLIENTE" VARCHAR2(2 BYTE), 
	"CALIFICACION_CUBIERTO" VARCHAR2(2 BYTE), 
	"CALIFICACION_EXPUESTO" VARCHAR2(2 BYTE), 
	"MTO_INT_FINANCIAMIENTO" NUMBER(18,2), 
	"TIPO_DE" VARCHAR2(5 BYTE), 
	"MTO_INTERES_SUSPENSO" NUMBER(18,2), 
	"MTO_MORA_ACUMULADA" NUMBER(18,2), 
	"MTO_MORA_PAGADO" NUMBER(18,2), 
	"PORCENTAJE_PROV" NUMBER(6,2), 
	"IND_GARANT_ASEG" VARCHAR2(1 BYTE), 
	"PERIODO_CUOTA" VARCHAR2(5 BYTE) DEFAULT 'ME', 
	"RAZON_CLASIF_DEUDOR" VARCHAR2(2 BYTE), 
	"DIAS_ATRASO_INTERES" NUMBER(5,0), 
	"CUENTA_EVERTEC" VARCHAR2(20 BYTE), 
	"CONGELAMIENTO_SIB" VARCHAR2(5 BYTE), 
	 CONSTRAINT "PK_DETALLE_DE08" PRIMARY KEY ("FUENTE", "FECHA_CORTE", "NO_CREDITO") DISABLE
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "PA_DAT" ;

   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."TIPO_CREDITO_COMERCIAL" IS 'tipo credito comercial dela operación individual';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."TIPO_CREDITO" IS 'Define el tipo de credito ';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."F_ULTIMA_REVISION" IS 'Fecha Revisión Tasa de Interés. Corresponde a proxima fecha de revisión de tasas. PR_CREDITOS.FEC_PROXIMA_REVISION';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."CODIGO_AGENCIA" IS 'Número de Oficina';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."CIUU_OPERACION" IS 'Campo relacionado a la tabla ACTIVIDADES_ECONOMICAS_BC_CIIU.';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."LOCALIDAD" IS 'Código de localidad del cliente';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."F_RESTRUC_A_VIGENTE" IS 'Fecha de renovación';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."F_RESTRUCTURACION" IS 'Fecha de reestructuración';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."COD_VINCULACION" IS 'Tipo de vinculación del cliente';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."CODIGO_ORIGEN" IS 'Origen o tipo de recurso';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."CODIGO_CALIFICACION_SISTEMA" IS 'Calificacion de a operación';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."TASA_INTERES" IS 'Tasa de interes de la operación';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."PERIODOS_GRACIA_PRINCIPAL" IS 'Periodo de gracia de la operación';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."CODIGO_PERIODO_INTERESES" IS 'Forma de Pago de Intereses y Comisiones';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."CODIGO_PERIODO_CUOTA" IS 'Forma de Pago del Capital';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."CUOTA" IS 'Monto de la Cuota / Monto de la Cuota Mínima TC';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."F_VENCIMIENTO" IS 'Fecha de Vencimiento / Fecha de Corte TC';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."MONTO_DESEMBOLSADO" IS 'Monto Desembolsado / Consumos del Mes TC';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."F_PRIMER_DESEMBOLSO" IS 'Fecha de Desembolso';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."MONTO_CREDITO" IS 'Monto Aprobado';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."F_APROBACION" IS 'Fecha de Aprobación del Crédito';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."COD_FACILIDAD" IS 'Código de la Facilidad';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."FEC_PRIMER_PAGO" IS 'Fecha Inicio del Primer Pago';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."FACILIDAD_CREDITIC" IS 'Facilidad Crediticia';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."CANT_PLASTICOS" IS 'Cantidad de Plásticos TC';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."COD_SUBRPRODUCTO" IS 'Código del Subproducto TC';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."BALAN_PROM_CAPITAL" IS 'Balance Promedio Diario de Capital del Mes';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."INTERES_DEVENG_CORTE" IS 'Intereses Devengados al Corte';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."COMIS_DEVENG_CORTE" IS 'Comisiones y Cargos Devengados al Corte';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."CODIGO_EMPRESA" IS 'Código identificador de la Empresa deseada';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."MONTO_PAGADO_INTERESES" IS 'Monto de intereses que han sido pagados';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."INTERESES_ACUMULADOS" IS 'Intereses acumulados a la fecha';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."MONTO_PAGADO_PRINCIPAL" IS 'Monto que corresponde a lo pagado del principal';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."TIPO_INTERESES" IS 'Tipo de interes que aplica a la operación';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."TIPO_CALENDARIO" IS 'Tipo de calendario utilizado en la operación';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."MONTO_GARANTIA" IS 'Monto correspondiente a la garantía admisible';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."MON_CAPITAL_PROVI" IS 'Monto correspondiente a la provisión de capital';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."PROVIS_CAPITAL_CREDITO" IS 'Corresponde a la provisión constituida por el crédito.  Dicha provisión se debe calcular distribuyendo la provisión total constituida entre cada una de las operaciones de consumo, utilizando la proporción en que cada operación crediticia contribuye a la provisión requerida total';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."PROVIS_RENDIMIENTOS" IS 'Corresponde al monto a provisionar a los rendimientos de los créditos, por concepto del riesgo del crédito, conforme a la clasificación otorgada a cada operación crediticia. Para calcular esta provisión de los créditos, sólo se deben considerar los rendimientos hasta 90 días. En los casos de Tarjetas de Créditos, sólo se deben considerar los rendimientos hasta 60 días. ';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."PROVIS_CONTIG" IS 'Corresponde al monto a provisionar a las contingencias por concepto del riesgo del deudor, conforme a la clasificación otorgada a cada operación crediticia. Para calcular esta provisión sólo se deben considerar los montos aprobados y no utilizados de las líneas de crédito de utilización automática. ';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."TCC_CLIENTE" IS 'Tipo de crédito comercial del cliente. Se indica con "C" si el crédito es Mayor Deudor, ¿M¿ si el crédito fue otorgado a un Menor Deudor o la microempresa, ¿R¿ si es un Microcrédito.';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."MTO_BALANCE_CAPITAL" IS 'Se carga el balance de capital a partir los movimientos';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."COBRANZA_JUDICIAL" IS 'Se indica una "S" si el crédito se encuentra en cobranza judicial  o con una "N" si el crédito no está en cobranza judicial. ';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."OPCION_CANCELA_ANTICIP" IS 'Se indica una "S" si el crédito tiene opción de pago o cancelación anticipada o con una "N" si el crédito no tiene está opción. ';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."PENALIZA_CANCELANTICIP" IS 'Se debe señalar el porcentaje con el cual se penaliza al cliente por la opción de pago o cancelación anticipada. Dicho porcentaje se debe reportar en números reales con dos posiciones decimales. Por ejemplo: 3.00 o 3.25. ';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."FEC_PAGO_EXTRAORD" IS 'Este campo se utilizará para indicar la fecha en la que se realizará el próximo pago de cuota extraordinaria, en el caso de que el crédito esté pactado con esa condición. ';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."MNTO_PAGO_EXTRAORD" IS 'Este campo se utilizará para indicar el monto de la cuota extraordinaria, en el caso de que el crédito esté pactado con esa condición. ';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."REESTRUCTURADO" IS 'Identifica el Tipo de reestructuración, si aplica, que ha tenido un crédito. Se indica con "RN" si el crédito ha sido reestructurado conforme a lo dispuesto en el REA; ¿RT¿ si el crédito ha sido reestructurado conforme a lo dispuesto en la Circular 003/09 y sus modificaciones; "NR" si el crédito no ha sido reestructurado. ';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."TIPO_TASA" IS 'Se deberá indicar ¿F¿ si la tasa de interés a la cual fue otorgado el crédito es fija o ¿V¿ si la tasa es variable. Para aquellos productos que se otorgan durante un  plazo determinado con una tasa fija y luego de un periodo de tiempo con una tasa  variable deberá colocarse de acuerdo al momento en que se encuentre la operación.  ';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."ORIGEN_CREDITO" IS 'Se indicará si fue originado a través de una feria ¿FR¿, de un Subagente Bancario ¿SB¿, Adquisición de Cartera de Crédito ¿CC¿ u Operaciones Diarias ¿OP¿.   ';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."FORMA_PAGO_CAPITAL" IS 'Debe indicarse la frecuencia en que deben realizarse los pagos sobre el Capital, (Ver Tabla 10.0  " Forma de pago de Interés y Capital "). Ésta solo puede ser diferente a la forma de pago de intereses y comisiones cuando el deudor posea depósitos en la misma entidad.';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."FORMA_PAGO_INT_COMI" IS 'Debe indicarse la frecuencia en que deben realizarse los pagos de intereses y comisiones, (Ver Tabla 10.0 " Forma de pago de Interés y Capital "). Ésta solo puede ser diferente a la forma de pago del capital cuando el deudor posea depósitos en la misma entidad. ';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."ORIGEN_DEL_CREDITO" IS 'Se indicará si fue originado a través de una feria ¿FR¿, de un Subagente Bancario ¿SB¿, Adquisición de Cartera de Crédito ¿CC¿ u Operaciones Diarias ¿OP¿. ';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."CALIFICA_CLIENTE" IS 'CALIFICACIÓN MÁS BAJA DEL CLIENTE DE ACUERO AL PROCESO QUE CORRESPONDE(Empeoramiento de la cartera)';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."CALIFICACION_CUBIERTO" IS 'Calificación del monto cubierto de la operación';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."CALIFICACION_EXPUESTO" IS 'Calificación del monto expuesto de la operación';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."TIPO_DE" IS 'Indica el De (11,13,14,15) a cual corresponde el registro';
   COMMENT ON COLUMN "PA"."PA_DETALLADO_DE08"."IND_GARANT_ASEG" IS 'Se indica con una "S" si el bien mueble o inmueble está asegurado contra todo tipo de riesgos y a la vez dicha póliza está vigente y endosada a favor de la entidad; con una "N" si no tiene seguro o si la póliza no está vigente o no está endosada a favor de la Entidad';

  CREATE INDEX "PA"."FECHA_CLIENTE" ON "PA"."PA_DETALLADO_DE08" ("FECHA_CORTE", "CODIGO_CLIENTE") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "PA_DAT" ;

  CREATE INDEX "PA"."IDX_DETALLE_DE08" ON "PA"."PA_DETALLADO_DE08" ("FUENTE", "FECHA_CORTE", "IDENTIFICA_DEUDOR") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "PA_DAT" ;

  CREATE INDEX "PA"."IDX_DETALLE_DE08_2" ON "PA"."PA_DETALLADO_DE08" ("FUENTE", "FECHA_CORTE", "NO_CREDITO", "CODIGO_CLIENTE") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "PA_IDX" ;

  CREATE INDEX "PA"."IDX_DET_DE08_2" ON "PA"."PA_DETALLADO_DE08" ("ID_SISTEMA_EXTERNO", "FECHA_CORTE") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "PA_IDX" ;

  CREATE INDEX "PA"."IDX_DET_DE08_FUENFECCOR" ON "PA"."PA_DETALLADO_DE08" ("FUENTE", "FECHA_CORTE") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "PA_DAT" ;

  CREATE INDEX "PA"."X" ON "PA"."PA_DETALLADO_DE08" ("NUM_TARJETA_DE") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "PA_DAT" ;

  CREATE OR REPLACE EDITIONABLE TRIGGER "PA"."BIU_PA_DETALLADO_DE08" 
BEFORE INSERT OR UPDATE
ON PA.PA_DETALLADO_DE08
REFERENCING NEW AS New OLD AS Old
FOR EACH ROW
BEGIN
   IF UPDATING THEN
       IF :new.estado = 'J' AND NVL(:new.cobranza_judicial,'N') = 'N' THEN
          :new.cobranza_judicial := 'S';
       END IF;
       IF :new.estado != 'J' AND NVL(:new.cobranza_judicial,'S') = 'S' THEN
          :new.cobranza_judicial := 'N';
       END IF;
       IF :new.califica_cliente = 'A' THEN
          :new.razon_clasif_deudor := 'Q';
       ELSE
          :new.razon_clasif_deudor := 'T';
       END IF;
   END IF;
   IF :new.reestructurado = 'RL' THEN
     :new.razon_clasif_deudor := 'J';
   END IF;
END BIU_pa_Detallado_de08;
/
ALTER TRIGGER "PA"."BIU_PA_DETALLADO_DE08" ENABLE;


  GRANT UPDATE ON "PA"."PA_DETALLADO_DE08" TO "BPA";
  GRANT SELECT ON "PA"."PA_DETALLADO_DE08" TO "SII";
  GRANT SELECT ON "PA"."PA_DETALLADO_DE08" TO "CB" WITH GRANT OPTION;
  GRANT REFERENCES ON "PA"."PA_DETALLADO_DE08" TO "CB" WITH GRANT OPTION;
  GRANT SELECT ON "PA"."PA_DETALLADO_DE08" TO "CDG";
  GRANT SELECT ON "PA"."PA_DETALLADO_DE08" TO "BPR";
  GRANT SELECT ON "PA"."PA_DETALLADO_DE08" TO "BPA";
  GRANT SELECT ON "PA"."PA_DETALLADO_DE08" TO "LV";
  GRANT DELETE ON "PA"."PA_DETALLADO_DE08" TO "BPA";
  GRANT SELECT ON "PA"."PA_DETALLADO_DE08" TO "TC" WITH GRANT OPTION;
