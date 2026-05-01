DROP TABLE PR.TEMPFUD CASCADE CONSTRAINTS;

CREATE TABLE PR.TEMPFUD
(
  ID_TEMPFUD                      NUMBER(15)    NOT NULL,
  NOMARCHIVO                      VARCHAR2(50 BYTE) NOT NULL,
  PROCESADO                       VARCHAR2(1 BYTE),
  IDAPERTURACLIENTE               VARCHAR2(50 BYTE),
  TIPODOCUMENTOIDENTIDAD          VARCHAR2(50 BYTE),
  NUMDOCUMENTOIDENTIDAD           VARCHAR2(50 BYTE),
  IDOFICIAL                       VARCHAR2(50 BYTE),
  IDAGENCIA                       VARCHAR2(50 BYTE),
  PRIMERNOMBRE                    VARCHAR2(50 BYTE),
  PRIMERAPELLIDO                  VARCHAR2(50 BYTE),
  SEXO                            VARCHAR2(50 BYTE),
  FECHANACIMIENTO                 VARCHAR2(50 BYTE),
  APODO                           VARCHAR2(50 BYTE),
  IDEMPLEADO                      VARCHAR2(50 BYTE),
  IDPAIS                          VARCHAR2(50 BYTE),
  IDPROVINCIA                     VARCHAR2(50 BYTE),
  IDMUNICIPIO                     VARCHAR2(50 BYTE),
  IDDISTRITO                      VARCHAR2(50 BYTE),
  IDESTADOCIVIL                   VARCHAR2(50 BYTE),
  NOHIJOS                         VARCHAR2(50 BYTE),
  DEPENDIENTES                    VARCHAR2(50 BYTE),
  GRADOINT                        VARCHAR2(50 BYTE),
  IDOCUPACION                     VARCHAR2(50 BYTE),
  IDVINCULADO                     VARCHAR2(50 BYTE),
  NOMBREVINCULADO                 VARCHAR2(50 BYTE),
  IDTIPOVINCULADO                 VARCHAR2(50 BYTE),
  IDCOMOSUPONOSOTROS              VARCHAR2(50 BYTE),
  DIRECCION                       VARCHAR2(50 BYTE),
  DIRECCION_IDSECTOR              VARCHAR2(50 BYTE),
  DIRECCION_IDPROVINCIA           VARCHAR2(50 BYTE),
  DIRECCION_IDMUNICIPIO           VARCHAR2(50 BYTE),
  DIRECCION_DISTRITO              VARCHAR2(50 BYTE),
  DIRECCION_IDTIPOVIVIENDA        VARCHAR2(50 BYTE),
  REF_DOMICILIO                   VARCHAR2(50 BYTE),
  TELEFONO_CASA                   VARCHAR2(50 BYTE),
  TELEFONO_CELULAR                VARCHAR2(50 BYTE),
  NOMBRENEGOCIO                   VARCHAR2(50 BYTE),
  NOEMPLEADOS                     VARCHAR2(50 BYTE),
  RNC                             VARCHAR2(50 BYTE),
  FAX                             VARCHAR2(50 BYTE),
  EMAIL                           VARCHAR2(50 BYTE),
  SECTORECONOMICO                 VARCHAR2(50 BYTE),
  ACTIVIDAD_CIIU                  VARCHAR2(50 BYTE),
  IDRAMA_CIIU                     VARCHAR2(50 BYTE),
  INICIO_MES                      VARCHAR2(50 BYTE),
  INICIO_ANO                      VARCHAR2(50 BYTE),
  UBICACION_NEG                   VARCHAR2(50 BYTE),
  LUGARTRABAJO                    VARCHAR2(50 BYTE),
  FECHAINGRESO                    VARCHAR2(50 BYTE),
  CARGO                           VARCHAR2(50 BYTE),
  TRABAJO_DIRECCION               VARCHAR2(255 BYTE),
  TRABAJO_IDSECTOR                VARCHAR2(255 BYTE),
  TRABAJO_IDPROVINCIA             VARCHAR2(50 BYTE),
  TRABAJO_IDMUNICIPIO             VARCHAR2(50 BYTE),
  TRABAJO_IDDISTRITO              VARCHAR2(50 BYTE),
  PUNTOREFERENCIA                 VARCHAR2(255 BYTE),
  TELEFONO                        VARCHAR2(50 BYTE),
  EXTENSION                       VARCHAR2(50 BYTE),
  REFPERSONALES_APELLIDOS         VARCHAR2(50 BYTE),
  REFPERSONALES_NOMBRES           VARCHAR2(50 BYTE),
  REFPERSONALES_TELEFONO          VARCHAR2(50 BYTE),
  REFPERSONALES_RELACIONFAMILIAR  VARCHAR2(50 BYTE),
  REFPERSONALES_NOMBRES2          VARCHAR2(50 BYTE),
  REFPERSONALES_APELLIDOS2        VARCHAR2(50 BYTE),
  REFPERSONALES_TELEFONO2         VARCHAR2(50 BYTE),
  REFPERSONALES_RELFAM2           VARCHAR2(50 BYTE),
  ACTUALMENTEENMORA               VARCHAR2(50 BYTE),
  CUMPLIOREQUISITOS               VARCHAR2(50 BYTE),
  PRESENTO_DOC_FRAUDULENTA        VARCHAR2(50 BYTE),
  DIJOLAVERDAD                    VARCHAR2(50 BYTE),
  CLIENTEESFIADOR                 VARCHAR2(50 BYTE),
  CLIENTEMOROSO                   VARCHAR2(50 BYTE),
  SOBREENDEUDAMIENTO_SF           VARCHAR2(50 BYTE),
  ACTIVIDADCLIENTE                VARCHAR2(50 BYTE),
  TIPOPERSONA                     VARCHAR2(50 BYTE),
  TIPODOCUMENTOIDENTIDADCO        VARCHAR2(50 BYTE),
  NUMDOCUMENTOIDENTIDADCO         VARCHAR2(50 BYTE),
  PRIMERNOMBRECO                  VARCHAR2(50 BYTE),
  PRIMERAPELLIDOCO                VARCHAR2(50 BYTE),
  SEXOCO                          VARCHAR2(50 BYTE),
  FECHANACIMIENTOCO               VARCHAR2(50 BYTE),
  APODOCO                         VARCHAR2(50 BYTE),
  IDEMPLEADOCO                    VARCHAR2(50 BYTE),
  IDPAISCO                        VARCHAR2(50 BYTE),
  IDPROVINCIACO                   VARCHAR2(50 BYTE),
  IDMUNICIPIOCO                   VARCHAR2(50 BYTE),
  IDDISTRITOCO                    VARCHAR2(50 BYTE),
  IDESTADOCIVILCO                 VARCHAR2(50 BYTE),
  NOHIJOSCO                       VARCHAR2(50 BYTE),
  DEPENDIENTESCO                  VARCHAR2(50 BYTE),
  GRADOINTCO                      VARCHAR2(50 BYTE),
  IDOCUPACIONCO                   VARCHAR2(50 BYTE),
  IDVINCULADOCO                   VARCHAR2(50 BYTE),
  NOMBREVINCULADOCO               VARCHAR2(50 BYTE),
  IDTIPOVINCULADOCO               VARCHAR2(50 BYTE),
  IDCOMOSUPONOSOTROSCO            VARCHAR2(50 BYTE),
  NOMBRENEGOCIOCO                 VARCHAR2(50 BYTE),
  NOEMPLEADOSCO                   VARCHAR2(50 BYTE),
  RNCCO                           VARCHAR2(50 BYTE),
  FAXCO                           VARCHAR2(50 BYTE),
  EMAILCO                         VARCHAR2(50 BYTE),
  SECTORECONOMICOCO               VARCHAR2(50 BYTE),
  ACTIVIDAD_CIIUCO                VARCHAR2(50 BYTE),
  IDRAMA_CIIUCO                   VARCHAR2(50 BYTE),
  INICIO_MESCO                    VARCHAR2(50 BYTE),
  INICIO_ANOCO                    VARCHAR2(50 BYTE),
  UBICACION_NEGCO                 VARCHAR2(50 BYTE),
  LUGARTRABAJOCO                  VARCHAR2(50 BYTE),
  FECHAINGRESOCO                  VARCHAR2(50 BYTE),
  TRABAJO_DIRECCIONCO             VARCHAR2(255 BYTE),
  TRABAJO_IDSECTORCO              VARCHAR2(50 BYTE),
  TRABAJO_IDPROVINCIACO           VARCHAR2(50 BYTE),
  TRABAJO_IDMUNICIPIOCO           VARCHAR2(50 BYTE),
  TRABAJO_IDDISTRITOCO            VARCHAR2(50 BYTE),
  PUNTOREFERENCIACO               VARCHAR2(255 BYTE),
  TELEFONOCO                      VARCHAR2(50 BYTE),
  EXTENSIONCO                     VARCHAR2(50 BYTE),
  CARGOCO                         VARCHAR2(50 BYTE),
  RESIDE_MES                      VARCHAR2(50 BYTE),
  RESIDE_ANO                      VARCHAR2(50 BYTE),
  ACTIVIDADCO                     VARCHAR2(50 BYTE),
  TIPOPERSONACO                   VARCHAR2(50 BYTE),
  TIPOSOLICITUD                   VARCHAR2(50 BYTE),
  CODIGOPROYECTO                  VARCHAR2(50 BYTE),
  DESTINOCREDITO                  VARCHAR2(50 BYTE),
  ESPECIFIQUEDESTINO              VARCHAR2(50 BYTE),
  TIPOPERSONACAL                  VARCHAR2(50 BYTE),
  EDADCAL                         VARCHAR2(50 BYTE),
  MONTOCAL                        VARCHAR2(50 BYTE),
  PLAZOCAL                        VARCHAR2(50 BYTE),
  MONEDACAL                       VARCHAR2(50 BYTE),
  DIAPAGOCAL                      VARCHAR2(50 BYTE),
  FRECUENCIACAL                   VARCHAR2(50 BYTE),
  GRACIACAL                       VARCHAR2(50 BYTE),
  GARANTIACAL                     VARCHAR2(50 BYTE),
  SEGURO_VEHICULOCAL              VARCHAR2(50 BYTE),
  SEGURO_VIDACAL                  VARCHAR2(50 BYTE),
  SEGURO_INCENDIOCAL              VARCHAR2(50 BYTE),
  GASTOSCAL                       VARCHAR2(50 BYTE),
  TIPOPRESTAMOCAL                 VARCHAR2(50 BYTE),
  GARANTIASOLIDARIACAL            VARCHAR2(50 BYTE),
  HIPOTECARIACAL                  VARCHAR2(50 BYTE),
  PRENDARIACAL                    VARCHAR2(50 BYTE),
  LIQUIDACAL                      VARCHAR2(50 BYTE),
  CUOTASEGUROCAL                  VARCHAR2(50 BYTE),
  CUOTAPRESTAMOCAL                VARCHAR2(50 BYTE),
  TOTALFINANCIARCAL               VARCHAR2(50 BYTE),
  TASACAL                         VARCHAR2(50 BYTE),
  GASTOSLEGALESCAL                VARCHAR2(50 BYTE),
  SEGUROVIDACAL                   VARCHAR2(50 BYTE),
  SEGUROALIADACAL                 VARCHAR2(50 BYTE),
  SEGUROVEHCAL                    VARCHAR2(50 BYTE),
  CLASIFICACION                   VARCHAR2(50 BYTE),
  FIRMACLIENTE                    VARCHAR2(50 BYTE),
  FIRMACO                         VARCHAR2(50 BYTE),
  CLIENTEPERTENECE                VARCHAR2(50 BYTE),
  FECHA_REGISTRO                  DATE,
  TIPOCAL                         NUMBER,
  TIPOPARENTESCO                  VARCHAR2(4 BYTE),
  TIPOPARENTESCOCO                VARCHAR2(4 BYTE),
  TIPOPERSONA2                    VARCHAR2(50 BYTE),
  TIPOCLIENTE                     VARCHAR2(50 BYTE),
  TIPOPRODUCTOS                   VARCHAR2(50 BYTE),
  ACTIVIDADCIIU_SOL               VARCHAR2(50 BYTE),
  IDRAMACIIU_SOL                  VARCHAR2(50 BYTE),
  IDESTADO                        VARCHAR2(1 BYTE) DEFAULT 'E',
  MENSAJE                         VARCHAR2(200 BYTE) DEFAULT 'Enviado',
  NOSUBIDA                        VARCHAR2(50 BYTE),
  NOSOLICITUD                     VARCHAR2(20 BYTE),
  IDBANCO                         VARCHAR2(50 BYTE),
  LATITUD                         NUMBER,
  LONGITUD                        NUMBER,
  RURALOURBANO                    VARCHAR2(1 BYTE),
  ENVIOWIFI                       VARCHAR2(10 BYTE),
  ENVIO3G                         VARCHAR2(10 BYTE),
  NOCREDITO                       VARCHAR2(7 BYTE),
  SECTORCONTABLE                  VARCHAR2(50 BYTE),
  SEGUNDONOMBRE                   VARCHAR2(50 BYTE),
  SEGUNDOAPELLIDO                 VARCHAR2(50 BYTE),
  SEGUNDONOMBRECO                 VARCHAR2(50 BYTE),
  SEGUNDOAPELLIDOCO               VARCHAR2(50 BYTE),
  CODPAISISO                      VARCHAR2(5 BYTE),
  APELLIDOCASADACLIENTE           VARCHAR2(50 BYTE),
  CEDULAEXTRANJERA                VARCHAR2(50 BYTE),
  DISPARA_TRG                     VARCHAR2(1 BYTE),
  RECIBEREMESAS                   VARCHAR2(1 BYTE)
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


CREATE UNIQUE INDEX PR.PK_TEMPFUD ON PR.TEMPFUD
(ID_TEMPFUD)
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
CREATE UNIQUE INDEX PR.PK_TEMPFUD1 ON PR.TEMPFUD
(ID_TEMPFUD, NOMARCHIVO)
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

ALTER TABLE PR.TEMPFUD ADD (
  CONSTRAINT PK_TEMPFUD1
  PRIMARY KEY
  (ID_TEMPFUD, NOMARCHIVO)
  USING INDEX PR.PK_TEMPFUD1
  ENABLE VALIDATE);


CREATE INDEX PR.IND01_TEMPFUD ON PR.TEMPFUD
(NUMDOCUMENTOIDENTIDAD)
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

CREATE INDEX PR.IND03_TEMPFUD ON PR.TEMPFUD
(NOCREDITO)
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

CREATE INDEX JESRODRIGUEZ.TEMPFUD_TIPO_PERSONA_IDX ON PR.TEMPFUD
(TIPOPERSONA)
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

DROP SEQUENCE PR.S_COD_PERSONA;

CREATE SEQUENCE PR.S_COD_PERSONA
  START WITH 5517008
  MAXVALUE 999999999999999999999999999
  MINVALUE 99999
  NOCYCLE
  NOCACHE
  NOORDER
  NOKEEP
  NOSCALE
  GLOBAL;


DROP SEQUENCE PR.S_DEPURADOR;

CREATE SEQUENCE PR.S_DEPURADOR
  START WITH 94634676
  MAXVALUE 9999999999
  MINVALUE 1
  CYCLE
  NOCACHE
  ORDER
  NOKEEP
  NOSCALE
  GLOBAL;


CREATE OR REPLACE TRIGGER PR.TR_POST_INSERT_TEMPFUD
   Before Insert
   On pr.tempfud
   Referencing New As New Old As Old
   For Each Row
DISABLE
Declare
   tmpvar                        Number;
   vmensaje_jmm                  Varchar2( 100 );
   p_codempresa                  Number( 5 );
   p_codagencia                  Number( 5 );
   p_nrocredito                  pr_creditos.no_credito%Type;
   p_mensajeerror                Varchar2( 200 );
   reg1                          pr_credito.t_rec_pr_creditos;
   v_error                       Varchar2( 200 );
   v_error_sysde                 Varchar2( 800 );
   v_desc_ejecutivo              Varchar2( 500 );
   v_desc_actividad              Varchar2( 500 );
   v_agencia_labora              Varchar2( 100 );
   v_desc_plan_inversion         Varchar2( 500 );
   v_persona                     id_personas.cod_persona%Type;
   v_persona2                    id_personas.cod_persona%Type;
   v_nompais                     pais.nacionalidad%Type;
   v_codpais                     pais.cod_pais%Type;
   --
   v_nompaisco                   pais.nacionalidad%Type;
   v_codpaisco                   pais.cod_pais%Type;
   --
   v_plazo                       pr_creditos.plazo%Type;
   vidprovincia                  provincias.cod_provincia%Type;
   tidprovincia                  provincias.cod_provincia%Type;
   --
   vplazo_minimo                 pr_tipo_credito.plazo_minimo%Type;
   vplazo_maximo                 pr_tipo_credito.plazo_maximo%Type;
   vmonto_minimo                 pr_tipo_credito.monto_minimo%Type;
   vmonto_maximo                 pr_tipo_credito.monto_maximo%Type;
   vvariacion_base               pr_tipo_credito.variacion_base%Type;
   --
   vporcentaje                   valores_de_tasas_de_interes.porcentaje%Type;
   vvariacion_min                tipos_de_tasas_de_interes.variacion_min%Type;
   vvariacion_max                tipos_de_tasas_de_interes.variacion_max%Type;
   --
   vidprovinciaco                provincias.cod_provincia%Type;
   tidprovinciaco                provincias.cod_provincia%Type;
   --
   v_cod_cat_clte                cat_clientes.cod_cat_clte%Type
      := param.parametro_x_empresa( p_codempresa => '1', p_abrev => 'P_COD_CAT_CLTE',
                                    p_codsistema => 'PA' );
   vcodoficial                   cliente.cod_oficial%Type;
   vcontempleados                Number;
   vfechapertura                 Varchar2( 11 );
   --
   vactividadc                   personas_fisicas.actividad%Type;
   vactividadp                   personas_fisicas.actividad%Type;
   vcodsubactividadc             sub_actividades_economicas.codigo_subactividad%Type;
   vcodsubactividadp             sub_actividades_economicas.codigo_subactividad%Type;
   v_credito_anula               Number( 5 );
   vpasext                       Varchar2( 1 ) := 'N';
   vpasextco                     Varchar2( 1 ) := 'N';
   --
   v_nombres                     Varchar2( 25 ) := Null;
   v_apellido1                   Varchar2( 25 ) := Null;
   v_apellido2                   Varchar2( 25 ) := Null;
   --
   v_nombresco                   Varchar2( 25 ) := Null;
   v_apellido1co                 Varchar2( 25 ) := Null;
   v_apellido2co                 Varchar2( 25 ) := Null;
   ---
   --- Excello:JPH:2019-02-12:Req._93767: Begin >>
   V_Procesado                   Varchar2( 1)   := Null; 
   V_MsgErr                      Varchar2(2000) := Null; 
   V_TipoTCo                     Varchar2( 1)   := Null; 
   --- Excello:JPH:2019-02-12:Req._93767: End <<  
   
   nacionalidadPE                Varchar2( 25 ) := Null;  
   nacionalidadPECO              Varchar2( 25 ) := Null;  
   
    v_paisx                      int := 1;
    v_distrito                   int := 0;
    v_distrito2                  int := 0;
    v_municipio                  Varchar2( 25 ) := Null;
    v_municipio2                 Varchar2( 25 ) := Null;
--
Begin

if nvl(:NEW.DISPARA_TRG,'S') = 'S' then
  f_log_procesoRR('TEMPFUD', 'ID_TEMPFUD: '||:new.id_tempfud||'  NOMARCHIVO: '||:new.nomarchivo
       ||'  IDENTIFICACION: '||:new.numdocumentoidentidad||'  agencia: '||:new.idagencia);
   
   p_codempresa               := 1;
   reg1.codigo_empresa        := To_number( p_codempresa );
   reg1.plazo_segun_unidad    := :New.plazocal;
   p_codagencia               := :New.idagencia;
   reg1.codigo_agencia        := To_number( p_codagencia );
   reg1.tipo_credito          := To_number( :New.tipoproductos );   --:New.tipoproductos;
   reg1.f_apertura            := fecha_actual_calendario( 'PR', p_codempresa, To_number( p_codagencia ));
                  
   --to_date('09/12/2015','dd/mm/yyyy');

-- p_depura('tempfud');
   --vfechapertura := fecha_actual_calendario( 'PR', p_codempresa, To_number( p_codagencia ));   --to_date('09/12/2015','dd/mm/yyyy');
   --reg1.f_apertura := to_date('18/12/2015','dd/mm/yyyy');--to_date(vfechapertura,'dd/mon/yyyy');
   -- Dbms_output.put_line( 'reg1.f_apertura=' || reg1.f_apertura );
   -- p_depura( 'reg1.f_apertura --> funcion: ' || vfechapertura );
   -- p_depura( 'reg1.f_apertura --> campo: ' || reg1.f_apertura );
   ---- p_depura('reg1.f_apertura --> funcion convert: '||to_date(fecha_actual_calendario( 'PR', p_codempresa, To_number( p_codagencia )),'dd/mm/yyyy'));
   ---- p_depura('reg1.f_apertura --> campo convert: '||to_char(reg1.f_apertura,'dd/mm/yyyy'));
   
    
    Begin
        
    
      Select cod_pais, nacionalidad
        Into v_codpais, v_nompais
        From pais
       Where pais_sb = trim(:New.idpais) and rownum < 2;
    
   Exception
      When No_data_found Then
        
         ---- Dbms_output.put_line(' codigo de pais no se encuentra registrado'|| :New.idpais);
         v_error                    :=
                               ' codigo de pais no se encuentra registrado'
                               || :New.idpais;
         :New.idestado              := 'R';
         -- :New.mensaje               := 'Rechazado';
         If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error, 0 ) Then
            -- Dbms_output.put_line(    ' codigo de pais no se encuentra registrado'
                                  --|| :New.idpais );
            f_log_procesoRR('TEMPFUD', 'V_error: '|| v_error|| ' - '||SQLERRM||'---'||DBMS_UTILITY.FORMAT_ERROR_STACK||'---'|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE );                    
            raise_application_error( num => -20000, msg => v_error );
         End If;
         f_log_procesoRR('TEMPFUD:'||:new.id_tempfud,'ID_TEMPFUD: '||:new.id_tempfud|| 'V_error: '|| v_error ); 
   End;
   If :New.idpaisco Is Not Null Then
      Begin
         Select cod_pais, nacionalidad
           Into v_codpaisco, v_nompaisco
           From pais
           Where pais_sb = :New.idpaisco and rownum < 2;
           
          --Where pais_sb = :New.idpais;
      Exception
         When No_data_found Then
            ---- Dbms_output.put_line(' codigo de pais no se encuentra registrado'|| :New.idpais);
            v_error                    :=
                               ' codigo de pais no se encuentra registrado'
                               || :New.idpais;
            :New.idestado              := 'R';
            -- :New.mensaje               := 'Rechazado';
            p_depura( 'Line : 145' || v_error );
            If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error, 0 ) Then
               -- Dbms_output.put_line(    ' codigo de pais no se encuentra registrado'
                                     --|| :New.idpais );
               f_log_procesoRR('TEMPFUD', 'V_error: '|| v_error|| ' - '||SQLERRM||'---'||DBMS_UTILITY.FORMAT_ERROR_STACK||'---'|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ); 
               raise_application_error( num => -20000, msg => v_error );
            End If;
            f_log_procesoRR('TEMPFUD:'||:new.id_tempfud,'ID_TEMPFUD: '||:new.id_tempfud|| 'V_error: '|| v_error );
      End;
   End If;
   Begin
      -- Dbms_output.put_line(    ' to_number(:New.tipoproductos)='
                            --|| To_number( :New.tipoproductos ));
      --------------------------------------------------------------------------------
      -- Validaci¿¿¿¿n del cliente
      --------------------------------------------------------------------------------        
      Begin
         Select cod_persona
           Into v_persona
           From id_personas b
          Where b.cod_tipo_id =
                      Decode( :New.tipodocumentoidentidad,
                              'C', '1',
                              'R', '2',
                              'P', '4',
                              'X', '5',
                              'PE','6'
                              )
            And b.num_id =
                   pa.formatear_identifi( :New.numdocumentoidentidad,
                                          Decode( :New.tipodocumentoidentidad,
                                                  'C', '1',
                                                  'R', '2',
                                                  'P', '4',
                                                  'X', '5',
                                                  'PE','6'));
         reg1.codigo_cliente        := v_persona;   -- JMM 20160423
      Exception
         When No_data_found Then
            /*Begin
               Select    ' identif: '
                      || Decode( :New.tipodocumentoidentidad,
                                 'C', '1',
                                 'R', '2',
                                 'P', '4' )
                      || ' * '
                      || pa.formatear_identifi( :New.numdocumentoidentidad,
                                                Decode( :New.tipodocumentoidentidad,
                                                        'C', '1',
                                                        'R', '2',
                                                        'P', '4' ))
                 Into vmensaje_jmm
                 From Dual;
            Exception
               When No_data_found Then */
               
                
            Begin
               Select cod_persona
                 Into v_persona
                 From id_personas b
                Where b.cod_tipo_id =
                         Decode( :New.tipodocumentoidentidad,
                                 'C', '1',
                                 'R', '2',
                                 'P', '4',
                                 'X', '5',
                                 'PE','6' )
                  And b.num_id =
                         pa.formatear_identifi( :New.numdocumentoidentidad,
                                                Decode( :New.tipodocumentoidentidad,
                                                        'C', '1',
                                                        'R', '2',
                                                        'P', '4',
                                                        'X', '5',
                                                        'PE','6' ));
               reg1.codigo_cliente        := v_persona;   -- JMM 20160423
               vpasext                    := 'S';
            Exception
               When No_data_found Then
                  reg1.codigo_cliente        := Null;
            End;
            --reg1.codigo_cliente := NULL;
            --End;
      -- p_depura( vmensaje_jmm );
      End;
      -- p_depura( 'v_persona: ' || v_persona );
      -- Verificacion de Codeudor
      
      
      Begin
         Select cod_persona
           Into v_persona2
           From id_personas b
          Where b.cod_tipo_id =
                    Decode( :New.tipodocumentoidentidadco,
                            'C', '1',
                            'R', '2',
                            'P', '4',
                            'X', '5',
                            'PE','6' )
            And b.num_id =
                   pa.formatear_identifi( :New.numdocumentoidentidadco,
                                          Decode( :New.tipodocumentoidentidadco,
                                                  'C', '1',
                                                  'R', '2',
                                                  'P', '4',
                                                  'X', '5',
                                                  'PE','6' ));
         reg1.codigo_clienteco      := v_persona2;   -- JMM 20160423
      Exception
         When No_data_found Then
            /*Begin
               Select    ' identif: '
                      || Decode( :New.tipodocumentoidentidadco,
                                 'C', '1',
                                 'R', '2',
                                 'P', '4' )
                      || ' * '
                      || pa.formatear_identifi( :New.numdocumentoidentidadco,
                                                Decode( :New.tipodocumentoidentidadco,
                                                        'C', '1',
                                                        'R', '2',
                                                        'P', '4' ))
                 Into vmensaje_jmm
                 From Dual;
            Exception
               When No_data_found Then*/
            Begin
               Select cod_persona
                 Into v_persona2
                 From id_personas b
                Where b.cod_tipo_id =
                         Decode( :New.tipodocumentoidentidadco,
                                 'C', '1',
                                 'R', '2',
                                 'P', '4',
                                 'X', '5',
                                 'PE','6' )
                  And b.num_id =
                         pa.formatear_identifi( :New.numdocumentoidentidadco,
                                                Decode( :New.tipodocumentoidentidadco,
                                                        'C', '1',
                                                        'R', '2',
                                                        'P', '4',
                                                        'X', '5',
                                                        'PE','6' ));
               reg1.codigo_clienteco      := v_persona2;   -- JMM 20160423
               vpasextco                  := 'S';
            Exception
               When Others Then
                  reg1.codigo_clienteco      := Null;
            End;
                  --Null;
            --End;
      -- p_depura( vmensaje_jmm );
      End;
      
      -- p_depura( 'v_persona2: ' || v_persona2 );
      --------------------------------------------------------------------------
      -- Creamos cliente  ** Identificaci¿¿¿¿n **
      --------------------------------------------------------------------------
      If     v_persona Is Null
         And reg1.codigo_cliente Is Null Then
         Select s_cod_persona.Nextval
           Into v_persona
           From Dual;
         -- p_depura( v_persona || ' PERSONA JMM' );
         reg1.codigo_cliente        := To_number( v_persona );
         --
         Begin
            Select concepto, grupo   --<<I.SSANMIGUEL|SYSDECL-508|13042016>>
              Into vactividadp, vcodsubactividadp
              From pa.actividades_economicas_bc_ciiu
             Where segregacion_rd = :New.idrama_ciiu
               And estado = 'S';
         --
         /*SELECT codigo_subactividad
           INTO vcodsubactividadp
           FROM sub_actividades_economicas
          WHERE codigo_actividad = :NEW.actividad_ciiu;  */
         Exception
            When Others Then
               v_error                    := 'Agregando Personas Fisicas' || Sqlerrm;
               :New.idestado              := 'R';
               -- :New.mensaje               := 'Rechazado';
               p_depura( 'Line : 334' || v_error );
               If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error, 0 ) Then
                  ---- Dbms_output.put_line(' codigo de pais no se encuentra registrado'|| :New.idpais);
                  f_log_procesoRR('TEMPFUD', 'V_error: '|| v_error|| ' - '||SQLERRM||'---'||DBMS_UTILITY.FORMAT_ERROR_STACK||'---'|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ); 
                  raise_application_error( num => -20000, msg => v_error );
               End If;
              f_log_procesoRR('TEMPFUD:'||:new.id_tempfud,'ID_TEMPFUD: '||:new.id_tempfud|| 'V_error: '|| v_error );
         End;
          --
          /*
          Begin
         SELECT substr(nombres,1,25), substr(apellido1,1,25), substr(apellido2,1,25)
         into v_nombres,v_apellido1,v_apellido2
            FROM TABLE (api_canales.fnconspadron2 (:NEW.numdocumentoidentidad, 'B2000'));
          exception when no_data_found then
              v_nombres := null;
              v_apellido1 := null;
              v_apellido2 := null;
          end;
          */
         --
         Begin
            Insert Into pa.personas_fisicas
                        ( cod_per_fisica, primer_nombre, primer_apellido,
                          segundo_apellido,segundo_nombre ,sexo,
                          fec_nacimiento,
                          est_civil, num_hijos, num_dependientes,
                          cod_sector, cod_actividad,
                          actividad, cod_subactividad, tipo_persona,
                          tipo_cliente, idioma_correo, email_usuario, email_servidor,
                          eval_ref_bancaria, eval_ref_tarjetas, eval_ref_laboral,
                          total_ingresos, cod_pais, fec_inclusion, incluido_por,
                          nacionalidad, rango_ingresos, CASADA_APELLIDO )
                 Values ( v_persona, :New.primernombre, Nvl( :New.primerapellido, ' ' ),
                          Nvl( :New.segundoapellido, ' ' ),:New.segundonombre, :New.sexo,
                          To_date( :New.fechanacimiento, 'dd/mm/yyyy' ),
                          :New.idestadocivil, :New.nohijos, :New.dependientes,
                          To_number( :New.sectoreconomico ), :New.idrama_ciiu,
                          vactividadp, vcodsubactividadp, :New.tipopersona2,
                          :New.tipocliente, 'ESPA', :New.email, Null,
                          'V', 'V', 'C',
                          0, v_codpais, Sysdate, User,
                          v_nompais, 1, :New.ApellidoCasadaCliente);
         Exception
            When Others Then
               v_error                    := 'Agregando Personas Fisicas' || Sqlerrm;
               :New.idestado              := 'R';
               -- :New.mensaje               := 'Rechazado';
               p_depura( 'Line : 381' || v_error );
               If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error, 0 ) Then
                  f_log_procesoRR('TEMPFUD', 'V_error: '|| v_error|| ' - '||SQLERRM||'---'||DBMS_UTILITY.FORMAT_ERROR_STACK||'---'|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ); 
                  raise_application_error( num => -20000, msg => v_error );
               End If;
               f_log_procesoRR('TEMPFUD:'||:new.id_tempfud,'ID_TEMPFUD: '||:new.id_tempfud|| 'V_error: '|| v_error );
         End;
         -- p_depura( 'PERSONAS Fisicas JMM ' || v_error );
         --------------------------------------------------------------------------
          
         Begin
            Insert Into pa.personas
                        ( cod_persona, cod_per_fisica, cod_per_juridica, es_fisica,
                          nombre, ind_clte_i2000,
                          paga_imp_ley288, benef_pag_ley288, cod_vinculacion,
                          cod_sec_contable, adicionado_por, fecha_adicion,
                          modificado_por, fecha_modificacion, codigo_sustituto,
                          estado_persona, cobr_nodgii_132011, lleno_fatca,
                          imprimio_fatca, es_fatca, fec_actualizacion, tel_verificado )
                 Values ( v_persona, v_persona, Null, 'S',
                          Substr( :New.primernombre || ' ' || :New.segundonombre || ' ' || :New.primerapellido || ' ' || :New.segundoapellido, 1, 65 ), 'N',
                          'S', 'S', :New.idtipovinculado,
                          :New.sectorcontable, User, Sysdate,
                          Null, Null, Null,
                          'A', 'S', 'N',   -- 'A', 'N', 'N',--- Excello:2022-09-01:REQ_155738: Se cambia el valor  indicador  cobr_nodgii_132011 a  'S' para que pague imp.
                          'N', 'N', Null, 'N' );
         Exception
            When Others Then
               v_error                    := 'Agregando Personas' || Sqlerrm;
               :New.idestado              := 'R';
               -- :New.mensaje               := 'Rechazado';
               p_depura('Agregando personas'|| v_error);
               If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error, 0 ) Then
                  f_log_procesoRR('TEMPFUD', 'V_error: '|| v_error|| ' - '||SQLERRM||'---'||DBMS_UTILITY.FORMAT_ERROR_STACK||'---'|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ); 
                  raise_application_error( num => -20000, msg => v_error );
               End If;
               f_log_procesoRR('TEMPFUD:'||:new.id_tempfud,'ID_TEMPFUD: '||:new.id_tempfud|| 'V_error: '|| v_error );
         End;
              -- p_depura( 'PERSONAS Fisicas JMM ' || v_error );
                  --------------------------------------------------------------------------
                  -- Direcci¿¿¿¿n del cliente
                  --------------------------------------------------------------------------
                  -- p_depura(    ' dir PERSONAS JMM '
         --                   || :New.direccion_idprovincia
         --                   || ' '
         --                   || :New.direccion_idmunicipio
         --                   || ' '
         --                   || :New.direccion_distrito );
          
         Begin
             v_paisx := v_codpais;
             vidprovincia := 0;
             v_distrito :=0;
         
              Select count(*) Into v_distrito
              From pa.distritos
              Where cod_pais = 1--v_codpais
               And cod_canton = To_number( Substr( :New.direccion_idmunicipio, 1, 2 ))
               And cod_distrito = To_number( Substr( :New.direccion_idmunicipio, 3, 2 ));
               
               v_municipio := Substr( :New.direccion_idmunicipio, 1, 2 );
               v_municipio2 := Substr( :New.direccion_idmunicipio, 3, 2 );
              
             
              
           if v_distrito > 0 then        
                 Select cod_provincia
                  Into vidprovincia
                  From pa.distritos
                 Where cod_pais = 1 --v_codpais
                   And cod_canton = To_number( Substr( :New.direccion_idmunicipio, 1, 2 ))
                   And cod_distrito = To_number( Substr( :New.direccion_idmunicipio, 3, 2 )); 
           else
                 vidprovincia := 1;
                 v_paisx := 1;
                 v_municipio := '1';
                 v_municipio2 := '1';
          
           end if;   
         

         Exception
            When Others Then
               v_error                    := Sqlerrm;
               :New.idestado              := 'R';
               -- :New.mensaje               := 'Rechazado';
               p_depura( 'PERSONAS distritos Fisicas JMM ' || v_error || 'Codigo Pais '|| v_codpais);
               vidprovincia := 1;
               v_paisx := 1;
               /*
               If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error, 0 ) Then
                  ---- Dbms_output.put_line(' codigo de pais no se encuentra registrado'|| :New.idpais);
                  raise_application_error( num => -20000, msg => v_error );
               End If;
               */
            
         End;
         Begin
             
            v_paisx := 1;
            
            
            Insert Into pa.dir_personas
                        ( cod_persona, cod_direccion, tip_direccion, apartado_postal,
                          cod_postal, detalle, cod_pais, cod_provincia,
                          cod_canton,
                          cod_distrito, cod_pueblo,
                          es_default, colonia, zona, ind_estado )
                 Values ( v_persona, 1, 1, Null,
                          Null, :New.direccion, v_paisx, vidprovincia,
                          To_number(v_municipio ),-- To_number( Substr( :New.direccion_idmunicipio, 1, 2 )),
                          --idmunicipio
                          To_number( Substr( :New.direccion_idmunicipio, 3, 2 )), 1,
                          'S', Null, Null, 'S' );
         Exception
            When Others Then
               v_error                    := 'Agregando Direccion 1 Personas' || Sqlerrm;
               :New.idestado              := 'R';
               
               -- :New.mensaje               := 'Rechazado';
               p_depura( 'Line : 499' || v_error );
               If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error, 0 ) Then
                  ---- Dbms_output.put_line(' codigo de pais no se encuentra registrado'|| :New.idpais);
                  f_log_procesoRR('TEMPFUD', 'V_error: '|| v_error|| ' - '||SQLERRM||'---'||DBMS_UTILITY.FORMAT_ERROR_STACK||'---'|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ); 
                  raise_application_error( num => -20000, msg => v_error );
               End If;
               f_log_procesoRR('TEMPFUD:'||:new.id_tempfud,'ID_TEMPFUD: '||:new.id_tempfud|| 'V_error: '|| v_error );
         End;
         -- p_depura( 'dir PERSONAS JMM post' || Sqlerrm );
         --------------------------------------------------------------------------
         -- p_depura( ' dir 2  PERSONAS JMM' );
         Begin
         /*
            Select cod_provincia
              Into tidprovincia
              From pa.distritos
             Where cod_pais = v_codpais
               And cod_canton = To_number( Substr( :New.trabajo_idmunicipio, 1, 2 ))
               And cod_distrito = To_number( Substr( :New.trabajo_idmunicipio, 3, 2 ));
              */ 
               
               
              v_paisx := v_codpais;
         
              Select count(*) Into v_distrito2
              From pa.distritos
               Where cod_pais = 1 --v_codpais
               And cod_canton = To_number( Substr( :New.trabajo_idmunicipio, 1, 2 ))
               And cod_distrito = To_number( Substr( :New.trabajo_idmunicipio, 3, 2 ));
               
               v_municipio := Substr( :New.trabajo_idmunicipio, 1, 2 );
               v_municipio2 := Substr( :New.trabajo_idmunicipio, 3, 2 );
                 
                
           if v_distrito2 > 0 then        
                 Select cod_provincia
                  Into tidprovincia
                  From pa.distritos
                 Where cod_pais = 1 --v_codpais
                   And cod_canton = To_number( Substr( :New.trabajo_idmunicipio, 1, 2 ))
                   And cod_distrito = To_number( Substr( :New.trabajo_idmunicipio, 3, 2 ));
           else
                 tidprovincia := 1;
                 v_paisx := 1;
                 v_municipio := '1';
                 v_municipio2 := '1';
           
           end if;     
               
               
               
               
               
               
         Exception
            When Others Then
               v_error                    := Sqlerrm;
               :New.idestado              := 'R';
               -- :New.mensaje               := 'Rechazado';
               p_depura( 'Line : 557' || v_error );
               If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error, 0 ) Then
                  ---- Dbms_output.put_line(' codigo de pais no se encuentra registrado'|| :New.idpais);
                  f_log_procesoRR('TEMPFUD', 'V_error: '|| v_error|| ' - '||SQLERRM||'---'||DBMS_UTILITY.FORMAT_ERROR_STACK||'---'|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ); 
                  raise_application_error( num => -20000, msg => v_error );
               End If;
               f_log_procesoRR('TEMPFUD:'||:new.id_tempfud,'ID_TEMPFUD: '||:new.id_tempfud|| 'V_error: '|| v_error );
         End;
         Begin
          v_paisx := 1;
            Insert Into pa.dir_personas
                        ( cod_persona, cod_direccion, tip_direccion, apartado_postal,
                          cod_postal, detalle, cod_pais, cod_provincia,
                          cod_canton,
                          cod_distrito, cod_pueblo,
                          es_default, colonia, zona, ind_estado )
                 Values ( v_persona, 2, 2, Null,
                          Null, :New.trabajo_direccion, v_paisx, tidprovincia,
                          To_number( v_municipio),--To_number( Substr( :New.trabajo_idmunicipio, 1, 2 )),
                          To_number( Substr( :New.trabajo_idmunicipio, 3, 2 )), Null,
                          'N', Null, Null, 'S' );
                           p_depura('aqui5555555x ****** '||:New.idpaisco); 
         Exception
            When Others Then
               v_error                    := 'Agregando Direccion 2 Personas' || Sqlerrm;
               :New.idestado              := 'R';
               -- :New.mensaje               := 'Rechazado';
                p_depura('Error Agregando Direccion 2 Personas '||:New.idpaisco); 
               If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error, 0 ) Then
                  ---- Dbms_output.put_line(' codigo de pais no se encuentra registrado'|| :New.idpais);
                  f_log_procesoRR('TEMPFUD', 'V_error: '|| v_error|| ' - '||SQLERRM||'---'||DBMS_UTILITY.FORMAT_ERROR_STACK||'---'|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ); 
                  raise_application_error( num => -20000, msg => v_error );
               End If;
               f_log_procesoRR('TEMPFUD:'||:new.id_tempfud,'ID_TEMPFUD: '||:new.id_tempfud|| 'V_error: '|| v_error );
         End;
       
         -- p_depura( ' dir 2  PERSONAS JMM post' || Sqlerrm );
         --------------------------------------------------------------------------
         -- Direccion de Envio
         --------------------------------------------------------------------------
        
         Begin
            Insert Into dir_envio_x_pers
                        ( cod_persona, tipo_envio, cod_direccion )
                 Values ( v_persona, 'D', 1 );
         Exception
            When Others Then
               v_error                    :=
                                      'Agregando Direccion Envio Por Personas' || Sqlerrm;
               :New.idestado              := 'R';
               -- :New.mensaje               := 'Rechazado';
               p_depura( 'Line : 604' || v_error );
               If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error, 0 ) Then
                  ---- Dbms_output.put_line(' codigo de pais no se encuentra registrado'|| :New.idpais);
                  f_log_procesoRR('TEMPFUD', 'V_error: '|| v_error|| ' - '||SQLERRM||'---'||DBMS_UTILITY.FORMAT_ERROR_STACK||'---'|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ); 
                  raise_application_error( num => -20000, msg => v_error );
               End If;
               f_log_procesoRR('TEMPFUD:'||:new.id_tempfud,'ID_TEMPFUD: '||:new.id_tempfud|| 'V_error: '|| v_error );
         End;
         -----------------------------------------------------------------------
         -- Tel¿¿¿¿fonos del cliente
         -----------------------------------------------------------------------
         -- JMoraM 20160305 -- Se validan que tengan al menos un telefono
         -----------------------------------------------------------------------
        
         Begin
            If     To_number( Replace( Trim( :New.telefono_casa ), '-' )) = 0
               And To_number( Replace( Trim( :New.telefono_celular ), '-' )) = 0 Then
               v_error                    :=
                            'El cliente debe tener minimo un telefono de casa o celular.';
               :New.idestado              := 'R';
               -- :New.mensaje               := 'Rechazado';
               p_depura( 'Line : 623' || v_error );
               If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error, 0 ) Then
               f_log_procesoRR('TEMPFUD', 'V_error: '|| v_error|| ' - '||SQLERRM||'---'||DBMS_UTILITY.FORMAT_ERROR_STACK||'---'|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ); 
                  raise_application_error( num => -20000, msg => v_error );
               End If;
            End If;
         Exception
            When Others Then
               v_error                    := 'Validando telefonos Deudor' || Sqlerrm;
               :New.idestado              := 'R';
               -- :New.mensaje               := 'Rechazado';
               p_depura( 'Line : 633' || v_error );
               If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error, 0 ) Then
                  raise_application_error( num => -20000, msg => v_error );
               End If;
               f_log_procesoRR('TEMPFUD:'||:new.id_tempfud,'ID_TEMPFUD: '||:new.id_tempfud|| 'V_error: '|| v_error );
         End;
         --------------------------------------------------------------------------
         If To_number( Replace( Trim( :New.telefono_casa ), '-' )) != 0 Then
            Begin
               Insert Into pa.tel_personas
                           ( cod_persona, cod_area,
                             num_telefono, tip_telefono,
                             tel_ubicacion, extension, nota, es_default, posicion,
                             cod_direccion, cod_pais, modificado_por,
                             fecha_modificacion, incluido_por, fec_inclusion )
                    Values ( v_persona, Substr( :New.telefono_casa, 1, 3 ),
                             Replace( Substr( :New.telefono_casa, 4 ), '-', Null ), 'R',
                             'O', Null, 'PortaCredit', 'S', Null,
                             1, v_codpais, Null,
                             Null, User, Sysdate );
            Exception
               WHEN DUP_VAL_ON_INDEX THEN
                  NULL;  -- JDIAZ 04/10/2019  Cuando el número existe no es necesario volver a incluirlo y no va a devolver error a Portacredit.
               When Others Then
                  v_error                    :=
                                               'Agregando Telefono 1 Personas' || Sqlerrm;
                  :New.idestado              := 'R';
                  -- :New.mensaje               := 'Rechazado';
                  p_depura( 'Line : 660' || v_error );
                  If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error, 0 ) Then
                     ---- Dbms_output.put_line(' codigo de pais no se encuentra registrado'|| :New.idpais);
                     f_log_procesoRR('TEMPFUD', 'V_error: '|| v_error|| ' - '||SQLERRM||'---'||DBMS_UTILITY.FORMAT_ERROR_STACK||'---'|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ); 
                     raise_application_error( num => -20000, msg => v_error );
                  End If;
                  f_log_procesoRR('TEMPFUD:'||:new.id_tempfud,'ID_TEMPFUD: '||:new.id_tempfud|| 'V_error: '|| v_error );
            End;
         End If;
         --------------------------------------------------------------------------
          
         If To_number( Replace( Trim( :New.telefono_celular ), '-' )) != 0 Then
            Begin
               Insert Into pa.tel_personas
                           ( cod_persona, cod_area,
                             num_telefono,
                             tip_telefono, tel_ubicacion, extension, nota, es_default,
                             posicion, cod_direccion, cod_pais, modificado_por,
                             fecha_modificacion, incluido_por, fec_inclusion )
                    Values ( v_persona, Substr( :New.telefono_celular, 1, 3 ),
                             Replace( Substr( :New.telefono_celular, 4 ), '-', Null ),
                             'R', 'O', Null, 'PortaCredit', 'S',
                             Null, 1, v_codpais, Null,
                             Null, User, Sysdate );
            Exception
             WHEN DUP_VAL_ON_INDEX THEN
                  NULL;  -- malmanzar 21/04/2021  Cuando el número existe no es necesario volver a incluirlo y no va a devolver error a Portacredit.
               When Others Then
                  v_error                    :=
                                               'Agregando Telefono 2 Personas' || Sqlerrm;
                  :New.idestado              := 'R';
                  -- :New.mensaje               := 'Rechazado';
                  p_depura( 'Line : 690' || v_error );
                  If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error, 0 ) Then
                     ---- Dbms_output.put_line(' codigo de pais no se encuentra registrado'|| :New.idpais);
                     f_log_procesoRR('TEMPFUD', 'V_error: '|| v_error|| ' - '||SQLERRM||'---'||DBMS_UTILITY.FORMAT_ERROR_STACK||'---'|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ); 
                     raise_application_error( num => -20000, msg => v_error );
                  End If;
                  f_log_procesoRR('TEMPFUD:'||:new.id_tempfud,'ID_TEMPFUD: '||:new.id_tempfud|| 'V_error: '|| v_error );
            End;
         End If;
         --------------------------------------------------------------------------
         -- Identificaci¿¿¿¿n del cliente
         --------------------------------------------------------------------------
         
         Begin
             
            IF :New.CODPAISISO IS NULL THEN
                nacionalidadPE := v_nompais;
            ELSE
                select nacionalidad into nacionalidadPE from pais where pais_sb = :New.CODPAISISO and rownum <= 1;     
            END IF;   
         
            p_depura('Nacionalidad  ' || nacionalidadPE);
         
            If vpasext = 'S' Then
                --PASAPORTE EXTRANJERO
                --
                IF :New.tipodocumentoidentidad = 'X' AND :New.CedulaExtranjera IS NOT NULL THEN 
                         Insert Into pa.id_personas
                           ( 
                             cod_persona,
                             cod_tipo_id,
                             num_id,
                             fec_vencimiento, 
                             cod_pais,
                             nacionalidad
                           )
                          Values (
                               v_persona,
                               6,
                               pa.formatear_identifi( :New.CedulaExtranjera, 6),
                               To_date( '31/12/2050', 'dd/mm/yyyy' ), 
                               v_codpais, 
                               nacionalidadPE);
                END IF;      
           
               Insert Into pa.id_personas
                           ( cod_persona,
                             cod_tipo_id,
                             num_id,
                             fec_vencimiento, 
                             cod_pais, 
                             nacionalidad )
                    Values ( v_persona,
                             Decode( :New.tipodocumentoidentidad,
                                     'C', '1',
                                     'R', '2',
                                     'P', '4',
                                     'X', '5',
                                     'PE','6'),
                             pa.formatear_identifi( :New.numdocumentoidentidad,
                                                    Decode( :New.tipodocumentoidentidad,
                                                             'C', '1',
                                                             'R', '2',
                                                             'P', '4',
                                                             'X', '5',
                                                             'PE','6')),
                             To_date( '31/12/2050', 'dd/mm/yyyy' ), v_codpais, nacionalidadPE );
            Else
             
    IF :New.tipodocumentoidentidad = 'X' AND :New.CedulaExtranjera IS NOT NULL THEN
                 Insert Into pa.id_personas
                   ( cod_persona,
                     cod_tipo_id,
                     num_id,
                     fec_vencimiento, 
                     cod_pais,
                     nacionalidad
                      )
                  Values (v_persona,
                       6,
                       pa.formatear_identifi( :New.CedulaExtranjera, 6),
                       To_date( '31/12/2050', 'dd/mm/yyyy' ), 
                       v_codpais, 
                       nacionalidadPE);
     END IF;    
            
               Insert Into pa.id_personas
                           ( cod_persona,
                             cod_tipo_id,
                             num_id,
                             fec_vencimiento, 
                             cod_pais,
                             nacionalidad )
                    Values ( v_persona,
                             Decode( :New.tipodocumentoidentidad,
                                     'C', '1',
                                     'R', '2',
                                     'P', '4',
                                     'X', '5',
                                     'PE','6'),
                             pa.formatear_identifi( :New.numdocumentoidentidad,
                                                    Decode( :New.tipodocumentoidentidad,
                                                            'C', '1',
                                                            'R', '2',
                                                            'P', '4',
                                                             'X', '5',
                                                             'PE','6' )),
                             To_date( '31/12/2050', 'dd/mm/yyyy' ), v_codpais, nacionalidadPE );
            End If;
         Exception
            When Others Then
               v_error                    := 'Agregando ID Personas' || Sqlerrm;
               :New.idestado              := 'R';
               -- :New.mensaje               := 'Rechazado';
               p_depura( 'Line : 802' || v_error );
               
               If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error, 0 ) Then
                  ---- Dbms_output.put_line(' codigo de pais no se encuentra registrado'|| :New.idpais);
                  f_log_procesoRR('TEMPFUD', 'V_error: '|| v_error|| ' - '||SQLERRM||'---'||DBMS_UTILITY.FORMAT_ERROR_STACK||'---'|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ); 
                  raise_application_error( num => -20000, msg => v_error );
               End If;
               f_log_procesoRR('TEMPFUD:'||:new.id_tempfud,'ID_TEMPFUD: '||:new.id_tempfud|| 'V_error: '|| v_error );
         End;
         ---- p_depura( 'id_personas ' || Sqlerrm );
         -- p_depura( 'insert info_doc_fisica_nacional' );
         --------------------------------------------------------------------------
         -- Se ingresa informacion documentos de persona fisica--------------------
         Begin
            Insert Into info_doc_fisica_nacional
                        ( cod_persona, pind_cedula, pind_licencia_conducir,
                          pind_residencia, pind_id_otro, id_otro_desc,
                          pind_certificado_nacimiento, pind_pensionado_jubilado,
                          pind_lab_tiempo, pind_lab_ingreso_anual,
                          pind_lab_puesto_desempena, pind_trabaja_independiente,
                          pind_independiente_actividad, pind_independiente_justifica_a,
                          comentarios_adicionales )
                 Values ( v_persona, 'S', 'N',
                          'N', 'N', Null,
                          'N', 'N',
                          'N', 'N',
                          'N', 'N',
                          'N', 'N',
                          'Registrado por PDA' );
         ---- p_depura( 'insert info_doc_fisica_nacional' || Sqlerrm );
         Exception
            When Others Then
               v_error                    :=
                                          'Agregando Informacion Doc Personas' || Sqlerrm;
               :New.idestado              := 'R';
               -- :New.mensaje               := 'Rechazado';
               p_depura( 'Line : 835' || v_error );
               If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error, 0 ) Then
                  ---- Dbms_output.put_line(' codigo de pais no se encuentra registrado'|| :New.idpais);
                  f_log_procesoRR('TEMPFUD', 'V_error: '|| v_error|| ' - '||SQLERRM||'---'||DBMS_UTILITY.FORMAT_ERROR_STACK||'---'|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ); 
                  raise_application_error( num => -20000, msg => v_error );
               End If;
               f_log_procesoRR('TEMPFUD:'||:new.id_tempfud,'ID_TEMPFUD: '||:new.id_tempfud|| 'V_error: '|| v_error );
         End;
         --------------------------------------------------------------------------
         --------------------------------------------------------------------------
         -- Cliente para pasarlo a Cliente
         --------------------------------------------------------------------------
         -- p_depura( 'insert Cliente para pasarlo a Cliente' );
        
         Begin
            -- p_depura( 'insert Cliente para pasarlo a Cliente - entro a insert ' );
           
            Begin
               Select codigo_persona
                 Into vcodoficial
                 From pr_analistas
                Where codigo_analista = :New.idoficial;
               If vcodoficial Is Not Null Then
                  Select Count( 1 )
                    Into vcontempleados
                    From empleados
                   Where id_empleado = vcodoficial;
                  If vcontempleados = 0 Then
                     v_error                    :=
                                            'No existe oficial como empleado ' || Sqlerrm;
                     :New.idestado              := 'R';
                     -- :New.mensaje               := 'Rechazado';
                     p_depura( 'Line : 866' || v_error );
                     If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error,
                                                        0 ) Then
                        ---- Dbms_output.put_line(' codigo de pais no se encuentra registrado'|| :New.idpais);
                        f_log_procesoRR('TEMPFUD', 'V_error: '|| v_error|| ' - '||SQLERRM||'---'||DBMS_UTILITY.FORMAT_ERROR_STACK||'---'|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ); 
                        raise_application_error( num => -20000, msg => v_error );
                     End If;
                  End If;
               End If;
            Exception
               When No_data_found Then
                  v_error                    := 'No existe oficial ' || Sqlerrm;
                  :New.idestado              := 'R';
                  -- :New.mensaje               := 'Rechazado';
                  p_depura( 'Line : 879' || v_error );
                  If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error, 0 ) Then
                     ---- Dbms_output.put_line(' codigo de pais no se encuentra registrado'|| :New.idpais);
                     f_log_procesoRR('TEMPFUD', 'V_error: '|| v_error|| ' - '||SQLERRM||'---'||DBMS_UTILITY.FORMAT_ERROR_STACK||'---'|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ); 
                     raise_application_error( num => -20000, msg => v_error );
                  End If;
            End;
            Insert Into cliente
                        ( cod_empresa, cod_cliente, num_cliente, cod_agencia,
                          cod_cat_clte, esta_activo, paga_impto_renta, fec_ingreso,
                          cat_riesgo, cod_oficial, cod_promotor, cliente_especial,
                          tipo_deudor, cross_estimado, cross_calculado, rentabilidad,
                          mon_ingreso_bco, mon_egreso_bco, estado_cliente, cod_nicho,
                          comentario_act_ingreso )
                 Values ( p_codempresa, v_persona, v_persona, To_number( p_codagencia ),
                          v_cod_cat_clte, 'S', 'S', Sysdate,

                          --to_date(reg1.f_apertura,'dd/mm/yyyy'),
                          'A', vcodoficial, vcodoficial, 'N',
                          '1', 30, 0, 0,
                          0, 0, 'A', '99',
                          'INGRESO POR PDA' );
            -- p_depura( 'culima insert into cliente:' || Sqlerrm );
         ---- p_depura( 'insert Cliente para pasarlo a Cliente - termino insert :' || Sqlerrm );
         Exception
            When Others Then
               v_error                    := 'Agregando Cliente' || Sqlerrm;
               :New.idestado              := 'R';
               -- :New.mensaje               := 'Rechazado';
               p_depura( 'Line : 907' || v_error );
               If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error, 0 ) Then
                  ---- Dbms_output.put_line(' codigo de pais no se encuentra registrado'|| :New.idpais);
                  f_log_procesoRR('TEMPFUD', 'V_error: '|| v_error|| ' - '||SQLERRM||'---'||DBMS_UTILITY.FORMAT_ERROR_STACK||'---'|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ); 
                  raise_application_error( num => -20000, msg => v_error );
               End If;
               f_log_procesoRR('TEMPFUD:'||:new.id_tempfud,'ID_TEMPFUD: '||:new.id_tempfud|| 'V_error: '|| v_error );
         End;
      -- p_depura( 'termino insert Cliente para pasarlo a Cliente:' || Sqlerrm );
       
      Else
        
         reg1.codigo_cliente        := To_number( v_persona );
         
         -- Excello:JPH:2019-02-12:Req._93767: Begin >>
         -- Actualizacion datos clientes  ---
         
         --1- Datos Persona --
         If :New.Idtipovinculado Is Not Null Then --- Tipo Vinculacion 
            PA.Pa_Mant_Datos_Personas.P_Act_Datos_Cliente_Persona( V_Persona,
                                                                'TIP_VINCULO',
                                                                :New.Idtipovinculado,                                 
                                                                V_Procesado,   
                                                                V_Error 
                                                               );  
         
            If V_MsgErr Is Not Null Then
              V_Error :=  'FUD Error procesando cliente '||' '||V_MsgErr;
              :New.Mensaje := Substr(V_Error,1,200);
            End If;
         
         End If;
                  
         If :New.Email Is Not Null Then
            PA.Pa_Mant_Datos_Personas.P_Act_Datos_Cliente_Persona( V_Persona,
                                                                'EMAIL',
                                                                :New.Email,                                 
                                                                V_Procesado,   
                                                                V_Error 
                                                               );  
         
            If V_MsgErr Is Not Null Then
              V_Error :=  'FUD Error procesando cliente '||' '||V_MsgErr;
              :New.Mensaje := Substr(V_Error,1,200);
            End If;
         
         End If;
      
         -- 2- Direcciones  --
         -- 2.1- Direccion Domicilio ---
         If  Length(:New.Direccion) > 0 Then
           PA.Pa_Mant_Datos_Personas.P_Inserta_Direccion( V_Persona,
                                                        :New.Direccion,
                                                        :New.Direccion_Idmunicipio,
                                                        V_Codpais,
                                                        '1',
                                                        'S',
                                                        V_Procesado,
                                                        V_MsgErr 
                                                      );
        
           If V_MsgErr Is Not Null Then
              V_Error :=  'FUD Error procesando cliente '||' '||V_MsgErr;
              :New.Mensaje := Substr(V_Error,1,200);
           End If;
        End If;
         
        -- 2.2- Direccion Trabajo ---
        If  Length(:New.Trabajo_Direccion) > 0 Then
           PA.Pa_Mant_Datos_Personas.P_Inserta_Direccion( V_Persona,
                                                        :New.Trabajo_Direccion,
                                                        :New.Trabajo_Idmunicipio,
                                                        V_Codpais,
                                                        '2',
                                                        'N',
                                                        V_Procesado,
                                                        V_MsgErr 
                                                      );
        
           If V_MsgErr Is Not Null Then
              V_Error :=  'FUD Error procesando cliente '||' '||V_MsgErr;
              :New.Mensaje := Substr(V_Error,1,200);
           End If;
        End If;
        
        --2.2.1 Información Laboral  --
        -- Se comenta porque se realziará desde el triger TR_POST_INSERT_TEMPFEC sobre TEMPFEC
        --- Excello:JPH:2020-03-20:REQ_108967:Begin >>
 /*       If:New.Nombrenegocio Is Not Null 
        Then
               PA.Pa_Mant_Datos_Personas.P_Inserta_Info_Laboral(  V_Persona,
                                                                  Nvl(To_Date(:New.Fechaingreso,'DD/MM/YYYY'),
                                                                      To_Date('01'||'/'||:New.Inicio_Mes||'/'||:New.Inicio_Ano
                                                                              ,'DD/MM/YYYY')),
                                                                  :New.Nombrenegocio,
                                                                  0, -- Sueldo (Campo no existe en tabla 
                                                                  Nvl(:New.Cargo,'PROPIETTARIO'),
                                                                  :New.Trabajo_Direccion,
                                                                  Replace(:New.Telefono,'-'),
                                                                  To_Char(To_Number(:New.Extension)),
                                                                 --- Excello:JPH:2020-03-19:REQ_108967:Begin >>
                                                                 :New.Nomarchivo,
                                                                 :New.Tipodocumentoidentidad,
                                                                 :New.Numdocumentoidentidad,
                                                                 --- Excello:JPH:2020-03-19:REQ_108967:End <<
                                                                 V_Procesado,
                                                                 V_MsgErr
                                                             );
                If V_MsgErr Is Not Null Then
                   V_Error :=  'FUD Error procesando información laboral'||' '||V_MsgErr;
                   :New.Mensaje := Substr(V_Error,1,200);
                End If;     
        --- Excello:JPH:2020-03-20:REQ_108967:End <<
        Elsif  :New.Lugartrabajo Is Not Null  
        Then   
            
                PA.Pa_Mant_Datos_Personas.P_Inserta_Info_Laboral(   V_Persona,
                                                                    To_Date(:New.Fechaingreso,'DD/MM/YYYY'),
                                                                    :New.Lugartrabajo,
                                                                    0, -- Sueldo (Campo no existe en tabla 
                                                                    Nvl(:New.Cargo,'NO ESPECIFICADO'),
                                                                    :New.Trabajo_Direccion,
                                                                    Replace(:New.Telefono,'-'),
                                                                    To_Char(To_Number(:New.Extension)),
                                                                    --- Excello:JPH:2020-03-19:REQ_108967:Begin >>
                                                                    :New.Nomarchivo,
                                                                    :New.Tipodocumentoidentidad,
                                                                    :New.Numdocumentoidentidad,
                                                                    --- Excello:JPH:2020-03-19:REQ_108967:End <<
                                                                    V_Procesado,
                                                                    V_MsgErr
                                                                );
                If V_MsgErr Is Not Null Then
                   V_Error :=  'FUD Error procesando información laboral'||' '||V_MsgErr;
                   :New.Mensaje := Substr(V_Error,1,200);
                End If;                                            
        
        End If;
     */   
        
        -- 3- Telefonos  --
        -- 3.1- Residencial --
        
        If  To_Number( Replace(:New.Telefono_Casa, '-' )) != 0 Then  
        
           PA.Pa_Mant_Datos_Personas.P_Inserta_Telefono( V_Persona,
                                                      Replace(:New.Telefono_Casa,'-' ),
                                                      Null,
                                                      'R',
                                                      'PortaCredit',
                                                      V_Codpais,
                                                      'S',
                                                      V_Procesado,
                                                      V_MsgErr 
                                                     );
        
           If V_MsgErr Is Not Null Then
              V_Error :=  'FUD Error procesando cliente '||' '||V_MsgErr;
              :New.Mensaje := Substr(V_Error,1,200);
           End If;
        End If;
        
        -- 3.2- celular --
        If  To_Number( Replace(:New.Telefono_Celular, '-' )) != 0 Then  
        
           PA.Pa_Mant_Datos_Personas.P_Inserta_Telefono( V_Persona,
                                                      Replace(:New.Telefono_Celular,'-' ),
                                                      Null,
                                                      'C',
                                                      'PortaCredit',
                                                      V_Codpais,
                                                      'N',
                                                      V_Procesado,
                                                      V_MsgErr 
                                                      );
        
           If V_MsgErr Is Not Null Then
              V_Error :=  'FUD Error procesando cliente '||' '||V_MsgErr;
              :New.Mensaje := Substr(V_Error,1,200);
           End If;
        End If; 
         
       -- Excello:JPH:2019-02-12:Req_93767: End << 
       
       --- Excello:JPH:2020-03-19:REQ_108967:Begin >>
       --==============================================
       /*  Nuevos campos a ser actualizados  */
       --==============================================
       -- 4- Tipo De Cliente
      
       If :New.Tipocliente IS Not Null Then
          PA.Pa_Mant_Datos_Personas.P_Act_Datos_Cliente_Persona( V_Persona,
                                                                 'TIPCLI',
                                                                 :New.Tipocliente,                                 
                                                                 V_Procesado,   
                                                                 V_Error 
                                                               );  
         
            If V_MsgErr Is Not Null Then
              V_Error :=  'FUD Error procesando cliente '||' '||V_MsgErr;
              :New.Mensaje := Substr(V_Error,1,200);
            End If;
       End If;
       
       -- 5- Estado Civil
       If :New.Idestadocivil IS Not Null Then
          PA.Pa_Mant_Datos_Personas.P_Act_Datos_Cliente_Persona( V_Persona,
                                                                 'ESTCIV',
                                                                 :New.Idestadocivil,                                 
                                                                 V_Procesado,   
                                                                 V_Error 
                                                               );  
         
            If V_MsgErr Is Not Null Then
              V_Error :=  'FUD Error procesando cliente '||' '||V_MsgErr;
              :New.Mensaje := Substr(V_Error,1,200);
            End If;
       End If;
        
       -- 6- Actividad Economica
       If :New.Idrama_Ciiu IS Not Null Then
          PA.Pa_Mant_Datos_Personas.P_Act_Datos_Cliente_Persona( V_Persona,
                                                                 'ACTECO',
                                                                 :New.Idrama_Ciiu,                                 
                                                                 V_Procesado,   
                                                                 V_Error 
                                                               );  
         
            If V_MsgErr Is Not Null Then
              V_Error :=  'FUD Error procesando cliente '||' '||V_MsgErr;
              :New.Mensaje := Substr(V_Error,1,200);
            End If;
       End If;
       
      
       
       --- Excello:JPH:2020-03-19:REQ_108967:End <<
       /*
       Begin
      SELECT substr(nombres,1,25), substr(apellido1,1,25), substr(apellido2,1,25)
      into v_nombres,v_apellido1,v_apellido2
         FROM TABLE (api_canales.fnconspadron2 (:NEW.numdocumentoidentidad, 'B2000'));
       exception when no_data_found then
           v_nombres := null;
           v_apellido1 := null;
           v_apellido2 := null;
       end;

       update personas_fisicas set primer_nombre = nvl(v_nombres,primer_nombre),
       primer_apellido = nvl(v_apellido1,primer_apellido),
       segundo_apellido = nvl(v_apellido2,segundo_apellido)
       where cod_per_fisica = v_persona;
       --
       --
       update personas set nombre = nvl(substr(nvl(v_nombres,' ')||' '||
       nvl(v_apellido1,' ')||' '||
       nvl(v_apellido2,' '),1,65),nombre)
       where cod_persona = v_persona;     */
      End If;
      --
      If     v_persona2 Is Null
         And reg1.codigo_clienteco Is Null
         And :New.numdocumentoidentidadco Is Not Null Then
         Select s_cod_persona.Nextval
           Into v_persona2
           From Dual;
         -- p_depura( v_persona2 || ' PERSONA deudor JMM' );
         reg1.codigo_clienteco      := To_number( v_persona2 );
         reg1.codigo_relacionco     := 'O';
         -- p_depura( v_persona2 || ' PERSONA deudor JMM ' );
         Begin
            Select concepto, grupo   --<<I.SSANMIGUEL|SYSDECL-508|13042016>>
              Into vactividadc, vcodsubactividadc
              From pa.actividades_economicas_bc_ciiu
             Where segregacion_rd = :New.idrama_ciiuco
               And estado = 'S';
         --
         --
         /*SELECT codigo_subactividad
           INTO vcodsubactividadc
           FROM sub_actividades_economicas
          WHERE codigo_actividad = :NEW.actividad_ciiuco; */
         Exception
            When Others Then
               v_error                    := 'Agregando Personas Fisicas' || Sqlerrm;
               :New.idestado              := 'R';
               -- :New.mensaje               := 'Rechazado';
               p_depura( 'Line : 1192' || v_error );
               If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error, 0 ) Then
                  ---- Dbms_output.put_line(' codigo de pais no se encuentra registrado'|| :New.idpais);
                  f_log_procesoRR('TEMPFUD', 'V_error: '|| v_error|| ' - '||SQLERRM||'---'||DBMS_UTILITY.FORMAT_ERROR_STACK||'---'|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ); 
                  raise_application_error( num => -20000, msg => v_error );
               End If;
               f_log_procesoRR('TEMPFUD:'||:new.id_tempfud,'ID_TEMPFUD: '||:new.id_tempfud|| 'V_error: '|| v_error );
         End;
          --
          /*
          Begin
         SELECT substr(nombres,1,25), substr(apellido1,1,25), substr(apellido2,1,25)
         into v_nombresco,v_apellido1co,v_apellido2co
            FROM TABLE (api_canales.fnconspadron2 (:NEW.numdocumentoidentidad, 'B2000'));
          exception when no_data_found then
              v_nombresco := null;
              v_apellido1co := null;
              v_apellido2co := null;
          end;
          */
          --
         Begin
            -- p_depura( 'personas_fisicas deudor ' );
            Begin
               Insert Into pa.personas_fisicas
                           ( cod_per_fisica, primer_nombre, primer_apellido,
                             segundo_apellido,segundo_nombre,   --
                                              sexo,
                             fec_nacimiento,
                             est_civil, num_hijos, num_dependientes,
                             cod_sector, cod_actividad,
                             actividad, cod_subactividad, tipo_persona,
                             tipo_cliente, idioma_correo, email_usuario, email_servidor,
                             eval_ref_bancaria, eval_ref_tarjetas, eval_ref_laboral,
                             total_ingresos, cod_pais, fec_inclusion, incluido_por,
                             nacionalidad, rango_ingresos )
                    Values ( v_persona2, :New.primernombreco, Nvl( :New.primerapellidoco, ' ' ),
                             Nvl( :New.segundoapellidoco, ' ' ), Nvl( :New.segundonombreco, ' ' ), :New.sexoco,
                             To_date( :New.fechanacimientoco, 'dd/mm/yyyy' ),
                             :New.idestadocivilco, :New.nohijosco, :New.dependientesco,
                             To_number( :New.sectoreconomico ), :New.idrama_ciiuco,
                             vactividadc, vcodsubactividadc, :New.tipopersona2,
                             :New.tipocliente, 'ESPA', :New.emailco, Null,
                             'V', 'V', 'C',
                             0, v_codpaisco, Sysdate, User,
                             v_nompaisco, 1 );
            Exception
               When Others Then
                  -- p_depura( 'personas_fisicas codeudor others:' || Sqlerrm );
                  v_error                    := 'P.F. codeudor others:' || Sqlerrm;
                  v_error                    :=
                                         'Agregando Personas Fisicas-Codeudor' || Sqlerrm;
                  :New.idestado              := 'R';
                  -- :New.mensaje               := 'Rechazado';
                  p_depura( 'Line : 1244' || v_error );
                  If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error, 0 ) Then
                     ---- Dbms_output.put_line(' codigo de pais no se encuentra registrado'|| :New.idpais);
                     f_log_procesoRR('TEMPFUD', 'V_error: '|| v_error|| ' - '||SQLERRM||'---'||DBMS_UTILITY.FORMAT_ERROR_STACK||'---'|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ); 
                     raise_application_error( num => -20000, msg => v_error );
                  End If;
                  f_log_procesoRR('TEMPFUD:'||:new.id_tempfud,'ID_TEMPFUD: '||:new.id_tempfud|| 'V_error: '|| v_error );
            End;
         Exception
            When Others Then
               v_error                    :=
                                         'Agregando Personas Fisicas-Codeudor' || Sqlerrm;
               :New.idestado              := 'R';
               -- :New.mensaje               := 'Rechazado';
               p_depura( 'Line : 1256' || v_error );
               If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error, 0 ) Then
                  ---- Dbms_output.put_line(' codigo de pais no se encuentra registrado'|| :New.idpais);
                  f_log_procesoRR('TEMPFUD', 'V_error: '|| v_error|| ' - '||SQLERRM||'---'||DBMS_UTILITY.FORMAT_ERROR_STACK||'---'|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ); 
                  raise_application_error( num => -20000, msg => v_error );
               End If;
               f_log_procesoRR('TEMPFUD:'||:new.id_tempfud,'ID_TEMPFUD: '||:new.id_tempfud|| 'V_error: '|| v_error );
         End;
         --------------------------------------------------------------------------
         Begin
            Begin
               Insert Into pa.personas
                           ( cod_persona, cod_per_fisica, cod_per_juridica, es_fisica,
                             nombre,
                             ind_clte_i2000, paga_imp_ley288, benef_pag_ley288,
                             cod_vinculacion, cod_sec_contable, adicionado_por,
                             fecha_adicion, modificado_por, fecha_modificacion,
                             codigo_sustituto, estado_persona, cobr_nodgii_132011,
                             lleno_fatca, imprimio_fatca, es_fatca, fec_actualizacion,
                             tel_verificado )
                    Values ( v_persona2, v_persona2, Null, 'S',
                             Substr( :New.primernombreco || ' ' || :New.segundonombreco || ' ' || :New.primerapellidoco  || ' ' || :New.segundoapellidoco, 1, 65 ),
                             'N', 'S', 'S',
                             :New.idtipovinculadoco, :New.sectorcontable, User,
                             Sysdate, Null, Null,
                             Null, 'A', 'S',  ---  Null, 'A', 'N'  --Excello:2022-09-01:REQ_155738: Se cambia el valor  indicador  cobr_nodgii_132011 a  'S' para que pague imp.
                             'N', 'N', 'N', Null,
                             'N' );
            Exception
               When Others Then
                  -- p_depura( 'personas codeudor others:' || Sqlerrm );
                  Null;
            End;
         Exception
            When Others Then
               v_error                    := 'Agregando Personas-Codeudor' || Sqlerrm;
               :New.idestado              := 'R';
               -- :New.mensaje               := 'Rechazado';
               p_depura( 'Line : 1292' || v_error );
               If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error, 0 ) Then
                  ---- Dbms_output.put_line(' codigo de pais no se encuentra registrado'|| :New.idpais);
                  f_log_procesoRR('TEMPFUD', 'V_error: '|| v_error|| ' - '||SQLERRM||'---'||DBMS_UTILITY.FORMAT_ERROR_STACK||'---'|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ); 
                  raise_application_error( num => -20000, msg => v_error );
               End If;
               f_log_procesoRR('TEMPFUD:'||:new.id_tempfud,'ID_TEMPFUD: '||:new.id_tempfud|| 'V_error: '|| v_error );
         End;
         --------------------------------------------------------------------------
         -- Direcci¿¿¿¿n del cliente
         --------------------------------------------------------------------------
         ---- p_depura( ' dir PERSONAS JMM '||:New.direccion_idprovincia||' '||:New.direccion_idmunicipio||' '||:New.direccion_distrito);
         Begin
            /*
            Select cod_provincia
              Into vidprovinciaco
              From pa.distritos
             Where cod_pais = v_codpaisco
               And cod_canton = To_number( Substr( :New.idmunicipioco, 1, 2 ))
               And cod_distrito = To_number( Substr( :New.idmunicipioco, 3, 2 ));
               */
               
              v_paisx := v_codpaisco;
              v_distrito := 0;
                
              Select count(*) Into v_distrito
              From pa.distritos
              Where cod_pais = 1 --v_codpaisco
               And cod_canton = To_number( Substr( :New.idmunicipioco, 1, 2 ))
               And cod_distrito = To_number( Substr( :New.idmunicipioco, 3, 2 ));
               
               v_municipio := Substr( :New.idmunicipioco, 1, 2 );
               v_municipio2 := Substr( :New.idmunicipioco, 3, 2 );
               
            p_depura('v_codpaisco ' || v_codpaisco);
               
           if v_distrito > 0 then        
                 Select cod_provincia
                  Into vidprovinciaco
                  From pa.distritos
                Where cod_pais = 1--v_codpaisco
               And cod_canton = To_number( Substr( :New.idmunicipioco, 1, 2 ))
               And cod_distrito = To_number( Substr( :New.idmunicipioco, 3, 2 ));
           else
                 vidprovinciaco := 1;
                 v_paisx := 1;
                 v_municipio := '1';
                 v_municipio2 := '1';
           
           end if;   
               
               
               
               
         Exception
            When Others Then
               v_error                    := Sqlerrm;
               :New.idestado              := 'R';
               -- :New.mensaje               := 'Rechazado';
               if vidprovinciaco = '' OR vidprovinciaco is null then
               
                 vidprovinciaco := 1;
               end if;
               /*
               If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error, 0 ) Then
                  ---- Dbms_output.put_line(' codigo de pais no se encuentra registrado'|| :New.idpais);
                  raise_application_error( num => -20000, msg => v_error );
               End If;
               */
         End;
         Begin
            v_paisx := 1;
         
            Insert Into pa.dir_personas
                        ( cod_persona, cod_direccion, tip_direccion, apartado_postal,
                          cod_postal, detalle, cod_pais, cod_provincia,
                          cod_canton,
                          cod_distrito, cod_pueblo, es_default,
                          colonia, zona, ind_estado )
                 Values ( v_persona2, 1, 1, Null,
                          Null, :New.trabajo_direccionco, v_paisx, vidprovinciaco,
                         To_number( v_municipio), -- To_number( Substr( :New.idmunicipioco, 1, 2 )),
                          --idmunicipio
                          To_number( Substr( :New.idmunicipioco, 3, 2 )), 1, 'S',
                          Null, Null, 'S' );
         Exception
            When Others Then
               v_error                    :=
                                     'Agregando Direccion 1 Personas Codeudor' || Sqlerrm;
               :New.idestado              := 'R';
               -- :New.mensaje               := 'Rechazado';
               p_depura( 'Line : 1381' || v_error );
               If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error, 0 ) Then
                  ---- Dbms_output.put_line(' codigo de pais no se encuentra registrado'|| :New.idpais);
                  f_log_procesoRR('TEMPFUD', 'V_error: '|| v_error|| ' - '||SQLERRM||'---'||DBMS_UTILITY.FORMAT_ERROR_STACK||'---'|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ); 
                  raise_application_error( num => -20000, msg => v_error );
               End If;
               f_log_procesoRR('TEMPFUD:'||:new.id_tempfud,'ID_TEMPFUD: '||:new.id_tempfud|| 'V_error: '|| v_error );
         End;
         --------------------------------------------------------------------------
         ---- p_depura( ' dir 2  PERSONAS JMM deudor ' );
         Begin
         /*
            Select cod_provincia
              Into tidprovinciaco
              From pa.distritos
             Where cod_pais = v_codpaisco
               And cod_canton = To_number( Substr( :New.trabajo_idmunicipioco, 1, 2 ))
               And cod_distrito = To_number( Substr( :New.trabajo_idmunicipioco, 3, 2 ));
             */
             
              v_paisx := v_codpaisco;
              v_distrito := 0;
                
              Select count(*) Into v_distrito
              From pa.distritos
              Where cod_pais = 1--v_codpaisco
               And cod_canton = To_number( Substr( :New.trabajo_idmunicipioco, 1, 2 ))
               And cod_distrito = To_number( Substr( :New.trabajo_idmunicipioco, 3, 2 ));
               
               v_municipio := Substr( :New.trabajo_idmunicipioco, 1, 2 );
               v_municipio2 := Substr( :New.trabajo_idmunicipioco, 3, 2 );
               
           if v_distrito > 0 then        
                 Select cod_provincia
                  Into tidprovinciaco
                  From pa.distritos
                Where cod_pais = v_codpaisco
               And cod_canton = To_number( Substr( :New.trabajo_idmunicipioco, 1, 2 ))
               And cod_distrito = To_number( Substr( :New.trabajo_idmunicipioco, 3, 2 ));
           else
                 tidprovinciaco := 1;
                 v_paisx := 1;
                 v_municipio := '1';
                 v_municipio2 := '1';
           
           end if;     
               
               
               
               
               
         Exception
            When Others Then
               v_error                    := Sqlerrm;
               :New.idestado              := 'R';
               -- :New.mensaje               := 'Rechazado';
               p_depura( 'Line : 1435' || v_error );
               If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error, 0 ) Then
                  ---- Dbms_output.put_line(' codigo de pais no se encuentra registrado'|| :New.idpais);
                  f_log_procesoRR('TEMPFUD', 'V_error: '|| v_error|| ' - '||SQLERRM||'---'||DBMS_UTILITY.FORMAT_ERROR_STACK||'---'|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ); 
                  raise_application_error( num => -20000, msg => v_error );
               End If;
               f_log_procesoRR('TEMPFUD:'||:new.id_tempfud,'ID_TEMPFUD: '||:new.id_tempfud|| 'V_error: '|| v_error );
         End;
         Begin
            v_paisx := 1;
            
            Insert Into pa.dir_personas
                        ( cod_persona, cod_direccion, tip_direccion, apartado_postal,
                          cod_postal, detalle, cod_pais, cod_provincia,
                          cod_canton,
                          cod_distrito, cod_pueblo,
                          es_default, colonia, zona, ind_estado )
                 Values ( v_persona2, 2, 2, Null,
                          Null, :New.trabajo_direccionco,v_paisx/* v_codpaisco*/, tidprovinciaco,
                          --To_number( Substr( :New.trabajo_idmunicipio, 1, 2 )),
                         To_number( v_municipio), -- To_number( Substr( :New.trabajo_idmunicipioco, 1, 2 )),
                          To_number( Substr( :New.trabajo_idmunicipioco, 3, 2 )), Null,
                          'N', Null, Null, 'S' );
         Exception
            When Others Then
               v_error                    :=
                                     'Agregando Direccion 2 Personas Codeudor' || Sqlerrm;
               :New.idestado              := 'R';
               -- :New.mensaje               := 'Rechazado';
               p_depura( 'Line : 1462' || v_error );
               If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error, 0 ) Then
                  ---- Dbms_output.put_line(' codigo de pais no se encuentra registrado'|| :New.idpais);
                  f_log_procesoRR('TEMPFUD', 'V_error: '|| v_error|| ' - '||SQLERRM||'---'||DBMS_UTILITY.FORMAT_ERROR_STACK||'---'|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ); 
                  raise_application_error( num => -20000, msg => v_error );
               End If;
                f_log_procesoRR('TEMPFUD:'||:new.id_tempfud,'ID_TEMPFUD: '||:new.id_tempfud|| 'V_error: '|| v_error );
         End;
          p_depura( ' ***AQUI***' || Sqlerrm );
         --------------------------------------------------------------------------
         -- Direccion de Envio
         --------------------------------------------------------------------------
         Begin
            Insert Into dir_envio_x_pers
                        ( cod_persona, tipo_envio, cod_direccion )
                 Values ( v_persona2, 'D', 1 );
         Exception
            When Others Then
               v_error                    :=
                             'Agregando Direccion Envio Por Personas Codeudor' || Sqlerrm;
               :New.idestado              := 'R';
               -- :New.mensaje               := 'Rechazado';
               p_depura( 'Line : 1483' || v_error );
               If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error, 0 ) Then
                  ---- Dbms_output.put_line(' codigo de pais no se encuentra registrado'|| :New.idpais);
                  f_log_procesoRR('TEMPFUD', 'V_error: '|| v_error|| ' - '||SQLERRM||'---'||DBMS_UTILITY.FORMAT_ERROR_STACK||'---'|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ); 
                  raise_application_error( num => -20000, msg => v_error );
               End If;
               f_log_procesoRR('TEMPFUD:'||:new.id_tempfud,'ID_TEMPFUD: '||:new.id_tempfud|| 'V_error: '|| v_error );
         End;
         
          
         -----------------------------------------------------------------------
         -- Tel¿¿¿¿fonos del codeudor
         -----------------------------------------------------------------------
         -- JMoraM 20180503 valida que no venga 0 en el numero telefono
         -----------------------------------------------------------------------
         Begin
          
            If To_number( Replace( Trim( :New.telefonoco ), '-' )) = 0 Then
            
               v_error                    :=
                                   'Codeudor tiene que tener al menos un telefono valido';
               :New.idestado              := 'R';
               -- :New.mensaje               := 'Rechazado';
                p_depura( ' FINAL INICIO TEL 1 ' || v_error );
               If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error, 0 ) Then
                  f_log_procesoRR('TEMPFUD', 'V_error: '|| v_error|| ' - '||SQLERRM||'---'||DBMS_UTILITY.FORMAT_ERROR_STACK||'---'|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ); 
                  raise_application_error( num => -20000, msg => v_error );
               End If;
               f_log_procesoRR('TEMPFUD:'||:new.id_tempfud,'ID_TEMPFUD: '||:new.id_tempfud|| 'V_error: '|| v_error );
                p_depura( ' FINAL INICIO FIN 1 ' || v_error );
            End If;
         Exception
            When Others Then
               v_error                    := 'Validando telefonos CoDeudor' || Sqlerrm;
               :New.idestado              := 'R';
               -- :New.mensaje               := 'Rechazado';
               If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error, 0 ) Then
                  f_log_procesoRR('TEMPFUD', 'V_error: '|| v_error|| ' - '||SQLERRM||'---'||DBMS_UTILITY.FORMAT_ERROR_STACK||'---'|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ); 
                  raise_application_error( num => -20000, msg => v_error );
               End If;
                f_log_procesoRR('TEMPFUD:'||:new.id_tempfud,'ID_TEMPFUD: '||:new.id_tempfud|| 'V_error: '|| v_error );
         End;
          p_depura( ' FINAL FIN TEL 1' );
         -----------------------------------------------------------------------
         Begin
            Insert Into pa.tel_personas
                        ( cod_persona, cod_area,
                          num_telefono, tip_telefono, tel_ubicacion,
                          extension, nota, es_default, posicion, cod_direccion,
                          cod_pais, modificado_por, fecha_modificacion, incluido_por,
                          fec_inclusion )
                 Values ( v_persona2, Substr( :New.telefonoco, 1, 3 ),
                          Replace( Substr( :New.telefonoco, 4 ), '-', Null ), 'R', 'O',
                          :New.extensionco, 'PortaCredit', 'S', Null, 1,
                          v_codpaisco, Null, Null, User,
                          Sysdate );
         Exception
             WHEN DUP_VAL_ON_INDEX THEN
                  NULL;  -- malmanzar 21/04/2021  Cuando el número existe no es necesario volver a incluirlo y no va a devolver error a Portacredit.
            When Others Then
            
               v_error                    :=
                                      'Agregando Telefono 1 Personas Codeudor' || Sqlerrm;
               :New.idestado              := 'R';
               -- :New.mensaje               := 'Rechazado';
               p_depura( ' Error Agregando Telefono 1 Personas Codeudor' );
               If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error, 0 ) Then
                  ---- Dbms_output.put_line(' codigo de pais no se encuentra registrado'|| :New.idpais);
                  f_log_procesoRR('TEMPFUD', 'V_error: '|| v_error|| ' - '||SQLERRM||'---'||DBMS_UTILITY.FORMAT_ERROR_STACK||'---'|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ); 
                  raise_application_error( num => -20000, msg => v_error );
               End If;
               f_log_procesoRR('TEMPFUD:'||:new.id_tempfud,'ID_TEMPFUD: '||:new.id_tempfud|| 'V_error: '|| v_error );
         End;
         -- p_depura( ' tel 2 PERSONAS deudor JMM' );
         
         --------------------------------------------------------------------------
         Begin
            Insert Into pa.tel_personas
                        ( cod_persona, cod_area,
                          num_telefono, tip_telefono, tel_ubicacion,
                          extension, nota, es_default, posicion, cod_direccion,
                          cod_pais, modificado_por, fecha_modificacion, incluido_por,
                          fec_inclusion )
                 Values ( v_persona2, Substr( :New.telefonoco, 1, 3 ),
                          Replace( Substr( :New.telefonoco, 4 ), '-', Null ), 'R', 'O',
                          Null, 'PortaCredit', 'S', Null, 1,
                          v_codpaisco, Null, Null, User,
                          Sysdate );
         Exception
         WHEN DUP_VAL_ON_INDEX THEN
                  NULL;  -- malmanzar 21/04/2021  Cuando el número existe no es necesario volver a incluirlo y no va a devolver error a Portacredit.
            When Others Then
            
               v_error                    :=
                                     'Agregando Telefono 2 Personas Codeudor ' || Sqlerrm;
               :New.idestado              := 'R';
               -- :New.mensaje               := 'Rechazado';
               p_depura( 'Line : 1574' || v_error );
               If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error, 0 ) Then
                  ---- Dbms_output.put_line(' codigo de pais no se encuentra registrado'|| :New.idpais);
                  f_log_procesoRR('TEMPFUD', 'V_error: '|| v_error|| ' - '||SQLERRM||'---'||DBMS_UTILITY.FORMAT_ERROR_STACK||'---'|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ); 
                  raise_application_error( num => -20000, msg => v_error );
               End If;
               f_log_procesoRR('TEMPFUD:'||:new.id_tempfud,'ID_TEMPFUD: '||:new.id_tempfud|| 'V_error: '|| v_error );
         End;
         --------------------------------------------------------------------------
         -- Identificaci¿¿¿¿n del cliente
         --------------------------------------------------------------------------
         -- p_depura( ' id PERSONAS deudor JMM' );
         
        
         Begin
            IF :New.IDPAISCO IS NULL THEN
                nacionalidadPECO := v_nompaisco;  
            ELSE
                select nacionalidad into nacionalidadPECO from pais where pais_sb = :New.IDPAISCO and rownum <= 1;   
            END IF;   
            
            
         
            If vpasext = 'S' Then
               Insert Into pa.id_personas
                           ( cod_persona,
                             cod_tipo_id,
                             num_id,
                             fec_vencimiento, cod_pais, nacionalidad )
                    Values ( v_persona2,
                             Decode( :New.tipodocumentoidentidadco,
                                     'C', '1',
                                     'R', '2',
                                     'P', '4',
                                     'X', '5',
                                     'PE','6'                                     ),
                             pa.formatear_identifi( :New.numdocumentoidentidadco,
                                                    Decode
                                                          ( :New.tipodocumentoidentidadco,
                                                            'C', '1',
                                                            'R', '2',
                                                            'P', '4',
                                                            'X', '5',
                                                            'PE','6' )),
                             To_date( '31/12/2050', 'dd/mm/yyyy' ), v_codpaisco ,nacionalidadPECO);
            Else
               Insert Into pa.id_personas
                           ( cod_persona,
                             cod_tipo_id,
                             num_id,
                             fec_vencimiento, cod_pais,nacionalidad )
                    Values ( v_persona2,
                             Decode( :New.tipodocumentoidentidadco,
                                     'C', '1',
                                     'R', '2',
                                     'P', '4',
                                     'X', '5',
                                     'PE','6' ),
                             pa.formatear_identifi( :New.numdocumentoidentidadco,
                                                    Decode
                                                          ( :New.tipodocumentoidentidadco,
                                                            'C', '1',
                                                            'R', '2',
                                                            'P', '4',
                                                            'X', '5',
                                                            'PE','6' )),
                             To_date( '31/12/2050', 'dd/mm/yyyy' ), v_codpaisco,nacionalidadPECO );
            End If;
         Exception
            When Others Then
               v_error                    := 'Agregando ID Personas Codeudor ' || Sqlerrm;
               :New.idestado              := 'R';
               -- :New.mensaje               := 'Rechazado';
               p_depura( 'Agregando ID Personas Codeudor' );
               If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error, 0 ) Then
                  ---- Dbms_output.put_line(' codigo de pais no se encuentra registrado'|| :New.idpais);
                  f_log_procesoRR('TEMPFUD', 'V_error: '|| v_error|| ' - '||SQLERRM||'---'||DBMS_UTILITY.FORMAT_ERROR_STACK||'---'|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ); 
                  raise_application_error( num => -20000, msg => v_error );
               End If;
               f_log_procesoRR('TEMPFUD:'||:new.id_tempfud,'ID_TEMPFUD: '||:new.id_tempfud|| 'V_error: '|| v_error );
         End;
         ---- p_depura( 'insert info_doc_fisica_nacional deudor ' );
         
         --------------------------------------------------------------------------
         -- Se ingresa informacion documentos de persona fisica--------------------
         Begin
            Insert Into info_doc_fisica_nacional
                        ( cod_persona, pind_cedula, pind_licencia_conducir,
                          pind_residencia, pind_id_otro, id_otro_desc,
                          pind_certificado_nacimiento, pind_pensionado_jubilado,
                          pind_lab_tiempo, pind_lab_ingreso_anual,
                          pind_lab_puesto_desempena, pind_trabaja_independiente,
                          pind_independiente_actividad, pind_independiente_justifica_a,
                          comentarios_adicionales )
                 Values ( v_persona2, 'S', 'N',
                          'N', 'N', Null,
                          'N', 'N',
                          'N', 'N',
                          'N', 'N',
                          'N', 'N',
                          'Registrado Codeudorpor PDA' );
         Exception
            When Others Then
               v_error                    :=
                                'Agregando Informacion Doc Personas Codeudor ' || Sqlerrm;
               :New.idestado              := 'R';
               -- :New.mensaje               := 'Rechazado';
                p_depura( 'Agregando Informacion Doc Personas Codeudor ' );
               If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error, 0 ) Then
                  ---- Dbms_output.put_line(' codigo de pais no se encuentra registrado'|| :New.idpais);
                  f_log_procesoRR('TEMPFUD', 'V_error: '|| v_error|| ' - '||SQLERRM||'---'||DBMS_UTILITY.FORMAT_ERROR_STACK||'---'|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ); 
                  raise_application_error( num => -20000, msg => v_error );
               End If;
               f_log_procesoRR('TEMPFUD:'||:new.id_tempfud,'ID_TEMPFUD: '||:new.id_tempfud|| 'V_error: '|| v_error );
                
         End;
         
         --------------------------------------------------------------------------
         --------------------------------------------------------------------------
         -- Cliente para pasarlo a Cliente
         --------------------------------------------------------------------------
         -- p_depura( 'insert Cliente para pasarlo a Cliente codeudor' );
         Begin
            Begin
               Select codigo_persona
                 Into vcodoficial
                 From pr_analistas
                Where codigo_analista = :New.idoficial;
               If vcodoficial Is Not Null Then
                  Select Count( 1 )
                    Into vcontempleados
                    From empleados
                   Where id_empleado = vcodoficial;
                  If vcontempleados = 0 Then
                     v_error                    :=
                                            'No existe oficial como empleado ' || Sqlerrm;
                     :New.idestado              := 'R';
                     -- :New.mensaje               := 'Rechazado';
                     p_depura('No existe oficial como empleado');
                     If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error,
                                                        0 ) Then
                        ---- Dbms_output.put_line(' codigo de pais no se encuentra registrado'|| :New.idpais);
                        f_log_procesoRR('TEMPFUD', 'V_error: '|| v_error|| ' - '||SQLERRM||'---'||DBMS_UTILITY.FORMAT_ERROR_STACK||'---'|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ); 
                        raise_application_error( num => -20000, msg => v_error );
                     End If;
                     f_log_procesoRR('TEMPFUD:'||:new.id_tempfud,'ID_TEMPFUD: '||:new.id_tempfud|| 'V_error: '|| v_error );
                  End If;
               End If;
            Exception
               When No_data_found Then
                  v_error                    := 'No existe oficial ' || Sqlerrm;
                  :New.idestado              := 'R';
                  -- :New.mensaje               := 'Rechazado';
                   p_depura('No existe oficial');
                  If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error, 0 ) Then
                     ---- Dbms_output.put_line(' codigo de pais no se encuentra registrado'|| :New.idpais);
                     f_log_procesoRR('TEMPFUD', 'V_error: '|| v_error|| ' - '||SQLERRM||'---'||DBMS_UTILITY.FORMAT_ERROR_STACK||'---'|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ); 
                     raise_application_error( num => -20000, msg => v_error );
                  End If;
                  f_log_procesoRR('TEMPFUD:'||:new.id_tempfud,'ID_TEMPFUD: '||:new.id_tempfud|| 'V_error: '|| v_error );
            End;
                        -- p_depura(    'realiza insert Cliente para pasarlo a Cliente codeudor '
            ----                      || p_codempresa
            --                      || ' '
            --                      || v_persona2
            --                      || ' '
            --                      || v_persona2
            --                      || ' '
            ----                      || To_number( p_codagencia )
            --                      || ' '
            --                      || v_cod_cat_clte
            --                      || ' '
            --                      || reg1.f_apertura
            ----                      || ' '
            --                      || vcodoficial
            --                      || ' '
            --                      || vcodoficial );
            
            Insert Into cliente
                        ( cod_empresa, cod_cliente, num_cliente,
                          cod_agencia, cod_cat_clte, esta_activo, paga_impto_renta,
                          fec_ingreso, cat_riesgo, cod_oficial, cod_promotor,
                          cliente_especial, tipo_deudor, cross_estimado, cross_calculado,
                          rentabilidad, mon_ingreso_bco, mon_egreso_bco, estado_cliente,
                          cod_nicho, comentario_act_ingreso )
                 Values ( p_codempresa, v_persona2, v_persona2,
                          To_number( p_codagencia ), v_cod_cat_clte, 'S', 'S',
                          reg1.f_apertura, 'A', vcodoficial, vcodoficial,
                          'N', '1', 30, 0,
                          0, 0, 0, 'A',
                          '99', 'INGRESO POR PDA' );
         ---- p_depura( 'insert Cliente para pasarlo a Cliente codeudor:' || Sqlerrm );
         Exception
            When Others Then
               v_error                    := 'Agregando Cliente Codeudor ' || Sqlerrm;
               :New.idestado              := 'R';
               -- :New.mensaje               := 'Rechazado';
                p_depura('Agregando Cliente Codeudor');
               If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error, 0 ) Then
                  ---- Dbms_output.put_line(' codigo de pais no se encuentra registrado'|| :New.idpais);
                  f_log_procesoRR('TEMPFUD', 'V_error: '|| v_error|| ' - '||SQLERRM||'---'||DBMS_UTILITY.FORMAT_ERROR_STACK||'---'|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ); 
                  raise_application_error( num => -20000, msg => v_error );
               End If;
               f_log_procesoRR('TEMPFUD:'||:new.id_tempfud,'ID_TEMPFUD: '||:new.id_tempfud|| 'V_error: '|| v_error );
         End;
         
      Else
        --- modificar aca 
         reg1.codigo_relacionco     := 'O';
         reg1.codigo_clienteco      := To_number( v_persona2 );
         
        
         
         -- Excello:JPH:2019-02-12:Req._93767: Begin >>
         -- Actualizacion datos Codeudores  ---
         
         --1- Datos Persona --
         If :New.IdtipovinculadoCo Is Not Null Then --- Tipo Vinculacion 
            PA.Pa_Mant_Datos_Personas.P_Act_Datos_Cliente_Persona( V_Persona2,
                                                                'TIP_VINCULO',
                                                                :New.IdtipovinculadoCo,                                 
                                                                V_Procesado,   
                                                                V_Error 
                                                               );  
         
            If V_MsgErr Is Not Null Then
              V_Error :=  'FUD Error procesando codeudor '||' '||V_MsgErr;
              :New.Mensaje := Substr(V_Error,1,200);
              f_log_procesoRR('TEMPFUD:'||:new.id_tempfud,'ID_TEMPFUD: '||:new.id_tempfud|| 'V_error: '|| v_error );
            End If;
        
         End If;
          
                  
         If :New.EmailCo Is Not Null Then
            PA.Pa_Mant_Datos_Personas.P_Act_Datos_Cliente_Persona( V_Persona2,
                                                                'EMAIL',
                                                                :New.EmailCo,                                 
                                                                V_Procesado,   
                                                                V_Error 
                                                               );  
         
            If V_MsgErr Is Not Null Then
              V_Error :=  'FUD Error procesando codeudor '||' '||V_MsgErr;
              :New.Mensaje := Substr(V_Error,1,200);
               
            End If;
         
         End If;
         
         -- 2- Direcciones  --
         -- 2.1- Direccion Trabajo ---
         If  Length(:New.Trabajo_DireccionCo) > 0 Then
           PA.Pa_Mant_Datos_Personas.P_Inserta_Direccion(  V_Persona2,
                                                        :New.Trabajo_DireccionCo,
                                                        :New.Trabajo_IdmunicipioCo,
                                                        V_CodpaisCo,
                                                        '2',
                                                        'S',
                                                        V_Procesado,
                                                        V_MsgErr 
                                                      );
        
           If V_MsgErr Is Not Null Then
              V_Error :=  'FUD Error procesando codeudor '||' '||V_MsgErr;
              :New.Mensaje := Substr(V_Error,1,200);
              f_log_procesoRR('TEMPFUD:'||:new.id_tempfud,'ID_TEMPFUD: '||:new.id_tempfud|| 'V_error: '|| v_error );
           End If;
        End If;
        
        -- 3- Telefonos  --
        -- 3.1- Residencial --
        If  To_Number( Replace(:New.TelefonoCo, '-' )) != 0 Then  
            If Length(:New.Extensionco) > 0  Then
               V_TipoTCo := 'T';
            Else 
               V_TipoTCo := 'R';
            End If;
              
            PA.Pa_Mant_Datos_Personas.P_Inserta_Telefono( V_Persona2,
                                                       Replace(:New.TelefonoCo,'-' ),
                                                       :New.Extensionco,
                                                       V_TipoTCo,
                                                       'PortaCredit',
                                                       V_Codpais,
                                                       'S',
                                                       V_Procesado,
                                                       V_MsgErr 
                                                      );
        
           If V_MsgErr Is Not Null Then
              V_Error :=  'FUD Error procesando codeudor '||' '||V_MsgErr;
              :New.Mensaje := Substr(V_Error,1,200);
           End If;
        End If;
         
       -- Excello:JPH:2019-02-12:Req._93767: End <<
       
       --- Excello:JPH:2020-03-19:REQ_108967:Begin >>
       --==============================================
       /*  Nuevos campos a ser actualizados  */
       --==============================================
       
       -- 4- Estado Civil
       If :New.Idestadocivilco IS Not Null Then
          PA.Pa_Mant_Datos_Personas.P_Act_Datos_Cliente_Persona( V_Persona,
                                                                 'ESTCIV',
                                                                 :New.Idestadocivilco,                                 
                                                                 V_Procesado,   
                                                                 V_Error 
                                                               );  
         
            If V_MsgErr Is Not Null Then
              V_Error :=  'FUD Error procesando codeudor '||' '||V_MsgErr;
              :New.Mensaje := Substr(V_Error,1,200);
            End If;
       End If;
       
       -- 6- Actividad Economica
       If :New.Idrama_Ciiuco IS Not Null Then
          PA.Pa_Mant_Datos_Personas.P_Act_Datos_Cliente_Persona( V_Persona,
                                                                 'ACTECO',
                                                                 :New.Idrama_Ciiuco,                                 
                                                                 V_Procesado,   
                                                                 V_Error 
                                                               );  
         
            If V_MsgErr Is Not Null Then
              V_Error :=  'FUD Error procesando codeudor '||' '||V_MsgErr;
              :New.Mensaje := Substr(V_Error,1,200);
            End If;
       End If;
       
       --- Excello:JPH:2020-03-19:REQ_108967:End <<
         
         
       /*
       Begin
      SELECT substr(nombres,1,25), substr(apellido1,1,25), substr(apellido2,1,25)
      into v_nombres,v_apellido1,v_apellido2
         FROM TABLE (api_canales.fnconspadron2 (:NEW.numdocumentoidentidad, 'B2000'));
       exception when no_data_found then
           v_nombresco := null;
           v_apellido1co := null;
           v_apellido2co := null;
       end;

       update personas_fisicas set primer_nombre = nvl(v_nombresco,primer_nombre),
       primer_apellido = nvl(v_apellido1co,primer_apellido),
       segundo_apellido = nvl(v_apellido2co,segundo_apellido)
       where cod_per_fisica = v_persona2;
       --
       update personas set nombre = substr(nvl(nvl(v_nombresco,' ')||' '||
       nvl(v_apellido1co,' ')||' '||
       nvl(v_apellido2co,' '),nombre),1,65)
       where cod_persona = v_persona2;
       */
      End If;
      -----------------------------------------------------------------------------
         --
         ---- p_depura( ' fin  pERSONAS deudor JMM' );
         
         
         --------------------------------------------------------------------------
      Select ptc.codigo_moneda, ptc.tipo_credito, ptc.es_linea_credito, ptc.tipo_linea,
             ptc.manejo, ptc.modalidad_cobro, ptc.tipo_intereses, ptc.tipo_calendario,
             ptc.periodo_comision_normal, ptc.comision_normal, ptc.tipo_tasa,
             ptc.codigo_tipo_de_tasa, ptc.variacion_base, ptc.tasa_interes,
             ptc.codigo_tasa_moratorios, ptc.variacion_mora, ptc.tasa_moratorios,
             ptc.gracia_principal, ptc.gracia_mora, ptc.codigo_origen,
             ptc.continua_cobro_intereses, ptc.dia_pago, ptc.revaloriza,
             ptc.codigo_sub_aplicacion, ptc.tipo_comision, ptc.tipo_mora,
             ptc.porcentaje_tasa_mora, ptc.permite_sobregiro, ptc.porcentaje_sobregiro,
             ptc.variacion_minima, ptc.variacion_maxima, ptc.periodos_gracia_principal,
             ptc.base_calculo_moratorios, ptc.descuenta_intereses_desembolso,
             ptc.cantidad_cuotas_descontar, ptc.ind_pr_vehiculo, 'C' tipo_desembolso,
             0 codigo_actividad, 0 codigo_subactividad, 0 codigo_sub_clase,   --,
                                                                           codigo_plazo
        --ppm.frecuencia_pago codigo_periodo_cuota,
        --ppm.frecuencia_pago codigo_periodo_interes,
        --ppm.frecuencia_pago periodo_comision_normal
      Into   reg1.codigo_moneda, reg1.tipo_credito, reg1.es_linea_credito,
             reg1.tipo_linea, reg1.manejo, reg1.modalidad_cobro, reg1.tipo_intereses,
             reg1.tipo_calendario, reg1.periodo_comision_normal, reg1.comision_normal,
             reg1.tipo_tasa, reg1.codigo_tipo_de_tasa, reg1.variacion_base,
             reg1.tasa_interes, reg1.codigo_tasa_moratorios, reg1.variacion_mora,
             reg1.tasa_moratorios, reg1.gracia_principal, reg1.gracia_mora,
             reg1.codigo_origen, reg1.continua_cobro_intereses, reg1.dia_pago,
             reg1.revaloriza, reg1.codigo_sub_aplicacion, reg1.tipo_comision,
             reg1.tipo_mora, reg1.porcentaje_tasa_mora,
                                                       -- reg1.codigo_plazo,
                                                       reg1.permite_sobregiro,
             reg1.porcentaje_sobregiro, reg1.variacion_minima, reg1.variacion_maxima,
             reg1.periodos_gracia_principal, reg1.base_calculo_moratorios,
             reg1.descuenta_intereses_desembolso, reg1.cantidad_cuotas_descontar,
             reg1.ind_pr_vehiculo,
                                  --  reg1.dias_periodo_cuota,
                                  -- reg1.plazo,
                                  reg1.tipo_desembolso, reg1.codigo_actividad,
             reg1.codigo_subactividad, reg1.codigo_sub_clase,   --,
                                                             reg1.codigo_plazo
        --reg1.codigo_periodo_cuota,
        --reg1.codigo_periodo_intereses,
        --reg1.periodo_comision_normal
      From   pr_tipo_credito ptc
       Where ptc.codigo_empresa = p_codempresa
         --         And ptc.tipo_credito = To_number( :New.tipoproductos )
         And ptc.tipo_credito = To_number( :New.codigoproyecto );
   -- p_depura( 'pr_tipo_credito ' || Sqlerrm );   --ptc.facilidad_creditic = To_number( :New.tipoproductos ) and
   Exception
      When No_data_found Then
         utilitarios.obt_mensaje_error( '000376', 'PR', v_error, Null );
         :New.idestado              := 'R';
         -- :New.mensaje               := 'Rechazado';
          p_depura('*********1935**********' || v_error );
         If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error, 0 ) Then
            --pa.utilitarios.obt_mensaje_error( '000376', 'PR', v_error, Null );
            -- Dbms_output.put_line( 'p_mensajeerror= codigoproyecto' );
            f_log_procesoRR('TEMPFUD', 'V_error(000376): '|| v_error|| ' - '||SQLERRM||'---'||DBMS_UTILITY.FORMAT_ERROR_STACK||'---'|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ); 
            raise_application_error( num => -20000, msg => v_error );
         End If;
         f_log_procesoRR('TEMPFUD:'||:new.id_tempfud,'ID_TEMPFUD: '||:new.id_tempfud|| 'V_error: '|| v_error );
          
   End;
   
            

   --
   -- p_depura( 'valida plazo ' || Sqlerrm );
   --
   reg1.estado                := 'R';
   reg1.tipo_cuota            := 'N';
   --
   -- p_depura( ':New.plazocal :' || :New.plazocal );
   -- p_depura( ':New.frecuenciacal :' || :New.frecuenciacal );
   --
   Begin
      Select codigo_periodo
        Into reg1.codigo_periodo_cuota
        From pr_periodicidad pp
       Where pp.codigo_periodo =
                Decode( To_number( Substr( :New.frecuenciacal, 1, 2 )),
                        1, 'SM',   --  Semanal
                        2, 'BS',   --  Bisemanal
                        3, 'TS',   --  Trisemanal
                        4, 'VO',   --  CuatriSemanal
                        5, 'ME',   --  Mensual
                        6, 'BI',   --  Bimestral
                        7, 'TR',   --  Trimestral
                        8, 'CU',   --  Cuatrimestral
                        9, 'SE',   --  Semestral
                        10, 'AN' );
   Exception
      When Others Then
         v_plazo                    := 0;
         v_error                    := 'p_mensajeerror = Revisar el campo Frecuenciacal';
         :New.idestado              := 'R';
         -- :New.mensaje               := 'Rechazado';
          p_depura('*********1975**********' || v_error );
         If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error, 0 ) Then
            -- Dbms_output.put_line( 'p_mensajeerror= Frecuenciacal' );
            f_log_procesoRR('TEMPFUD', 'V_error: '|| v_error|| ' - '||SQLERRM||'---'||DBMS_UTILITY.FORMAT_ERROR_STACK||'---'|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE );
            raise_application_error( num => -20000, msg => v_error );
         End If;
         f_log_procesoRR('TEMPFUD:'||:new.id_tempfud,'ID_TEMPFUD: '||:new.id_tempfud|| 'V_error: '|| v_error );
   --IA.API_PORTACREDIT.fnUpdateFud(PIDTEMPFUD IN NUMBER, PIDTEMPFEC IN NUMBER, PESTADO IN VARCHAR2, PMENSAJE IN VARCHAR2, PNO_SOL IN PR.PR_SOLICITUDES.NO_SOLICITUD%TYPE)

   --Aprobado:
   --IA.API_PORTACREDIT.fnUpdateFud(1170, 1125, 'A', `Procesado Correctamente', 1234567);
   End;
   
   
   --reg1.plazo                 := :New.plazocal * ;
   Begin
      Select dias_periodo * :New.plazocal   --, codigo_periodo
        Into v_plazo   --, reg1.codigo_periodo_cuota
        From pr_periodicidad pp
       Where pp.codigo_periodo = 'ME';
   Exception
      When Others Then
         v_plazo                    := 0;
         v_error                    := 'p_mensajeerror = Revisar el campo Frecuenciacal';
         :New.idestado              := 'R';
         -- :New.mensaje               := 'Rechazado';
          p_depura('*********1998**********' || v_error );
         If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error, 0 ) Then
            -- Dbms_output.put_line( 'p_mensajeerror= Frecuenciacal' );
            f_log_procesoRR('TEMPFUD', 'V_error: '|| v_error|| ' - '||SQLERRM||'---'||DBMS_UTILITY.FORMAT_ERROR_STACK||'---'|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE );
            raise_application_error( num => -20000, msg => v_error );
         End If;
         f_log_procesoRR('TEMPFUD:'||:new.id_tempfud,'ID_TEMPFUD: '||:new.id_tempfud|| 'V_error: '|| v_error );
   End;
   
   
   --reg1.plazo := v_plazo;
   reg1.plazo                 :=
              pr_proyeccion.my_add_month( reg1.f_apertura, :New.plazocal )
              - reg1.f_apertura;

   --
   Begin
      Select plazo_minimo, plazo_maximo, monto_minimo, monto_maximo, variacion_base
        Into vplazo_minimo, vplazo_maximo, vmonto_minimo, vmonto_maximo, vvariacion_base
        From pr_tipo_credito
       Where codigo_empresa = To_number( p_codempresa )
         And tipo_credito = To_number( :New.codigoproyecto );
   Exception
      When No_data_found Then
         v_error                    :=
                                   'p_mensajeerror = Revisar el campos : Codigo Proyecto';
         :New.idestado              := 'R';
         -- :New.mensaje               := 'Rechazado';
          p_depura('**********2026*********' || v_error );
         If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error, 0 ) Then
            -- Dbms_output.put_line( 'p_mensajeerror = Revisar el campo : Codigo Proyecto' );
            f_log_procesoRR('TEMPFUD', 'V_error: '|| v_error|| ' - '||SQLERRM||'---'||DBMS_UTILITY.FORMAT_ERROR_STACK||'---'|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE );
            raise_application_error( num => -20000, msg => v_error );
         End If;
         f_log_procesoRR('TEMPFUD:'||:new.id_tempfud,'ID_TEMPFUD: '||:new.id_tempfud|| 'V_error: '|| v_error );
         
   End;
      --
      -- p_depura( 'valida tipo_plazo ' || reg1.plazo || ' ' || vplazo_minimo || ' '
   --             || vplazo_maximo );
      --
      
   Begin
      Select codigo_plazo
        Into reg1.codigo_plazo
        From pr_tipos_plazos
       Where codigo_plazo = reg1.codigo_plazo
         And reg1.plazo Between plazo_minimo And plazo_maximo;
   --Between vPlazo_Minimo And vPlazo_Maximo;
   Exception
      When No_data_found Then
         v_error                    := 'p_mensajeerror = Revisar el campo : Plazo';
         :New.idestado              := 'R';
         -- :New.mensaje               := 'Rechazado';
          p_depura('********2049***********' || v_error );
         If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error, 0 ) Then
            -- Dbms_output.put_line( 'p_mensajeerror = Revisar el campos : Plazo' );
            raise_application_error( num => -20000, msg => v_error );
         End If;
        f_log_procesoRR('TEMPFUD:'||:new.id_tempfud,'ID_TEMPFUD: '||:new.id_tempfud|| 'V_error: '|| v_error );
   --
   End;
   --
   -- p_depura( 'valida reg1.monto_credito ' || Sqlerrm );
   --
   reg1.f_vencimiento         := reg1.f_apertura + reg1.plazo;
   --
   reg1.monto_credito         := :New.montocal;
   
    
   --
   If reg1.monto_credito Not Between vmonto_minimo And vmonto_maximo Then
      v_error                    :=
         'p_mensajeerror = Revisar el campo : Monto del Credito Solicitado, no se encuentra dentro de los rangos minimo y maximo del codigo de proyecto asignado';
      :New.idestado              := 'R';
      -- :New.mensaje               := 'Rechazado';
        p_depura('*******************' || v_error );
      If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error, 0 ) Then
                  -- Dbms_output.put_line
         --            ( 'p_mensajeerror = Revisar el campo : Monto del Credito Solicitado, no se encuentra dentro de los rangos minimo y maximo del codigo de proyecto asignado' );
         f_log_procesoRR('TEMPFUD', 'V_error: '|| v_error|| ' - '||SQLERRM||'---'||DBMS_UTILITY.FORMAT_ERROR_STACK||'---'|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE );
         raise_application_error( num => -20000, msg => v_error );
      End If;
      f_log_procesoRR('TEMPFUD:'||:new.id_tempfud,'ID_TEMPFUD: '||:new.id_tempfud|| 'V_error: '|| v_error );
   End If;
   --
   -- p_depura( 'valido monto_credito ' || Sqlerrm || ' ' || :New.cuotaprestamocal );
   Begin
      reg1.cuota                 := To_number( :New.cuotaprestamocal );
   --to_number(replace(:new.CUOTAPRESTAMOCAL,'.',','));--LMVR
   Exception
      When Others Then
         v_error                    :=
                'El valor del campo cuota no esta siendo enviado en el formato correcto.';
         :New.idestado              := 'R';
         -- :New.mensaje               := 'Rechazado';
           p_depura('*********2093**********' || v_error );
         If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error, 0 ) Then
                        -- Dbms_output.put_line
            --               ( 'El valor del campo cuota no esta siendo enviado en el formato correcto.' );
            raise_application_error( num => -20000, msg => v_error );
         End If;
       f_log_procesoRR('TEMPFUD:'||:new.id_tempfud,'ID_TEMPFUD: '||:new.id_tempfud|| 'V_error: '|| v_error );
   End;
   -- p_depura( 'valida :new.CUOTAPRESTAMOCAL ' || :New.cuotaprestamocal || ' ' || reg1.cuota );
   reg1.codigo_analista       := :New.idoficial;
   --
   -- p_depura( 'valida TIPOS_DE_TASAS_DE_INTERES ' || Sqlerrm );
   --
   Begin
      Select b.porcentaje, a.variacion_min, a.variacion_max
        Into vporcentaje, vvariacion_min, vvariacion_max
        /* into :BKCredit.Desc_TASA_INTERES_BASE, :BKCredit.Desc_valor_tasa_corrientes,
        :BKCredit.variacion_min_interes, :BKCredit.variacion_max_interes*/
      From   tipos_de_tasas_de_interes a, valores_de_tasas_de_interes b
       Where a.codigo_tipo_de_tasa = b.codigo_tipo_de_tasa
         And b.codigo_empresa = p_codempresa
         And a.codigo_tipo_de_tasa = To_number( reg1.codigo_tipo_de_tasa )
         --To_number( :New.tipocal )--LMVR
         And b.fecha_inicio =
                ( Select Max( fecha_inicio )
                   From valores_de_tasas_de_interes
                  Where codigo_empresa = p_codempresa
                    And codigo_tipo_de_tasa = a.codigo_tipo_de_tasa
                    And fecha_inicio <= :New.fecha_registro );
   -- p_depura( 'ejecuto tasa de interes?:' || Sqlerrm );
   Exception
      When No_data_found Then
         v_error                    :=
                 'no encontro registros, revisar campos : Validaci¿¿¿¿n de Tasa de Interes';
         :New.idestado              := 'R';
         -- :New.mensaje               := 'Rechazado';
          p_depura('*******2124************' || v_error );
         If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error, 0 ) Then
                        -- Dbms_output.put_line
            --                      ( 'p_mensajeerror = Revisar campos : Validaci¿¿¿¿n de Tasa de Interes' );
            raise_application_error( num => -20000, msg => v_error );
         End If;
         f_log_procesoRR('TEMPFUD:'||:new.id_tempfud,'ID_TEMPFUD: '||:new.id_tempfud|| 'V_error: '|| v_error );
        
      When Others Then
         -- p_depura( 'others tasa de interes:' || Sqlerrm );
         v_error                    :=
             'p_mensajeerror = revisar campos para consulta de tipos de tasas de interes';
         :New.idestado              := 'R';
         -- :New.mensaje               := 'Rechazado';
         p_depura('*******2137************' || v_error );
         If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error, 0 ) Then
                        -- Dbms_output.put_line
            --               ( 'p_mensajeerror = Revisar campos para consulta de tipos de tasas de interes' );
            raise_application_error( num => -20000, msg => v_error );
         End If;
         f_log_procesoRR('TEMPFUD:'||:new.id_tempfud,'ID_TEMPFUD: '||:new.id_tempfud|| 'V_error: '|| v_error );
   End;
   reg1.variacion_base        := :New.tasacal -( vporcentaje );
   ---- p_depura('salio de validaciones 2 '||sqlerrm);
   reg1.tasa_interes          := :New.tasacal;
   reg1.segregacion_rd        := :New.idrama_ciiu;
   ---- p_depura('salio de validaciones 3 '||sqlerrm);
   --
   -- p_depura( 'reg1.cuota ' || reg1.cuota );
   If :New.clientepertenece Is Null Then
      pr_credito.obtiene_planinversion( p_codempresa, 'ESPA', reg1.plan_inversion,
                                        v_desc_plan_inversion );
      --
      -- p_depura( 'Busca_Extras_Cliente ' || reg1.monto_credito || ' ' || reg1.cuota );
      --
      pr_credito.busca_extras_cliente
                                    ( p_codempresa, reg1.codigo_actividad,
                                      reg1.codigo_cliente,   --:New.idaperturacliente,--LMVR
                                      v_desc_ejecutivo, v_desc_ejecutivo,
                                      v_desc_actividad, v_agencia_labora,
                                      --FAMH --- 22-04-2005 PROBLEMA CON LA AGENCIA
                                      reg1, 'ESPA' );
         --
      -----------------------------------------------------------------------------
      -- JMoraM   02/08/2016
      -- Se valida si hay un cr¿¿¿¿dito en estado Registrado,
      -- Se anula los que est¿¿¿¿n para que cree el nuevo.
      -----------------------------------------------------------------------------
     p_depura('****** Line  2168 ************'||v_error);  
      If v_persona Is Not Null Then
         Begin
            Select Count( no_credito )
              Into v_credito_anula
              From pr.pr_creditos
             Where codigo_empresa = 1
               And estado = 'R'
               And codigo_cliente = v_persona;
         Exception
            When Others Then
               v_credito_anula            := 0;
               p_depura('*******2180************'  );
         End;
         If v_credito_anula > 0 Then
              /*Update pr.pr_creditos
                 Set estado = 'N'
               Where codigo_empresa = 1
                 And estado = 'R'
                 And codigo_cliente = v_persona;
              --LMVR
              insert into pr_creditos_hi
            select * from pr_creditos
               where codigo_empresa = 1
                 and codigo_cliente = v_persona
                 and estado = 'N';
              --
              delete PR_CREDITOS
              where codigo_empresa = 1
                 and codigo_cliente = v_persona
                 and estado = 'N';*/
            Begin
               For a In ( Select no_credito
                           From pr_creditos
                          Where codigo_empresa = 1
                            And estado = 'R'
                            And codigo_cliente = v_persona ) Loop
                  anula_credito_at( a.no_credito );
               End Loop;
            Exception
               When Others Then
               f_log_procesoRR('TEMPFUD:'||:new.id_tempfud,'ID_TEMPFUD: '||:new.id_tempfud|| 'V_error: '|| v_error );
                  If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R',
                                                     'Error Anulacion AT', 0 ) Then
                     -- Dbms_output.put_line( 'p_mensajeerror=' || p_mensajeerror );
                     Raise;
                  End If;
            End;
         --LMVR
         --
         End If;
      End If;
      -----------------------------------------------------------------------------
      --  JMORAM 22022018 -- Dinero mas rapido solo la primera vez               --
      -----------------------------------------------------------------------------
      
      Declare
         v_existe_credito              Varchar2( 1 ) := 'N';
      Begin
         Begin
            Select Distinct esta
                       Into v_existe_credito
                       From ( Select 'S' esta
                               From pr_creditos
                              Where codigo_empresa = 1
                                And estado In( 'D', 'V', 'M', 'E', 'J', 'C' )
                                And codigo_cliente = v_persona
                             Union All
                             Select 'S' esta
                               From pr_creditos_hi
                              Where codigo_empresa = 1
                                And estado = 'C'
                                And codigo_cliente = v_persona );
         Exception
            When Others Then
               v_existe_credito           := 'N';
         End;
         If     v_existe_credito = 'S'
            And Instr( param.parametro_x_empresa( 1, 'TIPCRED_VAL_CLT_NEW', 'PR' ),
                       :New.codigoproyecto ) > 0 Then
            v_error                    :=
                  'El codigo de proyecto '
               || :New.codigoproyecto
               || ' solo aplica para clientes nuevos.';
            :New.idestado              := 'R';
            -- :New.mensaje               := 'Rechazado';
            If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error, 0 ) Then
               :New.idestado              := 'R';
               -- :New.mensaje               := 'Rechazado';
               raise_application_error( num => -20000, msg => v_error );
            End If;
            f_log_procesoRR('TEMPFUD:'||:new.id_tempfud,'ID_TEMPFUD: '||:new.id_tempfud|| 'V_error: '|| v_error );
         Else
            pr_credito.inserta_credito( p_codempresa, To_number( p_codagencia ),
                                        p_nrocredito, reg1, p_mensajeerror );
         End If;
      End;
   -----------------------------------------------------------------------------
   --  JMORAM 22022018 -- Dinero mas rapido solo la primera vez               --
   -----------------------------------------------------------------------------
   
   End If;
     
   If    v_error Is Not Null
      Or p_mensajeerror Is Not Null
      Or :New.idestado = 'R' Then
    
      :New.idestado              := 'R';
      utilitarios.obt_mensaje_error( p_mensajeerror, 'PR', v_error_sysde, Null );
      If v_error_sysde Like '%PA-000000 El Mensaje de error no fue encontrado%' Then
         v_error                    :=
            Substr( Replace( '[' || v_error || '-' || p_mensajeerror || ']',
                             'p_mensajeerror = ' ),
                    1, 200 );
      Else
         v_error                    := v_error_sysde || '-' || v_error;
            
      End If;
      :New.mensaje               := v_error;
       
      
     
      
      /*
      If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R', v_error, 0 ) Then
         raise_application_error( num => -20000, msg => v_error );
      End If;
      */
      
       p_depura('****** Line  2288 ************'||v_error);   
   Else
      :New.nocredito             := p_nrocredito;
      :New.idestado              := 'A';
      :New.mensaje               := 'Procesado';
          
      --CZ17032022 Eliminar llamada webservices
      /*
      If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'A','Procesado Correctamente', p_nrocredito ) Then
           p_depura('****** Line  Correctamente ************'||p_nrocredito);
         Null;    
      End If;
      */
      p_depura('****** Line  2307 ************'||v_error);
   End If;
---
  End If;  --malmanzar  05-10-2022, para controlar llamado directo a proceso api_portacredit.pCrearFud   
  
Exception
   When Others Then
   f_log_procesoRR('TEMPFUD', 'V_error: '|| v_error|| ' - '||SQLERRM||'---'||DBMS_UTILITY.FORMAT_ERROR_STACK||'---'|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE );
      -- Consider logging the error and then re-raise
      :New.idestado              := 'R';
      :New.mensaje               := Nvl( v_error || '-' || Sqlerrm, 'Rechazado' );
       p_depura('******2316 Line Error ************'||v_error);
        raise_application_error(-20001,'Error '|| v_error);
      If ia.api_portacredit.fnupdatefud( :New.id_tempfud, 0, 'R',
                                         v_error || '-' || Sqlerrm, 0 ) Then
          p_depura('******RAISE ************'||v_error);
          f_log_procesoRR('TEMPFUD', 'V_error: '|| v_error|| ' - '||SQLERRM||'---'||DBMS_UTILITY.FORMAT_ERROR_STACK||'---'|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE );
         raise_application_error(-20001,'Error '|| v_error);
      End If;
End;
/


CREATE OR REPLACE PUBLIC SYNONYM TEMPFUD FOR PR.TEMPFUD;


GRANT DELETE, INSERT, SELECT, UPDATE ON PR.TEMPFUD TO BIA;

GRANT DELETE, INSERT, SELECT, UPDATE ON PR.TEMPFUD TO BPA;

GRANT DELETE, INSERT, SELECT, UPDATE ON PR.TEMPFUD TO BPR;

GRANT SELECT ON PR.TEMPFUD TO CDG;

GRANT DELETE, INSERT, SELECT, UPDATE ON PR.TEMPFUD TO IA;

GRANT DELETE, INSERT, SELECT, UPDATE ON PR.TEMPFUD TO PA WITH GRANT OPTION;

GRANT SELECT ON PR.TEMPFUD TO PUBLIC;

GRANT SELECT ON PR.TEMPFUD TO SII;

GRANT DELETE, INSERT, SELECT, UPDATE ON PR.TEMPFUD TO USR_APPS;

GRANT DELETE, INSERT, SELECT, UPDATE ON PR.TEMPFUD TO USR_BGP;

GRANT DELETE, INSERT, SELECT, UPDATE ON PR.TEMPFUD TO USR_BGP_DEPONENTE;

GRANT DELETE, INSERT, SELECT, UPDATE ON PR.TEMPFUD TO USR_BGP_SEGURO;

GRANT DELETE, INSERT, SELECT, UPDATE ON PR.TEMPFUD TO USR_DEBUG;

GRANT DELETE, INSERT, SELECT, UPDATE ON PR.TEMPFUD TO USR_DOC_FILEFLOW;

GRANT DELETE, INSERT, SELECT, UPDATE ON PR.TEMPFUD TO USR_PORTACREDIT_MS;

GRANT DELETE, INSERT, SELECT, UPDATE ON PR.TEMPFUD TO USR_QUASH;

GRANT DELETE, INSERT, SELECT, UPDATE ON PR.TEMPFUD TO USR_REPRESTAMO;
