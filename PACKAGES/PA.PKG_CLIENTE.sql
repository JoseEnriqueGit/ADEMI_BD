CREATE OR REPLACE PACKAGE BODY PA.PKG_CLIENTE IS

    FUNCTION Convertir_Cliente_Api(p_Json       IN     BLOB,
                                   p_error      IN OUT VARCHAR2) 
      RETURN PA.CLIENTES_PERSONA_FISICA_OBJ IS
        j                       APEX_JSON.T_VALUES;
        l_clob                  CLOB;
        l_dest_offset           PLS_INTEGER := 1;
        l_src_offset            PLS_INTEGER := 1;
        l_lang_context          PLS_INTEGER := DBMS_LOB.default_lang_ctx;
        l_warning               PLS_INTEGER;
        vFecha                  VARCHAR2(30);
        vPrimer_Nombre          PA.PERSONAS_FISICAS.PRIMER_NOMBRE%TYPE;
        vSegundo_Nombre         PA.PERSONAS_FISICAS.SEGUNDO_NOMBRE%TYPE;
        vPrimer_Apellido        PA.PERSONAS_FISICAS.PRIMER_APELLIDO%TYPE;
        vSegundo_Apellido       PA.PERSONAS_FISICAS.SEGUNDO_APELLIDO%TYPE;
        vTotalIngresos          NUMBER := 0;
        vTotalIdPersonas        PLS_INTEGER := 0;
        vTotalDirPersonas       PLS_INTEGER := 0;
        vTotalTelPersonas       PLS_INTEGER := 0;
        vTotalOtroBancos        PLS_INTEGER := 0;
        vTotalRefPers           PLS_INTEGER := 0;
        vTotalRefComerc         PLS_INTEGER := 0;
        vTotalListaPEP          PLS_INTEGER := 0;
        vTotalProm              PLS_INTEGER := 0;
        vIndI                   PLS_INTEGER := 0;
        vIndD                   PLS_INTEGER := 0;
        vIndT                   PLS_INTEGER := 0;
        vIndC                   PLS_INTEGER := 0;
        vIndRP                  PLS_INTEGER := 0;
        vIndRC                  PLS_INTEGER := 0;
        vIndP                   PLS_INTEGER := 0;
        vIndPP                  PLS_INTEGER := 0;
        vNacionalidad           PA.PAIS.NACIONALIDAD%TYPE;
        vTipoId                 PA.ID_PERSONAS.COD_TIPO_ID%TYPE;
        vMascara                PA.TIPOS_ID.MASCARA%TYPE;
        vTelefono               VARCHAR2(30);
        vCodArea                PA.TEL_PERSONAS.COD_AREA%TYPE;
        vNumTel                 PA.TEL_PERSONAS.NUM_TELEFONO%TYPE;
        vPaisIso3               VARCHAR2(100);
        vCodigoPais             PA.PAIS.COD_PAIS%TYPE;
        vDirSector              VARCHAR2(100);
        vDirBarrio              VARCHAR2(100);
        vDirCalle               VARCHAR2(100);
        vDirNumero              VARCHAR2(100);        
        vClientePersonaFisica   PA.CLIENTES_PERSONA_FISICA_OBJ := PA.CLIENTES_PERSONA_FISICA_OBJ();
        vPersona                PA.PERSONAS_OBJ := PA.PERSONAS_OBJ();
        vPersonaFisica          PA.PERSONAS_FISICAS_OBJ := PA.PERSONAS_FISICAS_OBJ();
        vIdPersonas             PA.ID_PERSONAS_LIST                := PA.ID_PERSONAS_LIST(); 
        vIdPersona              PA.ID_PERSONAS_OBJ                 := PA.ID_PERSONAS_OBJ();
        vDirPersonas            PA.DIR_PERSONAS_LIST               := PA.DIR_PERSONAS_LIST(); 
        vDirPersona             PA.DIR_PERSONAS_OBJ                := PA.DIR_PERSONAS_OBJ();
        vTelPersonas            PA.TEL_PERSONAS_LIST               := PA.TEL_PERSONAS_LIST(); 
        vTelPersona             PA.TEL_PERSONAS_OBJ                := PA.TEL_PERSONAS_OBJ();
        vDirEnvioxPers          PA.DIR_ENVIO_X_PERS_OBJ            := PA.DIR_ENVIO_X_PERS_OBJ();
        vInfoLaboral            PA.INFO_LABORAL_OBJ                := PA.INFO_LABORAL_OBJ(); 
        vCtaCliOtrBancos        PA.CTAS_CLIENTES_OTR_BANCOS_LIST   := PA.CTAS_CLIENTES_OTR_BANCOS_LIST();
        vCtaCliOtrBanco         PA.CTAS_CLIENTES_OTR_BANCOS_OBJ    := PA.CTAS_CLIENTES_OTR_BANCOS_OBJ();
        vRefPersonales          PA.REF_PERSONALES_LIST             := PA.REF_PERSONALES_LIST(); 
        vRefPersonal            PA.REF_PERSONALES_OBJ              := PA.REF_PERSONALES_OBJ();
        vRefComerciales         PA.REF_COMERCIALES_LIST            := PA.REF_COMERCIALES_LIST();
        vRefComercial           PA.REF_COMERCIALES_OBJ             := PA.REF_COMERCIALES_OBJ();
        vInfoProdSol            PA.INFO_PROD_SOL_OBJ               := PA.INFO_PROD_SOL_OBJ();    
        vInfoBuro               PA.INFO_BURO_OBJ                   :=  PA.INFO_BURO_OBJ();
        vInfoDocFisNac          PA.INFO_DOC_FISICA_NACIONAL_OBJ    := PA.INFO_DOC_FISICA_NACIONAL_OBJ();
        vInfoDocFisExtranj      PA.INFO_DOC_FISICA_EXTRANJ_OBJ     := PA.INFO_DOC_FISICA_EXTRANJ_OBJ();
        vInfoVerifDocFisNac     PA.INFO_VERIF_DOC_FIS_NAC_OBJ      := PA.INFO_VERIF_DOC_FIS_NAC_OBJ();
        vInfoVerifDocFisExt     PA.INFO_VERIF_DOC_FIS_EXTRAN_OBJ   := PA.INFO_VERIF_DOC_FIS_EXTRAN_OBJ();
        vInfoWorldCheck         PA.INFO_WORLD_CHECK_OBJ            := PA.INFO_WORLD_CHECK_OBJ();
        vListaPep               PA.LISTA_PEP_LIST                  := PA.LISTA_PEP_LIST();  
        vPep                    PA.LISTA_PEP_OBJ                   := PA.LISTA_PEP_OBJ();
        vPromocionPersonas      PA.PROMOCION_PERSONA_LIST          := PA.PROMOCION_PERSONA_LIST(); 
        vPromocionPersona       PA.PROMOCION_PERSONA_OBJ           := PA.PROMOCION_PERSONA_OBJ();
    BEGIN
        IF p_Json IS NOT NULL THEN        
             -- Convert the BLOB to a CLOB.
             DBMS_LOB.createtemporary( lob_loc => l_clob,
                                       cache   => FALSE,
                                       dur     => DBMS_LOB.call);

             DBMS_LOB.converttoclob(  dest_lob      => l_clob,
                                      src_blob      => p_Json,
                                      amount        => DBMS_LOB.lobmaxsize,
                                      dest_offset   => l_dest_offset,
                                      src_offset    => l_src_offset, 
                                      blob_csid     => DBMS_LOB.default_csid,
                                      lang_context  => l_lang_context,
                                      warning       => l_warning);   
                                        
            APEX_JSON.parse(j, l_clob);
            
            vClientePersonaFisica                   := PA.CLIENTES_PERSONA_FISICA_OBJ();    
                    
            vClientePersonaFisica.EsFisica          := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.EsFisica');
            vClientePersonaFisica.ConsultarBuro     := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.ConsultarBuro');     
            vClientePersonaFisica.ConsultarPadron   := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.ConsultarPadron'); 
            vClientePersonaFisica.Cod_Promotor      := TO_NUMBER(APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.CodPromotor'));
            vPrimer_Nombre                          := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.PrimerNombre');
            vSegundo_Nombre                         := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.SegundoNombre');
            vPrimer_Apellido                        := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.PrimerApellido');
            vSegundo_Apellido                       := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.SegundoApellido');
            
            -- Personas
            vPersona                                := PA.PERSONAS_OBJ();
            vPersona.ES_FISICA                      := vClientePersonaFisica.EsFisica;
            vPersona.NOMBRE                         := vPrimer_Nombre||' '||vSegundo_Nombre||' '||vPrimer_Apellido||' '||vSegundo_Apellido;
            vPersona.IND_CLTE_I2000                 := 'N';
            vPersona.PAGA_IMP_LEY288                := 'S';
            vPersona.BENEF_PAG_LEY288               := 'S';
            vPersona.COD_VINCULACION                := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.CodigoVinculacion');
            vPersona.COD_SEC_CONTABLE               := '030202';
            vPersona.CODIGO_SUSTITUTO               := NULL;
            vPersona.ESTADO_PERSONA                 := 'A';
            vPersona.COBR_NODGII_132011             := 'S';
            vPersona.LLENO_FATCA                    := 'N';
            vPersona.IMPRIMIO_FATCA                 := 'N';
            vPersona.ES_FATCA                       := 'N';
            vPersona.TEL_VERIFICADO                 := 'N';
                        
            vPersonaFisica                  := PA.PERSONAS_FISICAS_OBJ();
            vPersonaFisica.EST_CIVIL        := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.EstadoCivil');
            vPersonaFisica.SEXO             := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.Sexo');
            vFecha                          := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.FechaNacimiento');
            vPersonaFisica.FEC_NACIMIENTO   := TO_DATE(vFecha, 'DD/MM/RRRR');          
            vPersonaFisica.PRIMER_APELLIDO  := vPrimer_Apellido;
            vPersonaFisica.SEGUNDO_APELLIDO := vSegundo_Apellido;
            vPersonaFisica.PRIMER_NOMBRE    := vPrimer_Nombre;
            vPersonaFisica.SEGUNDO_NOMBRE   := vSegundo_Nombre;
            vPersonaFisica.IDIOMA_CORREO    := 'ESPA';
            vPersonaFisica.ES_MAL_DEUDOR    := 'N';
            vPersonaFisica.NACIONALIDAD     := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.Nacionalidad');
            vPersonaFisica.COD_SECTOR       := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.SectorActividad');
            vPersonaFisica.ESTATAL          := 'N';
            vPersonaFisica.EMAIL_USUARIO    := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.Email');
            vPersonaFisica.EMAIL_SERVIDOR   := NULL;
            vPersonaFisica.NIVEL_ESTUDIOS   := NULL;
            vPersonaFisica.TIPO_VIVIENDA    := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.TipoVivienda');
            vPersonaFisica.NUM_HIJOS        := NVL(APEX_JSON.get_number(p_values => j, p_path => 'ClientePersonaFisica.NumeroHijos'),0);
            vPersonaFisica.NUM_DEPENDIENTES := NVL(APEX_JSON.get_number(p_values => j, p_path => 'ClientePersonaFisica.NumeroDependientes'),0);
            vPersonaFisica.ES_RESIDENTE     := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.EsResidente');
            vPersonaFisica.TIEMPO_VIVIEN_ACT := NVL(APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.TiempoViviendaActual'),0);
            vPersonaFisica.EVAL_REF_BANCARIA := 'V';
            vPersonaFisica.EVAL_REF_TARJETAS := 'V';
            vPersonaFisica.EVAL_REF_LABORAL  := 'C';
            vTotalIngresos                  := NVL(APEX_JSON.get_number(p_values => j, p_path => 'ClientePersonaFisica.TotalIngresos'),0);
            vPersonaFisica.TOTAL_INGRESOS   := vTotalIngresos; 
            vPaisIso3                       := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.PaisIso3');
            BEGIN
                SELECT COD_PAIS 
                  INTO vCodigoPais 
                  FROM PA.PAIS 
                  WHERE PA.PAIS.COD_PAIS_ISO = vPaisIso3;
            EXCEPTION WHEN NO_DATA_FOUND THEN
                vCodigoPais := PA.OBT_PARAMETROS ('1', 'PA', 'CODIGO_PAIS_LOCAL');
            END;
            vPersonaFisica.COD_PAIS         := NVL(vCodigoPais, PA.OBT_PARAMETROS ('1', 'PA', 'CODIGO_PAIS_LOCAL'));
            vPersonaFisica.SCORING          := 0;
            vPersonaFisica.ACTIVIDAD        := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.ActividadQueRealiza');        
            vPersonaFisica.RANGO_INGRESOS   := NVL(PA.OBT_RANGO_INGRESOS(NVL(vTotalIngresos,0)), 1);
            vPersonaFisica.CASADA_APELLIDO  := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.ApellidoCasada');
            vPersonaFisica.ES_FUNCIONARIO   := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.EsFuncionarioPep');
            vPersonaFisica.ES_PEPS          := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.EsRelacionadoPep');
            vPersonaFisica.COD_ACTIVIDAD    := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.CodigoActividad');
            vPersonaFisica.COD_SUBACTIVIDAD := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.CodigoSubactividad');
            
            vPersonaFisica.TIPO_CLIENTE     := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.TipoCliente');
            vPersonaFisica.COD_FINALIDAD    := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.CodigoFinalidad');
            vPersonaFisica.APELLIDO_CASADA  := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.ApellidoCasada');
            vPersonaFisica.TERCER_NOMBRE    := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.TercerNombre');
            vPersonaFisica.TIPO_SOC_CONYUGAL := 'S';
            vPersonaFisica.GPO_RIESGO       := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.GrupoRiesgo');
            vPersonaFisica.IND_CLTE_VIP     := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.ClienteVIP');                        
            
            vTotalIdPersonas := APEX_JSON.get_count(p_values => j, p_path => 'ClientePersonaFisica.Identificaciones');
            vIdPersonas         := PA.ID_PERSONAS_LIST(); 
        
            IF vTotalIdPersonas > 0  THEN
                FOR i IN 1 .. vTotalIdPersonas LOOP
                    vIdPersona                    := PA.ID_PERSONAS_OBJ();
                    vTipoId  := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.Identificaciones[%d].TipoIdentificacion', p0 => i);
                    BEGIN
                        SELECT mascara 
                          INTO vMascara
                          FROM tipos_id 
                         WHERE cod_tipo_id = vTipoId;
                    EXCEPTION WHEN OTHERS THEN
                        vMascara    := 'NNN-NNNNNNN-N';
                    END;
                    vIdPersona.COD_TIPO_ID := vTipoId;
                    vIdPersona.NUM_ID := PA.Formatear_Identificacion(APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.Identificaciones[%d].NumeroIdentificacion', p0 => i),
                                                                    vMascara,
                                                                    'ESPA');                    
                    vIdPersona.FEC_VENCIMIENTO  := TO_DATE('31/12/2050', 'DD/MM/RRRR');
                    vPaisIso3 := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.Identificaciones[%d].PaisIso3Identificacion', P0 => i);
                    BEGIN
                        SELECT COD_PAIS 
                          INTO vCodigoPais 
                          FROM PA.PAIS 
                          WHERE PA.PAIS.COD_PAIS_ISO = vPaisIso3;
                    EXCEPTION WHEN NO_DATA_FOUND THEN
                        vCodigoPais := PA.OBT_PARAMETROS ('1', 'PA', 'CODIGO_PAIS_LOCAL');
                    END;
                     vIdPersona.COD_PAIS         :=  vCodigoPais;
                     
                    BEGIN
                        SELECT DISTINCT nacionalidad 
                          INTO vNacionalidad
                          FROM PA.PAIS
                         WHERE cod_pais = vIdPersona.COD_PAIS;
                    EXCEPTION WHEN NO_DATA_FOUND THEN
                        vNacionalidad := NULL;
                    END;     
                    
                    vIdPersona.NACIONALIDAD     := NVL(vNacionalidad, 'Dominicana');
                    vIdPersonas.EXTEND;
                    vIndI := vIndI + 1;
                    vIdPersonas(vIndI) :=  vIdPersona;  
                END LOOP;
            END IF;
            vPersonaFisica.TIPO_PERSONA     := NVL(APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.TipoPersona'), PA.ASIGNA_TIPO_PERSONA(vTipoID, vPersonaFisica.Sexo));
            vDirPersonas                    := PA.DIR_PERSONAS_LIST(); 
            vTotalDirPersonas := APEX_JSON.get_count(p_values => j, p_path => 'ClientePersonaFisica.Direcciones');
            IF vTotalDirPersonas > 0 THEN
                FOR d IN 1 .. vTotalDirPersonas LOOP
                    vDirPersona   := PA.DIR_PERSONAS_OBJ();
                    vDirPersona.TIP_DIRECCION   := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.Direcciones[%d].TipoDireccion',    p0 => d);                     -- Direccion donde Vive                      
                    vPaisIso3                   := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.Direcciones[%d].PaisIso3',       p0 => d);  
                    BEGIN
                        SELECT COD_PAIS 
                          INTO vCodigoPais 
                          FROM PA.PAIS 
                          WHERE PA.PAIS.COD_PAIS_ISO = vPaisIso3;
                    EXCEPTION WHEN NO_DATA_FOUND THEN
                        vCodigoPais := PA.OBT_PARAMETROS ('1', 'PA', 'CODIGO_PAIS_LOCAL');
                    END;
                    vDirPersona.COD_PAIS        := vCodigoPais; 
                    vDirPersona.COD_PROVINCIA   := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.Direcciones[%d].CodigoRegion',     p0 => d);  
                    vDirPersona.COD_CANTON      := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.Direcciones[%d].CodigoProvincia',  p0 => d);  
                    vDirPersona.COD_DISTRITO    := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.Direcciones[%d].CodigoMunicipio',  p0 => d);  
                    vDirPersona.COD_PUEBLO      := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.Direcciones[%d].CodigoPueblo',     p0 => d);  
                    vDirPersona.ES_DEFAULT      := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.Direcciones[%d].PorDefecto',       p0 => d);  
                    vDirSector                  := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.Direcciones[%d].Sector',           p0 => d);
                    vDirBarrio                  := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.Direcciones[%d].Barrio',           p0 => d);
                    vDirCalle                   := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.Direcciones[%d].Calle',            p0 => d);
                    vDirNumero                  := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.Direcciones[%d].NumeroCasaApto',   p0 => d);
                    vDirPersona.DETALLE         := vDirCalle||' NO.'||vDirNumero||', '||vDirBarrio||', '||vDirSector;
                    vDirPersonas.EXTEND;
                    vIndD := vIndD + 1;
                    vDirPersonas(vIndD)     := vDirPersona;
                END LOOP;
            END IF;
            vTelPersonas                    := PA.TEL_PERSONAS_LIST(); 
            vTotalTelPersonas := APEX_JSON.get_count(p_values => j, p_path => 'ClientePersonaFisica.Telefonos');
            IF vTotalTelPersonas > 0 THEN
                FOR t IN 1 .. vTotalTelPersonas LOOP
                    vTelPersona := PA.TEL_PERSONAS_OBJ();
                    vTelefono                   := PA.EXTRAER_NUMEROS(APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.Telefonos[%d].NumeroTelefono', p0 => t));  
                    vCodArea                    := SUBSTR(vTelefono,1,3);
                    vNumTel                     := SUBSTR(vTelefono, 4);
                    vTelPersona.COD_AREA        := vCodArea;
                    vTelPersona.NUM_TELEFONO    := vNumTel;
                    vTelPersona.TIP_TELEFONO    := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.Telefonos[%d].TipoTelefono', p0 => t);         -- Linea Directa 
                    vTelPersona.TEL_UBICACION   := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.Telefonos[%d].UbicacionTelefono', p0 => t);          -- Casa
                    vTelPersona.ES_DEFAULT      := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.Telefonos[%d].PorDefecto', p0 => t);  
                    vPaisIso3                   := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.Telefonos[%d].PaisIso3Telefono', p0 => t);
                    BEGIN
                        SELECT COD_PAIS 
                          INTO vCodigoPais 
                          FROM PA.PAIS 
                          WHERE PA.PAIS.COD_PAIS_ISO = vPaisIso3;
                    EXCEPTION WHEN NO_DATA_FOUND THEN
                        vCodigoPais := PA.OBT_PARAMETROS ('1', 'PA', 'CODIGO_PAIS_LOCAL');
                    END;
                    vTelPersona.COD_PAIS        := vCodigoPais;
                    vTelPersonas.EXTEND;
                    vIndT := vIndT + 1;
                    vTelPersonas(vIndT)     := vTelPersona;
                END LOOP;
            END IF;
            vDirEnvioxPers                 := PA.DIR_ENVIO_X_PERS_OBJ(); 
            vDirEnvioxPers.TIPO_ENVIO      := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.DireccionEnvio.TipoEnvio');
            /*vCodPais                       := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.DireccionEnvio.CodigoPais');
            vCodRegion                     := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.DireccionEnvio.CodigoRegion');
            vCodProvincia                  := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.DireccionEnvio.CodigoProvincia');
            vCodMunicipio                  := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.DireccionEnvio.CodigoMunicipio');
            vCodPueblo                     := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.DireccionEnvio.CodigoPueblo');
            vDetalleDireccion              := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.DireccionEnvio.Detalle');*/            
            vDirEnvioxPers.COD_DIRECCION   := 4; 
            vDirEnvioxPers.COD_EMPRESA     := '1';
            vDirEnvioxPers.COD_AGENCIA     := 50;
            vDirEnvioxPers.EMAIL_USUARIO   := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.DireccionEnvio.EmailEnvio');
            
            vInfoLaboral                := PA.INFO_LABORAL_OBJ();  
            vFecha	                    := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.InformacionLaboral.FechaIngreso');    
            vInfoLaboral.FEC_INGRESO    := TO_DATE(vFecha, 'DD/MM/RRRR');
            vInfoLaboral.LUGAR_TRABAJO  := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.InformacionLaboral.LugarTrabajo'); 
            vInfoLaboral.MONTO          := APEX_JSON.get_number(p_values => j, p_path => 'ClientePersonaFisica.InformacionLaboral.MontoIngreso'); 
            vInfoLaboral.COD_CARGO      := '50';
            vInfoLaboral.PUESTO         := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.InformacionLaboral.Puesto'); 
            vInfoLaboral.OBSERVACIONES  := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.InformacionLaboral.Observaciones');
            vInfoLaboral.TIPO_INGRESO   := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.InformacionLaboral.TipoIngresos');
            vInfoLaboral.EMPLEO_ACTUAL  := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.InformacionLaboral.EsEmpleoActual');
            vInfoLaboral.COD_MONEDA     := NULL;
            vInfoLaboral.MONTO_ORIGEN   := NULL;
            vInfoLaboral.DIRECCION      := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.InformacionLaboral.DireccionLaboral'); 
            vTelefono                   := PA.EXTRAER_NUMEROS(APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.InformacionLaboral.Telefono'));  
            vCodArea                    := SUBSTR(vTelefono,1,3);
            vNumTel                     := SUBSTR(vTelefono, 4);
            vInfoLaboral.COD_AREA       := vCodArea; 
            vInfoLaboral.NUM_TELEFONO   := vNumTel;
            vInfoLaboral.EXTENSION_TEL  := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.InformacionLaboral.ExtensionTelefonica');    
            vInfoLaboral.ANTIGUEDAD     := NULL;
            
            vCtaCliOtrBancos               := PA.CTAS_CLIENTES_OTR_BANCOS_LIST();
            vTotalOtroBancos         := APEX_JSON.get_count(p_values => j, p_path => 'ClientePersonaFisica.CuentaOtrosBancos');
            IF vTotalOtroBancos > 0 THEN
                FOR c IN 1 .. vTotalOtroBancos LOOP
                   vCtaCliOtrBanco          := PA.CTAS_CLIENTES_OTR_BANCOS_OBJ();
                   vCtaCliOtrBanco.COD_EMISOR           := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.CuentaOtrosBancos[%d].EntidadBancaria', p0 => c);    
                   vCtaCliOtrBanco.NUM_CUENTA           := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.CuentaOtrosBancos[%d].NumeroCuenta', p0 => c);
                   vCtaCliOtrBanco.NOM_CUENTA           := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.CuentaOtrosBancos[%d].NombreCuenta', p0 => c);
                   vCtaCliOtrBanco.TIPO_CUENTA          := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.CuentaOtrosBancos[%d].TipoCuenta', p0 => c);
                   vCtaCliOtrBanco.COD_MONEDA           := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.CuentaOtrosBancos[%d].MonedaCuenta', p0 => c);
                   vPaisIso3                            := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.CuentaOtrosBancos[%d].PaisIso3Cuenta', p0 => c);
                   BEGIN
                        SELECT COD_PAIS 
                          INTO vCodigoPais 
                          FROM PA.PAIS 
                          WHERE PA.PAIS.COD_PAIS_ISO = vPaisIso3;
                    EXCEPTION WHEN NO_DATA_FOUND THEN
                        vCodigoPais := PA.OBT_PARAMETROS ('1', 'PA', 'CODIGO_PAIS_LOCAL');
                    END;
                   vCtaCliOtrBanco.COD_PAIS             := vCodigoPais;
                   vCtaCliOtrBanco.OFICIAL_RESPONSABLE  := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.CuentaOtrosBancos[%d].Oficial', p0 => c);
                   vCtaCliOtrBanco.TIEMPO_APERTURA      := APEX_JSON.get_number(p_values => j, p_path => 'ClientePersonaFisica.CuentaOtrosBancos[%d].TiempoAperturaCuenta', p0 => c);
                   vCtaCliOtrBancos.EXTEND;
                   vIndC := vIndC + 1;
                   vCtaCliOtrBancos(vIndC)              := vCtaCliOtrBanco;
                END LOOP;
            END IF;
            
            vRefPersonales                              := PA.REF_PERSONALES_LIST();
            vTotalRefPers         := APEX_JSON.get_count(p_values => j, p_path => 'ClientePersonaFisica.ReferenciasPersonales');
            IF vTotalRefPers > 0 THEN
                FOR p IN 1 .. vTotalRefPers LOOP
                    vRefPersonal           := PA.REF_PERSONALES_OBJ();
                    vRefPersonal.COD_EMPRESA        := '1';
                    vRefPersonal.COD_TIPO_ID        := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.ReferenciasPersonales[%d].TipoIdentificacion', p0 => p);
                    vRefPersonal.NOMBRE_REF         := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.ReferenciasPersonales[%d].Nombres', p0 => p);
                    vRefPersonal.NUM_ID             := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.ReferenciasPersonales[%d].NumeroIdentificacion', p0 => p);
                    vTelefono                       := PA.EXTRAER_NUMEROS(APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.ReferenciasPersonales[%d].Telefono'));  
                    vCodArea                        := SUBSTR(vTelefono,1,3);
                    vNumTel                         := SUBSTR(vTelefono, 4);
                    vRefPersonal.COD_AREA           := vCodArea;
                    vRefPersonal.NUM_TELEFONO       := vNumTel;
                    vRefPersonal.PUESTO             := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.ReferenciasPersonales[%d].Puesto', p0 => p);
                    vRefPersonal.LUGAR_TRABAJO      := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.ReferenciasPersonales[%d].LugarTrabajo', p0 => p);
                    vRefPersonal.RELACION_PERSONA   := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.ReferenciasPersonales[%d].RelacionConCliente', p0 => p);
                    vRefPersonales.EXTEND;
                    vIndRP := vIndRP + 1;
                    vRefPersonales(vIndRP)          := vRefPersonal;
                END LOOP;
				ELSE
            --HAGUTIERREZ | ELSE Agregado para Onboarding
            --Se insertan referencias personasles dummy para saltar validacion del mismo
                FOR p IN 1 .. 2 LOOP
                    vRefPersonal           := PA.REF_PERSONALES_OBJ();
                    vRefPersonal.COD_EMPRESA        := '1';
                    vRefPersonal.COD_TIPO_ID        := '1';
                    vRefPersonal.NOMBRE_REF         := 'REF ONBOARDING';
                    vRefPersonal.NUM_ID             := '1';
                    vRefPersonal.RELACION_PERSONA   := 'FAMILIAR';
                    vRefPersonales.EXTEND;
                    vIndRP := vIndRP + 1;
                    vRefPersonales(vIndRP)          := vRefPersonal;
                END LOOP;

            END IF;
            
            vTotalRefComerc         := APEX_JSON.get_count(p_values => j, p_path => 'ClientePersonaFisica.RefenciasComerciales');
            IF vTotalRefComerc > 0 THEN
                FOR c IN 1 .. vTotalRefComerc LOOP
                    vRefComercial.COD_TIP_REF       := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.RefenciasComerciales[%d].TipoReferencia', p0 => c);
                    vRefComercial.COD_ENTE          := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.RefenciasComerciales[%d].EntidadComercial', p0 => c);
                    vRefComercial.NUM_CUENTA        := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.RefenciasComerciales[%d].NumeroCuenta', p0 => c);
                    vRefComercial.CREDITO_OTORGADO  := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.RefenciasComerciales[%d].CreditoOtorgado', p0 => c);
                    vRefComercial.SALDO_CREDITO     := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.RefenciasComerciales[%d].CreditoSaldado', p0 => c);
                    vRefComercial.CUOTA_MENSUAL     := APEX_JSON.get_number(p_values => j, p_path => 'ClientePersonaFisica.RefenciasComerciales[%d].CuotaMensual', p0 => c);
                    vRefComercial.COD_MONEDA        := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.RefenciasComerciales[%d].Moneda', p0 => c);
                    vFecha	                        := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.RefenciasComerciales[%d].FechaApertura', p0 => c);
                    vRefComercial.FEC_APERTURA      := TO_DATE(vFecha, 'DD/MM/RRRR');
                    vFecha	                        := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.RefenciasComerciales[%d].FechaVencimiento', p0 => c);
                    vRefComercial.FEC_VENCIMIENTO   := TO_DATE(vFecha, 'DD/MM/RRRR');
                    vRefComercial.DESC_GARANTIA     := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.RefenciasComerciales[%d].DescripionGarantia', p0 => c);
                    vRefComercial.OBSERVACIONES     := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.RefenciasComerciales[%d].Observaciones', p0 => c);
                    vRefComercial.OFICIAL           := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.RefenciasComerciales[%d].Oficial', p0 => c);
                    vRefComercial.NOMBRE_ENTE       := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.RefenciasComerciales[%d].NombreEntidad', p0 => c);
                    vRefComercial.NUM_TELEFONO      := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.RefenciasComerciales[%d].Telefono', p0 => c);
                    vRefComercial.TIPO_CUENTA       := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.RefenciasComerciales[%d].TipoCuenta', p0 => c);
                    vRefComerciales.EXTEND;
                    vIndRC	:= vIndRC + 1;
                    vRefComerciales(vIndRC)         := vRefComercial;
                END LOOP;
            END IF;
            
            vInfoProdSol.TIPO_PRODUCTO              := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.InformacionProductoSolicitado.TipoProducto');
            vInfoProdSol.COD_MONEDA                 := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.InformacionProductoSolicitado.Moneda');
            vInfoProdSol.PROPOSITO                  := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.InformacionProductoSolicitado.PropositoDelProducto');
            vInfoProdSol.MONTO_INICIAL              := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.InformacionProductoSolicitado.MontoProducto');
            vInfoProdSol.INSTRUMENTO_BANCARIO       := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.InformacionProductoSolicitado.InstrumentoBancario');
            vInfoProdSol.RANGO_MONETARIO_INI        := NULL;
            vInfoProdSol.RANGO_MONETARIO_FIN        := NULL;
            vInfoProdSol.PROM_MES_DEPO_EFECTIVO     := NULL;
            vInfoProdSol.PROM_MES_DEPO_CHEQUES      := NULL;
            vInfoProdSol.PROM_MES_RETI_EFECTIVO     := NULL;
            vInfoProdSol.PROM_MES_TRANS_ENVIADA     := NULL;
            vPaisIso3                               := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.InformacionProductoSolicitado.PaisIso3OrigenFondos');
            BEGIN
                SELECT COD_PAIS 
                  INTO vCodigoPais 
                  FROM PA.PAIS 
                  WHERE PA.PAIS.COD_PAIS_ISO = vPaisIso3;
            EXCEPTION WHEN NO_DATA_FOUND THEN
                vCodigoPais := PA.OBT_PARAMETROS ('1', 'PA', 'CODIGO_PAIS_LOCAL');
            END;
            vInfoProdSol.COD_PAIS_DESTINO           := vCodigoPais;
            vInfoProdSol.PROM_MES_TRANS_RECIBIDA    := NULL;
            vInfoProdSol.COD_PAIS_ORIGEN            := NULL;
            vInfoProdSol.COMPRAS_GIROS_CHEQUES_GER  := NULL;
            vInfoProdSol.ORIGEN_FONDOS              := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.InformacionProductoSolicitado.OrigenFondos');
            
             vInfoBuro                       := PA.INFO_BURO_OBJ();
            IF vClientePersonaFisica.ConsultarBuro = 'S' THEN
                vInfoBuro.REPORTE               := vClientePersonaFisica.ConsultarBuro;
                vInfoBuro.FECHA                 := SYSDATE;
                vInfoBuro.COMENTARIOS           := NULL;
            END IF;                                    
            
            vInfoDocFisNac                   := PA.INFO_DOC_FISICA_NACIONAL_OBJ();
            vInfoVerifDocFisNac              := PA.INFO_VERIF_DOC_FIS_NAC_OBJ();
            IF vPersonaFisica.COD_PAIS = '1' THEN
                vInfoDocFisNac.PIND_CEDULA                    := 'S';
                vInfoDocFisNac.PIND_LICENCIA_CONDUCIR         := 'N';
                vInfoDocFisNac.PIND_RESIDENCIA                := 'N';
                vInfoDocFisNac.PIND_ID_OTRO                   := 'N';
                vInfoDocFisNac.ID_OTRO_DESC                   := NULL;
                vInfoDocFisNac.PIND_CERTIFICADO_NACIMIENTO    := 'N';
                vInfoDocFisNac.PIND_PENSIONADO_JUBILADO       := 'N';
                vInfoDocFisNac.PIND_LAB_TIEMPO                := 'N';
                vInfoDocFisNac.PIND_LAB_INGRESO_ANUAL         := 'N';
                vInfoDocFisNac.PIND_LAB_PUESTO_DESEMPENA      := 'N';
                vInfoDocFisNac.PIND_TRABAJA_INDEPENDIENTE     := 'N';
                vInfoDocFisNac.PIND_INDEPENDIENTE_ACTIVIDAD   := 'N';
                vInfoDocFisNac.PIND_INDEPENDIENTE_JUSTIFICA_A := 'N';
                vInfoDocFisNac.COMENTARIOS_ADICIONALES        := NULL;  
            END IF;        
                          
            vInfoDocFisExtranj              := PA.INFO_DOC_FISICA_EXTRANJ_OBJ();
            vInfoVerifDocFisExt             := PA.INFO_VERIF_DOC_FIS_EXTRAN_OBJ();
            IF vPersonaFisica.COD_PAIS <> '1' THEN
                vInfoDocFisExtranj.PIND_PASAPORTE := 'N';
                vInfoDocFisExtranj.PIND_PERMISO := 'N';
                vInfoDocFisExtranj.PIND_CARTA_TRABAJO := 'N';
                vInfoDocFisExtranj.PIND_DECLA_RENTA := 'N';
                vInfoDocFisExtranj.PIND_NATURALEZA_ACTIVIDAD :='N';
                vInfoDocFisExtranj.PIND_LICENCIA_ACTIVIDAD := 'N';
            END IF;
               
            vInfoWorldCheck     := PA.INFO_WORLD_CHECK_OBJ();
            
            vListaPep                               := PA.LISTA_PEP_LIST();  
            
            IF vClientePersonaFisica.PersonaFisica.ES_FUNCIONARIO = 'S' OR vClientePersonaFisica.PersonaFisica.ES_PEPS = 'S' THEN        
                vTotalListaPEP         := APEX_JSON.get_count(p_values => j, p_path => 'ClientePersonaFisica.ListaPep');
                IF vTotalListaPEP > 0 THEN
                    FOR l IN 1 .. vTotalListaPEP LOOP
                        vPep             := PA.LISTA_PEP_OBJ();
                        vPep.CARGO                  := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.ListaPep[%d].CargoPolítico', p0 => l);
                        vFecha                      := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.ListaPep[%d].FechaIngresoAlCargo', p0 => l);
                        vPep.FEC_INGRESO            := TO_DATE(vFecha, 'DD/MM/RRRR');
                        vFecha                      := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.ListaPep[%d].FechaSalidaDelCargo', p0 => l);
                        vPep.FEC_VENCIMIENTO        := TO_DATE(vFecha, 'DD/MM/RRRR');
                        vPep.APODO                  := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.ListaPep[%d].Apodo', p0 => l);
                        vPep.CODIGO_PARENTESCO      := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.ListaPep[%d].Parentesco', p0 => l);
                        vPep.INSTITUCION_POLITICA   := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.ListaPep[%d].InstitucionPolitica', p0 => l);
                        vPep.COD_MONEDA             := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.ListaPep[%d].Moneda', p0 => l);
                        vPaisIso3                   := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.ListaPep[%d].PaisIso3', p0 => l);
                        BEGIN
                            SELECT COD_PAIS 
                              INTO vCodigoPais 
                              FROM PA.PAIS 
                              WHERE PA.PAIS.COD_PAIS_ISO = vPaisIso3;
                        EXCEPTION WHEN NO_DATA_FOUND THEN
                            vCodigoPais := PA.OBT_PARAMETROS ('1', 'PA', 'CODIGO_PAIS_LOCAL');
                        END;
                        vPep.COD_PAIS               := vCodigoPais;
                        vPep.NOMBRE_REL_PEP         := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.ListaPep[%d].NombreRelacionadoPep', p0 => l);
                        vListaPep.EXTEND;
                        vIndP	                    := vIndP + 1;
                        vListaPep(vIndP)            := vPep;
                    END LOOP;
                END IF;
            END IF;
            
            vPromocionPersonas                      := PA.PROMOCION_PERSONA_LIST();
            vTotalProm         := APEX_JSON.get_count(p_values => j, p_path => 'ClientePersonaFisica.PromocionPersonas');
            IF vTotalProm > 0 THEN
                FOR p IN 1 ..  vTotalProm LOOP
                    vPromocionPersona       := PA.PROMOCION_PERSONA_OBJ();
                    vPromocionPersona.COD_CANAL               := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.PromocionPersonas[%d].CodigoCanal', p0 => p);
                    vPromocionPersona.FECHA_AUTORIZACION      := SYSDATE;
                    vPromocionPersona.AUTORIZADO              := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.PromocionPersonas[%d].AutorizaPromocionesPorCanal', p0 => p);
                    vPromocionPersona.COD_ORIGEN              := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.PromocionPersonas[%d].FuenteOrigenPromocion', p0 => p);      
                    vPromocionPersonas.EXTEND;
                    vIndPP := vIndPP + 1;
                    vPromocionPersonas(vIndPP)                := vPromocionPersona;                                  
                END LOOP;
            END IF;
                
            vClientePersonaFisica.Persona           := vPersona;
            vClientePersonaFisica.PersonaFisica     := vPersonaFisica;
            vClientePersonaFisica.IdPersonas        := vIdPersonas;
            vClientePersonaFisica.DirPersonas       := vDirPersonas;
            vClientePersonaFisica.TelPersonas       := vTelPersonas;
            vClientePersonaFisica.DirEnvioxPers     := vDirEnvioxPers;
            vClientePersonaFisica.InfoLaboral       := vInfoLaboral;            
            vClientePersonaFisica.CtaCliOtrBancos   := vCtaCliOtrBancos;
            vClientePersonaFisica.RefPersonales     := vRefPersonales;
            vClientePersonaFisica.RefComerciales    := vRefComerciales;
            vClientePersonaFisica.InfoProdSol       := vInfoProdSol;
                                     
            vClientePersonaFisica.InfoBuro            := vInfoBuro;
            vClientePersonaFisica.InfoDocFisNac       := vInfoDocFisNac;
            vClientePersonaFisica.InfoDocFisExtranj   := vInfoDocFisExtranj;
            vClientePersonaFisica.InfoVerifDocFisNac  := vInfoVerifDocFisNac;
            vClientePersonaFisica.InfoVerifDocFisExt  := vInfoVerifDocFisExt;
            vClientePersonaFisica.InfoWorldCheck      := vInfoWorldCheck;
            vClientePersonaFisica.ListaPep            := vListaPEP;  
            vClientePersonaFisica.PromocionPersonas   := vPromocionPersonas; 
                  
        ELSE
            p_error := p_error || ' Error - El JSON está vacio.';
            RAISE_APPLICATION_ERROR(-20100, p_error);
        END IF; 
        DBMS_LOB.FREETEMPORARY(l_clob);
        RETURN vClientePersonaFisica;
    EXCEPTION WHEN OTHERS THEN
        p_error := SQLERRM||' '||dbms_utility.format_error_backtrace;
        RETURN vClientePersonaFisica;
    END;

    PROCEDURE Procesar_Cliente_Fisica(inEs_Fisica           IN     VARCHAR2 DEFAULT 'S',
                                      inConsultarBuro       IN     VARCHAR2 DEFAULT 'N',     -- Consultar en el Buro
                                      inConsultarPadron     IN     VARCHAR2 DEFAULT 'N',     -- Consulta en Padron
                                      inCod_Promotor        IN     VARCHAR2,                                                                    
                                      inPaga_Imp_Ley288     IN     VARCHAR2 DEFAULT 'S',
                                      inBenef_Pag_Ley288    IN     VARCHAR2 DEFAULT 'S',
                                      inCod_Vinculacion     IN     VARCHAR2,
                                      inCobr_Nodgii_132011  IN     VARCHAR2 DEFAULT 'S',                                                                    
                                      inPrimer_Apellido     IN     VARCHAR2,
                                      inSegundo_Apellido    IN     VARCHAR2,
                                      inPrimer_Nombre       IN     VARCHAR2,
                                      inSegundo_Nombre      IN     VARCHAR2,                              
                                      inNacionalidad        IN     VARCHAR2,
                                      inEst_Civil           IN     VARCHAR2,
                                      inSexo                IN     VARCHAR2,
                                      inFec_Nacimiento      IN     DATE,                                      
                                      inCodSector_Actividad IN     VARCHAR2,
                                      inEmail               IN     VARCHAR2,
                                      inTipo_Vivienda       IN     VARCHAR2 DEFAULT NULL,
                                      inNum_Hijos           IN     PLS_INTEGER,
                                      inNum_Dependientes    IN     PLS_INTEGER,
                                      inEs_Residente        IN     VARCHAR2 DEFAULT 'S',
                                      inTiempo_Vivien_Act   IN     PLS_INTEGER,                              
                                      inTotal_Ingresos      IN     NUMBER,
                                      inCod_Pais            IN     VARCHAR2,
                                      inActividad           IN     VARCHAR2,                                      
                                      inCasada_Apellido     IN     VARCHAR2 DEFAULT NULL,
                                      inEs_FuncionarioPep   IN     VARCHAR2 DEFAULT 'N',
                                      inEs_RelacionadoPep   IN     VARCHAR2 DEFAULT 'N',
                                      inCod_Actividad       IN     VARCHAR2,
                                      inCod_Subactividad    IN     VARCHAR2,
                                      inTipo_Persona        IN     VARCHAR2,
                                      inTipo_Cliente        IN     VARCHAR2,
                                      inCod_Finalidad       IN     VARCHAR2,
                                      inTercer_Nombre       IN     VARCHAR2 DEFAULT NULL,
                                      inTipo_Soc_Conyugal   IN     VARCHAR2 DEFAULT 'S',
                                      inGpo_Riesgo          IN     VARCHAR2 DEFAULT 'B',
                                      inIndClienteVIP       IN     VARCHAR2 DEFAULT 'N',
                                      inTipoGenDivisas      IN     VARCHAR2 DEFAULT NULL,
                                      inOcupacionClasifNac  IN     VARCHAR2 DEFAULT NULL,
                                      -- Identificaciones                                      
                                      inIdentificacion      IN     PA.ID_PERSONAS_LIST,                                      
                                      -- Direcciones                                 
                                      inDirecciones         IN     PA.DIR_PERSONAS_LIST,                                                                            
                                      -- Telefonos       
                                      inTelefonos           IN     PA.TEL_PERSONAS_LIST,                                  
                                      -- Informacion Laboral
                                      inInfoLaboral         IN     PA.INFO_LABORAL_OBJ,                                    
                                      -- Direccion de Envio
                                      inDirEnvioxPers       IN     PA.DIR_ENVIO_X_PERS_OBJ,                                       
                                      -- Cuenta de Otros Bancos
                                      inCtaOtrosBancos      IN     PA.CTAS_CLIENTES_OTR_BANCOS_LIST,                                       
                                      -- Referencias Personales
                                      inRefPersonales       IN     PA.REF_PERSONALES_LIST,                                       
                                      -- Referencias Comerciales
                                      inRefComerciales      IN     PA.REF_COMERCIALES_LIST,                                       
                                      -- Informacion Producto Solicitado
                                      inInfoProdSol         IN     PA.INFO_PROD_SOL_OBJ,                                       
                                      -- Lista PEP
                                      inListaPep            IN     PA.LISTA_PEP_LIST,                                      
                                      -- Promociones Personas   
                                      inPromocionPersonas   IN     PA.PROMOCION_PERSONA_LIST,                                        
                                      outCodCliente         IN OUT VARCHAR2,
                                      outError              IN OUT VARCHAR2) IS        
        vCedula             PA.ID_PERSONAS.NUM_ID%TYPE         := NULL;
        vTipoID             PA.ID_PERSONAS.COD_TIPO_ID%TYPE;
        vCodPersona         PA.PERSONAS.COD_PER_FISICA%TYPE;
        vCodigoPais         PA.PAIS.COD_PAIS%TYPE;
        vError              VARCHAR2(4000);
        vCliente            PA.CLIENTES_PERSONA_FISICA_OBJ;
        vPersona            PA.PERSONAS_OBJ := PA.PERSONAS_OBJ();
        vPersonaFisica      PA.PERSONAS_FISICAS_OBJ := PA.PERSONAS_FISICAS_OBJ();
        vInfoBuro           PA.INFO_BURO_OBJ :=  PA.INFO_BURO_OBJ();
        vInfoDocFisNac      PA.INFO_DOC_FISICA_NACIONAL_OBJ := PA.INFO_DOC_FISICA_NACIONAL_OBJ();
        vInfoDocFisExtranj  PA.INFO_DOC_FISICA_EXTRANJ_OBJ := PA.INFO_DOC_FISICA_EXTRANJ_OBJ();
        vInfoVerifDocFisNac PA.INFO_VERIF_DOC_FIS_NAC_OBJ := PA.INFO_VERIF_DOC_FIS_NAC_OBJ();
        vInfoVerifDocFisExt PA.INFO_VERIF_DOC_FIS_EXTRAN_OBJ := PA.INFO_VERIF_DOC_FIS_EXTRAN_OBJ();
        vInfoWorldCheck     PA.INFO_WORLD_CHECK_OBJ := PA.INFO_WORLD_CHECK_OBJ();
    BEGIN        
    
        vCliente                        := PA.CLIENTES_PERSONA_FISICA_OBJ();
        FOR i IN 1 .. inIdentificacion.COUNT LOOP
            vTipoID  := inIdentificacion(i).COD_TIPO_ID;
            IF vTipoId = '1' then
                EXIT;
            END IF;
        END LOOP;
        vCliente.ConsultarBuro          := inConsultarBuro;
        vCliente.ConsultarPadron        := inConsultarPadron; 
        vCliente.Cod_Promotor           := inCod_Promotor;
        vCliente.EsFisica               := inEs_Fisica;
    
        vPersona                        := PA.PERSONAS_OBJ();       
        IF inPrimer_Nombre IS NOT NULL THEN
            vPersona.Nombre := inPrimer_Nombre||' '||inSegundo_Nombre||' '||inPrimer_Apellido||' '||inSegundo_Apellido;
        END IF;                                
        vPersona.ES_FISICA              := inEs_Fisica;
        vPersona.IND_CLTE_I2000         := 'N';
        vPersona.PAGA_IMP_LEY288        := inPaga_Imp_Ley288;
        vPersona.BENEF_PAG_LEY288       := inBenef_Pag_Ley288;
        vPersona.COD_VINCULACION        := inCod_Vinculacion;
        vPersona.COD_SEC_CONTABLE       := '030202';
        vPersona.ESTADO_PERSONA         := 'A';
        vPersona.COBR_NODGII_132011     := inCobr_Nodgii_132011;
        vPersona.LLENO_FATCA            := 'N';
        vPersona.IMPRIMIO_FATCA         := 'N';
        vPersona.ES_FATCA               := 'N';
        vPersona.TEL_VERIFICADO         := 'N';    
        vCliente.Persona                := vPersona;
        
        vPersonaFisica                  := PA.PERSONAS_FISICAS_OBJ();
        vPersonaFisica.EST_CIVIL        := inEst_Civil;
        vPersonaFisica.SEXO             := inSexo;
        vPersonaFisica.FEC_NACIMIENTO   := inFec_Nacimiento;
        vPersonaFisica.PRIMER_APELLIDO  := inPrimer_Apellido;
        vPersonaFisica.SEGUNDO_APELLIDO := inSegundo_Apellido;
        vPersonaFisica.PRIMER_NOMBRE    := inPrimer_Nombre;
        vPersonaFisica.SEGUNDO_NOMBRE   := inSegundo_Nombre;
        vPersonaFisica.IDIOMA_CORREO    := 'ESPA';
        vPersonaFisica.ES_MAL_DEUDOR    := 'N';
        vPersonaFisica.NACIONALIDAD     := inNacionalidad;
        vPersonaFisica.COD_SECTOR       := inCodSector_Actividad;
        vPersonaFisica.ESTATAL          := 'N';
        vPersonaFisica.EMAIL_USUARIO    := inEmail;
        vPersonaFisica.EMAIL_SERVIDOR   := NULL;
        vPersonaFisica.NIVEL_ESTUDIOS   := NULL;
        vPersonaFisica.TIPO_VIVIENDA    := inTipo_Vivienda;
        vPersonaFisica.NUM_HIJOS        := NVL(inNum_Hijos,0);
        vPersonaFisica.NUM_DEPENDIENTES := NVL(inNum_Dependientes,0);
        vPersonaFisica.ES_RESIDENTE     := inEs_Residente;
        vPersonaFisica.TIEMPO_VIVIEN_ACT := NVL(inTiempo_Vivien_Act,0);
        vPersonaFisica.EVAL_REF_BANCARIA := 'V';
        vPersonaFisica.EVAL_REF_TARJETAS := 'V';
        vPersonaFisica.EVAL_REF_LABORAL  := 'C';
        vPersonaFisica.TOTAL_INGRESOS    := NVL(inTotal_Ingresos,0);
        vPersonaFisica.COD_PAIS         := inCod_Pais;
        vPersonaFisica.SCORING          := 0;
        vPersonaFisica.ACTIVIDAD        := inActividad;        
        vPersonaFisica.RANGO_INGRESOS   := NVL(PA.OBT_RANGO_INGRESOS(NVL(inTotal_Ingresos,0)), 1);
        vPersonaFisica.CASADA_APELLIDO  := inCasada_Apellido;
        vPersonaFisica.ES_FUNCIONARIO   := inEs_FuncionarioPep;
        vPersonaFisica.ES_PEPS          := inEs_RelacionadoPep;
        vPersonaFisica.COD_ACTIVIDAD    := inCod_Actividad;
        vPersonaFisica.COD_SUBACTIVIDAD := inCod_Subactividad;
        vPersonaFisica.TIPO_PERSONA     := NVL(inTipo_Persona, PA.ASIGNA_TIPO_PERSONA(vTipoID, inSexo));
        vPersonaFisica.TIPO_CLIENTE     := inTipo_Cliente;
        vPersonaFisica.COD_FINALIDAD    := inCod_Finalidad;
        vPersonaFisica.APELLIDO_CASADA  := inCasada_Apellido;
        vPersonaFisica.TERCER_NOMBRE    := inTercer_Nombre;
        vPersonaFisica.TIPO_SOC_CONYUGAL := NVL(inTipo_Soc_Conyugal,'S');
        vPersonaFisica.GPO_RIESGO       := inGpo_Riesgo;
        vPersonaFisica.IND_CLTE_VIP     := inIndClienteVIP;
        vPersonaFisica.TIPO_GEN_DIVISAS := inTipoGenDivisas;
        vPersonaFisica.OCUPACION_CLASIF_NAC:= inOcupacionClasifNac;
        
        vCliente.PersonaFisica          := vPersonaFisica;
        vCliente.IdPersonas             := inIdentificacion;
        vCliente.DirPersonas            := inDirecciones;
        vCliente.TelPersonas            := inTelefonos;                                             
        vCliente.DirEnvioxPers          := inDirEnvioxPers;                                                  
        vCliente.InfoLaboral            := inInfoLaboral;            
        vCliente.CtaCliOtrBancos        := inCtaOtrosBancos;                   
        vCliente.RefPersonales          := inRefPersonales;            
        vCliente.RefComerciales         := inRefComerciales;            
        vCliente.InfoProdSol            := inInfoProdSol;
           
        vInfoBuro                       := PA.INFO_BURO_OBJ();
        IF inConsultarBuro = 'S' THEN
            vInfoBuro.REPORTE               := inConsultarBuro;
            vInfoBuro.FECHA                 := SYSDATE;
            vInfoBuro.COMENTARIOS           := NULL;
        END IF;                        
        vCliente.InfoBuro                := vInfoBuro;
        
        vInfoDocFisNac                   := PA.INFO_DOC_FISICA_NACIONAL_OBJ();
        vInfoVerifDocFisNac              := PA.INFO_VERIF_DOC_FIS_NAC_OBJ();
        IF inCod_Pais = '1' THEN
            vInfoDocFisNac.PIND_CEDULA                    := 'S';
            vInfoDocFisNac.PIND_LICENCIA_CONDUCIR         := 'N';
            vInfoDocFisNac.PIND_RESIDENCIA                := 'N';
            vInfoDocFisNac.PIND_ID_OTRO                   := 'N';
            vInfoDocFisNac.ID_OTRO_DESC                   := NULL;
            vInfoDocFisNac.PIND_CERTIFICADO_NACIMIENTO    := 'N';
            vInfoDocFisNac.PIND_PENSIONADO_JUBILADO       := 'N';
            vInfoDocFisNac.PIND_LAB_TIEMPO                := 'N';
            vInfoDocFisNac.PIND_LAB_INGRESO_ANUAL         := 'N';
            vInfoDocFisNac.PIND_LAB_PUESTO_DESEMPENA      := 'N';
            vInfoDocFisNac.PIND_TRABAJA_INDEPENDIENTE     := 'N';
            vInfoDocFisNac.PIND_INDEPENDIENTE_ACTIVIDAD   := 'N';
            vInfoDocFisNac.PIND_INDEPENDIENTE_JUSTIFICA_A := 'N';
            vInfoDocFisNac.COMENTARIOS_ADICIONALES        := NULL;  
        END IF;
        vCliente.InfoVerifDocFisNac     := vInfoVerifDocFisNac;             
        vCliente.InfoDocFisNac          := vInfoDocFisNac;   
                      
        vInfoDocFisExtranj              := PA.INFO_DOC_FISICA_EXTRANJ_OBJ();
        vInfoVerifDocFisExt             := PA.INFO_VERIF_DOC_FIS_EXTRAN_OBJ();
        IF inCod_Pais <> '1' THEN
            vInfoDocFisExtranj.PIND_PASAPORTE := 'N';
            vInfoDocFisExtranj.PIND_PERMISO := 'N';
            vInfoDocFisExtranj.PIND_CARTA_TRABAJO := 'N';
            vInfoDocFisExtranj.PIND_DECLA_RENTA := 'N';
            vInfoDocFisExtranj.PIND_NATURALEZA_ACTIVIDAD :='N';
            vInfoDocFisExtranj.PIND_LICENCIA_ACTIVIDAD := 'N';
        END IF;
        vCliente.InfoDocFisExtranj      := vInfoDocFisExtranj;
        vCliente.InfoVerifDocFisExt     := vInfoVerifDocFisExt;        
        vInfoWorldCheck     := PA.INFO_WORLD_CHECK_OBJ();
        vCliente.InfoWorldCheck         := vInfoWorldCheck;
        vCliente.ListaPep               := inListaPep;                               
        vCliente.PromocionPersonas  := inPromocionPersonas;                                                                        
        
        -- Determina y asigna el Código de la Persona por la identificación
        FOR i IN 1 .. vCliente.IdPersonas.COUNT LOOP
            vCedula := PA.FORMATO_CEDULA(REPLACE(vCliente.IdPersonas(i).NUM_ID,'-'), vCliente.idPersonas(i).COD_TIPO_ID, vError); 
            vCodPersona := PA.OBT_CODPERSONA_CON_ID(vCliente.IdPersonas(i).COD_TIPO_ID, vCedula);
            IF vCodPersona IS NOT NULL THEN
                EXIT;
            END IF;    
        END LOOP;
                
        -- Asigna el Codigo de Persona
        IF vCodPersona IS NULL THEN
            vCodPersona := PA.NUEVO_CODPERSONA ( '1', '0');            
        END IF;        
        vCliente.Persona.COD_PERSONA := vCodPersona;
		vCliente.Persona.COD_PER_FISICA := vCodPersona;
        vCliente.PersonaFisica.COD_PER_FISICA := vCodPersona;
        FOR i IN 1 .. vCliente.IdPersonas.COUNT LOOP
            vCliente.IdPersonas(i).COD_PERSONA := vCodPersona;                                    
        END LOOP;
        FOR d IN 1 .. vCliente.DirPersonas.COUNT LOOP
            vCliente.DirPersonas(d).COD_PERSONA := vCodPersona;            
        END LOOP;
        FOR t IN 1 .. vCliente.TelPersonas.COUNT LOOP
            vCliente.TelPersonas(t).COD_PERSONA := vCodPersona;
        END LOOP;
        vCliente.DirEnvioxPers.COD_PERSONA := vCodPersona;
        vCliente.InfoLaboral.COD_PER_FISICA := vCodPersona;
        FOR c IN 1 .. vCliente.CtaCliOtrBancos.COUNT LOOP
            vCliente.CtaCliOtrBancos(c).COD_CLIENTE := vCodPersona;
        END LOOP;
        FOR r IN 1 .. vCliente.RefPersonales.COUNT LOOP
            vCliente.RefPersonales(r).COD_PERSONA := vCodPersona;
        END LOOP;
        FOR r IN 1 .. vCliente.RefComerciales.COUNT LOOP
            vCliente.RefComerciales(r).COD_PERSONA := vCodPersona;
        END LOOP;
        vCliente.InfoProdSol.COD_PERSONA := vCodPersona;
        vCliente.InfoBuro.COD_PERSONA := vCodPersona;
        vCliente.InfoDocFisNac.COD_PERSONA := vCodPersona;
        vCliente.InfoDocFisExtranj.COD_PERSONA := vCodPersona;
        vCliente.InfoVerifDocFisNac.COD_PERSONA := vCodPersona;
        vCliente.InfoVerifDocFisExt.COD_PERSONA := vCodPersona;
        vCliente.InfoWorldCheck.COD_PERSONA := vCodPersona;
        IF inEs_FuncionarioPep = 'S' OR inEs_RelacionadoPep = 'S' THEN            
            FOR p IN 1 .. vCliente.ListaPEP.COUNT LOOP
                vCliente.ListaPep(p).COD_PERSONA := vCodPersona;
            END LOOP;
        END IF;  
        FOR p IN 1 .. vCliente.PromocionPersonas.COUNT LOOP
            vCliente.PromocionPersonas(p).COD_PERSONA := vCodPersona;
        END LOOP;  
        
        BEGIN
            vCliente.Generar();            
        EXCEPTION WHEN OTHERS THEN
            IF vError IS NULL THEN
                vError:= SUBSTR(SQLERRM||' '||dbms_utility.format_error_backtrace,1,4000);
            ELSE
                vError:= SUBSTR(vError||' '||SQLERRM||' '||dbms_utility.format_error_backtrace,1,4000);
            END IF;
            outError := vError;
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20100, vError );
        END;
        
        outCodCliente := vCodPersona;
        
    /*EXCEPTION WHEN OTHERS THEN
        outCodCliente := '0';
        IF vError IS NULL THEN
            vError:= SUBSTR(SQLERRM||' '||dbms_utility.format_error_backtrace,1,4000);
        ELSE
            vError:= SUBSTR(vError||' '||SQLERRM||' '||dbms_utility.format_error_backtrace,1,4000);
        END IF;
        outError := vError;
        DBMS_OUTPUT.PUT_LINE( vError );
        ROLLBACK; */   
    END Procesar_Cliente_Fisica;

    PROCEDURE Generar_Cliente(inEs_Fisica           IN     VARCHAR2 DEFAULT 'S',
                              inIndConsultarBuro    IN     VARCHAR2 DEFAULT 'N',     -- Consultar en el Buro
                              inIndConsultarPadron  IN     VARCHAR2 DEFAULT 'N',     -- Consulta en Padron
                              inTipoIdent           IN     VARCHAR2,
                              inIdentificacion      IN     VARCHAR2,                              
                              inPaga_Imp_Ley288     IN     VARCHAR2 DEFAULT 'S',
                              inBenef_Pag_Ley288    IN     VARCHAR2 DEFAULT 'S',
                              inCod_Vinculacion     IN     VARCHAR2,
                              inCobr_Nodgii_132011  IN     VARCHAR2 DEFAULT 'S',                              
                              inEst_Civil           IN     VARCHAR2,
                              inSexo                IN     VARCHAR2,
                              inFec_Nacimiento      IN     VARCHAR2,
                              inPrimer_Apellido     IN     VARCHAR2,
                              inSegundo_Apellido    IN     VARCHAR2,
                              inPrimer_Nombre       IN     VARCHAR2,
                              inSegundo_Nombre      IN     VARCHAR2,                              
                              inNacionalidad        IN     VARCHAR2,
                              inCod_Sector          IN     VARCHAR2,
                              inEmail               IN     VARCHAR2,
                              inTipo_Vivienda       IN     VARCHAR2 DEFAULT NULL,
                              inNum_Hijos           IN     VARCHAR2,
                              inNum_Dependientes    IN     VARCHAR2,
                              inEs_Residente        IN     VARCHAR2 DEFAULT 'S',
                              inTiempo_Vivien_Act   IN     VARCHAR2,                              
                              inTotal_Ingresos      IN     VARCHAR2,
                              inCod_Pais            IN     VARCHAR2,
                              inActividad           IN     VARCHAR2,
                              inRango_Ingresos      IN     VARCHAR2,
                              inCasada_Apellido     IN     VARCHAR2 DEFAULT NULL,
                              inEs_Funcionario      IN     VARCHAR2 DEFAULT 'N',
                              inEs_Peps             IN     VARCHAR2 DEFAULT 'N',
                              inCod_Actividad       IN     VARCHAR2,
                              inCod_Subactividad    IN     VARCHAR2,
                              inTipo_Persona        IN     VARCHAR2,
                              inTipo_Cliente        IN     VARCHAR2,
                              inCod_Finalidad       IN     VARCHAR2,
                              inTercer_Nombre       IN     VARCHAR2 DEFAULT NULL,
                              inTipo_Soc_Conyugal   IN     VARCHAR2 DEFAULT 'S',
                              inGpo_Riesgo          IN     VARCHAR2 DEFAULT 'B',
                              inCod_Promotor        IN     VARCHAR2,
                              
                              -- Direccion Personal                                      
                              inCod_Provincia       IN     VARCHAR2,  
                              inCod_Canton          IN     VARCHAR2,
                              inCod_Distrito        IN     VARCHAR2,
                              inCod_Pueblo          IN     VARCHAR2,
                              inDirDetalle          IN     VARCHAR2,
                                
                              -- Direccion Trabajo
                              inCod_Pais_Trabajo      IN     VARCHAR2,  
                              inCod_Provincia_Trabajo IN     VARCHAR2,  
                              inCod_Canton_Trabajo    IN     VARCHAR2,
                              inCod_Distrito_Trabajo  IN     VARCHAR2,
                              inCod_Pueblo_Trabajo    IN     VARCHAR2,
                              inDirDetalle_Trabajo    IN     VARCHAR2,                         
     
                              -- Telefonos       
                              inTelefonoCasa        IN     VARCHAR2,
                              inTelefonoCelular     IN     VARCHAR2,
                              inTelefonoTrabajo     IN     VARCHAR2,
                              inTelefonoExtTrabajo  IN     VARCHAR2,
                              
                              -- Informacion Laboral
                              pCod_Agencia_DirEnv   IN     VARCHAR2,
                              inFec_Ingreso         IN     VARCHAR2,
                              inLugar_Trabajo       IN     VARCHAR2,
                              inSueldo              IN     VARCHAR2,
                              inPuesto              IN     VARCHAR2,
                              inTipo_Ingreso        IN     VARCHAR2,    
                              inEmpleo_Actual       IN     VARCHAR2,
                              inProfesion           IN     VARCHAR2,
                              
                              -- Cuentas de Otros Bancos
                              inCod_Emisor_Cta      IN     VARCHAR2,
                              inNum_Cuenta          IN     VARCHAR2,
                              inNom_Cuenta          IN     VARCHAR2,
                              inTipo_Cuenta         IN     VARCHAR2,
                              inCod_Moneda_Cta      IN     VARCHAR2,
                              inCod_Pais_Cta        IN     VARCHAR2,
                              inOficial_Responsable IN     VARCHAR2,
                              inTiempo_Apertura_Cta IN     VARCHAR2,
                              
                              -- Referencias Personales
                              inTipo_Id_RefPers1    IN     VARCHAR2,           
                              inNombre_RefPers1     IN     VARCHAR2,  
                              inIdent_RefPers1      IN     VARCHAR2,           
                              inTelefono_RefPers1   IN     VARCHAR2,           
                              inRelacion_Persona1   IN     VARCHAR2,
                              
                              inTipo_Id_RefPers2    IN     VARCHAR2,           
                              inNombre_RefPers2     IN     VARCHAR2,  
                              inIdent_RefPers2      IN     VARCHAR2,           
                              inTelefono_RefPers2   IN     VARCHAR2,           
                              inRelacion_Persona2   IN     VARCHAR2,     
                              
                              -- Referencias Comerciales
                              inCod_Tip_RefComerc   IN     VARCHAR2,      
                              inCod_EnteComerc      IN     VARCHAR2,
                              inOficial_Comerc      IN     VARCHAR2,
                              inNombre_EnteComerc   IN     VARCHAR2,
                                     
                              --  Informacion Producto Soliictado
                              inTipo_Producto       IN     VARCHAR2, 
                              inCod_Moneda_ProdSol  IN     VARCHAR2,  
                              inProposito_ProdSol   IN     VARCHAR2,         
                              inMonto_Ini_ProdSol   IN     VARCHAR2,  
                              inInstrumento_Bancario IN    VARCHAR2,
                              inOrigen_Fondos       IN     VARCHAR2,   
                              outCodPersona         IN OUT VARCHAR2,
                              outError              IN OUT VARCHAR2) IS
    
       vCliente             PA.CLIENTES_OBJ;   
       vPersona             PA.PERSONAS_OBJ;
       vPersonaFisica       PA.PERSONAS_FISICAS_OBJ;
       vIdPersona           PA.ID_PERSONAS_OBJ;
       vIdPersonas          PA.ID_PERSONAS_LIST := PA.ID_PERSONAS_LIST();
       vDirPersona          PA.DIR_PERSONAS_OBJ;
       vDirPersonas         PA.DIR_PERSONAS_LIST := PA.DIR_PERSONAS_LIST();
       vTelPersona          PA.TEL_PERSONAS_OBJ;
       vTelPersonas         PA.TEL_PERSONAS_LIST := PA.TEL_PERSONAS_LIST();
       vDirEnvioxPers       PA.DIR_ENVIO_X_PERS_OBJ;
       vInfoLaboral         PA.INFO_LABORAL_OBJ;
       vCtaCliOtrBanco      PA.CTAS_CLIENTES_OTR_BANCOS_OBJ;
       vCtaCliOtrBancos     PA.CTAS_CLIENTES_OTR_BANCOS_LIST := PA.CTAS_CLIENTES_OTR_BANCOS_LIST();
       vRefPersonal         PA.REF_PERSONALES_OBJ;
       vRefPersonales       PA.REF_PERSONALES_LIST := PA.REF_PERSONALES_LIST();
       vRefComercial        PA.REF_COMERCIALES_OBJ;
       vRefComerciales      PA.REF_COMERCIALES_LIST := PA.REF_COMERCIALES_LIST();
       vInfoProdSol         PA.INFO_PROD_SOL_OBJ;
       vInfoBuro            PA.INFO_BURO_OBJ;
       vInfoDocFisNac       PA.INFO_DOC_FISICA_NACIONAL_OBJ;
       vInfoDocFisExtranj   PA.INFO_DOC_FISICA_EXTRANJ_OBJ;
       vInfoVerifDocFisNac  PA.INFO_VERIF_DOC_FIS_NAC_OBJ;
       vInfoVerifDocFisExt  PA.INFO_VERIF_DOC_FIS_EXTRAN_OBJ;
       vInfoWorldCheck      PA.INFO_WORLD_CHECK_OBJ;
       vPromocionPersona    PA.PROMOCION_PERSONA_OBJ;
       vListaPep            PA.LISTA_PEP_LIST := PA.LISTA_PEP_LIST();
       pResultado           resultado;
       nIndexTel            NUMBER := 0;
       vCodArea             VARCHAR2(3);
       vNumTel              VARCHAR2(10);
       nIndexDir            NUMBER := 0;
       nIndexRefPers        NUMBER := 0;
       
       vCodPais             PA.PAIS.COD_PAIS%TYPE;
       vCodProvincia        PA.PROVINCIAS.COD_PROVINCIA%TYPE; 
       vCodCanton           PA.CANTONES.COD_CANTON%TYPE;
       vCodDistrito         PA.DISTRITOS.COD_DISTRITO%TYPE;
       vCodPueblo           PA.SECTORES.COD_SECTOR%TYPE;
       
       vTelefonoCasa        VARCHAR2(30);     
       vTelefonoCelular     VARCHAR2(30);
       vTelefonoTrabajo     VARCHAR2(30);  
       vTelefono_RefPers1   VARCHAR2(30);
       vTelefono_RefPers2   VARCHAR2(30);       
       
       vCod_Sector          VARCHAR2(10);
       vProfesion           PA.PERSONAS_FISICAS.PROFESION%TYPE;
       
       vRangoIngresos       PA.RANGO_INGRESO_NICHO.CODIGO%TYPE;
       
       vCodPersona          PA.PERSONAS_FISICAS.COD_PER_FISICA%TYPE;
       vCedula              PA.ID_PERSONAS.NUM_ID%TYPE;
       
  --     vParametros CLOB; 
       
    BEGIN      
        
        -- Llenar datos para crear Cliente
        
        -- Formato de la Identificacion.
               
        BEGIN
            vCedula             := PA.FORMATO_CEDULA(inIdentificacion, inTipoIdent, outError);            
            vTelefonoCasa       := PA.EXTRAER_NUMEROS(inTelefonoCasa);
            vTelefonoCelular    := PA.EXTRAER_NUMEROS(inTelefonoCelular); 
            vTelefonoTrabajo    := PA.EXTRAER_NUMEROS(inTelefonoTrabajo);
            vTelefono_RefPers1  := PA.EXTRAER_NUMEROS(inTelefono_RefPers1);
            vTelefono_RefPers2  := PA.EXTRAER_NUMEROS(inTelefono_RefPers2);
            vCod_Sector         := PA.EXTRAER_NUMEROS(inCod_Sector);
            
        EXCEPTION WHEN OTHERS THEN
            outCodPersona := '0';
            outError := 'Error - Formateando los telefonos/identificación.  '||inIdentificacion||' '||inTelefonoCasa||' '||inTelefonoCelular||' '||inTelefonoTrabajo||' '||inTelefono_RefPers1||' '||inTelefono_RefPers2;
            RETURN;
        END;      
            
--DBMS_OUTPUT.PUT_LINE('vTelefonoCasa='||vTelefonoCasa||' vTelefonoCelular='|| vTelefonoCelular ||' vTelefonoTrabajo='||vTelefonoTrabajo||
--                     ' vTelefono_RefPers1='||vTelefono_RefPers1||' vTelefono_RefPers2='|| vTelefono_RefPers2||' vCod_Sector='||vCod_Sector);        
        BEGIN
            SELECT p.cod_pais
              INTO vCodPais
              FROM PA.PAIS p
             WHERE P.COD_PAIS = TO_NUMBER(inCod_Pais);
        EXCEPTION WHEN NO_DATA_FOUND THEN
            vCodPais := 1;
        END;
--DBMS_OUTPUT.PUT_LINE('vCodPais='||vCodPais);        
        --  Determinar si el cliente existe
        BEGIN
              SELECT I.COD_PERSONA
                INTO vCodPersona
                FROM PA.ID_PERSONAS I
               WHERE I.COD_TIPO_ID = inTipoIdent
                 AND REPLACE(I.NUM_ID,'-','') = REPLACE(vCedula,'-','');                                   
        EXCEPTION WHEN NO_DATA_FOUND THEN
            -- vCodPersona := PA.NUEVO_CODPERSONA ( '1', '0');
              null; --Omariot / malmanzar 15-03-2023
        END;                   
--DBMS_OUTPUT.PUT_LINE('vCodPersona='||vCodPersona);           
        -- Determina el Rango de Ingresos
        IF inTotal_Ingresos IS NOT NULL THEN
            BEGIN
               SELECT TO_CHAR (Codigo) Codigo
                 INTO vRangoIngresos
                 FROM Rango_Ingreso_Nicho
                WHERE TO_NUMBER (inTotal_Ingresos) >= rango_inicio 
                  AND TO_NUMBER (inTotal_Ingresos) <= rango_fin;
            EXCEPTION WHEN NO_DATA_FOUND THEN
               vRangoIngresos := '2';--inRango_Ingresos;        
            END;
        END IF;
--DBMS_OUTPUT.PUT_LINE('vRangoIngresos='||vCodPersona);        
        --  Empleado 
        IF inProfesion = '01' THEN
            vProfesion := '58';
            
        -- Jubilado    
        ELSIF inProfesion = '04' THEN
            vProfesion := '53';
            
        -- Porfesional Independiente        
        ELSIF inProfesion = '05' THEN
            vProfesion := '677';
            
        --  Otros    
        ELSE
            vProfesion := '999';
        END IF;
        
--DBMS_OUTPUT.PUT_LINE('vProfesion='||vProfesion);        
        -- Personas Fisicas
        vPersonaFisica                      := PA.PERSONAS_FISICAS_OBJ();
        vPersonaFisica.COD_PER_FISICA       := vCodPersona;
        vPersonaFisica.Est_Civil            := NVL(inEst_Civil,'S');
        vPersonaFisica.Sexo                 := NVL(inSexo,'M');        
        vPersonaFisica.Fec_Nacimiento       := TO_DATE(inFec_Nacimiento,'DD/MM/YYYY');
        vPersonaFisica.Primer_Apellido      := UPPER(inPrimer_Apellido);
        vPersonaFisica.Segundo_Apellido     := UPPER(inSegundo_Apellido);
        vPersonaFisica.Primer_Nombre        := UPPER(inPrimer_Nombre);
        vPersonaFisica.Segundo_Nombre       := UPPER(inSegundo_Nombre);
        vPersonaFisica.Profesion            := vProfesion;
        vPersonaFisica.Es_Mal_Deudor        := NULL;
        vPersonaFisica.Conyugue             := NULL;
        vPersonaFisica.Nacionalidad         := inNacionalidad;            
        vPersonaFisica.Cod_Sector           := TO_NUMBER(vCod_Sector);        
        vPersonaFisica.Estatal              := NULL;
        --vPersonaFisica.Email_Usuario        := SUBSTR(inEmail, 1, INSTR(inEmail,'@',1)-1);
        vPersonaFisica.Email_Usuario        := inEmail;
        vPersonaFisica.Email_Servidor       := NULL;
        --vPersonaFisica.Email_Servidor       := SUBSTR(inEmail, INSTR(inEmail,'@',1));
        vPersonaFisica.Nivel_Estudios       := NULL;
        vPersonaFisica.Tipo_Vivienda        := inTipo_Vivienda;
        vPersonaFisica.Num_Hijos            := TO_NUMBER(inNum_Hijos);
        vPersonaFisica.Num_Dependientes     := TO_NUMBER(inNum_Dependientes);
        vPersonaFisica.Es_Residente         := inEs_Residente;
        BEGIN
            vPersonaFisica.Tiempo_Vivien_Act    := TO_NUMBER(inTiempo_Vivien_Act/365);
        EXCEPTION WHEN OTHERS THEN
            outCodPersona := '0';
            outError := 'Error - Convirtiendo el tiempo de vivienda actual. '||inTiempo_Vivien_Act||' '||SQLERRM;
            RAISE_APPLICATION_ERROR(-20105, outError);
        END;
        vPersonaFisica.Eval_Ref_Bancaria    := 'V';
        vPersonaFisica.Eval_Ref_Tarjetas    := 'V';
        vPersonaFisica.Eval_Ref_Laboral     := 'C';
        vPersonaFisica.Total_Ingresos       := TO_NUMBER(inTotal_Ingresos);
        vPersonaFisica.Cod_Pais             := TO_NUMBER(vCodPais);
        vPersonaFisica.Actividad            := inActividad;
        vPersonaFisica.Rango_Ingresos       := TO_NUMBER(vRangoIngresos);
        vPersonaFisica.Casada_Apellido      := NULL;
        vPersonaFisica.Es_Funcionario       := inEs_Funcionario;
        vPersonaFisica.Es_Peps              := inEs_Peps;
        vPersonaFisica.Cod_Actividad        := inCod_Actividad;
        vPersonaFisica.Cod_Subactividad     := NULL;
        vPersonaFisica.Tipo_Persona         := inTipo_Persona;
        vPersonaFisica.Tipo_Cliente         := TO_NUMBER(inTipo_Cliente);
        vPersonaFisica.Cod_Pais_Padre       := NULL;
        vPersonaFisica.Cod_Pais_Madre       := NULL;
        vPersonaFisica.Cod_Pais_Conyugue    := NULL;
        vPersonaFisica.Mas_180_Dias_Eeuu    := NULL;
        vPersonaFisica.Cod_Finalidad        := inCod_Finalidad;
        vPersonaFisica.Peso                 := NULL;
        vPersonaFisica.Estatura             := NULL;
        vPersonaFisica.Actividad_Polizah    := NULL;
        vPersonaFisica.Deporte_Polizah      := NULL;
        vPersonaFisica.Peso_Polizah         := NULL;
        vPersonaFisica.Estatura_Polizah     := NULL;
        vPersonaFisica.Apellido_Casada      := NULL;
        vPersonaFisica.Tercer_Nombre        := NULL;
        vPersonaFisica.Tipo_Soc_Conyugal    := inTipo_Soc_Conyugal;
        vPersonaFisica.Ind_Fallecimiento    := 'N';
        vPersonaFisica.Fec_Fallecimiento    := NULL;
        vPersonaFisica.Gpo_Riesgo           := inGpo_Riesgo;
        vPersonaFisica.Num_Empleados        := NULL;
        vPersonaFisica.Ventas_Ingresos      := NULL;
        vPersonaFisica.Cp_Total_Activo      := NULL;
        vPersonaFisica.Ind_Clte_Vip         := NULL;        
        
        -- Persona
        vPersona                      := PA.PERSONAS_OBJ();
        vPersona.cod_persona          := vPersonaFisica.COD_PER_FISICA;
        vPersona.COD_PER_FISICA       := vPersonaFisica.COD_PER_FISICA; 
        vPersona.Es_Fisica            := inEs_Fisica;
        vPersona.Nombre               := UPPER(inPrimer_Nombre||' '||inSegundo_Nombre||' '||inPrimer_Apellido||' '||inSegundo_Apellido);
        vPersona.Paga_Imp_Ley288      := inPaga_Imp_Ley288;
        vPersona.Benef_Pag_Ley288     := inBenef_Pag_Ley288;
        vPersona.Cod_Vinculacion      := inCod_Vinculacion;
        vPersona.Codigo_Sustituto     := NULL;
        vPersona.Cobr_Nodgii_132011   := inCobr_Nodgii_132011;               
        
        -- Id Personas
        vIdPersona                    := PA.ID_PERSONAS_OBJ();
        vIdPersona.cod_persona        := vPersonaFisica.COD_PER_FISICA;
        vIdPersona.Cod_Tipo_Id        := TO_NUMBER(inTipoIdent);
        vIdPersona.Num_Id             := vCedula;
        vIdPersona.Fec_Vencimiento    := TO_DATE('31/12/2050','DD/MM/YYYY');
        vIdPersona.Cod_Pais           := TO_NUMBER(vCodPais);
--dbms_output.put_line('Dentro de pkg_cliente TipoId='||TO_NUMBER(inTipoIdent)||' vIdPersona.Cod_Tipo_Id='||vIdPersona.Cod_Tipo_Id);
        BEGIN
            SELECT NACIONALIDAD
              INTO vIdPersona.NACIONALIDAD
              FROM pa.pais
             WHERE cod_pais = TO_NUMBER(vCodPais);
        EXCEPTION WHEN OTHERS THEN
            vIdPersona.NACIONALIDAD := NULL; 
        END;            
        
        vPersonaFisica.Nacionalidad         := NVL(vIdPersona.NACIONALIDAD, inNacionalidad);
        IF vIdPersona.NACIONALIDAD IS NULL THEN
            vIdPersona.NACIONALIDAD := inNacionalidad; 
        END IF;  
            
        vIdPersonas.EXTEND;
        vIdPersonas(1)                      := vIdPersona;
            
        -- Dir Personas
        vDirPersona                         := PA.DIR_PERSONAS_OBJ();
        IF inDirDetalle IS NOT NULL THEN
        
            BEGIN           
                SELECT COD_PROVINCIA, COD_CANTON, COD_DISTRITO
                  INTO vCodProvincia, vCodCanton, vCodDistrito
                  FROM PA.DISTRITOS c 
                 WHERE C.COD_PAIS = vCodPais
                   AND C.COD_PROVINCIA = inCod_Provincia
                   AND C.COD_CANTON = inCod_Canton
                   AND C.COD_DISTRITO = inCod_Distrito;                   
            EXCEPTION WHEN NO_DATA_FOUND THEN
                vCodProvincia := inCod_Provincia;
                vCodCanton  := inCod_Canton;
                vCodDistrito := inCod_Distrito;
            END;                                
--DBMS_OUTPUT.PUT_LINE('vCodPais='||vCodPais||' vCodProvincia=['||vCodProvincia||'-'||inCod_Provincia||'] vCodCanton=['||vCodCanton||'-'||inCod_Canton||'] vCodDistrito='||vCodDistrito||' vCodPueblo='||inCod_Pueblo||' '||inDirDetalle);        
            vDirPersona.Tip_Direccion           := 1;
            vDirPersona.Detalle                 := UPPER(inDirDetalle);
            vDirPersona.Cod_Pais                := TO_NUMBER(vCodPais);
            vDirPersona.Cod_Provincia           := TO_NUMBER(vCodProvincia);
            vDirPersona.Cod_Canton              := TO_NUMBER(vCodCanton);
            vDirPersona.Cod_Distrito            := TO_NUMBER(vCodDistrito);
            vDirPersona.Cod_Pueblo              := TO_NUMBER(NVL(inCod_Pueblo,nvl(vCodPueblo,1)));
            vDirPersona.Es_Default              := 'S';        
            vDirPersonas.EXTEND;
            nIndexDir   := nIndexDir + 1;
            vDirPersonas(nIndexDir)             := vDirPersona;
        END IF;
        
        IF inDirDetalle_Trabajo IS NOT NULL THEN
        
            BEGIN           
                SELECT COD_PROVINCIA, COD_CANTON, COD_DISTRITO
                  INTO vCodProvincia, vCodCanton, vCodDistrito
                  FROM PA.DISTRITOS c 
                 WHERE C.COD_PAIS = vCodPais
                   AND C.COD_CANTON = inCod_Provincia_Trabajo
                   AND C.COD_DISTRITO = inCod_Canton_Trabajo;
                   
            EXCEPTION WHEN NO_DATA_FOUND THEN
                vCodProvincia := NULL;
            END;     
            
--DBMS_OUTPUT.PUT_LINE('vCodProvincia=' || vCodProvincia || ' vCodCanton=' || vCodCanton || ' vCodDistrito=' || vCodDistrito || ' vCodPueblo='|| inCod_Pueblo);                                        
            
            vDirPersona.Tip_Direccion           := 2;
            vDirPersona.Detalle                 := UPPER(inDirDetalle_Trabajo);
            vDirPersona.Cod_Pais                := TO_NUMBER(inCod_Pais_Trabajo);
            vDirPersona.Cod_Provincia           := TO_NUMBER(vCodProvincia);
            vDirPersona.Cod_Canton              := TO_NUMBER(vCodCanton);
            vDirPersona.Cod_Distrito            := TO_NUMBER(vCodDistrito);
            vDirPersona.Cod_Pueblo              := TO_NUMBER(NVL(inCod_Pueblo,nvl(vCodPueblo,1)));
            vDirPersona.Es_Default              := 'N';        
            vDirPersonas.EXTEND;
            nIndexDir   := nIndexDir + 1;
            vDirPersonas(nIndexDir)             := vDirPersona;
        END IF;
        
        -- Tel Personas
        vTelPersona                         := PA.TEL_PERSONAS_OBJ ();
        vTelPersona.Extension               := NULL;
        vTelPersona.Nota                    := NULL;        
        vTelPersona.Posicion                := NULL;
        vTelPersona.Cod_Direccion           := NULL;
        vTelPersona.Cod_Pais                := NULL;
        
        -- Casa
        IF vTelefonoCasa IS NOT NULL AND LENGTH(vTelefonoCasa) >= 10 THEN
            vCodArea                            := SUBSTR(vTelefonoCasa,1,3);
            vNumTel                             := SUBSTR(vTelefonoCasa, 4);
            vTelPersona.Cod_Area                := vCodArea;
            vTelPersona.Num_Telefono            := vNumTel;
            vTelPersona.Tip_Telefono            := 'D';
            vTelPersona.Tel_Ubicacion           := 'C';
            vTelPersona.Es_Default              := 'S';
            nIndexTel   := nIndexTel + 1;    
            vTelPersonas.EXTEND;
            vTelPersonas(nIndexTel)             := vTelPersona;            
        ELSE
            outCodPersona := '0';
            outError := 'Error - El Teléfono de la casa está incompleto.   Ejemplo: 8099999999';
            RAISE_APPLICATION_ERROR(-20105, outError);            
        END IF; 
        
--DBMS_OUTPUT.PUT_LINE('vTelefonoCasa=' || vTelefonoCasa);           
        
        IF vTelefonoCelular IS NOT NULL AND LENGTH(vTelefonoCelular) >= 10 THEN
            vCodArea    := SUBSTR(vTelefonoCelular,1,3);
            vNumTel     := SUBSTR(vTelefonoCelular, 4);
            vTelPersona.Cod_Area                := vCodArea;
            vTelPersona.Num_Telefono            := vNumTel;
            vTelPersona.Tip_Telefono            := 'C';
            vTelPersona.Tel_Ubicacion           := 'C';
            IF vTelefonoCasa IS NULL THEN
                vTelPersona.Es_Default              := 'S';
            ELSE
                vTelPersona.Es_Default              := 'N';
            END iF;
            nIndexTel   := nIndexTel + 1;    
            vTelPersonas.EXTEND;
            vTelPersonas(nIndexTel)             := vTelPersona;
        ELSE
            outCodPersona := '0';
            outError := 'Error - El Teléfono celular está incompleto.   Ejemplo: 8099999999';
            RAISE_APPLICATION_ERROR(-20105, outError);  
        END IF; 
        
--DBMS_OUTPUT.PUT_LINE('vTelefonoCelular=' || vTelefonoCelular); 
        
        IF vTelefonoTrabajo IS NOT NULL AND LENGTH(vTelefonoTrabajo) >= 10 THEN
            vCodArea    := SUBSTR(vTelefonoTrabajo,1,3);
            vNumTel     := SUBSTR(vTelefonoTrabajo, 4);
            vTelPersona.Cod_Area                := vCodArea;
            vTelPersona.Num_Telefono            := vNumTel;
            vTelPersona.Tip_Telefono            := 'D';
            vTelPersona.Tel_Ubicacion           := 'T';
            vTelPersona.Extension               := inTelefonoExtTrabajo;
            IF vTelefonoCasa IS NULL AND vTelefonoCelular IS NULL THEN
                vTelPersona.Es_Default              := 'S';
            ELSE
                vTelPersona.Es_Default              := 'N';
            END iF;
            nIndexTel   := nIndexTel + 1;    
            vTelPersonas.EXTEND;
            vTelPersonas(nIndexTel)             := vTelPersona;
        ELSE
            outCodPersona := '0';
            outError := 'Error - El Teléfono del trabajo está incompleto.   Ejemplo: 8099999999';
            RAISE_APPLICATION_ERROR(-20105, outError); 
        END IF;
        
--DBMS_OUTPUT.PUT_LINE('vTelefonoTrabajo=' || vTelefonoTrabajo); 
                
        -- Dir Envio x Persona
        vDirEnvioxPers                      := PA.DIR_ENVIO_X_PERS_OBJ();
        vDirEnvioxPers.Tipo_Envio           := 'R';
        vDirEnvioxPers.Apdo_Postal          := NULL;
        vDirEnvioxPers.Codigo_Postal        := NULL;
        vDirEnvioxPers.Cod_Direccion        := NULL;
        vDirEnvioxPers.Cod_Area             := NULL; 
        vDirEnvioxPers.Num_Telefono         := NULL;
        vDirEnvioxPers.Num_Casilla          := NULL;
        vDirEnvioxPers.Cod_Empresa          := '1';
        vDirEnvioxPers.Cod_Agencia          := pCod_Agencia_DirEnv;
        vDirEnvioxPers.Email_Usuario        := NULL;
        vDirEnvioxPers.Email_Servidor       := NULL;  
--DBMS_OUTPUT.PUT_LINE('pCod_Agencia_DirEnv=' || pCod_Agencia_DirEnv);               
        
        -- Info Laboral 
        vInfoLaboral                        := PA.INFO_LABORAL_OBJ();
        vInfoLaboral.Fec_Ingreso            := TO_DATE(inFec_Ingreso,'DD/MM/YYYY');
        vInfoLaboral.Fec_Salida             := NULL;           
        vInfoLaboral.Lugar_Trabajo          := UPPER(inLugar_Trabajo);
        vInfoLaboral.Monto                  := TO_NUMBER(inSueldo);
        vInfoLaboral.Cod_Cargo              := NULL;
        vInfoLaboral.Puesto                 := inPuesto;
        vInfoLaboral.Observaciones          := NULL;
        vInfoLaboral.Tipo_Ingreso           := NVL(inTipo_Ingreso,'S');
        vInfoLaboral.Empleo_Actual          := inEmpleo_Actual;
        vInfoLaboral.Cod_Moneda             := NULL;
        vInfoLaboral.Monto_Origen           := NULL;
--DBMS_OUTPUT.PUT_LINE('inLugar_Trabajo=' || inLugar_Trabajo||' inPuesto='||inPuesto||' inSueldo='||inSueldo);        
        
        IF inDirDetalle_Trabajo IS NOT NULL THEN
            vInfoLaboral.Direccion          := UPPER(inDirDetalle_Trabajo);
        END IF;
        
        IF vTelefonoTrabajo IS NOT NULL AND LENGTH(vTelefonoTrabajo) >= 10 THEN
            vCodArea    := SUBSTR(vTelefonoTrabajo,1,3);
            vNumTel     := SUBSTR(vTelefonoTrabajo, 4);
            vInfoLaboral.Cod_Area           := vCodArea;
            vInfoLaboral.Num_Telefono       := vNumTel;
        END IF;        
        vInfoLaboral.Ind_Verificado         := 'S';
              
         
        -- Cuenta Cliente Otros Bancos
        vCtaCliOtrBanco                     := PA.CTAS_CLIENTES_OTR_BANCOS_OBJ();
        IF inCod_Emisor_Cta IS NOT NULL THEN
            vCtaCliOtrBanco.Cod_Emisor          := TO_NUMBER(inCod_Emisor_Cta);
            vCtaCliOtrBanco.Num_Cuenta          := inNum_Cuenta;          
            vCtaCliOtrBanco.Nom_Cuenta          := UPPER(inNom_Cuenta);          
            vCtaCliOtrBanco.Tipo_Cuenta         := inTipo_Cuenta;         
            vCtaCliOtrBanco.Cod_Moneda          := TO_NUMBER(inCod_Moneda_Cta);          
            vCtaCliOtrBanco.Cod_Pais            := TO_NUMBER(inCod_Pais_Cta);            
            vCtaCliOtrBanco.Oficial_Responsable := inOficial_Responsable; 
            vCtaCliOtrBanco.Tiempo_Apertura     := TO_NUMBER(inTiempo_Apertura_Cta); 
        END IF;    
        vCtaCliOtrBancos.EXTEND;                            
        vCtaCliOtrBancos(1)                 := vCtaCliOtrBanco;       
        
        
        -- Ref Personales 
        vRefPersonal                         := PA.REF_PERSONALES_OBJ();
        vRefPersonal.Cod_Empresa             := '1';
        vRefPersonal.Extension_Tel           := NULL;
        vRefPersonal.Cod_Tipo_Id             := TO_NUMBER(inTipo_Id_RefPers1);
        vRefPersonal.Nombre_Ref              := UPPER(inNombre_RefPers1);
        vRefPersonal.Num_Id                  := inIdent_RefPers1;
        IF vTelefono_RefPers1 IS NOT NULL THEN
            vCodArea    := SUBSTR(vTelefono_RefPers1,1,3);
            vNumTel     := SUBSTR(vTelefono_RefPers1, 4);
            vRefPersonal.Cod_Area                := vCodArea;
            vRefPersonal.Num_Telefono            := vNumTel;
        END IF;
        vRefPersonal.Relacion_Persona        := inRelacion_Persona1;
        
        vRefPersonales.EXTEND;
        nIndexRefPers := nIndexRefPers + 1;
        vRefPersonales(nIndexRefPers)        := vRefPersonal;
        
        vRefPersonal.Cod_Tipo_Id             := TO_NUMBER(inTipo_Id_RefPers2);
        vRefPersonal.Nombre_Ref              := UPPER(inNombre_RefPers2);
        vRefPersonal.Num_Id                  := inIdent_RefPers2;
        IF vTelefono_RefPers2 IS NOT NULL THEN
            vCodArea                         := SUBSTR(vTelefono_RefPers2,1,3);
            vNumTel                          := SUBSTR(vTelefono_RefPers2, 4);
            vRefPersonal.Cod_Area            := vCodArea;
            vRefPersonal.Num_Telefono        := vNumTel;
        END IF;
        vRefPersonal.Relacion_Persona        := UPPER(inRelacion_Persona2);        
        vRefPersonales.EXTEND;
        nIndexRefPers := nIndexRefPers + 1;
        vRefPersonales(nIndexRefPers)        := vRefPersonal;
        
        -- Ref Comerciales        
        vRefComercial                       := PA.REF_COMERCIALES_OBJ ();
        IF inNombre_EnteComerc IS NOT NULL THEN
            vRefComercial.Cod_Tip_Ref           := TO_NUMBER(inCod_Tip_RefComerc);
            vRefComercial.Cod_Ente              := TO_NUMBER(inCod_EnteComerc);
            vRefComercial.Num_Cuenta            := NULL;
            vRefComercial.Cod_Moneda            := 1;
            vRefComercial.Oficial               := inOficial_Comerc;
            vRefComercial.Nombre_Ente           := UPPER(inNombre_EnteComerc);
        END IF;
        vRefComerciales.EXTEND;
        vRefComerciales(1)                  := vRefComercial;        
        
        -- Info Producto Solicitado
        vInfoProdSol                        := PA.INFO_PROD_SOL_OBJ ();
        vInfoProdSol.Tipo_Producto          := inTipo_Producto;
        vInfoProdSol.Cod_Moneda             := TO_NUMBER(inCod_Moneda_ProdSol);
        vInfoProdSol.Proposito              := inProposito_ProdSol;
        vInfoProdSol.Monto_Inicial          := TO_NUMBER(inMonto_Ini_ProdSol);
        vInfoProdSol.Instrumento_Bancario   := UPPER(inInstrumento_Bancario);
        vInfoProdSol.Origen_Fondos          := inOrigen_Fondos;
        
        -- Info Buro
        IF inIndConsultarBuro = 'S' THEN
            vInfoBuro                           := PA.INFO_BURO_OBJ();
            vInfoBuro.Reporte                   := inIndConsultarBuro;
        END IF;             

        -- Info Doc Fisica Nacional
        vInfoDocFisNac                                := PA.INFO_DOC_FISICA_NACIONAL_OBJ();
        vInfoDocFisNac.Pind_Cedula                    := 'S';
        vInfoDocFisNac.Pind_Licencia_Conducir         := 'N';
        vInfoDocFisNac.Pind_Residencia                := 'N'; 
        vInfoDocFisNac.Pind_Id_Otro                   := 'N'; 
        vInfoDocFisNac.Id_Otro_Desc                   := 'N'; 
        vInfoDocFisNac.Pind_Certificado_Nacimiento    := 'N'; 
        vInfoDocFisNac.Pind_Pensionado_Jubilado       := 'N'; 
        vInfoDocFisNac.Pind_Lab_Tiempo                := 'N';
        vInfoDocFisNac.Pind_Lab_Ingreso_Anual         := 'N';
        vInfoDocFisNac.Pind_Lab_Puesto_Desempena      := 'N';
        vInfoDocFisNac.Pind_Trabaja_Independiente     := 'N';
        vInfoDocFisNac.Pind_Independiente_Actividad   := 'N';
        vInfoDocFisNac.Pind_Independiente_Justifica_A := 'N';
        vInfoDocFisNac.Comentarios_Adicionales        := 'N';
        
        -- Info Doc 
        vInfoDocFisExtranj           := PA.INFO_DOC_FISICA_EXTRANJ_OBJ ();
        vInfoVerifDocFisNac          := PA.INFO_VERIF_DOC_FIS_NAC_OBJ();
        vInfoVerifDocFisExt          := PA.INFO_VERIF_DOC_FIS_EXTRAN_OBJ();  
        vInfoWorldCheck              := PA.INFO_WORLD_CHECK_OBJ();      
        vListaPep                    := PA.LISTA_PEP_LIST();                                                                        
        
        -- Cliente
        vCliente                     :=  PA.CLIENTES_OBJ();
        vCliente.IndConsultarBuro    :=  inIndConsultarBuro;
        vCliente.IndConsultarPadron  :=  inIndConsultarPadron;
        vCliente.inCod_Promotor      :=  inCod_Promotor;
        vCliente.Persona             :=  vPersona;
        vCliente.PersonaFisica       :=  vPersonaFisica;       
        vCliente.IdPersonas          :=  vIdPersonas;          
        vCliente.DirPersonas         :=  vDirPersonas;         
        vCliente.TelPersonas         :=  vTelPersonas;         
        vCliente.DirEnvioxPers       :=  vDirEnvioxPers;       
        vCliente.InfoLaboral         :=  vInfoLaboral;         
        vCliente.CtaCliOtrBancos     :=  vCtaCliOtrBancos;     
        vCliente.RefPersonales       :=  vRefPersonales;       
        vCliente.RefComerciales      :=  vRefComerciales;      
        vCliente.InfoProdSol         :=  vInfoProdSol;         
        vCliente.InfoBuro            :=  vInfoBuro;            
        vCliente.InfoDocFisNac       :=  vInfoDocFisNac;       
        vCliente.InfoDocFisExtranj   :=  vInfoDocFisExtranj;   
        vCliente.InfoVerifDocFisNac  :=  vInfoVerifDocFisNac;  
        vCliente.InfoVerifDocFisExt  :=  vInfoVerifDocFisExt;  
        vCliente.InfoWorldCheck      :=  vInfoWorldCheck;      
        vCliente.ListaPep            :=  vListaPep; 
--DBMS_OUTPUT.PUT_LINE('Antes de Generar_Persona_Fisica');         
        BEGIN
            
            Generar_Persona_Fisica(vCliente, pResultado);

            IF pResultado.Codigo IS NOT NULL THEN
                outCodPersona := '0';
                outError :=  pResultado.Descripcion;
                RETURN;
            ELSE
                outCodPersona := PA.OBT_CODPERSONA_CON_ID (p_tipoID => inTipoIdent,  p_numId  => vCedula);--vCliente.PersonaFisica.Cod_per_fisica;  --malmanzar 15-03-2023
                outError :=  pResultado.Descripcion;
            END IF;    
        EXCEPTION WHEN OTHERS THEN
            IF pResultado.Codigo IS NOT NULL THEN
                outError := pResultado.Descripcion;
            ELSE
                outError:= SUBSTR(SQLERRM||' '||dbms_utility.format_error_backtrace,1,4000);
            END IF;
            outCodPersona := '0';
            RETURN;
        END;        
--DBMS_OUTPUT.PUT_LINE('Después de Generar_Persona_Fisica '||outError);           
        BEGIN
            --
            -- Activar las promociones por todos los canales
            PA.PKG_PROMOCION_PERSONA.AsignarCanales(pCod_Persona          => outCodPersona,--vCodPersona,--vCliente.PersonaFisica.Cod_per_fisica, --malmanzar 15-03-2023
                                                    pFecha_Autorizacion  => SYSDATE,
                                                    pAutorizado           => 'S',
                                                    pCod_Origen           => 'APP',
                                                    pObservaciones        => 'Contactado al Cliente directamente por el APP Portacredit',
                                                    pResultado            => outError);
        EXCEPTION WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error Asignando Canales de Promociones '||dbms_utility.format_error_backtrace);
            IF pResultado.Codigo IS NOT NULL THEN
                outError := pResultado.Descripcion;
            ELSE
                outError:= SUBSTR(SQLERRM||' '||dbms_utility.format_error_backtrace,1,4000);
            END IF;
        END;
        
        IF outError = 'Exitoso.' THEN
            outError := NULL;
        END IF;
        
--DBMS_OUTPUT.PUT_LINE('Después de AsignarCanales '||outError);        
--DBMS_OUTPUT.PUT_LINE('Antes de Convertir a Cliente');
/****  ---Omariot / malmanzar 15-03-2023
        BEGIN
            vCliente.Convertir();
        EXCEPTION WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error convirtiendo a Cliente '||SQLERRM);
            IF pResultado.Codigo IS NOT NULL THEN
                outError := pResultado.Descripcion;
            ELSE
                outError:= SUBSTR(SQLERRM||' '||dbms_utility.format_error_backtrace,1,4000);
            END IF;
            DBMS_OUTPUT.PUT_LINE( outError );
        END;
        ****/
--DBMS_OUTPUT.PUT_LINE('Después de Convertir a Cliente');        
    EXCEPTION WHEN OTHERS THEN
        outCodPersona := '0';
        IF outError IS NULL THEN
            outError:= SUBSTR(SQLERRM||' '||dbms_utility.format_error_backtrace,1,4000);
        END IF;
        DBMS_OUTPUT.PUT_LINE( outError );
        ROLLBACK;
       -- INSERT INTO tc.datatemptc (CAMPO, FECHA, VALOR) VALUES ('PKG_CLIENTE ERROR 2', SYSDATE, outError); commit;   */              
    END;    

    PROCEDURE Generar_Persona_Fisica (pCliente     IN OUT PA.CLIENTES_OBJ,                      
                                      pResultado   IN OUT resultado) IS
        vCodPersona         PA.PERSONAS.COD_PERSONA%TYPE := NULL;                                    
        vExiste             BOOLEAN := FALSE;
        vIgual              BOOLEAN := FALSE;
        vCliente            PA.CLIENTES_OBJ;
        vClienteRegistrado  PA.CLIENTES_OBJ;
    BEGIN  
      vCodPersona := NULL;
      vCliente := pCliente;
      FOR i IN 1 .. vCliente.idPersonas.COUNT LOOP
         BEGIN
              SELECT I.COD_PERSONA
                INTO vCodPersona
                FROM PA.ID_PERSONAS I
               WHERE I.COD_TIPO_ID = vCliente.idPersonas(i).Cod_Tipo_Id
                 AND REPLACE(I.NUM_ID,'-','') = REPLACE(vCliente.idPersonas(i).num_id,'-','')
                 AND ROWNUM = 1;
              
             vCliente.Persona.cod_persona               := vCodPersona;
             EXIT;
         EXCEPTION WHEN NO_DATA_FOUND THEN
             NULL;
         END;     
      END LOOP;   
      
      vExiste := vCliente.Persona.Existe();      
               
       -- Si No Existe la Persona entonces Crea 
       IF vExiste = FALSE THEN
           BEGIN 
               vCliente.Crear();
               pResultado.Codigo := NULL;
               pResultado.Descripcion := 'Cliente '||vCliente.PersonaFisica.Cod_per_fisica||' creado satisfactoriamente.';
               COMMIT;
           EXCEPTION WHEN OTHERS THEN
               DBMS_OUTPUT.PUT_LINE('Error en Crear Cliente '||SUBSTR(SQLERRM||' '||dbms_utility.format_error_backtrace,1,4000));
               vCliente.Persona.cod_persona := NULL; 
               pResultado.Codigo := SQLCODE;
               pResultado.Descripcion := SUBSTR(SQLERRM,1,4000);
               ROLLBACK;                                  
           END;                
       ELSE           
           BEGIN 
               vCliente.Actualizar();
               pResultado.Codigo := NULL;
               pResultado.Descripcion := 'Cliente '||vCliente.PersonaFisica.Cod_per_fisica||' actualizado satisfactoriamente.';
               COMMIT;
           EXCEPTION WHEN OTHERS THEN
               DBMS_OUTPUT.PUT_LINE('Error en Actualizar Cliente '||SUBSTR(SQLERRM||' '||dbms_utility.format_error_backtrace,1,4000));
               vCliente.Persona.cod_persona := NULL;
               pResultado.Codigo := SQLCODE;
               pResultado.Descripcion := SUBSTR(SQLERRM,1,4000);
               ROLLBACK;                       
           END;
       END IF;    
           
    END;

    FUNCTION Consultar_Persona_Fisica (pCodPersona      IN VARCHAR2,
                                       pTipoId          IN NUMBER,
                                       pNumId           IN VARCHAR2)
      RETURN PA.CLIENTES_OBJ IS      
   
       vPersona             PA.PERSONAS_OBJ;
       vPersonaFisica       PA.PERSONAS_FISICAS_OBJ;
       vIdPersonas          PA.ID_PERSONAS_LIST;
       vDirPersonas         PA.DIR_PERSONAS_LIST;
       vTelPersonas         PA.TEL_PERSONAS_LIST;
       vDirEnvioxPers       PA.DIR_ENVIO_X_PERS_OBJ;
       vInfoLaboral         PA.INFO_LABORAL_OBJ;
       vCtaCliOtrBancos     PA.CTAS_CLIENTES_OTR_BANCOS_LIST;
       vRefPersonales       PA.REF_PERSONALES_LIST;
       vRefComerciales      PA.REF_COMERCIALES_LIST;
       vInfoProdSol         PA.INFO_PROD_SOL_OBJ;
       vInfoBuro            PA.INFO_BURO_OBJ;
       vInfoDocFisNac       PA.INFO_DOC_FISICA_NACIONAL_OBJ;
       vInfoDocFisExtranj   PA.INFO_DOC_FISICA_EXTRANJ_OBJ;
       vInfoVerifDocFisNac  PA.INFO_VERIF_DOC_FIS_NAC_OBJ;
       vInfoVerifDocFisExt  PA.INFO_VERIF_DOC_FIS_EXTRAN_OBJ;
       vInfoWorldCheck      PA.INFO_WORLD_CHECK_OBJ;
       vListaPep            PA.LISTA_PEP_LIST;       
       
       vCliente             PA.CLIENTES_OBJ;                     
       
    BEGIN
       vCliente             := PA.CLIENTES_OBJ(); 
       vPersona             := PA.PERSONAS_OBJ();
       vPersonaFisica       := PA.PERSONAS_FISICAS_OBJ();
       vIdPersonas          := PA.ID_PERSONAS_LIST();
       vDirPersonas         := PA.DIR_PERSONAS_LIST();
       vTelPersonas         := PA.TEL_PERSONAS_LIST();
       vDirEnvioxPers       := PA.DIR_ENVIO_X_PERS_OBJ();
       vInfoLaboral         := PA.INFO_LABORAL_OBJ();
       vCtaCliOtrBancos     := PA.CTAS_CLIENTES_OTR_BANCOS_LIST();
       vRefPersonales       := PA.REF_PERSONALES_LIST();
       vRefComerciales      := PA.REF_COMERCIALES_LIST();
       vInfoProdSol         := PA.INFO_PROD_SOL_OBJ();
       vInfoBuro            := PA.INFO_BURO_OBJ();
       vInfoDocFisNac       := PA.INFO_DOC_FISICA_NACIONAL_OBJ();
       vInfoDocFisExtranj   := PA.INFO_DOC_FISICA_EXTRANJ_OBJ();
       vInfoVerifDocFisNac  := PA.INFO_VERIF_DOC_FIS_NAC_OBJ();
       vInfoVerifDocFisExt  := PA.INFO_VERIF_DOC_FIS_EXTRAN_OBJ();
       vInfoWorldCheck      := PA.INFO_WORLD_CHECK_OBJ();
       vListaPep            := PA.LISTA_PEP_LIST(); 
        
       -- Datos de Persona 
       IF pCodPersona IS NOT NULL OR (pTipoId IS NOT NULL AND pNumId IS NOT NULL) THEN
            -- Datos Personas Fisicas
            DECLARE
                vPersonasFisicas    PA.PERSONAS_FISICAS_LIST := PA.PERSONAS_FISICAS_LIST();
            BEGIN
                vPersonasFisicas.DELETE;
                vPersonasFisicas :=  PA.PKG_PERSONAS_FISICAS.CONSULTAR
                  (pCod_Per_Fisica      => pCodPersona,
                   pEst_Civil           => NULL,
                   pSexo                => NULL,
                   pFec_Nacimiento      => NULL,
                   pPrimer_Apellido     => NULL,
                   pSegundo_Apellido    => NULL,
                   pPrimer_Nombre       => NULL,
                   pSegundo_Nombre      => NULL,
                   pProfesion           => NULL,
                   pIdioma_Correo       => NULL,
                   pEs_Mal_Deudor       => NULL,
                   pConyugue            => NULL,
                   pNacionalidad        => NULL,
                   pCod_Sector          => NULL,
                   pEstatal             => NULL,
                   pEmail_Usuario       => NULL,
                   pEmail_Servidor      => NULL,
                   pNivel_Estudios      => NULL,
                   pTipo_Vivienda       => NULL,
                   pNum_Hijos           => NULL,
                   pNum_Dependientes    => NULL,
                   pEs_Residente        => NULL,
                   pTiempo_Vivien_Act   => NULL,
                   pEval_Ref_Bancaria   => NULL,
                   pEval_Ref_Tarjetas   => NULL,
                   pEval_Ref_Laboral    => NULL,
                   pTotal_Ingresos      => NULL,
                   pCod_Pais            => NULL,
                   pIncluido_Por        => NULL,
                   pFec_Inclusion       => NULL,
                   pModificado_Por      => NULL,
                   pFec_Modificacion    => NULL,
                   pScoring             => NULL,
                   pActividad           => NULL,
                   pRango_Ingresos      => NULL,
                   pCasada_Apellido     => NULL,
                   pEs_Funcionario      => NULL,
                   pEs_Peps             => NULL,
                   pCod_Actividad       => NULL,
                   pCod_Subactividad    => NULL,
                   pTipo_Persona        => NULL,
                   pTipo_Cliente        => NULL,
                   pCod_Pais_Padre      => NULL,
                   pCod_Pais_Madre      => NULL,
                   pCod_Pais_Conyugue   => NULL,
                   pMas_180_Dias_Eeuu   => NULL,
                   pCod_Finalidad       => NULL,
                   pPeso                => NULL,
                   pEstatura            => NULL,
                   pActividad_Polizah   => NULL,
                   pDeporte_Polizah     => NULL,
                   pPeso_Polizah        => NULL,
                   pEstatura_Polizah    => NULL,
                   pApellido_Casada     => NULL,
                   pTercer_Nombre       => NULL,
                   pTipo_Soc_Conyugal   => NULL,
                   pInd_Fallecimiento   => NULL,
                   pFec_Fallecimiento   => NULL,
                   pGpo_Riesgo          => NULL,
                   pNum_Empleados       => NULL,
                   pVentas_Ingresos     => NULL,
                   pCp_Total_Activo     => NULL,
                   pInd_Clte_Vip        => NULL,
                   pTipo_Gen_Divisas    => NULL,
                   pOcupacion_Clasif_nac => NULL);   
                 
                 IF vPersonasFisicas.COUNT >= 1 THEN
                     vPersonaFisica := vPersonasFisicas(1);   
                 END IF;             
            EXCEPTION WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20404, 'Datos de Persona Física no encontrados');
            END;
             
            IF vPersonaFisica.Cod_Per_Fisica IS NOT NULL THEN 
                DECLARE                               
                    vPersonasList    PA.PERSONAS_LIST := PA.PERSONAS_LIST();                
                BEGIN
                    vPersonasList.DELETE;
                    vPersonasList := PA.PKG_PERSONAS.CONSULTAR(
                                                                  pCod_Persona          => vPersonaFisica.Cod_Per_Fisica,
                                                                  pCod_Per_Fisica       => vPersonaFisica.Cod_Per_Fisica,
                                                                  pCod_Per_Juridica     => NULL,
                                                                  pEs_Fisica            => NULL,
                                                                  pNombre               => NULL,
                                                                  pInd_Clte_I2000       => NULL,
                                                                  pPaga_Imp_Ley288      => NULL,
                                                                  pBenef_Pag_Ley288     => NULL,
                                                                  pCod_Vinculacion      => NULL,
                                                                  pCod_Sec_Contable     => NULL,
                                                                  pAdicionado_Por       => NULL,
                                                                  pFecha_Adicion        => NULL,
                                                                  pModificado_Por       => NULL,
                                                                  pFecha_Modificacion   => NULL,
                                                                  pCodigo_Sustituto     => NULL,
                                                                  pEstado_Persona       => NULL,
                                                                  pCobr_Nodgii_132011   => NULL,
                                                                  pLleno_Fatca          => NULL,
                                                                  pImprimio_Fatca       => NULL,
                                                                  pEs_Fatca             => NULL,
                                                                  pFec_Actualizacion    => NULL,
                                                                  pTel_Verificado       => NULL
                                                              );
                    IF vPersonasList.COUNT >= 1 THEN
                        vPersona :=  vPersonasList(1);
                    END IF;                                                         
                                                         
                EXCEPTION WHEN NO_DATA_FOUND THEN
                    RAISE_APPLICATION_ERROR(-20404, 'Datos de Persona no encontrados');
                END;
                
                IF vPersona.COD_PERSONA IS NOT NULL THEN
                    -- Id Personas                                              
                    BEGIN
                        vIdPersonas.DELETE;
                        vIdPersonas := PA.PKG_ID_PERSONAS.CONSULTAR(   pCod_Persona       => vPersona.COD_PERSONA,
                                                                       pCod_Tipo_Id       => NULL,
                                                                       pNum_Id            => NULL,
                                                                       pFec_Vencimiento   => NULL,
                                                                       pCod_Pais          => NULL,
                                                                       pNacionalidad      => NULL);
                    EXCEPTION WHEN NO_DATA_FOUND THEN
                        RAISE_APPLICATION_ERROR(-20404, 'Datos de Id Personas no encontrados');
                    END;
                    
                    -- Dir Personas                         
                    BEGIN
                        vDirPersonas.DELETE;
                        vDirPersonas := PA.PKG_DIR_PERSONAS.CONSULTAR (pCod_Persona          => vPersona.COD_PERSONA,
                                                                       pCod_Direccion        => NULL,
                                                                       pTip_Direccion        => NULL,
                                                                       pApartado_Postal      => NULL,
                                                                       pCod_Postal           => NULL,
                                                                       pDetalle              => NULL,
                                                                       pCod_Pais             => NULL,
                                                                       pCod_Provincia        => NULL,
                                                                       pCod_Canton           => NULL,
                                                                       pCod_Distrito         => NULL,
                                                                       pCod_Pueblo           => NULL,
                                                                       pEs_Default           => NULL,
                                                                       pColonia              => NULL,
                                                                       pZona                 => NULL,
                                                                       pInd_Estado           => NULL,
                                                                       pIncluido_Por         => NULL,
                                                                       pFec_Inclusion        => NULL,
                                                                       pModificado_Por       => NULL,
                                                                       pFecha_Modificacion   => NULL);
                                                                                           
                           
                    EXCEPTION WHEN NO_DATA_FOUND THEN
                        RAISE_APPLICATION_ERROR(-20404, 'Datos de Direcciones de Personas no encontrados');
                    END;
                    
                    -- Tel Personas
                    BEGIN
                        vTelPersonas.DELETE;
                        vTelPersonas := PA.PKG_TEL_PERSONAS.CONSULTAR (pCod_Persona              => vPersona.COD_PERSONA,
                                                                       pCod_Area                 => NULL,
                                                                       pNum_Telefono             => NULL,
                                                                       pTip_Telefono             => NULL,
                                                                       pTel_Ubicacion            => NULL,
                                                                       pExtension                => NULL,
                                                                       pNota                     => NULL,
                                                                       pEs_Default               => NULL,
                                                                       pPosicion                 => NULL,
                                                                       pCod_Direccion            => NULL,
                                                                       pCod_Pais                 => NULL,
                                                                       pModificado_Por           => NULL,
                                                                       pFecha_Modificacion       => NULL,
                                                                       pIncluido_Por             => NULL,
                                                                       pFec_Inclusion            => NULL,
                                                                       pNotif_Digital            => NULL,
                                                                       pFecha_Notif_Digital      => NULL,
                                                                       pUsuaario_Notif_Digital   => NULL
                                                                       );
                    EXCEPTION WHEN NO_DATA_FOUND THEN
                        RAISE_APPLICATION_ERROR(-20404, 'Datos de Telefonos de Personas no encontrados');
                    END;
                    
                    -- Dir Envio x Personas
                    DECLARE
                        vDirEnvioxPersList  PA.DIR_ENVIO_X_PERS_LIST := PA.DIR_ENVIO_X_PERS_LIST();
                    BEGIN
                        vDirEnvioxPersList := PA.PKG_DIR_ENVIO_X_PERS.CONSULTAR   (pCod_Persona      => vPersona.COD_PERSONA,
                                                                                   pTipo_Envio       => NULL,
                                                                                   pApdo_Postal      => NULL,
                                                                                   pCodigo_Postal    => NULL,
                                                                                   pCod_Direccion    => NULL,
                                                                                   pCod_Area         => NULL,
                                                                                   pNum_Telefono     => NULL,
                                                                                   pNum_Casilla      => NULL,
                                                                                   pCod_Empresa      => NULL,
                                                                                   pCod_Agencia      => NULL,
                                                                                   pEmail_Usuario    => NULL,
                                                                                   pEmail_Servidor   => NULL);
                        IF vDirEnvioxPersList.COUNT >= 1 THEN
                            vDirEnvioxPers := vDirEnvioxPersList(1);
                        END IF;                                                                               
                    EXCEPTION WHEN NO_DATA_FOUND THEN
                        RAISE_APPLICATION_ERROR(-20404, 'Datos de Direccion de Envio por Personas no encontrados');
                    END;
                    
                    -- Info Laboral
                    DECLARE                    
                        vInfoLaboralList    PA.INFO_LABORAL_LIST := PA.INFO_LABORAL_LIST();
                    BEGIN
                        vInfoLaboralList := PA.PKG_INFO_LABORAL.Consultar( pCod_Per_Fisica   => vPersona.COD_PERSONA,
                                                                           pCod_Laboral      => NULL,
                                                                           pFec_Ingreso      => NULL,
                                                                           pFec_Salida       => NULL,
                                                                           pLugar_Trabajo    => NULL,
                                                                           pMonto            => NULL,
                                                                           pCod_Cargo        => NULL,
                                                                           pPuesto           => NULL,
                                                                           pObservaciones    => NULL,
                                                                           pTipo_Ingreso     => NULL,
                                                                           pEmpleo_Actual    => NULL,
                                                                           pCod_Moneda       => NULL,
                                                                           pMonto_Origen     => NULL,
                                                                           pDireccion        => NULL,
                                                                           pCod_Area         => NULL,
                                                                           pNum_Telefono     => NULL,
                                                                           pExtension_Tel    => NULL,
                                                                           pInd_Verificado   => NULL,
                                                                           pAntiguedad       => NULL);    
                        IF vInfoLaboralList.COUNT >= 1 THEN
                            vInfoLaboral := vInfoLaboralList(1);                    
                        END IF;
                    EXCEPTION WHEN NO_DATA_FOUND THEN
                        RAISE_APPLICATION_ERROR(-20404, 'Datos de la Información Laboral no encontrados');    
                    END;
                    
                    -- Cuentas Clientes de Otros Bancos                
                    BEGIN
                        vCtaCliOtrBancos.DELETE;
                        vCtaCliOtrBancos := PA.PKG_CTAS_CLIENTES_OTR_BANCOS.Consultar (pCod_Cliente           => vPersona.COD_PERSONA,
                                                                                       pCod_Emisor            => NULL,
                                                                                       pNum_Cuenta            => NULL,
                                                                                       pNom_Cuenta            => NULL,
                                                                                       pTipo_Cuenta           => NULL,
                                                                                       pCod_Moneda            => NULL,
                                                                                       pAdicionado_Por        => NULL,
                                                                                       pFecha_Adicion         => NULL,
                                                                                       pModificado_Por        => NULL,
                                                                                       pFecha_Modificacion    => NULL,
                                                                                       pCod_Pais              => NULL,
                                                                                       pOficial_Responsable   => NULL,
                                                                                       pTiempo_Apertura       => NULL);
                    EXCEPTION WHEN NO_DATA_FOUND THEN
                        RAISE_APPLICATION_ERROR(-20404, 'Datos de las Cuentas de Cliente de Otros Bancos no encontrados');    
                    END;
                    
                    -- Referencias Personales
                    DECLARE
                        
                    BEGIN
                        vRefPersonales.DELETE;
                        vRefPersonales := PA.PKG_REF_PERSONALES.Consultar (pCod_Ref_Per        => NULL,
                                                                           pCod_Persona        => vPersona.COD_PERSONA,
                                                                           pCod_Empresa        => NULL,
                                                                           pCod_Tipo_Id        => NULL,
                                                                           pNombre_Ref         => NULL,
                                                                           pNum_Id             => NULL,
                                                                           pCod_Area           => NULL,
                                                                           pNum_Telefono       => NULL,
                                                                           pPuesto             => NULL,
                                                                           pLugar_Trabajo      => NULL,
                                                                           pRelacion_Persona   => NULL,
                                                                           pObservaciones      => NULL,
                                                                           pExtension_Tel      => NULL);
                    EXCEPTION WHEN NO_DATA_FOUND THEN
                        RAISE_APPLICATION_ERROR(-20404, 'Datos de las Referencias Personales no encontrados');    
                    END;
                    
                    -- Referencias Comerciales               
                    BEGIN
                        vRefComerciales.DELETE;
                        vRefComerciales := PA.PKG_REF_COMERCIALES.Consultar(pCod_Ref_Com        => NULL,
                                                                            pCod_Tip_Ref        => NULL,
                                                                            pCod_Persona        => vPersona.COD_PERSONA,
                                                                            pCod_Ente           => NULL,
                                                                            pNum_Cuenta         => NULL,
                                                                            pCredito_Otorgado   => NULL,
                                                                            pSaldo_Credito      => NULL,
                                                                            pCuota_Mensual      => NULL,
                                                                            pCod_Moneda         => NULL,
                                                                            pFec_Apertura       => NULL,
                                                                            pFec_Vencimiento    => NULL,
                                                                            pDesc_Garantia      => NULL,
                                                                            pObservaciones      => NULL,
                                                                            pOficial            => NULL,
                                                                            pNombre_Ente        => NULL);
                    EXCEPTION WHEN NO_DATA_FOUND THEN
                        RAISE_APPLICATION_ERROR(-20404, 'Datos de las Referencias Comerciales no encontrados');    
                    END;
                    
                    -- Info Prod Sol
                    DECLARE                   
                       vInfoProdSolList        PA.INFO_PROD_SOL_LIST := PA.INFO_PROD_SOL_LIST();  
                    BEGIN
                        vInfoProdSolList.DELETE;
                        vInfoProdSolList := PA.PKG_INFO_PROD_SOL.Consultar(pCod_Persona                 => vPersona.COD_PERSONA,
                                                                           pTipo_Producto               => NULL,
                                                                           pCod_Moneda                  => NULL,
                                                                           pProposito                   => NULL,
                                                                           pMonto_Inicial               => NULL,
                                                                           pInstrumento_Bancario        => NULL,
                                                                           pRango_Monetario_Ini         => NULL,
                                                                           pRango_Monetario_Fin         => NULL,
                                                                           pProm_Mes_Depo_Efectivo      => NULL,
                                                                           pProm_Mes_Depo_Cheques       => NULL,
                                                                           pProm_Mes_Reti_Efectivo      => NULL,
                                                                           pProm_Mes_Trans_Enviada      => NULL,
                                                                           pCod_Pais_Destino            => NULL,
                                                                           pProm_Mes_Trans_Recibida     => NULL,
                                                                           pCod_Pais_Origen             => NULL,
                                                                           pCompras_Giros_Cheques_Ger   => NULL, 
                                                                           pOrigen_Fondos               => NULL);
                        
                        IF vInfoProdSolList.COUNT >= 1 THEN
                            vInfoProdSol := vInfoProdSolList(1);
                        END IF;     
                                                                                          
                    EXCEPTION WHEN NO_DATA_FOUND THEN
                        --RAISE_APPLICATION_ERROR(-20404, 'Datos de la Información del Producto Solicitado no encontrados');
                        vInfoProdSol := PA.INFO_PROD_SOL_OBJ();
                    END;
                    
                    -- Info Buro
                    DECLARE                    
                       vInfoBuroList        PA.INFO_BURO_LIST := PA.INFO_BURO_LIST();  
                    BEGIN
                        vInfoBuroList.DELETE;
                        vInfoBuroList := PA.PKG_INFO_BURO.Consultar(   pCod_Persona   => vPersona.COD_PERSONA,
                                                                       pReporte       => NULL,
                                                                       pFecha         => NULL,
                                                                       pComentarios   => NULL,
                                                                       pArchivo       => NULL);
                        IF vInfoBuroList.COUNT >= 1 THEN
                            vInfoBuro := vInfoBuroList(1);
                        END IF;
                    EXCEPTION WHEN NO_DATA_FOUND THEN
                        vInfoBuro  := PA.INFO_BURO_OBJ();
                    END;
                    
                    -- Info Doc Fisica Nacional
                    DECLARE
                        
                       vInfoDocFisNacList        PA.INFO_DOC_FISICA_NACIONAL_LIST := PA.INFO_DOC_FISICA_NACIONAL_LIST();  
                    BEGIN
                        vInfoDocFisNacList.DELETE;
                        vInfoDocFisNacList := PA.PKG_INFO_DOC_FISICA_NACIONAL.Consultar(pCod_Persona                    => vPersona.COD_PERSONA,
                                                                                        pPind_Cedula                    => NULL,
                                                                                        pPind_Licencia_Conducir         => NULL,
                                                                                        pPind_Residencia                => NULL,
                                                                                        pPind_Id_Otro                   => NULL,
                                                                                        pId_Otro_Desc                   => NULL,
                                                                                        pPind_Certificado_Nacimiento    => NULL,
                                                                                        pPind_Pensionado_Jubilado       => NULL,
                                                                                        pPind_Lab_Tiempo                => NULL,
                                                                                        pPind_Lab_Ingreso_Anual         => NULL,
                                                                                        pPind_Lab_Puesto_Desempena      => NULL,
                                                                                        pPind_Trabaja_Independiente     => NULL,
                                                                                        pPind_Independiente_Actividad   => NULL,
                                                                                        pPindIndependienteJustificaA    => NULL,
                                                                                        pComentarios_Adicionales        => NULL);
                        
                        IF vInfoDocFisNacList.COUNT >= 1 THEN
                            vInfoDocFisNac := vInfoDocFisNacList(1);
                        END IF;                                                                
                    EXCEPTION WHEN NO_DATA_FOUND THEN
                        vInfoDocFisNac  := PA.INFO_DOC_FISICA_NACIONAL_OBJ();
                    END;
                    
                    -- Info Doc Fisica Extranjero
                    DECLARE
                        
                       vInfoDocFisExtraList     PA.INFO_DOC_FISICA_EXTRANJ_LIST := PA.INFO_DOC_FISICA_EXTRANJ_LIST();  
                    BEGIN
                        vInfoDocFisExtraList.DELETE;
                        vInfoDocFisExtraList := PA.PKG_INFO_DOC_FISICA_EXTRANJERO.Consultar(pCod_Persona                 => vPersona.COD_PERSONA,
                                                                                            pPind_Pasaporte              => NULL,
                                                                                            pPind_Permiso                => NULL,
                                                                                            pPind_Carta_Trabajo          => NULL,
                                                                                            pPind_Decla_Renta            => NULL,
                                                                                            pPind_Naturaleza_Actividad   => NULL,
                                                                                            pPind_Licencia_Actividad     => NULL);
                        IF vInfoDocFisExtraList.COUNT >= 1 THEN
                            vInfoDocFisExtranj := vInfoDocFisExtraList(1);
                        END IF;
                                                                                            
                    EXCEPTION WHEN NO_DATA_FOUND THEN
                        vInfoDocFisExtranj       := PA.INFO_DOC_FISICA_EXTRANJ_OBJ();
                    END;
                    
                    -- Info Verifica Doc Fisica Nacional
                    DECLARE                    
                       vData        PA.INFO_VERIF_DOC_FIS_NAC_LIST := PA.INFO_VERIF_DOC_FIS_NAC_LIST();  
                    BEGIN
                        vData.DELETE;
                        vData := PA.PKG_INFO_VERIF_DOC_FIS_NAC.Consultar
                          (pCod_Persona               => vPersona.COD_PERSONA,
                           pPind_Telefono             => NULL,
                           pTelefono_Fecha            => NULL,
                           pTelefono_Icp              => NULL,
                           pPind_Domicilio            => NULL,
                           pDomicilio_Fecha           => NULL,
                           pDomicilio_Icp             => NULL,
                           pPind_Trabajo              => NULL,
                           pTrabajo_Fecha             => NULL,
                           pTrabajo_Icp               => NULL,
                           pPind_Ref_Personal         => NULL,
                           pRef_Personal_Fecha        => NULL,
                           pRef_Personal_Icp          => NULL,
                           pPind_Ref_Crediticias      => NULL,
                           pRef_Crediticias_Fecha     => NULL,
                           pRef_Crediticias_Icp       => NULL,
                           pComentarios_Adicionales   => NULL,
                           pOpinion_Oficial           => NULL,
                           pPind_Email                => NULL,
                           pEmail_Fecha               => NULL,
                           pEmail_Icp                 => NULL,
                           pPind_Direnvio             => NULL,
                           pDirenvio_Fecha            => NULL,
                           pDirenvio_Icp              => NULL);
                         
                        IF vData.COUNT >= 1 THEN
                            vInfoVerifDocFisNac := vData(1);
                        END IF; 
                          
                    EXCEPTION WHEN NO_DATA_FOUND THEN
                        vInfoVerifDocFisNac    := PA.INFO_VERIF_DOC_FIS_NAC_OBJ();
                    END;
                    
                    -- Info Verifica Doc Fisica Extranjero
                    DECLARE
                        
                       vData        PA.INFO_VERIF_DOC_FIS_EXTRAN_LIST := PA.INFO_VERIF_DOC_FIS_EXTRAN_LIST();  
                    BEGIN
                        vData.DELETE;
                        vData := PA.PKG_INFO_VERIF_DOC_FIS_EXTRAN.Consultar
                          (pCod_Persona                    => vPersona.COD_PERSONA,
                           pPind_Telefono                  => NULL,
                           pTelefono_Fecha                 => NULL,
                           pTelefono_Icp                   => NULL,
                           pPind_Domicilio                 => NULL,
                           pDomicilio_Fecha                => NULL,
                           pDomicilio_Icp                  => NULL,
                           pPind_Trabajo                   => NULL,
                           pTrabajo_Fecha                  => NULL,
                           pTrabajo_Icp                    => NULL,
                           pPind_Ref_Personal              => NULL,
                           pRef_Personal_Fecha             => NULL,
                           pRef_Personal_Icp               => NULL,
                           pPind_Ref_Crediticias           => NULL,
                           pRef_Crediticias_Fecha          => NULL,
                           pRef_Crediticias_Icp            => NULL,
                           pPind_Datos_Personales          => NULL,
                           pPind_Domicilio_Local           => NULL,
                           pPind_Domicilio_Facturas        => NULL,
                           pPind_Domicilio_Llamando        => NULL,
                           pPind_Condicion_Migratoria      => NULL,
                           pPind_Licencia_Com_Industrial   => NULL,
                           pComentarios_Adicionales        => NULL,
                           pPind_Ref_Personales            => NULL,
                           pRef_Personales_Icp             => NULL,
                           pPind_Ref_Banacarias_Local      => NULL,
                           pRef_Banacarias_Local_Icp       => NULL,
                           pPind_Ref_Bancarias_Ext         => NULL,
                           pRef_Bancarias_Ext_Icp          => NULL,
                           pPind_Ref_Credito               => NULL,
                           pRef_Credito_Icp                => NULL,
                           pPind_Ref_Cond_Legal            => NULL,
                           pRef_Cond_Legal_Icp             => NULL,
                           pOpinion_Oficial                => NULL,
                           pPind_Email                     => NULL,
                           pEmail_Fecha                    => NULL,
                           pEmail_Icp                      => NULL,
                           pPind_Direnvio                  => NULL,
                           pDirenvio_Fecha                 => NULL,
                           pDirenvio_Icp                   => NULL);
                           
                        IF vData.COUNT >= 1 THEN
                            vInfoVerifDocFisExt := vData(1);
                        END IF;
                        
                    EXCEPTION WHEN NO_DATA_FOUND THEN
                        vInfoVerifDocFisExt  := PA.INFO_VERIF_DOC_FIS_EXTRAN_OBJ();
                    END;
                    
                    -- Info World Check
                    DECLARE                   
                       vData        PA.INFO_WORLD_CHECK_LIST := PA.INFO_WORLD_CHECK_LIST();  
                    BEGIN
                        vData.DELETE;
                        vData := PA.PKG_INFO_WORLD_CHECK.Consultar(pCod_Persona   => vPersona.COD_PERSONA,
                                                                   pReporte       => NULL,
                                                                   pFecha         => NULL,
                                                                   pComentarios   => NULL);
                        IF vData.COUNT >= 1 THEN
                            vInfoWorldCheck := vData(1);
                        END IF;                                                               
                    EXCEPTION WHEN NO_DATA_FOUND THEN
                        vInfoWorldCheck     := PA.INFO_WORLD_CHECK_OBJ();
                    END;
                    
                    -- Lista PEP                
                    BEGIN
                        vListaPep.DELETE;
                        vListaPep := PA.PKG_LISTA_PEP.Consultar
                          (pCod_Persona            => vPersona.COD_PERSONA,
                           pConsecutivo            => NULL,
                           pCargo                  => NULL,
                           pFec_Ingreso            => NULL,
                           pFec_Vencimiento        => NULL,
                           pApodo                  => NULL,
                           pAdicionado_Por         => NULL,
                           pFecha_Adicion          => NULL,
                           pModificado_Por         => NULL,
                           pFecha_Modificacion     => NULL,
                           pCodigo_Parentesco      => NULL,
                           pInstitucion_Politica   => NULL,
                           pCodigo_Operacion       => NULL,
                           pCod_Moneda             => NULL,
                           pCod_Pais               => NULL,
                           pNombre_Rel_Pep         => NULL);
                    EXCEPTION WHEN NO_DATA_FOUND THEN
                        vListaPep := PA.LISTA_PEP_LIST();    
                    END;
                                       
                END IF;
            END IF;
            --IA.LOGGER.OUTPUTOFF;
       END IF;
             
       vCliente.Persona                := vPersona;
       vCliente.PersonaFisica          := vPersonaFisica; 
       vCliente.IdPersonas             := vIdPersonas;
       vCliente.DirPersonas            := vDirPersonas;
       vCliente.TelPersonas            := vTelPersonas;
       vCliente.DirEnvioxPers          := vDirEnvioxPers;
       vCliente.InfoLaboral            := vInfoLaboral;
       vCliente.CtaCliOtrBancos        := vCtaCliOtrBancos;    
       vCliente.RefPersonales          := vRefPersonales;      
       vCliente.RefComerciales         := vRefComerciales;     
       vCliente.InfoProdSol            := vInfoProdSol;        
       vCliente.InfoBuro               := vInfoBuro;           
       vCliente.InfoDocFisNac          := vInfoDocFisNac;      
       vCliente.InfoDocFisExtranj      := vInfoDocFisExtranj;  
       vCliente.InfoVerifDocFisNac     := vInfoVerifDocFisNac; 
       vCliente.InfoVerifDocFisExt     := vInfoVerifDocFisExt; 
       vCliente.InfoWorldCheck         := vInfoWorldCheck;     
       vCliente.ListaPep               := vListaPep;     
        
       RETURN vCliente;
    EXCEPTION WHEN OTHERS THEN
         RAISE_APPLICATION_ERROR(-20104, 'Error - '||sqlerrm||'-'||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE||'-'||DBMS_UTILITY.FORMAT_ERROR_STACK );      
    END;
    
    FUNCTION CompararClientes(pCliente1          IN PA.CLIENTES_OBJ,
                              pCliente2          IN PA.CLIENTES_OBJ) 
      RETURN BOOLEAN IS            
      -- Cliente 1
      vPersona1             PA.PERSONAS_OBJ;
      vPersonaFisica1       PA.PERSONAS_FISICAS_OBJ;
      vIdPersonas1          PA.ID_PERSONAS_LIST;
      vDirPersonas1         PA.DIR_PERSONAS_LIST;
      vTelPersonas1         PA.TEL_PERSONAS_LIST;
      vDirEnvioxPers1       PA.DIR_ENVIO_X_PERS_OBJ;
      vInfoLaboral1         PA.INFO_LABORAL_OBJ;
      vCtaCliOtrBancos1     PA.CTAS_CLIENTES_OTR_BANCOS_LIST;
      vRefPersonales1       PA.REF_PERSONALES_LIST;
      vRefComerciales1      PA.REF_COMERCIALES_LIST;
      vInfoProdSol1         PA.INFO_PROD_SOL_OBJ; 
      
      -- Cliente 2
      vPersona2             PA.PERSONAS_OBJ;
      vPersonaFisica2       PA.PERSONAS_FISICAS_OBJ;
      vIdPersonas2          PA.ID_PERSONAS_LIST;
      vDirPersonas2         PA.DIR_PERSONAS_LIST;
      vTelPersonas2         PA.TEL_PERSONAS_LIST;
      vDirEnvioxPers2       PA.DIR_ENVIO_X_PERS_OBJ;
      vInfoLaboral2         PA.INFO_LABORAL_OBJ;
      vCtaCliOtrBancos2     PA.CTAS_CLIENTES_OTR_BANCOS_LIST;
      vRefPersonales2       PA.REF_PERSONALES_LIST;
      vRefComerciales2      PA.REF_COMERCIALES_LIST;
      vInfoProdSol2         PA.INFO_PROD_SOL_OBJ;
      
      
      vRetorno BOOLEAN := FALSE;  
    BEGIN
       vPersona1            := pCliente1.Persona; 
       vPersonaFisica1      := pCliente1.PersonaFisica; 
       vIdPersonas1         := pCliente1.IdPersonas;  
       vDirPersonas1        := pCliente1.DirPersonas;    
       vTelPersonas1        := pCliente1.TelPersonas;    
       vDirEnvioxPers1      := pCliente1.DirEnvioxPers;  
       vInfoLaboral1        := pCliente1.InfoLaboral;  
       vCtaCliOtrBancos1    := pCliente1.CtaCliOtrBancos;
       vRefPersonales1      := pCliente1.RefPersonales;
       vRefComerciales1     := pCliente1.RefComerciales; 
       vInfoProdSol1        := pCliente1.InfoProdSol; 
       
       vPersona2            := pCliente2.Persona; 
       vPersonaFisica2      := pCliente2.PersonaFisica; 
       vIdPersonas2         := pCliente2.IdPersonas;  
       vDirPersonas2        := pCliente2.DirPersonas;    
       vTelPersonas2        := pCliente2.TelPersonas;    
       vDirEnvioxPers2      := pCliente2.DirEnvioxPers;  
       vInfoLaboral2        := pCliente2.InfoLaboral;  
       vCtaCliOtrBancos2    := pCliente2.CtaCliOtrBancos;
       vRefPersonales2      := pCliente2.RefPersonales;
       vRefComerciales2     := pCliente2.RefComerciales; 
       vInfoProdSol2        := pCliente2.InfoProdSol; 
       
       -- Comparar
       vRetorno := vPersona1.Comparar(vPersona2);
       IF vRetorno = FALSE THEN
         RETURN vRetorno;
       END IF;
       
       vRetorno := vPersonaFisica1.Comparar(vPersonaFisica2);
       IF vRetorno = FALSE THEN
         RETURN vRetorno;
       END IF;
       /*
       FOR i IN 1 .. vIdPersonas1.COUNT LOOP
           vRetorno := vIdPersonas1(i).Comparar(vIdPersonas2(i));
           IF vRetorno = FALSE THEN
             RETURN vRetorno;
           END IF;
       END LOOP;
       
       FOR i IN 1 .. vDirPersonas1.COUNT LOOP
           vRetorno := vDirPersonas1(i).Comparar(vDirPersonas2(i));
           IF vRetorno = FALSE THEN
             RETURN vRetorno;
           END IF;
       END LOOP;
       
       FOR i IN 1 .. vTelPersonas1.COUNT LOOP
           vRetorno := vTelPersonas1(i).Comparar(vTelPersonas2(i));
           IF vRetorno = FALSE THEN
             RETURN vRetorno;
           END IF;
       END LOOP;
       
       
       vRetorno := vPersona1.Comparar(vPersona2);
       IF vRetorno = FALSE THEN
         RETURN vRetorno;
       END IF;
       vRetorno := vPersona1.Comparar(vPersona2);
       IF vRetorno = FALSE THEN
         RETURN vRetorno;
       END IF;
       vRetorno := vPersona1.Comparar(vPersona2);
       IF vRetorno = FALSE THEN
         RETURN vRetorno;
       END IF;
       vRetorno := vPersona1.Comparar(vPersona2);
       IF vRetorno = FALSE THEN
         RETURN vRetorno;
       END IF;
       vRetorno := vPersona1.Comparar(vPersona2);
       IF vRetorno = FALSE THEN
         RETURN vRetorno;
       END IF;
       vRetorno := vPersona1.Comparar(vPersona2);
       IF vRetorno = FALSE THEN
         RETURN vRetorno;
       END IF;
       */
        RETURN vRetorno; 
    END;
                                   
    
    PROCEDURE Doc_Fisica_nacional(pCod_Persona                    IN     VARCHAR2,
                                  pPind_Cedula                    IN     VARCHAR2,
                                  pPind_Licencia_Conducir         IN     VARCHAR2,
                                  pPind_Residencia                IN     VARCHAR2,
                                  pPind_Id_Otro                   IN     VARCHAR2,
                                  pId_Otro_Desc                   IN     VARCHAR2,
                                  pPind_Certificado_Nacimiento    IN     VARCHAR2,
                                  pPind_Pensionado_Jubilado       IN     VARCHAR2,
                                  pPind_Lab_Tiempo                IN     VARCHAR2,
                                  pPind_Lab_Ingreso_Anual         IN     VARCHAR2,
                                  pPind_Lab_Puesto_Desempena      IN     VARCHAR2,
                                  pPind_Trabaja_Independiente     IN     VARCHAR2,
                                  pPind_Independiente_Actividad   IN     VARCHAR2,
                                  pPindIndependienteJustificaA    IN     VARCHAR2,
                                  pComentarios_Adicionales        IN     VARCHAR2,      
                                  pError                          IN OUT VARCHAR) IS

        vError      PA.PKG_INFO_DOC_FISICA_NACIONAL.RESULTADO;                                  

    BEGIN
        PA.PKG_INFO_DOC_FISICA_NACIONAL.GENERAR(
                                                  pCod_Persona                    ,
                                                  pPind_Cedula                    ,
                                                  pPind_Licencia_Conducir         ,
                                                  pPind_Residencia                ,
                                                  pPind_Id_Otro                   ,
                                                  pId_Otro_Desc                   ,
                                                  pPind_Certificado_Nacimiento    ,
                                                  pPind_Pensionado_Jubilado       ,
                                                  pPind_Lab_Tiempo                ,
                                                  pPind_Lab_Ingreso_Anual         ,
                                                  pPind_Lab_Puesto_Desempena      ,
                                                  pPind_Trabaja_Independiente     ,
                                                  pPind_Independiente_Actividad   ,
                                                  pPindIndependienteJustificaA    ,
                                                  pComentarios_Adicionales        ,
                                                  vError
                                               );

        pError := vError.descripcion;                                
    END;
                                      
    FUNCTION Remover_Caracteres_Especiales(pData     IN VARCHAR2)
     RETURN VARCHAR2 IS
   
      vResult       VARCHAR2(4000);
      vExclusion    VARCHAR2(1000) := '!$%*+<=>?^_{|}~?¡¢£€¥Š§š©ª«¬®¯°±²³Žµ¶·ž¹º»Œœ¿ÀÂÃÅÆÇÈÊÌÎÐÒÔÕ×ØÙÛÞßàâãåæçèêìîðòôõ÷øùûýþ';
      vChar         VARCHAR2(1);
      nLength       NUMBER := 0;
    BEGIN    
        SELECT LENGTH(pData) INTO nLength FROM DUAL;
        
        vResult := PData;
        IF pData IS NOT NULL THEN
            FOR i IN 1..nLength LOOP
                vChar := SUBSTR(pData, i, 1);
                BEGIN 
                    SELECT REPLACE(vResult, vChar, '') INTO vResult FROM dual WHERE vExclusion LIKE '%'||vChar||'%';
                 
                EXCEPTION WHEN NO_DATA_FOUND THEN
                    NULL;
                END;
                
            END LOOP;
        END IF;
        
        RETURN RTRIM(LTRIM(vResult)); 
     
    END;                                                            

    PROCEDURE mapear_Direccion(inIdPais          IN     VARCHAR2,
                               inIdCanton        IN     VARCHAR2,
                               outCod_Provincia  IN OUT VARCHAR2,  
                               outCod_Canton      IN OUT VARCHAR2,
                               outCod_Distrito   IN OUT VARCHAR2,
                               outError          IN OUT VARCHAR2) IS
        vIdPais         VARCHAR2(10);                               
    BEGIN
        outError := NULL;
        IF inIdPais = 'DO' THEN
            vIdPais := 1;
        ELSE
            vIdPais := Remover_Caracteres_Especiales(inIdPais);
        END IF;
        
        BEGIN        
               
            SELECT cod_provincia, cod_canton, cod_distrito
              INTO outCod_Provincia, outCod_Canton, outCod_Distrito
              FROM pa.distritos
             WHERE cod_pais = vIdPais
               AND cod_canton   = TO_NUMBER( SUBSTR( Remover_Caracteres_Especiales(inIdCanton), 1, 2 ))
               AND cod_distrito = TO_NUMBER( SUBSTR( Remover_Caracteres_Especiales(inIdCanton), 3, 2 ));                   
        
        EXCEPTION WHEN NO_DATA_FOUND THEN
            outCod_Provincia   := NULL;
            outCod_Canton      := NULL;
            outCod_Distrito    := NULL;
            outError := 'Error Mapeando los códigos de la dirección ('||inIdCanton||').';
            RAISE_APPLICATION_ERROR(-20100, outError);
        END;
    END; 

END PKG_CLIENTE;
/