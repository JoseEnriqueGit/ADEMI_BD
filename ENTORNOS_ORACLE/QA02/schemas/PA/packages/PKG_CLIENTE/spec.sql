CREATE OR REPLACE PACKAGE PA.PKG_CLIENTE IS
   
    TYPE resultado IS RECORD
    (
        codigo        VARCHAR2 (30),
        descripcion   VARCHAR2 (4000)
    );
    
    FUNCTION Convertir_Cliente_Api(p_Json       IN     BLOB,
                                   p_error      IN OUT VARCHAR2) 
      RETURN PA.CLIENTES_PERSONA_FISICA_OBJ;

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
                                      
                                      -- Canal Solicitud
                                      inCanal               IN     PA.CANAL_SOLICITUD_OBJ DEFAULT NULL, 
                                         
                                      outCodCliente         IN OUT VARCHAR2,
                                      outError              IN OUT VARCHAR2);

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
                              outError              IN OUT VARCHAR2);

    PROCEDURE Generar_Persona_Fisica (pCliente          IN OUT PA.CLIENTES_OBJ,                      
                                      pResultado        IN OUT resultado);

    FUNCTION Consultar_Persona_Fisica (pCodPersona      IN VARCHAR2,
                                       pTipoId          IN NUMBER,
                                       pNumId           IN VARCHAR2)
      RETURN PA.CLIENTES_OBJ;
    
    FUNCTION CompararClientes(pCliente1          IN PA.CLIENTES_OBJ,
                              pCliente2          IN PA.CLIENTES_OBJ) 
      RETURN BOOLEAN;    
      
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
                                  pError                          IN OUT VARCHAR);      

     FUNCTION Remover_Caracteres_Especiales(pData     IN VARCHAR2)
     RETURN VARCHAR2;       
     
     PROCEDURE mapear_Direccion(inIdPais          IN     VARCHAR2,
                                inIdCanton        IN     VARCHAR2,
                                outCod_Provincia  IN OUT VARCHAR2,  
                                outCod_Canton     IN OUT VARCHAR2,
                                outCod_Distrito   IN OUT VARCHAR2,
                                outError          IN OUT VARCHAR2);                                                                         

END PKG_CLIENTE;
/

