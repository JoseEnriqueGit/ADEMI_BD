DROP TABLE PR.PR_SOLICITUD_REPRESTAMO CASCADE CONSTRAINTS;

CREATE TABLE PR.PR_SOLICITUD_REPRESTAMO
(
  CODIGO_EMPRESA        NUMBER(4)               NOT NULL,
  ID_REPRESTAMO         NUMBER(14)              NOT NULL,
  NOMBRES               VARCHAR2(65 BYTE),
  APELLIDOS             VARCHAR2(65 BYTE),
  IDENTIFICACION        VARCHAR2(30 BYTE),
  FEC_NACIMIENTO        DATE,
  SEXO                  VARCHAR2(3 BYTE),
  NACIONALIDAD          VARCHAR2(20 BYTE),
  ESTADO_CIVIL          VARCHAR2(3 BYTE),
  TELEFONO_CELULAR      VARCHAR2(20 BYTE),
  TELEFONO_RESIDENCIA   VARCHAR2(20 BYTE),
  TELEFONO_TRABAJO      VARCHAR2(20 BYTE),
  EMAIL                 VARCHAR2(200 BYTE),
  COD_DIRECCION         VARCHAR2(15 BYTE),
  TIP_DIRECCION         VARCHAR2(1 BYTE),
  DIRECCION             VARCHAR2(160 BYTE),
  PLAZO                 NUMBER(5),
  OPCION_RECHAZO        VARCHAR2(1 BYTE),
  NO_CREDITO            NUMBER(7),
  ESTADO                VARCHAR2(5 BYTE)        NOT NULL,
  ADICIONADO_POR        VARCHAR2(30 BYTE)       NOT NULL,
  FECHA_ADICION         DATE                    NOT NULL,
  MODIFICADO_POR        VARCHAR2(30 BYTE),
  FECHA_MODIFICACION    DATE,
  CODIGO_ACTIVIDAD      VARCHAR2(15 BYTE),
  MARGEN_BRUTO_STD      NUMBER(6,4),
  GASTO_OPERATIVO_STD   NUMBER(14,2),
  VENTAS_MENSUAL        NUMBER(14,2),
  COSTO_VENTAS          NUMBER(14,2),
  GASTO_OPERATIVO       NUMBER(14,2),
  OTROS_INGRESOS        NUMBER(14,2),
  GASTOS_FAMILIARES     NUMBER(14,2),
  EXCEDENTE_FAMILIARES  NUMBER(14,2),
  REL_CUOTA_EXCED_FAM   NUMBER(14,2),
  CODIGO_AGENCIA        VARCHAR2(5 BYTE),
  CODIGO_OFICIAL        VARCHAR2(5 BYTE),
  ID_TEMPFUD            NUMBER(15),
  NOMARCHIVO            VARCHAR2(50 BYTE),
  ID_TEMPFEC            NUMBER(15),
  COD_PAIS              VARCHAR2(5 BYTE),
  COD_PROVINCIA         VARCHAR2(5 BYTE),
  COD_CANTON            VARCHAR2(5 BYTE),
  COD_DISTRITO          VARCHAR2(5 BYTE),
  COD_CIUDAD            VARCHAR2(5 BYTE),
  TIPO_CREDITO          NUMBER                  DEFAULT NULL,
  WORLD_COMPLIANCE      NUMBER,
  IDENTIFICADOR_FIADOR  VARCHAR2(30 BYTE),
  TELEFONO_FIADOR       VARCHAR2(30 BYTE),
  EMAIL_FIADOR          VARCHAR2(200 BYTE),
  DIRECCION_FIADOR      VARCHAR2(160 BYTE)
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


CREATE UNIQUE INDEX PR.PK_SOLICITUD_REPRESTAMO ON PR.PR_SOLICITUD_REPRESTAMO
(CODIGO_EMPRESA, ID_REPRESTAMO)
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

ALTER TABLE PR.PR_SOLICITUD_REPRESTAMO ADD (
  CONSTRAINT PK_SOLICITUD_REPRESTAMO
  PRIMARY KEY
  (CODIGO_EMPRESA, ID_REPRESTAMO)
  USING INDEX PR.PK_SOLICITUD_REPRESTAMO
  ENABLE VALIDATE);


CREATE INDEX PR.PR_SOLICITUD_REPRESTAMO_IDX ON PR.PR_SOLICITUD_REPRESTAMO
(CODIGO_EMPRESA, NO_CREDITO)
LOGGING
TABLESPACE PR_IDX
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

CREATE OR REPLACE TRIGGER "PR"."TRG_BUI_SOLICITUD_REPRESTAMO" 
    before insert or update
    on pr.pr_solicitud_represtamo
    referencing new as new old as old
    for each row
declare
    cursor cur_datos(pcodigo_empresa in number, pidreprestamo in number) is
        select codigo_cliente
        from pr_represtamos
        where codigo_empresa = pcodigo_empresa
        and   id_represtamo = pidreprestamo;

    vcodigo_cliente pr_represtamos.codigo_cliente%type;
begin
    if inserting then
        :new.fecha_adicion := sysdate;
    else
        if :new.no_credito is not null then
            -- Se interta en pr_analisis solic
            begin
                open cur_datos(:new.codigo_empresa, :new.id_represtamo);

                fetch cur_datos into   vcodigo_cliente;

                close cur_datos;

                :new.fecha_modificacion := sysdate;

                insert into pr_analisis_solic
                    select :new.codigo_empresa codigo_empresa,
                           :new.no_credito no_solicitud,
                           0   ventas_mensuales_neg,
                           0   costo_ventas_neg,
                           0   utilidad_bruta_ventas_neg,
                           0   alquiler_local_neg,
                           0   servicios_municipales_neg,
                           0   salarios_neg,
                           0   servicios_varios_neg,
                           0   transporte_neg,
                           0   contador_neg,
                           0   celular_neg,
                           0   prestamos_tarjeta_cred_neg,
                           0   otros_neg,
                           0   gastos_operacion_neg,
                           0   excedente_neg,
                           0   remesas_fam,
                           0   alquileres_fam,
                           0   otros_fam,
                           0   otros_ingresos_fam,
                           0   alimentacion_fam,
                           0   alquiler_fam,
                           0   servicios_varios_fam,
                           0   educacion_fam,
                           0   celular_fam,
                           0   gastos_imprevistos_fam,
                           0   otros_gastos_fam,
                           0   gastos_fam,
                           0   excedente_mensual_fam,
                           0   activo_corriente_bge,
                           0   efectivo_bge,
                           0   cuentas_bancarias_bge,
                           0   cuentas_cobrar_bge,
                           0   inventario_mercaderias_bge,
                           0   inventario_prod_proc_bge,
                           0   inventario_prod_term_bge,
                           0   activo_no_corriente_bge,
                           0   inmuebles_bge,
                           0   vehiculos_bge,
                           0   maquinaria_computacion_bge,
                           0   mobiliario_oficina_bge,
                           0   herramientas_bge,
                           0   mobiliario_electrod_bge,
                           0   puesto_propio_bge,
                           0   otros_bge,
                           0   suma_total_activo_bge,
                           0   pasivo_corriente_bge,
                           0   cuentas_pagar_bge,
                           0   prestamos_pagar_bge,
                           0   tarjetas_credito_bge,
                           0   deudas_personal_fam_bge,
                           0   otros_pas_bge,
                           0   pasivo_no_corriente_bge,
                           0   cuentas_pagar_pnc_bge,
                           0   prestamos_pagar_pnc_bge,
                           0   hipotecas_pnc_bge,
                           0   otros_pnc_bge,
                           0   suma_pasivo_bge,
                           0   capital_bge,
                           0   utilidad_operativa_bge,
                           0   suma_patrimonio_bge,
                           0   suma_activo_bge,
                           0   endeudamiento_total_ifa,
                           0   limite_tolerable_ea,
                           0   liquidez_corriente_ifa,
                           0   limite_tolerable_lc,
                           0   gastos_familiares_ifa,
                           0   limite_tolerable_gf,
                           0   capacidad_pago_ifa,
                           0   limite_tolerable_cp,
                           0   capital_trabajo_ifa,
                           0   rotacion_capital_trabajo_ifa,
                           0   monto_autorizar,
                           0   liquidez_acida_ifa,
                           0   cobertura_garantias_ifa,
                           0   rentabilidad_ventas_ifa,
                           vcodigo_cliente codigo_cliente,
                           user adicionado_por,
                           sysdate fecha_adicion,
                           null modificado_por,
                           null fecha_modifica,
                           null cant_mujeres_lab,
                           null cant_hombres_lab,
                           0   anticipo_proveedores_bge,
                           0   intereses_neg,
                           0   vestido_fam,
                           0   medicinas_fam,
                           0   transporte_fam,
                           0   pasivo_patrimonio_ind,
                           0   activo_pasivo_ind,
                           0   otrosingresos_excedentefam,
                           0   cuota_excedentefam,
                           0   tot_pasivo_patrimonio,
                           0   utilidadneta_patrimonio,
                           0   utilidadneta_activostotal,
                           0   utilidadneta_ingresos,
                           0   ctasxcobrar_ingresos,
                           0   costoventas_inventario,
                           0   cuota_cr,
                           0   muebles_vehiculos_bgf,
                           0   inmuebles_bgf,
                           0   tot_activos_bgf,
                           0   deuda_comercial_bgf,
                           0   deuda_bancaria_bgf,
                           0   tot_pasivo_bgf,
                           0   patrimonio_bgf,
                           trunc(sysdate) fecha_bgf,
                           0   monto_rec,
                           0   moneda_rec,
                           0   tasa_rec,
                           0   plazo_rec,
                           0   frecuencia_rec,
                           null destino_credito_rec,
                           null detalle_destino_rec,
                           null cod_estado_solici_rec,
                           null pri_ref_enf,
                           null seg_ref_enf,
                           null ambiente_fam_enf,
                           null dependientes_enf,
                           null edad_enf,
                           null est_salud_enf,
                           null estabilidad_enf,
                           null otros_ing_enf,
                           null experiencia_enf,
                           null horas_enf,
                           null local_propio_enf,
                           null tiempo_local_enf,
                           null ubic_negocio_enf,
                           null lleva_registros_enf,
                           null mejoras_negocio_enf,
                           null frecuencia_clte_enf,
                           null nivel_compe_enf,
                           null ventas_diarias_evf,
                           null dias_trabmes_evf,
                           null ventas_mensual_evf,
                           null compras_semprom_evf,
                           null compras_mendecl_evf,
                           null margen_decl_evf,
                           0   monto_mesalto_evf,
                           0   monto_mesmedio_evf,
                           0   monto_mesbajo_evf,
                           0   venta_mes_evf,
                           0   costo_ventames_evf,
                           0   margen_ganancia_evf,
                           trunc(sysdate) fecha_bge,
                           trunc(sysdate) fecha_desde_neg,
                           trunc(sysdate) fecha_hasta_neg,
                           null num_identificacion,
                           null excedente_neg_esp,
                           '0' tipo_solicitud
                    from dual;
            exception
                when others then
                    null;
            end;
        end if;
    end if;
end;
/


CREATE OR REPLACE PUBLIC SYNONYM PR_SOLICITUD_REPRESTAMO FOR PR.PR_SOLICITUD_REPRESTAMO;


ALTER TABLE PR.PR_SOLICITUD_REPRESTAMO ADD (
  CONSTRAINT FK_SOLICITUD_REPRESTAMO 
  FOREIGN KEY (CODIGO_EMPRESA, ID_REPRESTAMO) 
  REFERENCES PR.PR_REPRESTAMOS (CODIGO_EMPRESA, ID_REPRESTAMO)
  ENABLE VALIDATE);

GRANT INSERT, SELECT, UPDATE ON PR.PR_SOLICITUD_REPRESTAMO TO BPR;

GRANT SELECT ON PR.PR_SOLICITUD_REPRESTAMO TO PA WITH GRANT OPTION;
