CREATE OR REPLACE PACKAGE BODY TC.TC_SOLICITUD IS   
    FUNCTION Convertir_Solicitud_Api(p_Json       IN     BLOB,
                                   p_error      IN OUT VARCHAR2) 
      RETURN TC.SOLICITUD_TARJETA_OBJ IS
      
      j                     APEX_JSON.T_VALUES;
      l_clob                CLOB;
      l_dest_offset         PLS_INTEGER := 1;
      l_src_offset          PLS_INTEGER := 1;
      l_lang_context        PLS_INTEGER := DBMS_LOB.default_lang_ctx;
      l_warning             PLS_INTEGER;
      vFecha                VARCHAR2(30);
      vTotal                PLS_INTEGER := 0;
      vIndA                 PLS_INTEGER := 0;
      vEsEmpleado           BOOLEAN := false;
      
      vSolicitud            TC.SOLICITUD_TARJETA_OBJ := TC.SOLICITUD_TARJETA_OBJ();   
      vSolicitudAdicList    TC.TC_SOLICITUD_TAR_ADIC_LIST    := TC.TC_SOLICITUD_TAR_ADIC_LIST();      
      vSolicitudAdic        TC.TC_SOLICITUD_TAR_ADIC_OBJ    := TC.TC_SOLICITUD_TAR_ADIC_OBJ();
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
            
            vSolicitud                    := TC.SOLICITUD_TARJETA_OBJ();  
            vSolicitud.TipoIdentificacion := APEX_JSON.get_varchar2(p_values => j, p_path => 'SolicitudTarjeta.TipoIdentificacion');
            vSolicitud.Identificacion     := APEX_JSON.get_varchar2(p_values => j, p_path => 'SolicitudTarjeta.NumeroIdentificacion');       
            vSolicitud.OficinaOrigen      := APEX_JSON.get_varchar2(p_values => j, p_path => 'SolicitudTarjeta.OficinaOrigen');
            vSolicitud.CodigoCliente      := APEX_JSON.get_varchar2(p_values => j, p_path => 'SolicitudTarjeta.CodigoCliente');
            vSolicitud.NombrePlastico     := APEX_JSON.get_varchar2(p_values => j, p_path => 'SolicitudTarjeta.NombrePlastico');
            vSolicitud.TipoProducto       := APEX_JSON.get_varchar2(p_values => j, p_path => 'SolicitudTarjeta.TipoProducto');
            vSolicitud.TipoEmision        := APEX_JSON.get_varchar2(p_values => j, p_path => 'SolicitudTarjeta.TipoEmision');
            vSolicitud.FechaSolicitud     := SYSDATE;
            vSolicitud.TipoTarjeta        := APEX_JSON.get_varchar2(p_values => j, p_path => 'SolicitudTarjeta.TipoTarjeta');
            vSolicitud.OficinaEntrega     := APEX_JSON.get_varchar2(p_values => j, p_path => 'SolicitudTarjeta.OficinaEntrega');
            vSolicitud.CodPromotor        := APEX_JSON.get_varchar2(p_values => j, p_path => 'SolicitudTarjeta.CodPromotor');
            vSolicitud.CodCicloFact       := APEX_JSON.get_varchar2(p_values => j, p_path => 'SolicitudTarjeta.CodCicloFact');
            vSolicitud.TipoMonedaTarjeta  := APEX_JSON.get_varchar2(p_values => j, p_path => 'SolicitudTarjeta.TipoMonedaTarjeta');
            vSolicitud.MontoSolicitadoRD  := APEX_JSON.get_number(p_values => j, p_path => 'SolicitudTarjeta.MontoSolicitadoRD');
            vSolicitud.MontoSolicitadoUS  := APEX_JSON.get_number(p_values => j, p_path => 'SolicitudTarjeta.MontoSolicitadoUS');
            vEsEmpleado                   := APEX_JSON.get_boolean(p_values => j, p_path => 'SolicitudTarjeta.EsEmpleado');
            IF vEsEmpleado THEN
                vSolicitud.EsEmpleado         := 'S';
            ELSE
                vSolicitud.EsEmpleado         := 'N';
            END IF;
            vSolicitud.TipoGarantia       := APEX_JSON.get_varchar2(p_values => j, p_path => 'SolicitudTarjeta.TipoGarantia');
            vSolicitud.ValorGarantia      := APEX_JSON.get_varchar2(p_values => j, p_path => 'SolicitudTarjeta.ValorGarantia');
            vSolicitud.CodigoActividad    := APEX_JSON.get_varchar2(p_values => j, p_path => 'SolicitudTarjeta.CodigoActividad');
            vSolicitud.CodPaisEnvio       := APEX_JSON.get_varchar2(p_values => j, p_path => 'SolicitudTarjeta.DireccionEnvio.CodPaisEnvio');
            vSolicitud.CodRegionEnvio     := APEX_JSON.get_varchar2(p_values => j, p_path => 'SolicitudTarjeta.DireccionEnvio.CodRegionEnvio');
            vSolicitud.CodProvinciaEnvio  := APEX_JSON.get_varchar2(p_values => j, p_path => 'SolicitudTarjeta.DireccionEnvio.CodProvinciaEnvio');
            vSolicitud.CodMunicipioEnvio  := APEX_JSON.get_varchar2(p_values => j, p_path => 'SolicitudTarjeta.DireccionEnvio.CodMunicipioEnvio');
            vSolicitud.CodPuebloEnvio     := APEX_JSON.get_varchar2(p_values => j, p_path => 'SolicitudTarjeta.DireccionEnvio.CodPuebloEnvio');
            vSolicitud.Sector             := APEX_JSON.get_varchar2(p_values => j, p_path => 'SolicitudTarjeta.DireccionEnvio.Sector');
            vSolicitud.Barrio             := APEX_JSON.get_varchar2(p_values => j, p_path => 'SolicitudTarjeta.DireccionEnvio.Barrio');
            vSolicitud.Calle              := APEX_JSON.get_varchar2(p_values => j, p_path => 'SolicitudTarjeta.DireccionEnvio.Calle');
            vSolicitud.Numero             := APEX_JSON.get_varchar2(p_values => j, p_path => 'SolicitudTarjeta.DireccionEnvio.Numero');
            vSolicitud.Direccion          := vSolicitud.Barrio ||' Calle '|| vSolicitud.Calle ||' No.'|| vSolicitud.Numero;           
            
            vTotal := APEX_JSON.get_count(p_values => j, p_path => 'SolicitudTarjeta.SolicitudAdicional');
            vSolicitudAdicList := TC.TC_SOLICITUD_TAR_ADIC_LIST();    
            IF vTotal > 0 THEN
                
                FOR i IN 1 .. vTotal LOOP
                    vSolicitudAdic := TC.TC_SOLICITUD_TAR_ADIC_OBJ();
                    vSolicitudAdic.PRIMER_NOMBRE            := APEX_JSON.get_varchar2(p_values => j, p_path => 'SolicitudTarjeta.SolicitudAdicional[%d].PrimerNombre', p0 => i);
                    vSolicitudAdic.SEGUNDO_NOMBRE           := APEX_JSON.get_varchar2(p_values => j, p_path => 'SolicitudTarjeta.SolicitudAdicional[%d].SegundoNombre', p0 => i);
                    vSolicitudAdic.PRIMER_APELLIDO          := APEX_JSON.get_varchar2(p_values => j, p_path => 'SolicitudTarjeta.SolicitudAdicional[%d].PrimerApellido', p0 => i);
                    vSolicitudAdic.SEGUNDO_APELLIDO         := APEX_JSON.get_varchar2(p_values => j, p_path => 'SolicitudTarjeta.SolicitudAdicional[%d].SegundoApellido', p0 => i);
                    vSolicitudAdic.NOMBRE_PLASTICO          := APEX_JSON.get_varchar2(p_values => j, p_path => 'SolicitudTarjeta.SolicitudAdicional[%d].NombrePlastico', p0 => i);
                    vSolicitudAdic.COD_PARENTESCO           := APEX_JSON.get_varchar2(p_values => j, p_path => 'SolicitudTarjeta.SolicitudAdicional[%d].Parentesco', p0 => i);
                    vFecha                                  := APEX_JSON.get_varchar2(p_values => j, p_path => 'SolicitudTarjeta.SolicitudAdicional[%d].FechaNacimiento', p0 => i);
                    vSolicitudAdic.FECHA_NACIMIENTO         := TO_DATE(vFecha, 'DD-MM-YYYY');
                    vSolicitudAdic.TIPO_IDENTIFICACION      := APEX_JSON.get_varchar2(p_values => j, p_path => 'SolicitudTarjeta.SolicitudAdicional[%d].TipoIdentificacion', p0 => i);
                    vSolicitudAdic.IDENTIFICACION           := APEX_JSON.get_varchar2(p_values => j, p_path => 'SolicitudTarjeta.SolicitudAdicional[%d].NumeroIdentificacion', p0 => i);
                    vSolicitudAdic.EMAIL                    := APEX_JSON.get_varchar2(p_values => j, p_path => 'SolicitudTarjeta.SolicitudAdicional[%d].Email', p0 => i);
                    vSolicitudAdic.SEXO                     := APEX_JSON.get_varchar2(p_values => j, p_path => 'SolicitudTarjeta.SolicitudAdicional[%d].Sexo', p0 => i);
                    vSolicitudAdic.ESTADO_CIVIL             := APEX_JSON.get_varchar2(p_values => j, p_path => 'SolicitudTarjeta.SolicitudAdicional[%d].EstadoCivil', p0 => i);
                    vSolicitudAdic.LIMITE_SOLICITADO_RD     := APEX_JSON.get_number(p_values => j, p_path => 'SolicitudTarjeta.SolicitudAdicional[%d].MontoSolicitadoRD', p0 => i);
                    vSolicitudAdic.LIMITE_SOLICITADO_US     := APEX_JSON.get_number(p_values => j, p_path => 'SolicitudTarjeta.SolicitudAdicional[%d].MontoSolicitadoUS', p0 => i);
                    vSolicitudAdicList.EXTEND;
                    vIndA := vIndA + 1;
                    vSolicitudAdicList(vIndA) := vSolicitudAdic;
                END LOOP;
            END IF;
            vSolicitud.SolicitudAdicional := vSolicitudAdicList;
        ELSE
            p_error := p_error || ' Error - El JSON está vacio.';
            RAISE_APPLICATION_ERROR(-20100, p_error);
        END IF; 
        
        DBMS_LOB.FREETEMPORARY(l_clob);
        
        RETURN vSolicitud;
        
    EXCEPTION WHEN OTHERS THEN
        p_error := SQLERRM||' '||dbms_utility.format_error_backtrace;
        RETURN vSolicitud;
    END Convertir_Solicitud_Api;
    
    PROCEDURE procesar_solicitud_api (
        inSolicitudTarjeta       IN     TC.SOLICITUD_TARJETA_OBJ,
        outSolicitudNumero          OUT VARCHAR2,
        outError                 IN OUT VARCHAR2) IS
        vValorGarantia         NUMBER;
        vFecha_nacimiento      DATE;
        vNum_dependientes      NUMBER;
        vExtTelefono           NUMBER := 0;
        vZPostalCorresp        NUMBER := 0;
        vSolicitudNumero       NUMBER := 0;
        vSolicitudAdicNumero   NUMBER := 0;
        vFechaNacAdic          DATE;
        vParentescoAdic        NUMBER;
        vLimiteSolRDAdic       NUMBER := 0;
        vLimiteSolUSAdic       NUMBER := 0;
        vEsCliente             NUMBER := 0;
        vTipoId                PA.ID_PERSONAS.COD_TIPO_ID%TYPE;
        vNumId                 PA.ID_PERSONAS.NUM_ID%TYPE; 
        vCod_Pais              SECTORES.COD_PAIS%TYPE;
        vCod_Provincia         SECTORES.COD_PROVINCIA%TYPE;
        vCod_Canton            SECTORES.COD_CANTON%TYPE;
        vCod_Distrito          SECTORES.COD_DISTRITO%TYPE;
        vCod_Pueblo            SECTORES.COD_PUEBLO%TYPE;
        vCod_Sector            SECTORES.COD_SECTOR%TYPE;
        outApellido1           PA.PERSONAS_FISICAS.PRIMER_APELLIDO%TYPE;
        outApellido2           PA.PERSONAS_FISICAS.SEGUNDO_APELLIDO%TYPE;
        outPrimerNombre        PA.PERSONAS_FISICAS.PRIMER_NOMBRE%TYPE;
        outSegundoNombre       PA.PERSONAS_FISICAS.SEGUNDO_NOMBRE%TYPE;
        outEstado_civil        PA.PERSONAS_FISICAS.EST_CIVIL%TYPE;
        outSexo                PA.PERSONAS_FISICAS.SEXO%TYPE;
        outEmail               VARCHAR2 (300);
        outTelefono            VARCHAR2 (60);
        outTELEFONO_CORRESP    VARCHAR2(60);
        outProfesion           VARCHAR2(500);  
        outTipoVivienda        VARCHAR2(60);
        vNombrePlastico        VARCHAR2(60);
    BEGIN
        outError          := NULL;
        vValorGarantia    := 0;
        --vFecha_nacimiento := TO_DATE (outFecha_nacimiento, 'DD/MM/YYYY HH24:MI:SS');
        vNum_dependientes := 0;
        --DBMS_OUTPUT.PUT_LINE ( 'inSolicitudTarjeta.CodigoCliente = ' || inSolicitudTarjeta.CodigoCliente );
        IF inSolicitudTarjeta.CodigoCliente IS NOT NULL AND inSolicitudTarjeta.CodigoCliente <> 0 THEN
            BEGIN
                -- Verifica si el cliente existe
                SELECT 1, C.CODIGO_TIPO_IDENTIFICACION, C.NUMERO_IDENTIFICACION 
                  INTO vEsCliente, vTipoId, vNumId              
                  FROM PA.CLIENTES_B2000 C
                 WHERE C.CODIGO_EMPRESA = '1'
                   AND C.CODIGO_CLIENTE = inSolicitudTarjeta.CodigoCliente;
            EXCEPTION WHEN NO_DATA_FOUND THEN
                vEsCliente := 0;
            END;                        
            

            IF vEsCliente > 0 THEN
                IF NVL(inSolicitudTarjeta.EsEmpleado,'X') NOT IN ('X','S') THEN
                
                    vTipoId := nvl(inSolicitudTarjeta.TipoIdentificacion, vTipoId);
                    vNumId := PA.Formato_Cedula(nvl(inSolicitudTarjeta.Identificacion, vNumId), vTipoId, outError);
                    DBMS_OUTPUT.PUT_LINE ( 'vEsCliente = ' || vEsCliente ||' Tipo ='||vTipoId||' Numero='||vNumId);
                    -- Determinar el Sector
                    BEGIN
                        SELECT Cod_pais, Cod_Provincia, Cod_Canton, Cod_Distrito, Cod_Pueblo, Cod_Sector
                          INTO vCod_pais, vCod_Provincia, vCod_Canton, vCod_Distrito, vCod_Pueblo, vCod_Sector
                          FROM Sectores
                         WHERE Cod_Pais = inSolicitudTarjeta.CodPaisEnvio
                           AND Cod_Sector = inSolicitudTarjeta.Sector;
                    EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                            vCod_Provincia  := inSolicitudTarjeta.CodRegionEnvio;
                            vCod_Canton     := inSolicitudTarjeta.CodProvinciaEnvio;
                            vCod_Distrito   := inSolicitudTarjeta.CodMunicipioEnvio;
                            vCod_Pueblo     := inSolicitudTarjeta.CodPuebloEnvio;
                            vCod_Sector     := inSolicitudTarjeta.Sector;
                    END;

                    BEGIN
                        procesar_solicitud (
                            inOficinaOrigen       => inSolicitudTarjeta.OficinaOrigen,
                            inTipoId              => vTipoId,
                            inNumId               => vNumId,
                            inNombrePlastico      => inSolicitudTarjeta.NombrePlastico,
                            inTipoProducto        => inSolicitudTarjeta.TipoProducto,
                            inTipoEmision         => inSolicitudTarjeta.TipoEmision,
                            inFechaSolicitud      => SYSDATE,
                            inTipoTarjeta         => inSolicitudTarjeta.TipoTarjeta,
                            inOficinaEntrega      => inSolicitudTarjeta.OficinaEntrega,
                            inCodPromotor         => inSolicitudTarjeta.CodPromotor,
                            inCodCicloFact        => inSolicitudTarjeta.CodCicloFact,
                            inTipoMonedaTarjeta   => inSolicitudTarjeta.TipoMonedaTarjeta,
                            inMontoSolicitadoRD   => NVL(inSolicitudTarjeta.MontoSolicitadoRD, '0'),
                            inMontoSolicitadoUS   => NVL(inSolicitudTarjeta.MontoSolicitadoUS, '0'),
                            inEsEmpleado          => inSolicitudTarjeta.EsEmpleado,
                            inTipoGarantia        => inSolicitudTarjeta.TipoGarantia,
                            inValorGarantia       => inSolicitudTarjeta.ValorGarantia,
                            inSegregacionRD       => inSolicitudTarjeta.CodigoActividad,
                            outEstado_civil       => outEstado_civil,
                            outSexo               => outSexo,
                            outFecha_nacimiento   => vFecha_nacimiento,
                            outApellido1          => outApellido1,
                            outApellido2          => outApellido2,
                            outPrimerNombre       => outPrimerNombre,
                            outSegundoNombre      => outSegundoNombre,
                            outNum_dependientes   => vNum_dependientes,
                            outProfesion          => outProfesion,
                            outTipoVivienda       => outTipoVivienda,
                            outCodPais            => vCod_Pais,
                            outCodProvincia       => vCod_Provincia,
                            outCodCanton          => vCod_Canton,
                            outCodDistrito        => vCod_Distrito,
                            outCodCiudad          => vCod_Pueblo,
                            inSector_Res          => inSolicitudTarjeta.Sector,
                            inBarrio_Res          => inSolicitudTarjeta.Barrio,
                            inCalle_Res           => inSolicitudTarjeta.Calle,
                            inNumero_Res          => inSolicitudTarjeta.Numero,
                            inDetalle_Res         => inSolicitudTarjeta.Direccion,
                            outTELEFONO_CORRESP   => outTELEFONO_CORRESP,
                            outExtTelefono        => vExtTelefono,
                            outZPostalCorresp     => vZPostalCorresp,
                            outEmail              => outEmail,
                            outTelefono           => outTelefono,
                            outSolicitudNumero    => vSolicitudNumero,
                            outError              => outError);
                         DBMS_OUTPUT.PUT_LINE ( 'vSolicitudNumero = ' || vSolicitudNumero );
                        IF outError IS NOT NULL AND UPPER(outError) LIKE '%ERROR%' THEN
                            RAISE_APPLICATION_ERROR (-20100, outError);
                        END IF;

                        outSolicitudNumero := NVL (TO_CHAR(vSolicitudNumero), '0');
                    EXCEPTION
                        WHEN OTHERS THEN
                            outSolicitudNumero := '0';

                            IF outError IS NULL THEN
                                outError := SUBSTR (SQLERRM, 1, 4000);
                            END IF;

                            RAISE_APPLICATION_ERROR (-20105, 'SOLICITUD: ' || outError, FALSE);
                    END;

                    IF vSolicitudNumero IS NOT NULL AND vSolicitudNumero > 0 THEN
                        FOR a IN 1 .. inSolicitudTarjeta.SolicitudAdicional.COUNT LOOP
                            IF inSolicitudTarjeta.SolicitudAdicional (a).IDENTIFICACION IS NOT NULL THEN
                                BEGIN
                                    vFechaNacAdic       := inSolicitudTarjeta.SolicitudAdicional(a).FECHA_NACIMIENTO;
                                    vParentescoAdic     := inSolicitudTarjeta.SolicitudAdicional(a).COD_PARENTESCO;
                                    vLimiteSolRDAdic    := inSolicitudTarjeta.SolicitudAdicional(a).LIMITE_SOLICITADO_RD;
                                    vLimiteSolUSAdic    := inSolicitudTarjeta.SolicitudAdicional(a).LIMITE_SOLICITADO_US;
                                    vNombrePlastico     := inSolicitudTarjeta.SolicitudAdicional(a).NOMBRE_PLASTICO;
                                    
                                    -- Adicional 1
                                    procesar_adicional (
                                        pNo_Solicitud         => vSolicitudNumero,
                                        pTipo_Identificacion  => Remover_Caracteres_Especiales (inSolicitudTarjeta.SolicitudAdicional(a).TIPO_IDENTIFICACION),
                                        pIdentificacion       => Remover_Caracteres_Especiales (inSolicitudTarjeta.SolicitudAdicional(a).IDENTIFICACION),
                                        pPrimer_Nombre        => outPrimerNombre,
                                        pSegundo_Nombre       => outSegundoNombre,
                                        pPrimer_Apellido      => outApellido1,
                                        pSegundo_Apellido     => outApellido2,
                                        pNombre_Plastico      => vNombrePlastico,
                                        pFechaNacimiento      => vFechaNacAdic,
                                        pSexo                 => outSexo,
                                        pEstado_civil         => outEstado_civil,
                                        pEmail                => outEmail,
                                        pTelefono             => outTelefono,
                                        pCod_Parentesco       => vParentescoAdic,
                                        pSecuencia            => a,
                                        pLimite_Solicitado_Rd => vLimiteSolRDAdic,
                                        pLimite_Solicitado_Us => vLimiteSolUSAdic,
                                        outNo_Solicitud_Adi   => vSolicitudAdicNumero,
                                        outError              => outError);
                                EXCEPTION
                                    WHEN OTHERS THEN
                                        vSolicitudAdicNumero := '0';

                                        IF outError IS NULL THEN
                                            outError := SUBSTR (SQLERRM, 1, 4000);
                                        END IF;

                                        RAISE_APPLICATION_ERROR (-20105, 'ADICIONAL ' || a || ' ' || outError);
                                END;
                            END IF;
                        END LOOP;
                    END IF;

                    
                END IF;
                
            DECLARE
                   vURL                 VARCHAR2(4000);
                   vIdAplication        PLS_INTEGER := 7; -- Tarjetas
                   vIdTipoDocumento     PLS_INTEGER := '429'; -- Formulario de Conozca
                   vCodigoReferencia    VARCHAR2(100) := vSolicitudNumero; --pCodigoCliente||':'||vSolicitudNumero;
                   vDocumento           VARCHAR2(30) := 'FCSCPF';
                BEGIN
                
                
                   -- Generar Conozca Su Cliente para File Flow 
                   vDocumento       := 'FCSCPF';
                   vIdTipoDocumento := '429';
                   vUrl := PA.PKG_TIPO_DOCUMENTO_PKM.UrlConozcaSuCliente2(pCodCliente => inSolicitudTarjeta.CodigoCliente, pEmpresa => '1');                   
                   PA.PKG_TIPO_DOCUMENTO_PKM.InsertUrlReporte( pCodigoReferencia   => vCodigoReferencia,
                                                    pFechaReporte       => SYSDATE,
                                                    pId_Aplicacion      => vIdAplication,
                                                    pIdTipoDocumento    => vIdTipoDocumento,
                                                    pOrigenPkm          => 'Tarjeta',  
                                                    pUrlReporte         => vUrl, 
                                                    pFormatoDocumento   => 'PDF',
                                                    pNombreArchivo      => vDocumento||'_'||vSolicitudNumero||'_'||inSolicitudTarjeta.CodigoCliente||'.pdf',   
                                                    pRespuesta          => outError
                                                   );
                                
                   
                   -- Formulario Solicitud de Tarjeta de Crédito
                   vDocumento       := 'SolicitudTarjeta';
                   vIdTipoDocumento := '424';
                   vUrl := PA.PKG_TIPO_DOCUMENTO_PKM.UrlSolicitudTarjeta(pNoSolicitud => vSolicitudNumero);                   
                   PA.PKG_TIPO_DOCUMENTO_PKM.InsertUrlReporte( pCodigoReferencia   => vCodigoReferencia,
                                                    pFechaReporte       => SYSDATE,
                                                    pId_Aplicacion      => vIdAplication,
                                                    pIdTipoDocumento    => vIdTipoDocumento,
                                                    pOrigenPkm          => 'Tarjeta',  
                                                    pUrlReporte         => vUrl, 
                                                    pFormatoDocumento   => 'PDF',
                                                    pNombreArchivo      => vDocumento||'_'||vSolicitudNumero||'_'||inSolicitudTarjeta.CodigoCliente||'.pdf',   
                                                    pRespuesta          => outError
                                                   );
                                                   
                                                                               
                    vIdTipoDocumento := '428';  -- CONSULTA BURO DE CREDITO PRIVADO 
                    vDocumento       := 'BURO';  
                    vCodigoReferencia := vTipoId||':'||vNumId||':'||vSolicitudNumero||': :'||vDocumento||': '; 
                    --vNombreArchivo    := vDocumento||'_'||vSolicitudNumero||'_'||inSolicitudTarjeta.CodigoCliente;                                                   
                    PA.PKG_TIPO_DOCUMENTO_PKM.InsertUrlReporte( pCodigoReferencia   => vCodigoReferencia,
                                                    pFechaReporte       => SYSDATE,
                                                    pId_Aplicacion      => vIdAplication,
                                                    pIdTipoDocumento    => vIdTipoDocumento,
                                                    pOrigenPkm          => 'Tarjeta',  
                                                    pUrlReporte         => NULL, 
                                                    pFormatoDocumento   => 'PDF',
                                                    pNombreArchivo      => vDocumento||'_'||vSolicitudNumero||'_'||inSolicitudTarjeta.CodigoCliente||'.pdf',   
                                                    pEstado             => 'R',
                                                    pRespuesta          => outError
                                                   );
                
                    vIdTipoDocumento := '527';  -- CONSULTA BUSCADOR DE GOOGLE
                    vDocumento       := 'SIB';  
                    vCodigoReferencia := vTipoId||':'||vNumId||':'||vSolicitudNumero||': :'||vDocumento;     
                    --vNombreArchivo    := vDocumento||'_'||vSolicitudNumero||'_'||inSolicitudTarjeta.CodigoCliente;                                                                                                 
                    PA.PKG_TIPO_DOCUMENTO_PKM.InsertUrlReporte( pCodigoReferencia   => vCodigoReferencia,
                                                    pFechaReporte       => SYSDATE,
                                                    pId_Aplicacion      => vIdAplication,
                                                    pIdTipoDocumento    => vIdTipoDocumento,
                                                    pOrigenPkm          => 'Tarjeta',  
                                                    pUrlReporte         => NULL, 
                                                    pFormatoDocumento   => 'PDF',
                                                    pNombreArchivo      => vDocumento||'_'||vSolicitudNumero||'_'||inSolicitudTarjeta.CodigoCliente||'.pdf',   
                                                    pEstado             => 'R',
                                                    pRespuesta          => outError
                                                   );
                    -- Generar LEXISNEXIS para File Flow                                
                    vIdTipoDocumento := '511';
                    vDocumento := 'LEXISNEXIS';
                    vCodigoReferencia := vTipoId||':'||vNumId||':'||vSolicitudNumero||': :'||vDocumento;
                            PA.PKG_TIPO_DOCUMENTO_PKM.InsertUrlReporte(
                                pCodigoReferencia   => vCodigoReferencia,
                                pFechaReporte       => SYSDATE,
                                pId_Aplicacion      => vIdAplication,
                                pIdTipoDocumento    => vIdTipoDocumento,
                                pOrigenPkm          => 'Tarjeta',
                                pUrlReporte         => NULL,
                                pFormatoDocumento   => 'PDF',
                                pNombreArchivo      => vDocumento||'_'||vSolicitudNumero||'_'||inSolicitudTarjeta.CodigoCliente||'.pdf',
                                pEstado             => 'R',
                                pRespuesta          => outError);                                                             
                   
                EXCEPTION WHEN OTHERS THEN 
                   outError := outError||' '||dbms_utility.format_error_backtrace;      
                   RAISE_APPLICATION_ERROR(-20104, outError);
                END;
                
                DBMS_OUTPUT.PUT_LINE ( 'vSolicitudNumero = ' || vSolicitudNumero );
                
                IF outError IS NULL AND vSolicitudNumero > 0 THEN
                    outError := 'Solicitud '|| vSolicitudNumero || ' creada satisfactoriamente.';
                    COMMIT;                
                END IF;
                
            ELSIF inSolicitudTarjeta.EsEmpleado = 'X' THEN
                outError := 'Rechazado porque es un empleado';
            END IF;
        ELSIF NVL (vEsCliente, 0) = 0 THEN
            outError := 'Esta persona no está creado como Cliente, favor verificar...' || inSolicitudTarjeta.CodigoCliente;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            outSolicitudNumero := '0';

            IF outError IS NULL THEN
                outError := SQLERRM||' '||dbms_utility.format_error_backtrace;
            END IF;

            ROLLBACK;
            --INSERT INTO tc.datatemptc (CAMPO, FECHA, VALOR) VALUES ('TC_SOLICITUD ERROR', SYSDATE, outError); commit;
            RETURN;
    END;

   PROCEDURE generar_solicitud( inOficinaOrigen           IN     VARCHAR2,                                
                                inTipoId                  IN     VARCHAR2, 
                                inNumId                   IN     VARCHAR2,
                                inNombrePlastico          IN     VARCHAR2,
                                inTipoProducto            IN     VARCHAR2,
                                inTipoEmision             IN     VARCHAR2,
                                inFechaSolicitud          IN     VARCHAR2,
                                inTipoTarjeta             IN     VARCHAR2,      -- P = PRINCIPAL, A = ADICIONAL  
                                inOficinaEntrega          IN     VARCHAR2,
                                inCodPromotor             IN     VARCHAR2,
                                inCodCicloFact            IN     VARCHAR2, 
                                inTipoMonedaTarjeta       IN     VARCHAR2, 
                                inMontoSolicitadoRD       IN     VARCHAR2,
                                inMontoSolicitadoUS       IN     VARCHAR2, 
                                inEsEmpleado              IN     VARCHAR2,      -- S = Continuar si es empleado    
                                inTipoGarantia            IN     VARCHAR2, 
                                inValorGarantia           IN     VARCHAR2,  
                                inSegregacionRD           IN     VARCHAR2,                 
                                outEstado_civil           IN OUT VARCHAR2,
                                outSexo                   IN OUT VARCHAR2,
                                outFecha_nacimiento       IN OUT VARCHAR2,
                                outApellido1              IN OUT VARCHAR2,
                                outApellido2              IN OUT VARCHAR2,
                                outPrimerNombre           IN OUT VARCHAR2,
                                outSegundoNombre          IN OUT VARCHAR2,
                                outNum_dependientes       IN OUT VARCHAR2,
                                outProfesion              IN OUT VARCHAR2,
                                outTipoVivienda           IN OUT VARCHAR2,
                                outCodPais                IN OUT VARCHAR2,
                                outCodProvincia           IN OUT VARCHAR2,
                                outCodCanton              IN OUT VARCHAR2,
                                outCodDistrito            IN OUT VARCHAR2,
                                outCodCiudad              IN OUT VARCHAR2,
                                inSector_Res              IN     VARCHAR2,
                                inBarrio_Res              IN     VARCHAR2,
                                inCalle_Res               IN     VARCHAR2,
                                inNumero_Res              IN     VARCHAR2,
                                inDetalle_Res             IN     VARCHAR2,
                                outTELEFONO_CORRESP       IN OUT VARCHAR2,
                                outExtTelefono            IN OUT VARCHAR2,
                                outZPostalCorresp         IN OUT VARCHAR2,
                                outEmail                  IN OUT VARCHAR2,
                                outTelefono               IN OUT VARCHAR2,
                                outSolicitudNumero        IN OUT VARCHAR2,
                                inTipoIdAdic1             IN     VARCHAR2,
                                inIdentAdic1              IN     VARCHAR2,
                                outPrimerNombreAdic1      IN OUT VARCHAR2,
                                outSegundoNombreAdic1     IN OUT VARCHAR2,
                                outPrimerApellidoAdic1    IN OUT VARCHAR2,
                                outSegundoApellidoAdic1   IN OUT VARCHAR2,
                                outNombrePlasticoAdic1    IN OUT VARCHAR2,
                                outFechaNacimientoAdic1   IN OUT VARCHAR2,
                                outSexoAdic1              IN OUT VARCHAR2,
                                outEstadoCivilAdic1       IN OUT VARCHAR2,
                                outEmailAdic1             IN OUT VARCHAR2,
                                outTelefonoAdic1          IN OUT VARCHAR2,
                                inParentescoAdic1         IN     VARCHAR2,
                                inLimiteSolicitadoRDAdic1 IN     VARCHAR2,
                                inLimiteSolicitadoUSAdic1 IN     VARCHAR2,
                                outNo_Solicitud_Adic1     IN OUT VARCHAR2,                                
                                inTipoIdAdic2             IN     VARCHAR2,
                                inIdentAdic2              IN     VARCHAR2,
                                outPrimerNombreAdic2      IN OUT VARCHAR2,
                                outSegundoNombreAdic2     IN OUT VARCHAR2,
                                outPrimerApellidoAdic2    IN OUT VARCHAR2,
                                outSegundoApellidoAdic2   IN OUT VARCHAR2,
                                outNombrePlasticoAdic2    IN OUT VARCHAR2,
                                outFechaNacimientoAdic2   IN OUT VARCHAR2,
                                outSexoAdic2              IN OUT VARCHAR2,
                                outEstadoCivilAdic2       IN OUT VARCHAR2,
                                outEmailAdic2             IN OUT VARCHAR2,
                                outTelefonoAdic2          IN OUT VARCHAR2,
                                inParentescoAdic2         IN     VARCHAR2,
                                inLimiteSolicitadoRDAdic2 IN     VARCHAR2,
                                inLimiteSolicitadoUSAdic2 IN     VARCHAR2,
                                outNo_Solicitud_Adic2     IN OUT VARCHAR2,                                
                                outError                  IN OUT VARCHAR2) IS
                                
    vFechaSolicitud      DATE;
    vMontoSolicitadoRD   NUMBER;
    vMontoSolicitadoUS   NUMBER;
    vValorGarantia       NUMBER;
    vFecha_nacimiento    DATE;
    vNum_dependientes    NUMBER;
    vExtTelefono         NUMBER:=0;
    vZPostalCorresp      NUMBER:=0;
    vSolicitudNumero     NUMBER:=0;
    vSolicitudAdicNumero NUMBER:=0;
    vFechaNacAdic        DATE;
    vParentescoAdic      NUMBER;
    vLimiteSolRDAdic     NUMBER := 0;
    vLimiteSolUSAdic     NUMBER := 0;
    
 --   vParametros CLOB; 
                                    
   BEGIN      
        outError:= NULL;
        outSolicitudNumero := ' ';       
         
          vFechaSolicitud     := SYSDATE; --TO_DATE(NVL(inFechaSolicitud,SYSDATE),'DD/MM/YYYY');
          vMontoSolicitadoRD  := TO_NUMBER(NVL(inMontoSolicitadoRD,'0'));
          vMontoSolicitadoUS  := TO_NUMBER(NVL(inMontoSolicitadoUS,'0'));          
          vValorGarantia      := 0;--TO_NUMBER(NVL(inValorGarantia,'0'));
          vFecha_nacimiento   := TO_DATE(outFecha_nacimiento,'DD/MM/YYYY HH24:MI:SS');
          vNum_dependientes   := 0;--TO_NUMBER(NVL(Remover_Caracteres_Especiales(outNum_dependientes),'0'));
          outCodCiudad        := NVL(outCodCiudad,1);
--DBMS_OUTPUT.PUT_LINE('Monto RD$'||vMontoSolicitadoRD  ||' '|| TO_NUMBER(NVL(inMontoSolicitadoRD,'0'))||' MontoUS$'||vMontoSolicitadoUS||' '||TO_NUMBER(NVL(inMontoSolicitadoUS,'0')));
--DBMS_OUTPUT.PUT_LINE(' Pais='||outCodPais||' Provincia='||outCodProvincia||' Canton='||outCodCanton||' Distrito='||outCodDistrito||' Ciudad='||outCodCiudad||' Sector='||inSector_Res);          

          BEGIN  
              procesar_solicitud( inOficinaOrigen      => inOficinaOrigen,                                
                                  inTipoId             => inTipoId, 
                                  inNumId              => inNumId,
                                  inNombrePlastico     => inNombrePlastico,
                                  inTipoProducto       => inTipoProducto,
                                  inTipoEmision        => inTipoEmision,
                                  inFechaSolicitud     => vFechaSolicitud,
                                  inTipoTarjeta        => inTipoTarjeta,        
                                  inOficinaEntrega     => inOficinaEntrega,
                                  inCodPromotor        => inCodPromotor,
                                  inCodCicloFact       => inCodCicloFact, 
                                  inTipoMonedaTarjeta  => inTipoMonedaTarjeta, 
                                  inMontoSolicitadoRD  => vMontoSolicitadoRD,
                                  inMontoSolicitadoUS  => vMontoSolicitadoUS,
                                  inEsEmpleado         => inEsEmpleado,          
                                  inTipoGarantia       => inTipoGarantia, 
                                  inValorGarantia      => vValorGarantia, 
                                  inSegregacionRD      => inSegregacionRD,                 
                                  outEstado_civil      => outEstado_civil,
                                  outSexo              => outSexo,
                                  outFecha_nacimiento  => vFecha_nacimiento,
                                  outApellido1         => outApellido1,
                                  outApellido2         => outApellido2,
                                  outPrimerNombre      => outPrimerNombre,
                                  outSegundoNombre     => outSegundoNombre,
                                  outNum_dependientes  => vNum_dependientes,
                                  outProfesion         => outProfesion,
                                  outTipoVivienda      => outTipoVivienda,
                                  outCodPais           => outCodPais,
                                  outCodProvincia      => outCodProvincia,
                                  outCodCanton         => outCodCanton,
                                  outCodDistrito       => outCodDistrito,
                                  outCodCiudad         => outCodCiudad,
                                  inSector_Res         => inSector_Res ,
                                  inBarrio_Res         => inBarrio_Res,
                                  inCalle_Res          => inCalle_Res,
                                  inNumero_Res         => inNumero_Res,
                                  inDetalle_Res        => inDetalle_Res,
                                  outTELEFONO_CORRESP  => outTELEFONO_CORRESP,
                                  outExtTelefono       => vExtTelefono,
                                  outZPostalCorresp    => vZPostalCorresp,
                                  outEmail             => outEmail,
                                  outTelefono          => outTelefono,
                                  outSolicitudNumero   => vSolicitudNumero,
                                  outError             => outError);

              IF outError IS NOT NULL THEN
                outSolicitudNumero := '0';
                RAISE_APPLICATION_ERROR(-20100, outError);
              END IF;
              
              outFecha_nacimiento  := TO_CHAR(vFecha_nacimiento,'DD/MM/YYYY');
              outNum_dependientes  := TO_CHAR(vNum_dependientes);
              outExtTelefono       := TO_CHAR(vExtTelefono);
              outZPostalCorresp    := TO_CHAR(vZPostalCorresp);
              outSolicitudNumero   := NVL(TO_CHAR(vSolicitudNumero),0);
              vFecha_nacimiento    := NULL;              
                                  
          EXCEPTION WHEN OTHERS THEN
              outSolicitudNumero := '0';
              IF outError IS NULL THEN
                outError := SUBSTR(SQLERRM,1, 4000);
              END IF;
              RAISE_APPLICATION_ERROR(-20105, 'SOLICITUD: '||outError, FALSE);
          END;
          
          IF vSolicitudNumero IS NOT NULL  AND vSolicitudNumero > 0 THEN
              IF inIdentAdic1 IS NOT NULL THEN
                  BEGIN
                        vFechaNacAdic       := TO_DATE(outFechaNacimientoAdic1, 'DD/MM/YYYY');
                        vParentescoAdic     := TO_NUMBER(inParentescoAdic1);
                        vLimiteSolRDAdic    := TO_NUMBER(inLimiteSolicitadoRDAdic1);
                        vLimiteSolUSAdic    := TO_NUMBER(inLimiteSolicitadoUSAdic1);  
                        -- Adicional 1
                        procesar_adicional(pNo_Solicitud           => vSolicitudNumero,                                                                
                                           pTipo_Identificacion    => Remover_Caracteres_Especiales(inTipoIdAdic1),
                                           pIdentificacion         => Remover_Caracteres_Especiales(inIdentAdic1),
                                           pPrimer_Nombre          => outPrimerNombreAdic1,
                                           pSegundo_Nombre         => outSegundoNombreAdic1,
                                           pPrimer_Apellido        => outPrimerApellidoAdic1,
                                           pSegundo_Apellido       => outSegundoApellidoAdic1,
                                           pNombre_Plastico        => outNombrePlasticoAdic1,
                                           pFechaNacimiento        => vFechaNacAdic,
                                           pSexo                   => outSexoAdic1,
                                           pEstado_civil           => outEstadoCivilAdic1,
                                           pEmail                  => outEmailAdic1,
                                           pTelefono               => outTelefonoAdic1,
                                           pCod_Parentesco         => vParentescoAdic,
                                           pSecuencia              => 1,
                                           pLimite_Solicitado_Rd   => vLimiteSolRDAdic,
                                           pLimite_Solicitado_Us   => vLimiteSolUSAdic,
                                           outNo_Solicitud_Adi     => vSolicitudAdicNumero,
                                           outError                => outError);
                                           
                        outFechaNacimientoAdic1 := TO_CHAR(vFechaNacAdic, 'DD/MM/YYYY');
                        outNo_Solicitud_Adic1   := TO_CHAR(vSolicitudAdicNumero);
                        vFechaNacAdic := NULL;       
                        vParentescoAdic := NULL;  
                        vLimiteSolRDAdic := NULL;
                        vLimiteSolUSAdic := NULL;                          
                        vSolicitudAdicNumero := NULL;
                  EXCEPTION WHEN OTHERS THEN
                      outSolicitudNumero := '0';
                      IF outError IS NULL THEN
                          outError := SUBSTR(SQLERRM,1, 4000);
                      END IF;
                      RAISE_APPLICATION_ERROR(-20105, 'ADICIONAL 1 '||outError);
                  END;
              END IF;
              
              IF inIdentAdic2 IS NOT NULL THEN
                  BEGIN
                        vFechaNacAdic       := TO_DATE(outFechaNacimientoAdic2, 'DD/MM/YYYY');
                        vParentescoAdic     := TO_NUMBER(inParentescoAdic2);
                        vLimiteSolRDAdic    := TO_NUMBER(inLimiteSolicitadoRDAdic2);
                        vLimiteSolUSAdic    := TO_NUMBER(inLimiteSolicitadoUSAdic2); 
                        
                        -- Adicional 2
                        procesar_adicional(pNo_Solicitud           => vSolicitudNumero,                                                                
                                           pTipo_Identificacion    => Remover_Caracteres_Especiales(inTipoIdAdic2),
                                           pIdentificacion         => Remover_Caracteres_Especiales(inIdentAdic2),
                                           pPrimer_Nombre          => outPrimerNombreAdic2,
                                           pSegundo_Nombre         => outSegundoNombreAdic2,
                                           pPrimer_Apellido        => outPrimerApellidoAdic2,
                                           pSegundo_Apellido       => outSegundoApellidoAdic2,
                                           pNombre_Plastico        => outNombrePlasticoAdic2,
                                           pFechaNacimiento        => vFechaNacAdic,
                                           pSexo                   => outSexoAdic2,
                                           pEstado_civil           => outEstadoCivilAdic2,
                                           pEmail                  => outEmailAdic2,
                                           pTelefono               => outTelefonoAdic2,
                                           pCod_Parentesco         => inParentescoAdic2,
                                           pSecuencia              => 2,
                                           pLimite_Solicitado_Rd   => inLimiteSolicitadoRDAdic2,
                                           pLimite_Solicitado_Us   => inLimiteSolicitadoUSAdic2,
                                           outNo_Solicitud_Adi     => outNo_Solicitud_Adic2,
                                           outError                => outError);
                        outFechaNacimientoAdic2 := TO_CHAR(vFechaNacAdic, 'DD/MM/YYYY');
                        outNo_Solicitud_Adic2   := TO_CHAR(vSolicitudAdicNumero);
                        vFechaNacAdic := NULL;       
                        vParentescoAdic := NULL;  
                        vLimiteSolRDAdic := NULL;
                        vLimiteSolUSAdic := NULL;                          
                        vSolicitudAdicNumero := NULL;
                  EXCEPTION WHEN OTHERS THEN
                      outSolicitudNumero := '0';
                      IF outError IS NULL THEN
                          outError := SUBSTR(SQLERRM,1, 4000);
                      END IF;
                      RAISE_APPLICATION_ERROR(-20105, 'ADICIONAL 2 '||outError);      
                  END;
              END IF;
              
              IF outError IS NULL THEN
                  outError := 'Solicitud '||outSolicitudNumero||' creada satisfactoriamente.';
                  COMMIT;              
                  --notificar_solicitud(outSolicitudNumero, outError);
              END IF;
              
          END IF;                      
      
   EXCEPTION WHEN OTHERS THEN
     outSolicitudNumero := '0';
     IF outError IS NULL THEN
         outError := SUBSTR(SQLERRM/*||' '||dbms_utility.format_error_backtrace*/,1, 4000);
     END IF; 
     ROLLBACK;                       
     --INSERT INTO tc.datatemptc (CAMPO, FECHA, VALOR) VALUES ('TC_SOLICITUD ERROR', SYSDATE, outError); commit;
     RETURN;
   END generar_solicitud;
    
   PROCEDURE generar_solicitud2(inOficinaOrigen           IN     VARCHAR2,                                
                                inTipoId                  IN     VARCHAR2, 
                                inNumId                   IN     VARCHAR2,
                                inNombrePlastico          IN     VARCHAR2,
                                inTipoProducto            IN     VARCHAR2,
                                inTipoEmision             IN     VARCHAR2,
                                inFechaSolicitud          IN     VARCHAR2,
                                inTipoTarjeta             IN     VARCHAR2,      -- P = PRINCIPAL, A = ADICIONAL  
                                inOficinaEntrega          IN     VARCHAR2,
                                inCodPromotor             IN     VARCHAR2,
                                inCodCicloFact            IN     VARCHAR2, 
                                inTipoMonedaTarjeta       IN     VARCHAR2, 
                                inMontoSolicitadoRD       IN     VARCHAR2,
                                inMontoSolicitadoUS       IN     VARCHAR2, 
                                inEsEmpleado              IN     VARCHAR2,      -- S = Continuar si es empleado    
                                inTipoGarantia            IN     VARCHAR2, 
                                inValorGarantia           IN     VARCHAR2,  
                                inSegregacionRD           IN     VARCHAR2,                 
                                outEstado_civil           IN OUT VARCHAR2,
                                outSexo                   IN OUT VARCHAR2,
                                outFecha_nacimiento       IN OUT VARCHAR2,
                                outApellido1              IN OUT VARCHAR2,
                                outApellido2              IN OUT VARCHAR2,
                                outPrimerNombre           IN OUT VARCHAR2,
                                outSegundoNombre          IN OUT VARCHAR2,
                                outNum_dependientes       IN OUT VARCHAR2,
                                outProfesion              IN OUT VARCHAR2,
                                outTipoVivienda           IN OUT VARCHAR2,
                                outCodPais                IN OUT VARCHAR2,
                                outCodProvincia           IN OUT VARCHAR2,
                                outCodCanton              IN OUT VARCHAR2,
                                outCodDistrito            IN OUT VARCHAR2,
                                outCodCiudad              IN OUT VARCHAR2,
                                inSector_Res              IN     VARCHAR2,
                                inBarrio_Res              IN     VARCHAR2,
                                inCalle_Res               IN     VARCHAR2,
                                inNumero_Res              IN     VARCHAR2,
                                inDetalle_Res             IN     VARCHAR2,
                                outTELEFONO_CORRESP       IN OUT VARCHAR2,
                                outExtTelefono            IN OUT VARCHAR2,
                                outZPostalCorresp         IN OUT VARCHAR2,
                                outEmail                  IN OUT VARCHAR2,
                                outTelefono               IN OUT VARCHAR2,
                                outSolicitudNumero        IN OUT VARCHAR2,
                                inTipoIdAdic1             IN     VARCHAR2,
                                inIdentAdic1              IN     VARCHAR2,
                                outPrimerNombreAdic1      IN OUT VARCHAR2,
                                outSegundoNombreAdic1     IN OUT VARCHAR2,
                                outPrimerApellidoAdic1    IN OUT VARCHAR2,
                                outSegundoApellidoAdic1   IN OUT VARCHAR2,
                                outNombrePlasticoAdic1    IN OUT VARCHAR2,
                                outFechaNacimientoAdic1   IN OUT VARCHAR2,
                                outSexoAdic1              IN OUT VARCHAR2,
                                outEstadoCivilAdic1       IN OUT VARCHAR2,
                                outEmailAdic1             IN OUT VARCHAR2,
                                outTelefonoAdic1          IN OUT VARCHAR2,
                                inParentescoAdic1         IN     VARCHAR2,
                                inLimiteSolicitadoRDAdic1 IN     VARCHAR2,
                                inLimiteSolicitadoUSAdic1 IN     VARCHAR2,
                                outNo_Solicitud_Adic1     IN OUT VARCHAR2,                                
                                inTipoIdAdic2             IN     VARCHAR2,
                                inIdentAdic2              IN     VARCHAR2,
                                outPrimerNombreAdic2      IN OUT VARCHAR2,
                                outSegundoNombreAdic2     IN OUT VARCHAR2,
                                outPrimerApellidoAdic2    IN OUT VARCHAR2,
                                outSegundoApellidoAdic2   IN OUT VARCHAR2,
                                outNombrePlasticoAdic2    IN OUT VARCHAR2,
                                outFechaNacimientoAdic2   IN OUT VARCHAR2,
                                outSexoAdic2              IN OUT VARCHAR2,
                                outEstadoCivilAdic2       IN OUT VARCHAR2,
                                outEmailAdic2             IN OUT VARCHAR2,
                                outTelefonoAdic2          IN OUT VARCHAR2,
                                inParentescoAdic2         IN     VARCHAR2,
                                inLimiteSolicitadoRDAdic2 IN     VARCHAR2,
                                inLimiteSolicitadoUSAdic2 IN     VARCHAR2,
                                outNo_Solicitud_Adic2     IN OUT VARCHAR2,                                
                                outError                  IN OUT VARCHAR2) IS
                                
    vFechaSolicitud      DATE;
    vMontoSolicitadoRD   NUMBER;
    vMontoSolicitadoUS   NUMBER;
    vValorGarantia       NUMBER;
    vFecha_nacimiento    DATE;
    vNum_dependientes    NUMBER;
    vExtTelefono         NUMBER:=0;
    vZPostalCorresp      NUMBER:=0;
    vSolicitudNumero     NUMBER:=0;
    vSolicitudAdicNumero NUMBER:=0;
    vFechaNacAdic        DATE;
    vParentescoAdic      NUMBER;
    vLimiteSolRDAdic     NUMBER := 0;
    vLimiteSolUSAdic     NUMBER := 0;
    
 --   vParametros CLOB; 
                                    
   BEGIN      
        outError:= NULL;
        outSolicitudNumero := ' ';       
         
          vFechaSolicitud     := SYSDATE; --TO_DATE(NVL(inFechaSolicitud,SYSDATE),'DD/MM/YYYY');
          vMontoSolicitadoRD  := TO_NUMBER(NVL(inMontoSolicitadoRD,'0'));
          vMontoSolicitadoUS  := TO_NUMBER(NVL(inMontoSolicitadoUS,'0'));          
          vValorGarantia      := 0;--TO_NUMBER(NVL(inValorGarantia,'0'));
          vFecha_nacimiento   := TO_DATE(outFecha_nacimiento,'DD/MM/YYYY HH24:MI:SS');
          vNum_dependientes   := 0;--TO_NUMBER(NVL(Remover_Caracteres_Especiales(outNum_dependientes),'0'));
          outCodCiudad        := NVL(outCodCiudad,1);
--DBMS_OUTPUT.PUT_LINE('Monto RD$'||vMontoSolicitadoRD  ||' '|| TO_NUMBER(NVL(inMontoSolicitadoRD,'0'))||' MontoUS$'||vMontoSolicitadoUS||' '||TO_NUMBER(NVL(inMontoSolicitadoUS,'0')));
--DBMS_OUTPUT.PUT_LINE(' Pais='||outCodPais||' Provincia='||outCodProvincia||' Canton='||outCodCanton||' Distrito='||outCodDistrito||' Ciudad='||outCodCiudad||' Sector='||inSector_Res);          

          BEGIN  
              procesar_solicitud2( inOficinaOrigen      => inOficinaOrigen,                                
                                  inTipoId             => inTipoId, 
                                  inNumId              => inNumId,
                                  inNombrePlastico     => inNombrePlastico,
                                  inTipoProducto       => inTipoProducto,
                                  inTipoEmision        => inTipoEmision,
                                  inFechaSolicitud     => vFechaSolicitud,
                                  inTipoTarjeta        => inTipoTarjeta,        
                                  inOficinaEntrega     => inOficinaEntrega,
                                  inCodPromotor        => inCodPromotor,
                                  inCodCicloFact       => inCodCicloFact, 
                                  inTipoMonedaTarjeta  => inTipoMonedaTarjeta, 
                                  inMontoSolicitadoRD  => vMontoSolicitadoRD,
                                  inMontoSolicitadoUS  => vMontoSolicitadoUS,
                                  inEsEmpleado         => inEsEmpleado,          
                                  inTipoGarantia       => inTipoGarantia, 
                                  inValorGarantia      => vValorGarantia, 
                                  inSegregacionRD      => inSegregacionRD,                 
                                  outEstado_civil      => outEstado_civil,
                                  outSexo              => outSexo,
                                  outFecha_nacimiento  => vFecha_nacimiento,
                                  outApellido1         => outApellido1,
                                  outApellido2         => outApellido2,
                                  outPrimerNombre      => outPrimerNombre,
                                  outSegundoNombre     => outSegundoNombre,
                                  outNum_dependientes  => vNum_dependientes,
                                  outProfesion         => outProfesion,
                                  outTipoVivienda      => outTipoVivienda,
                                  outCodPais           => outCodPais,
                                  outCodProvincia      => outCodProvincia,
                                  outCodCanton         => outCodCanton,
                                  outCodDistrito       => outCodDistrito,
                                  outCodCiudad         => outCodCiudad,
                                  inSector_Res         => inSector_Res ,
                                  inBarrio_Res         => inBarrio_Res,
                                  inCalle_Res          => inCalle_Res,
                                  inNumero_Res         => inNumero_Res,
                                  inDetalle_Res        => inDetalle_Res,
                                  outTELEFONO_CORRESP  => outTELEFONO_CORRESP,
                                  outExtTelefono       => vExtTelefono,
                                  outZPostalCorresp    => vZPostalCorresp,
                                  outEmail             => outEmail,
                                  outTelefono          => outTelefono,
                                  outSolicitudNumero   => vSolicitudNumero,
                                  outError             => outError);

              IF outError IS NOT NULL THEN
                outSolicitudNumero := '0';
                RAISE_APPLICATION_ERROR(-20100, outError);
              END IF;
              
              outFecha_nacimiento  := TO_CHAR(vFecha_nacimiento,'DD/MM/YYYY');
              outNum_dependientes  := TO_CHAR(vNum_dependientes);
              outExtTelefono       := TO_CHAR(vExtTelefono);
              outZPostalCorresp    := TO_CHAR(vZPostalCorresp);
              outSolicitudNumero   := NVL(TO_CHAR(vSolicitudNumero),0);
              vFecha_nacimiento    := NULL;              
                                  
          EXCEPTION WHEN OTHERS THEN
              outSolicitudNumero := '0';
              IF outError IS NULL THEN
                outError := SUBSTR(SQLERRM,1, 4000);
              END IF;
              RAISE_APPLICATION_ERROR(-20105, 'SOLICITUD: '||outError, FALSE);
          END;
          
          IF vSolicitudNumero IS NOT NULL  AND vSolicitudNumero > 0 THEN
              IF inIdentAdic1 IS NOT NULL THEN
                  BEGIN
                        vFechaNacAdic       := TO_DATE(outFechaNacimientoAdic1, 'DD/MM/YYYY');
                        vParentescoAdic     := TO_NUMBER(inParentescoAdic1);
                        vLimiteSolRDAdic    := TO_NUMBER(inLimiteSolicitadoRDAdic1);
                        vLimiteSolUSAdic    := TO_NUMBER(inLimiteSolicitadoUSAdic1);  
                        -- Adicional 1
                        procesar_adicional(pNo_Solicitud           => vSolicitudNumero,                                                                
                                           pTipo_Identificacion    => Remover_Caracteres_Especiales(inTipoIdAdic1),
                                           pIdentificacion         => Remover_Caracteres_Especiales(inIdentAdic1),
                                           pPrimer_Nombre          => outPrimerNombreAdic1,
                                           pSegundo_Nombre         => outSegundoNombreAdic1,
                                           pPrimer_Apellido        => outPrimerApellidoAdic1,
                                           pSegundo_Apellido       => outSegundoApellidoAdic1,
                                           pNombre_Plastico        => outNombrePlasticoAdic1,
                                           pFechaNacimiento        => vFechaNacAdic,
                                           pSexo                   => outSexoAdic1,
                                           pEstado_civil           => outEstadoCivilAdic1,
                                           pEmail                  => outEmailAdic1,
                                           pTelefono               => outTelefonoAdic1,
                                           pCod_Parentesco         => vParentescoAdic,
                                           pSecuencia              => 1,
                                           pLimite_Solicitado_Rd   => vLimiteSolRDAdic,
                                           pLimite_Solicitado_Us   => vLimiteSolUSAdic,
                                           outNo_Solicitud_Adi     => vSolicitudAdicNumero,
                                           outError                => outError);
                                           
                        outFechaNacimientoAdic1 := TO_CHAR(vFechaNacAdic, 'DD/MM/YYYY');
                        outNo_Solicitud_Adic1   := TO_CHAR(vSolicitudAdicNumero);
                        vFechaNacAdic := NULL;       
                        vParentescoAdic := NULL;  
                        vLimiteSolRDAdic := NULL;
                        vLimiteSolUSAdic := NULL;                          
                        vSolicitudAdicNumero := NULL;
                  EXCEPTION WHEN OTHERS THEN
                      outSolicitudNumero := '0';
                      IF outError IS NULL THEN
                          outError := SUBSTR(SQLERRM,1, 4000);
                      END IF;
                      RAISE_APPLICATION_ERROR(-20105, 'ADICIONAL 1 '||outError);
                  END;
              END IF;
              
              IF inIdentAdic2 IS NOT NULL THEN
                  BEGIN
                        vFechaNacAdic       := TO_DATE(outFechaNacimientoAdic2, 'DD/MM/YYYY');
                        vParentescoAdic     := TO_NUMBER(inParentescoAdic2);
                        vLimiteSolRDAdic    := TO_NUMBER(inLimiteSolicitadoRDAdic2);
                        vLimiteSolUSAdic    := TO_NUMBER(inLimiteSolicitadoUSAdic2); 
                        
                        -- Adicional 2
                        procesar_adicional(pNo_Solicitud           => vSolicitudNumero,                                                                
                                           pTipo_Identificacion    => Remover_Caracteres_Especiales(inTipoIdAdic2),
                                           pIdentificacion         => Remover_Caracteres_Especiales(inIdentAdic2),
                                           pPrimer_Nombre          => outPrimerNombreAdic2,
                                           pSegundo_Nombre         => outSegundoNombreAdic2,
                                           pPrimer_Apellido        => outPrimerApellidoAdic2,
                                           pSegundo_Apellido       => outSegundoApellidoAdic2,
                                           pNombre_Plastico        => outNombrePlasticoAdic2,
                                           pFechaNacimiento        => vFechaNacAdic,
                                           pSexo                   => outSexoAdic2,
                                           pEstado_civil           => outEstadoCivilAdic2,
                                           pEmail                  => outEmailAdic2,
                                           pTelefono               => outTelefonoAdic2,
                                           pCod_Parentesco         => inParentescoAdic2,
                                           pSecuencia              => 2,
                                           pLimite_Solicitado_Rd   => inLimiteSolicitadoRDAdic2,
                                           pLimite_Solicitado_Us   => inLimiteSolicitadoUSAdic2,
                                           outNo_Solicitud_Adi     => outNo_Solicitud_Adic2,
                                           outError                => outError);
                        outFechaNacimientoAdic2 := TO_CHAR(vFechaNacAdic, 'DD/MM/YYYY');
                        outNo_Solicitud_Adic2   := TO_CHAR(vSolicitudAdicNumero);
                        vFechaNacAdic := NULL;       
                        vParentescoAdic := NULL;  
                        vLimiteSolRDAdic := NULL;
                        vLimiteSolUSAdic := NULL;                          
                        vSolicitudAdicNumero := NULL;
                  EXCEPTION WHEN OTHERS THEN
                      outSolicitudNumero := '0';
                      IF outError IS NULL THEN
                          outError := SUBSTR(SQLERRM,1, 4000);
                      END IF;
                      RAISE_APPLICATION_ERROR(-20105, 'ADICIONAL 2 '||outError);      
                  END;
              END IF;
              
              IF outError IS NULL THEN
                  outError := 'Solicitud '||outSolicitudNumero||' creada satisfactoriamente.';
                  COMMIT;              
                  --notificar_solicitud(outSolicitudNumero, outError);
              END IF;
              
          END IF;                      
      
   EXCEPTION WHEN OTHERS THEN
     outSolicitudNumero := '0';
     IF outError IS NULL THEN
         outError := SUBSTR(SQLERRM/*||' '||dbms_utility.format_error_backtrace*/,1, 4000);
     END IF; 
     ROLLBACK;                       
     --INSERT INTO tc.datatemptc (CAMPO, FECHA, VALOR) VALUES ('TC_SOLICITUD ERROR', SYSDATE, outError); commit;
     RETURN;
   END generar_solicitud2;
   
   PROCEDURE procesar_solicitud(inOficinaOrigen       IN     VARCHAR2,                                
                                inTipoId              IN     VARCHAR2, 
                                inNumId               IN     VARCHAR2,
                                inNombrePlastico      IN     VARCHAR2,
                                inTipoProducto        IN     VARCHAR2,
                                inTipoEmision         IN     VARCHAR2,
                                inFechaSolicitud      IN     DATE,
                                inTipoTarjeta         IN     VARCHAR2,      -- P = PRINCIPAL, A = ADICIONAL  
                                inOficinaEntrega      IN     VARCHAR2,
                                inCodPromotor         IN     VARCHAR2,
                                inCodCicloFact        IN     VARCHAR2, 
                                inTipoMonedaTarjeta   IN     VARCHAR2, 
                                inMontoSolicitadoRD   IN     NUMBER,
                                inMontoSolicitadoUS   IN     NUMBER, 
                                inEsEmpleado          IN     VARCHAR2,      -- S = Continuar si es empleado    
                                inTipoGarantia        IN     VARCHAR2, 
                                inValorGarantia       IN     NUMBER,  
                                inSegregacionRD       IN     VARCHAR2,                 
                                outEstado_civil       IN OUT VARCHAR2,
                                outSexo               IN OUT VARCHAR2,
                                outFecha_nacimiento   IN OUT DATE,
                                outApellido1          IN OUT VARCHAR2,
                                outApellido2          IN OUT VARCHAR2,
                                outPrimerNombre       IN OUT VARCHAR2,
                                outSegundoNombre      IN OUT VARCHAR2,
                                outNum_dependientes   IN OUT NUMBER,
                                outProfesion          IN OUT VARCHAR2,
                                outTipoVivienda       IN OUT VARCHAR2,
                                outCodPais            IN OUT VARCHAR2,
                                outCodProvincia       IN OUT VARCHAR2,
                                outCodCanton          IN OUT VARCHAR2,
                                outCodDistrito        IN OUT VARCHAR2,
                                outCodCiudad          IN OUT VARCHAR2,
                                inSector_Res          IN     VARCHAR2,
                                inBarrio_Res          IN     VARCHAR2,
                                inCalle_Res           IN     VARCHAR2,
                                inNumero_Res          IN     VARCHAR2,
                                inDetalle_Res         IN     VARCHAR2,
                                outTELEFONO_CORRESP   IN OUT VARCHAR2,
                                outExtTelefono        IN OUT NUMBER,
                                outZPostalCorresp     IN OUT NUMBER,
                                outEmail              IN OUT VARCHAR2,
                                outTelefono           IN OUT VARCHAR2,
                                outSolicitudNumero    IN OUT NUMBER,
                                outError              IN OUT VARCHAR2) IS

      vValida               BOOLEAN := FALSE;
      vSolicitudNumero      NUMBER := 0; 
      vEmpleadoAdemi        VARCHAR2(1); 
      vExisteCliente        NUMBER := 0;    
      vCodPersona           TC.TC_SOLICITUD_TARJETA.COD_PERSONA%TYPE;
      vCodTipoId            TC.TC_SOLICITUD_TARJETA.COD_TIPO_ID%TYPE;
      vNumId                TC.TC_SOLICITUD_TARJETA.NUM_ID%TYPE;
      vEstadoSolicitud      TC.TC_SOLICITUD_TARJETA.ESTADO_SOLICITUD%TYPE;
      vEstado_documentacion TC.TC_SOLICITUD_TARJETA.ESTADO_DOCUMENTACION%TYPE;
      vEstado               TC.TC_SOLICITUD_TARJETA.ESTADO%TYPE;
      vDescripcionSolicitud PA.PA_CATALOGO_CODIGOS.DESCRIPCION%TYPE;
      vFechaSolicitud       TC.TC_SOLICITUD_TARJETA.FECHA_SOLICITUD%TYPE;
      vOficina              TC.TC_SOLICITUD_TARJETA.OFICINA%TYPE;
      vOficinaEntrega       TC.TC_SOLICITUD_TARJETA.OFICINA_ENTREGA_TARJ%TYPE;
      vDescOficina          PA.AGENCIA.DESCRIPCION%TYPE;
      vCodPromotor          PR.PR_ANALISTAS.CODIGO_PERSONA%TYPE;
      vDescPromotor         PR.PR_ANALISTAS.NOMBRE_ANALISTA%TYPE;
      vCodigoActividad      TC.TC_SOLICITUD_TARJETA.CODIGO_ACTIVIDAD%TYPE;
      vCodigoSubActividad   TC.TC_SOLICITUD_TARJETA.CODIGO_SUBACTIVIDAD%TYPE;
      vCodigoSubClase       TC.TC_SOLICITUD_TARJETA.CODIGO_SUB_CLASE%TYPE;
      vCodPais_Est          TC.TC_SOLICITUD_TARJETA.COD_PAIS_EST%TYPE;
      vDescPais_Est         PAIS.pais%type; 
      vCodRegion_Est        TC.TC_SOLICITUD_TARJETA.COD_REGION_EST%TYPE;
      vDesRegion_Est        PROVINCIAS.descripcion%type; 
      vCodProvincia_Est     TC.TC_SOLICITUD_TARJETA.COD_PROVINCIA_EST%TYPE;
      vDescProvincia_Est    CANTONES.descripcion%type;
      vCodCiudad_Est        TC.TC_SOLICITUD_TARJETA.COD_CIUDAD_EST%TYPE;
      vDescCiudad_Est       DISTRITOS.descripcion%TYPE;
      vCodMunicipio_est     TC.TC_SOLICITUD_TARJETA.COD_MUNICIPIO_EST%TYPE;
      vDescMunicipio_Est    PUEBLOS.DESCRIPCION%TYPE;
      vDescSector           SECTORES.DESCRIPCION%TYPE;
      vDescactividad_ciiu   pa.actividades_economicas_bc_ciiu.concepto%type;
      vDescactividad        actividades_economicas.descripcion%type;
      vDescsubactividad     sub_actividades_economicas.descripcion%type;
      vDescsubclase         sub_sub_actividades_economicas.descripcion%type;
      vDescAgencia          agencia.descripcion%type;
      vTipoMonedaTarjeta    TC.TC_PROD_EMIS_TJT.TIP_RESTRICC_USO%TYPE;
      vCodEmisor            TC.TC_PROD_EMIS_TJT.COD_EMISOR%TYPE;
      vValidaLimite         BOOLEAN := FALSE;
      vNombrePlastico       TC.TC_SOLICITUD_TARJETA.NOMBRE_PLASTICO%TYPE;
      vCasadaApellido       VARCHAR2(60);
      
   BEGIN
      outError := null;
      vFechaSolicitud := nvl(inFechaSolicitud,TRUNC(sysdate));
      vOficina        := inOficinaOrigen;  
      
      IF inOficinaEntrega is null or inOficinaEntrega = 0 then
          BEGIN
          
              SELECT e.cod_agencia_labora  
                INTO vOficinaEntrega
                FROM empleados e
               WHERE cod_empresa = '1'
                 AND id_empleado = inCodPromotor;
          EXCEPTION WHEN NO_DATA_FOUND THEN
            vOficinaEntrega := vOficina;
          END;
      else
        vOficinaEntrega := inOficinaEntrega;
      end if;     
      
      vValida := Valida_Campos( inOficina             => vOficina,
                                inNombrePlastico      => UPPER(inNombrePlastico),
                                inCodTipoProducto     => inTipoProducto,
                                inTipoEmision         => inTipoEmision,
                                inFechaSolicitud      => vFechaSolicitud,
                                inIndTipoTarjeta      => inTipoTarjeta,
                                inIndPlastico         => 'S',
                                inCupoIndependiente   => 'N' ,
                                inOficinaEntregaTarj  => inOficinaEntrega,
                                inCodPromotor         => inCodPromotor,
                                inCodSistema          => 'TC',
                                inCodCicloFact        => inCodCicloFact,
                                inCupoSolicitadoRD    => inMontoSolicitadoRD, 
                                inCupoSolicitadoUS    => inMontoSolicitadoUS, 
                                inTipoMonedaTarjeta   => inTipoMonedaTarjeta,
                                inMensaje             => outError);

      IF vValida THEN  
            vCodTipoId  := inTipoId;
            vNumId      := inNumId;                                    
            outError    := NULL;
            DBMS_OUTPUT.PUT_LINE ( 'vCodPersona = ' || vCodPersona );
            DBMS_OUTPUT.PUT_LINE ( 'vCodTipoId = ' || vCodTipoId );
            DBMS_OUTPUT.PUT_LINE ( 'vNumId = ' || vNumId );
            CodPersonaById(outCodPersona    => vCodPersona,
                           outTipoId        => vCodTipoId,                                                        
                           outNumId         => vNumId,
                           outError         => outError);
      
            IF outError IS NOT NULL THEN
                RAISE_APPLICATION_ERROR(-20100, outError);
            END IF;                   
       
            vExisteCliente := existe_cliente(vCodPersona);
                
            IF NVL (vExisteCliente, 0) = 0 THEN
               outError := 'Esta persona no está creado como Cliente, favor verificar...'||vCodPersona;
               RAISE_APPLICATION_ERROR(-20404, outError);
            END IF;
            
            BEGIN    
                TC.TC_SOLICITUD.Datos_per_fisica(  inCodPersona          => vCodPersona,
                                                   outEstado_civil       => outEstado_civil,
                                                   outSexo               => outSexo,
                                                   OutFecha_nacimiento   => outFecha_nacimiento,
                                                   OutApellido1          => outApellido1,
                                                   OutApellido2          => outApellido2,
                                                   OutPrimerNombre       => outPrimerNombre,
                                                   OutSegundoNombre      => outSegundoNombre,
                                                   OutCasadaApellido     => vCasadaApellido,
                                                   OutNum_dependientes   => outNum_dependientes,                                                   
                                                   OutProfesion          => outProfesion,
                                                   OutTipoVivienda       => outTipoVivienda,
                                                   outEmail              => outEmail,
                                                   outTelefono           => outTelefono,
                                                   outError              => outError);          
                                               
                                                                                                   
            
                vEstadoSolicitud        := 'P';
                vEstado_documentacion   := 'P';
                vEstado                 := 'P';                    
            EXCEPTION WHEN OTHERS THEN
                IF outError IS NULL THEN
                    outError := SUBSTR(SQLERRM,1, 3000);
                END IF;
                RAISE_APPLICATION_ERROR(-20100, SUBSTR(outError,1,3000));           
            END;
                        
            
            vSolicitudNumero := Verifica_Existe_Solicitud (pTipoId           => vCodTipoId,
                                                           pNumId            => vNumId,
                                                           pTipoProd         => inTipoProducto,
                                                           outFechaSolicitud => vFechaSolicitud,
                                                           outOficina        => vOficina,
                                                           outEstado         => vEstadoSolicitud,
                                                           outError          => outError);
            IF outError IS NOT NULL THEN
                RAISE_APPLICATION_ERROR(-20100, outError);                
            END IF; 
            
            IF vSolicitudNumero > 0 THEN
                RAISE_APPLICATION_ERROR(-20100, outError);                
            ELSE
                BEGIN
                    Solicitud_Empleado( pCodPersona       => vCodPersona,
                                        pEmpresa          => 1,
                                        pAgencia          => vOficina,
                                        pOficina          => vOficina,
                                        pDescOficina      => vDescOficina,
                                        pPromotor         => vCodPromotor,
                                        pDescPromotor     => vDescPromotor,
                                        pEmpleado         => vEmpleadoAdemi,
                                        outError          => outError);
                   
                    IF vEmpleadoAdemi = 'S' THEN
                        IF outError IS NOT NULL THEN
                            RAISE_APPLICATION_ERROR(-20100, outError);
                        END IF;                    
                    END IF; 
                EXCEPTION WHEN OTHERS THEN
                    IF outError IS NULL THEN
                        outError := SUBSTR(SQLERRM,1, 3000);
                    END IF;
                    RAISE_APPLICATION_ERROR(-20100, SUBSTR(outError,1,3000));           
                END;
                
                BEGIN
                    Buscar_actividad(  inSegregacionRD             => inSegregacionRD,
                                       outCodigoActividad          => vCodigoActividad,
                                       outCodigoSubactividad       => vCodigoSubactividad,
                                       outCodigoSubClase           => vCodigoSubClase,
                                       outDescactividad_ciiu       => vDescactividad_ciiu,
                                       outDescactividad            => vDescactividad,
                                       outDescsubactividad         => vDescsubactividad, 
                                       outDescsubclase             => vDescsubclase,  
                                       outError                    => outError);
                                        
                    IF outError IS NOT NULL THEN
                        RAISE_APPLICATION_ERROR(-20100, outError);                    
                    END IF;
                EXCEPTION WHEN OTHERS THEN
                    IF outError IS NULL THEN
                        outError := SUBSTR(SQLERRM,1, 3000);
                    END IF;
                    RAISE_APPLICATION_ERROR(-20100, SUBSTR(outError,1,3000));           
                END;
                
                BEGIN
                    Oficina_entrega( inOficinaEntregaTarj       => vOficinaEntrega,
                                     outDesAgencia              => vDescAgencia, 
                                     outCodPais_est             => vCodPais_Est,
                                     outDescPais_est            => vDescPais_Est,
                                     outCodRegion_est           => vCodRegion_Est,
                                     outDescRegion_est          => vDesRegion_Est,
                                     outCodProvincia_est        => vCodProvincia_Est,
                                     outDescProvincia_est       => vDescProvincia_Est,
                                     outCodCiudad_est           => vCodCiudad_Est,
                                     outDescCiudad_est          => vDescCiudad_Est,
                                     outCodMunicipio_est        => vCodMunicipio_est,
                                     outDescMunicipio_est       => vDescMunicipio_Est,
                                     outError                   => outError );
                    
                    IF outError IS NOT NULL THEN
                        RAISE_APPLICATION_ERROR(-20100, outError);                    
                    END IF;                                        
                    
                EXCEPTION WHEN OTHERS THEN
                    IF outError IS NULL THEN
                        outError := SUBSTR(SQLERRM,1, 3000);
                    END IF;
                    RAISE_APPLICATION_ERROR(-20100, SUBSTR(outError,1,3000));           
                END;  
                
                /*
                BEGIN
                     SELECT D.COD_PAIS, D.COD_PROVINCIA, D.COD_CANTON, D.COD_DISTRITO, D.COD_PUEBLO
                       INTO outCodPais, outCodProvincia, outCodCanton, outCodDistrito, outCodCiudad
                       FROM PA.DIR_PERSONAS d
                      WHERE D.COD_PERSONA = vCodPersona
                        AND D.COD_DIRECCION = D.COD_DIRECCION+0 
                        AND D.TIP_DIRECCION = 1
                        AND D.ES_DEFAULT = 'S'
                        AND ROWNUM = 1;  
                EXCEPTION WHEN NO_DATA_FOUND THEN
                    outError := 'Datos de la dirección en la solicitud no encontrados.';
                    RAISE_APPLICATION_ERROR(-20100, SUBSTR(outError,1,3000));    
                END;      */          
                                   
                vCodEmisor := Param.parametro_x_empresa(1, 'COD_EMISOR', 'TC');
                
                begin
                   select tip_restricc_uso
                     into vTipoMonedaTarjeta                          
                     from tc_prod_emis_tjt
                    where cod_emisor      = vCodEmisor
                      and cod_prod_emisor = inTipoProducto
                      and cod_empresa     = 1;
                      
                exception
                    when no_data_found then
                   IF outError IS NULL THEN
                        outError := SUBSTR('Datos Tipo de producto no encontrados. '||vCodEmisor||' '||inTipoProducto||' '||SQLERRM,1, 3000);
                   END IF;
                   RAISE_APPLICATION_ERROR(-20100, SUBSTR(outError,1,3000));
                end;
                
                vValidaLimite := TC.TC_Solicitud.Valida_Monto_Solicitado(pTipoMonedaTarjeta    =>  vTipoMonedaTarjeta,
                                                                         pCupoSolicitadoRD     =>  inMontoSolicitadoRD,
                                                                         pCupoSolicitadoUS     =>  inMontoSolicitadoUS,
                                                                         pTipoCampo            =>  pa_utl.obtiene_tipo_cambio(1, 1, SYSDATE),
                                                                         pTipoProducto         =>  inTipoProducto,
                                                                         pCodEmisor            =>  vCodEmisor,
                                                                         outError              =>  outError);
        
        
                IF vValidaLimite = FALSE THEN
                    IF outError IS NULL THEN
                        outError := SUBSTR(SQLERRM,1, 3000);
                    END IF;
                    RAISE_APPLICATION_ERROR(-20100, SUBSTR(outError,1,3000));
                END IF;
                
                IF inNombrePlastico IS NOT NULL THEN
                
                    IF LENGTH(inNombrePlastico) > 21 THEN
                        outError := 'La longitud del nombre del plastico sobrepasa los 21 caracteres.';
                        RAISE_APPLICATION_ERROR(-20100, SUBSTR(outError,1,3000));
                    END IF;
                    vNombrePlastico := UPPER(REPLACE(inNombrePlastico,' ',','));
                ELSE 
                    vNombrePlastico := SUBSTR(REPLACE(outPrimerNombre,' ',',')||','||REPLACE(outApellido1,' ',','),1,21);
                END IF;
                
                BEGIN
                     DBMS_OUTPUT.PUT_LINE('ANTES Pais='||outCodPais||' Provincia='||outCodProvincia||' Canton='||outCodCanton||' Distrito='||outCodDistrito||' Ciudad='||outCodCiudad||' Sector='||inSector_Res);                     
                     outCodCiudad       := outCodDistrito;
                     outCodDistrito     := outCodCanton;
                     outCodCanton       := outCodProvincia;
                     BEGIN
                         select c.cod_provincia
                           into outCodProvincia
                           from PA.CANTONES c
                          where c.cod_pais = NVL(outCodPais,1)
                            and C.COD_CANTON = outCodCanton;
                     EXCEPTION WHEN NO_DATA_FOUND THEN
                            outError := 'Codigo de la region en la solicitud no encontrados '||outCodCanton;
                            RAISE_APPLICATION_ERROR(-20100, SUBSTR(outError,1,3000));
                        WHEN TOO_MANY_ROWS THEN
                            outError := 'Codigo de la region en la solicitud no determinados '||outCodCanton;
                        RAISE_APPLICATION_ERROR(-20100, SUBSTR(outError,1,3000));
                     END;
                     DBMS_OUTPUT.PUT_LINE('DESPUES Pais='||outCodPais||' Provincia='||outCodProvincia||' Canton='||outCodCanton||' Distrito='||outCodDistrito||' Ciudad='||outCodCiudad||' Sector='||inSector_Res);
                     vDescSector     := PA.OBT_DESC_SECTOR ( NVL(outCodPais,1), outCodProvincia, outCodCanton, outCodDistrito, outCodCiudad, inSector_Res);
                     
                     IF vDescSector IS NULL THEN
                        outError := 'Datos del sector en la solicitud no encontrados Pais='||outCodPais||' Provincia='||outCodProvincia||' Canton='||outCodCanton||' Distrito='||outCodDistrito||' Ciudad='||outCodCiudad||' Sector='||inSector_Res;
                        RAISE_APPLICATION_ERROR(-20100, SUBSTR(outError,1,3000));
                     END IF;
                     
                EXCEPTION WHEN OTHERS THEN
                    outError := 'Datos del sector en la solicitud no encontrados Pais='||outCodPais||' Provincia='||outCodProvincia||' Canton='||outCodCanton||' Distrito='||outCodDistrito||' Ciudad='||outCodCiudad||' Sector='||inSector_Res||' '||SQLERRM;
                    RAISE_APPLICATION_ERROR(-20100, SUBSTR(outError,1,3000));
                END;
                
                /*DBMS_OUTPUT.PUT_LINE(' pCOD_PERSONA = '|| vCodPersona||
                     ' pNO_SOLICITUD = '|| vSolicitudNumero||
                     ' pNUM_ID = '|| vNumId||
                     ' pCOD_TIPO_PRODUCTO = '|| inTipoProducto||
                     ' pFECHA_SOLICITUD = '|| vFechaSolicitud||
                     ' pCOD_TIPO_ID = '|| vCodTipoId||
                     ' pNOMBRE_PLASTICO = '|| UPPER(NVL(inNombrePlastico,vNombrePlastico))||
                     ' pCOD_CICLO_FACT = '|| LPAD(inCodCicloFact,2, '0')||
                     ' pCUPO_SOLICITADO_RD = '|| inMontoSolicitadoRD||
                     ' pESTADO_DOCUMENTACION = '|| vEstado_documentacion||
                     ' pOFICINA = '|| vOficina||
                     ' pOFICINA_ENTREGA_TARJ = '|| vOficinaEntrega||
                     ' pCOD_PAIS = '|| NVL(outCodPais,1)||
                     ' pCOD_PROVINCIA = '|| TRIM(outCodProvincia)||
                     ' pCOD_CANTON = '|| TRIM(outCodCanton)||
                     ' pCOD_DISTRITO = '|| TRIM(outCodDistrito)||
                     ' pCOD_CIUDAD = '|| TRIM(outCodCiudad)||
                     ' pTELEFONO_CORRESP = '|| outTELEFONO_CORRESP||
                     ' pEXT_TELEFONO = '|| outExtTelefono||
                     ' pZPOSTAL_CORRESP = '|| outZPostalCorresp||
                     ' pTIPO_EMISION = '|| inTipoEmision||
                     ' pIND_TIPO_TARJETA = '|| inTipoTarjeta||
                     ' pESTADO = '|| vEstado||
                     ' pLIMITE_ASIGNADO_RD = '|| inMontoSolicitadoRD||
                     ' pLIMITE_ASIGNADO_US = '|| inMontoSolicitadoUS||
                     ' pESTADO_SOLICITUD = '|| vEstadoSolicitud||
                     ' pCOD_PAIS_EST = '|| vCodPais_Est||
                     ' pCOD_REGION_EST = '|| vCodRegion_Est||
                     ' pCOD_PROVINCIA_EST = '|| vCodProvincia_Est||
                     ' pCOD_CIUDAD_EST = '|| vCodCiudad_Est||
                     ' pCOD_MUNICIPIO_EST = '|| vCodMunicipio_est||
                     ' pSECTOR_RES = '|| UPPER(vDescSector)||
                     ' pBARRIO_RES = '|| UPPER(inBarrio_Res)||
                     ' pCALLE_RES = '|| UPPER(inCalle_Res)||
                     ' pNUMERO_RES = '|| UPPER(inNumero_Res)||
                     ' pDETALLE_RES = '|| UPPER(inDetalle_Res)||
                     ' pSEGREGACION_RD = '|| inSegregacionRD||
                     ' pCODIGO_ACTIVIDAD = '|| vCodigoActividad||
                     ' pCODIGO_SUBACTIVIDAD = '|| vCodigoSubActividad||
                     ' pCODIGO_SUB_CLASE = '|| vCodigoSubClase||
                     ' pCUPO_SOLICITADO_US = '|| inMontoSolicitadoUS||
                     ' pCOD_PROMOTOR = '|| inCodPromotor);*/
                
                DBMS_OUTPUT.PUT_LINE('ANTES CREAR SOLICITUD');
                
                BEGIN
                    Crear_Solicitud(  pCOD_PERSONA             => vCodPersona,
                                      pNO_SOLICITUD            => vSolicitudNumero,
                                      pNUM_ID                  => vNumId,
                                      pCOD_TIPO_PRODUCTO       => inTipoProducto,
                                      pFECHA_SOLICITUD         => vFechaSolicitud,
                                      pCOD_TIPO_ID             => vCodTipoId,
                                      pAMPARADA_POR            => NULL,
                                      pNOMBRE_PLASTICO         => UPPER(NVL(inNombrePlastico,vNombrePlastico)),
                                      pCOD_MOTIVO_NEGACION     => NULL,
                                      pCUPO_INDEPENDIENTE      => 'N',
                                      pCOD_CICLO_FACT          => LPAD(inCodCicloFact,2, '0'),
                                      pCOD_TIPO_MERCADO        => NULL,
                                      pCUPO_SOLICITADO_RD      => inMontoSolicitadoRD,
                                      pESTADO_DOCUMENTACION    => vEstado_documentacion,
                                      pCOD_TIPO_CLIENTE        => '1',
                                      pOFICINA                 => vOficina,
                                      pIND_PLASTICO            => 'S',
                                      pIND_DIFIERE             => 'N',
                                      pCOD_DESPACHO            => NULL,
                                      pOFICINA_ENTREGA_TARJ    => vOficinaEntrega,
                                      pIND_CARGO_AUTOMATICO    => 0,
                                      pCOD_COMPENSACION        => NULL,
                                      pCTA_CARGO_AUTOMATICO    => NULL,
                                      pCTA_ALTERNA             => NULL,
                                      pNUM_ID_CODEUDOR         => NULL,
                                      pTIPO_GARANTIA           => NULL,--inTipoGarantia,
                                      pVALOR_GARANTIA          => NULL,--inValorGarantia,
                                      pMODO_AMORTIZACION       => NULL,
                                      pCLIENTE_PRE_EMBOZO      => NULL,
                                      pMES_INICIAL_AMORT       => NULL,
                                      pEMPRESA_AGENTES         => NULL,
                                      pCOD_AGENTE              => NULL,
                                      pEMP_ASIGNADA_AGTE       => NULL,
                                      pDIRECCION_CORRESP1      => NULL,
                                      pDIRECCION_CORRESP2      => NULL,
                                      pDIRECCION_CORRESP3      => NULL,
                                      pDIRECCION_CORRESP4      => NULL,
                                      pCOD_PAIS                => NVL(outCodPais,1),
                                      pCOD_PROVINCIA           => TRIM(outCodProvincia),
                                      pCOD_CANTON              => TRIM(outCodCanton),
                                      pCOD_DISTRITO            => TRIM(outCodDistrito),
                                      pCOD_CIUDAD              => TRIM(outCodCiudad),
                                      pTELEFONO_CORRESP        => outTELEFONO_CORRESP,
                                      pEXT_TELEFONO            => outExtTelefono,
                                      pZPOSTAL_CORRESP         => outZPostalCorresp,
                                      pTIPO_EMISION            => inTipoEmision,
                                      pIND_TIPO_TARJETA        => inTipoTarjeta,
                                      pESTADO                  => vEstado,
                                      pLIMITE_ASIGNADO_RD      => inMontoSolicitadoRD,
                                      pLIMITE_ASIGNADO_US      => inMontoSolicitadoUS,
                                      pESTADO_SOLICITUD        => vEstadoSolicitud,
                                      pFECHA_NEGACION          => NULL,
                                      pBIN                     => NULL,
                                      pCOD_PAIS_EST            => vCodPais_Est,
                                      pCOD_REGION_EST          => vCodRegion_Est,
                                      pCOD_PROVINCIA_EST       => vCodProvincia_Est,
                                      pCOD_CIUDAD_EST          => vCodCiudad_Est,
                                      pCOD_MUNICIPIO_EST       => vCodMunicipio_est,
                                      pCOD_SECTOR_EST          => NULL,
                                      pCOD_BARRIO_EST          => NULL,
                                      pCOD_CALLE_EST           => NULL,
                                      pNUMERO_EST              => NULL,
                                      pDETALLE_EST             => NULL,
                                      pRES_APR_INMED           => NULL,
                                      pSECTOR_RES              => UPPER(TRIM(vDescSector)),
                                      pBARRIO_RES              => UPPER(inBarrio_Res),
                                      pCALLE_RES               => UPPER(inCalle_Res),
                                      pNUMERO_RES              => UPPER(inNumero_Res),
                                      pDETALLE_RES             => UPPER(inDetalle_Res),
                                      pSEGREGACION_RD          => inSegregacionRD,
                                      pCODIGO_ACTIVIDAD        => vCodigoActividad,
                                      pCODIGO_SUBACTIVIDAD     => vCodigoSubActividad,
                                      pCODIGO_SUB_CLASE        => vCodigoSubClase,
                                      pFEC_DIGITACION          => SYSDATE,
                                      pFEC_RECIBO              => NULL,
                                      pLIMITE_APROBADO_RD      => NULL,
                                      pCUPO_SOLICITADO_US      => inMontoSolicitadoUS,
                                      pLIMITE_APROBADO_US      => NULL,
                                      pFECHA_APROBACION        => NULL,
                                      pUSUARIO_APROBACION      => NULL,
                                      pCOD_PROMOTOR            => inCodPromotor,
                                      pJUSTIF_DENEGADA         => NULL,
                                      pNUMERO_ASIENTO          => NULL,
                                      pCOD_TIPO_ID_CODEUDOR    => NULL,
                                      outError                 => outError);

                    outSolicitudNumero :=  vSolicitudNumero;
                EXCEPTION WHEN OTHERS THEN
                    IF outError IS NULL THEN
                        outError := SUBSTR(SQLERRM,1, 3000);
                    END IF;
                    RAISE_APPLICATION_ERROR(-20100, SUBSTR(outError,1,3000));                                     
                END;
                DBMS_OUTPUT.PUT_LINE('DESPUES CREAR SOLICITUD');
            END IF;            
            
      ELSE
          RAISE_APPLICATION_ERROR(-20100, outError);
      END IF;              
   EXCEPTION WHEN OTHERS THEN
      IF outError IS NULL THEN
        outError := SUBSTR(SQLERRM,1, 3000);
      END IF;
      RAISE_APPLICATION_ERROR(-20100, outError);
                                  
   END procesar_solicitud; 
   
   PROCEDURE procesar_solicitud2(inOficinaOrigen       IN     VARCHAR2,                                
                                inTipoId              IN     VARCHAR2, 
                                inNumId               IN     VARCHAR2,
                                inNombrePlastico      IN     VARCHAR2,
                                inTipoProducto        IN     VARCHAR2,
                                inTipoEmision         IN     VARCHAR2,
                                inFechaSolicitud      IN     DATE,
                                inTipoTarjeta         IN     VARCHAR2,      -- P = PRINCIPAL, A = ADICIONAL  
                                inOficinaEntrega      IN     VARCHAR2,
                                inCodPromotor         IN     VARCHAR2,
                                inCodCicloFact        IN     VARCHAR2, 
                                inTipoMonedaTarjeta   IN     VARCHAR2, 
                                inMontoSolicitadoRD   IN     NUMBER,
                                inMontoSolicitadoUS   IN     NUMBER, 
                                inEsEmpleado          IN     VARCHAR2,      -- S = Continuar si es empleado    
                                inTipoGarantia        IN     VARCHAR2, 
                                inValorGarantia       IN     NUMBER,  
                                inSegregacionRD       IN     VARCHAR2,                 
                                outEstado_civil       IN OUT VARCHAR2,
                                outSexo               IN OUT VARCHAR2,
                                outFecha_nacimiento   IN OUT DATE,
                                outApellido1          IN OUT VARCHAR2,
                                outApellido2          IN OUT VARCHAR2,
                                outPrimerNombre       IN OUT VARCHAR2,
                                outSegundoNombre      IN OUT VARCHAR2,
                                outNum_dependientes   IN OUT NUMBER,
                                outProfesion          IN OUT VARCHAR2,
                                outTipoVivienda       IN OUT VARCHAR2,
                                outCodPais            IN OUT VARCHAR2,
                                outCodProvincia       IN OUT VARCHAR2,
                                outCodCanton          IN OUT VARCHAR2,
                                outCodDistrito        IN OUT VARCHAR2,
                                outCodCiudad          IN OUT VARCHAR2,
                                inSector_Res          IN     VARCHAR2,
                                inBarrio_Res          IN     VARCHAR2,
                                inCalle_Res           IN     VARCHAR2,
                                inNumero_Res          IN     VARCHAR2,
                                inDetalle_Res         IN     VARCHAR2,
                                outTELEFONO_CORRESP   IN OUT VARCHAR2,
                                outExtTelefono        IN OUT NUMBER,
                                outZPostalCorresp     IN OUT NUMBER,
                                outEmail              IN OUT VARCHAR2,
                                outTelefono           IN OUT VARCHAR2,
                                outSolicitudNumero    IN OUT NUMBER,
                                outError              IN OUT VARCHAR2) IS

      vValida               BOOLEAN := FALSE;
      vSolicitudNumero      NUMBER := 0; 
      vEmpleadoAdemi        VARCHAR2(1); 
      vExisteCliente        NUMBER := 0;    
      vCodPersona           TC.TC_SOLICITUD_TARJETA.COD_PERSONA%TYPE;
      vCodTipoId            TC.TC_SOLICITUD_TARJETA.COD_TIPO_ID%TYPE;
      vNumId                TC.TC_SOLICITUD_TARJETA.NUM_ID%TYPE;
      vEstadoSolicitud      TC.TC_SOLICITUD_TARJETA.ESTADO_SOLICITUD%TYPE;
      vEstado_documentacion TC.TC_SOLICITUD_TARJETA.ESTADO_DOCUMENTACION%TYPE;
      vEstado               TC.TC_SOLICITUD_TARJETA.ESTADO%TYPE;
      vDescripcionSolicitud PA.PA_CATALOGO_CODIGOS.DESCRIPCION%TYPE;
      vFechaSolicitud       TC.TC_SOLICITUD_TARJETA.FECHA_SOLICITUD%TYPE;
      vOficina              TC.TC_SOLICITUD_TARJETA.OFICINA%TYPE;
      vOficinaEntrega       TC.TC_SOLICITUD_TARJETA.OFICINA_ENTREGA_TARJ%TYPE;
      vDescOficina          PA.AGENCIA.DESCRIPCION%TYPE;
      vCodPromotor          PR.PR_ANALISTAS.CODIGO_PERSONA%TYPE;
      vDescPromotor         PR.PR_ANALISTAS.NOMBRE_ANALISTA%TYPE;
      vCodigoActividad      TC.TC_SOLICITUD_TARJETA.CODIGO_ACTIVIDAD%TYPE;
      vCodigoSubActividad   TC.TC_SOLICITUD_TARJETA.CODIGO_SUBACTIVIDAD%TYPE;
      vCodigoSubClase       TC.TC_SOLICITUD_TARJETA.CODIGO_SUB_CLASE%TYPE;
      vCodPais_Est          TC.TC_SOLICITUD_TARJETA.COD_PAIS_EST%TYPE;
      vDescPais_Est         PAIS.pais%type; 
      vCodRegion_Est        TC.TC_SOLICITUD_TARJETA.COD_REGION_EST%TYPE;
      vDesRegion_Est        PROVINCIAS.descripcion%type; 
      vCodProvincia_Est     TC.TC_SOLICITUD_TARJETA.COD_PROVINCIA_EST%TYPE;
      vDescProvincia_Est    CANTONES.descripcion%type;
      vCodCiudad_Est        TC.TC_SOLICITUD_TARJETA.COD_CIUDAD_EST%TYPE;
      vDescCiudad_Est       DISTRITOS.descripcion%TYPE;
      vCodMunicipio_est     TC.TC_SOLICITUD_TARJETA.COD_MUNICIPIO_EST%TYPE;
      vDescMunicipio_Est    PUEBLOS.DESCRIPCION%TYPE;
      vDescSector           SECTORES.DESCRIPCION%TYPE;
      vDescactividad_ciiu   pa.actividades_economicas_bc_ciiu.concepto%type;
      vDescactividad        actividades_economicas.descripcion%type;
      vDescsubactividad     sub_actividades_economicas.descripcion%type;
      vDescsubclase         sub_sub_actividades_economicas.descripcion%type;
      vDescAgencia          agencia.descripcion%type;
      vTipoMonedaTarjeta    TC.TC_PROD_EMIS_TJT.TIP_RESTRICC_USO%TYPE;
      vCodEmisor            TC.TC_PROD_EMIS_TJT.COD_EMISOR%TYPE;
      vValidaLimite         BOOLEAN := FALSE;
      vNombrePlastico       TC.TC_SOLICITUD_TARJETA.NOMBRE_PLASTICO%TYPE;
      vCasadaApellido       VARCHAR2(60);
      
   BEGIN
      outError := null;
      vFechaSolicitud := nvl(inFechaSolicitud,TRUNC(sysdate));
      vOficina        := inOficinaOrigen;  
      
      IF inOficinaEntrega is null or inOficinaEntrega = 0 then
          BEGIN
          
              SELECT e.cod_agencia_labora  
                INTO vOficinaEntrega
                FROM empleados e
               WHERE cod_empresa = '1'
                 AND id_empleado = inCodPromotor;
          EXCEPTION WHEN NO_DATA_FOUND THEN
            vOficinaEntrega := vOficina;
          END;
      else
        vOficinaEntrega := inOficinaEntrega;
      end if;     
      
      vValida := Valida_Campos( inOficina             => vOficina,
                                inNombrePlastico      => UPPER(inNombrePlastico),
                                inCodTipoProducto     => inTipoProducto,
                                inTipoEmision         => inTipoEmision,
                                inFechaSolicitud      => vFechaSolicitud,
                                inIndTipoTarjeta      => inTipoTarjeta,
                                inIndPlastico         => 'S',
                                inCupoIndependiente   => 'N' ,
                                inOficinaEntregaTarj  => inOficinaEntrega,
                                inCodPromotor         => inCodPromotor,
                                inCodSistema          => 'TC',
                                inCodCicloFact        => inCodCicloFact,
                                inCupoSolicitadoRD    => inMontoSolicitadoRD, 
                                inCupoSolicitadoUS    => inMontoSolicitadoUS, 
                                inTipoMonedaTarjeta   => inTipoMonedaTarjeta,
                                inMensaje             => outError);

      IF vValida THEN  
            vCodTipoId  := inTipoId;
            vNumId      := inNumId;                                    
            outError    := NULL;
            CodPersonaById(outCodPersona    => vCodPersona,
                           outTipoId        => vCodTipoId,                                                        
                           outNumId         => vNumId,
                           outError         => outError);
      
            IF outError IS NOT NULL THEN
                RAISE_APPLICATION_ERROR(-20100, outError);
            END IF;                   
       
            vExisteCliente := existe_cliente(vCodPersona);
                
            IF NVL (vExisteCliente, 0) = 0 THEN
               outError := 'Esta persona no está creado como Cliente, favor verificar...'||vCodPersona;
               RAISE_APPLICATION_ERROR(-20404, outError);
            END IF;
            
            BEGIN    
                TC.TC_SOLICITUD.Datos_per_fisica(  inCodPersona          => vCodPersona,
                                                   outEstado_civil       => outEstado_civil,
                                                   outSexo               => outSexo,
                                                   OutFecha_nacimiento   => outFecha_nacimiento,
                                                   OutApellido1          => outApellido1,
                                                   OutApellido2          => outApellido2,
                                                   OutPrimerNombre       => outPrimerNombre,
                                                   OutSegundoNombre      => outSegundoNombre,
                                                   OutCasadaApellido     => vCasadaApellido,
                                                   OutNum_dependientes   => outNum_dependientes,                                                   
                                                   OutProfesion          => outProfesion,
                                                   OutTipoVivienda       => outTipoVivienda,
                                                   outEmail              => outEmail,
                                                   outTelefono           => outTelefono,
                                                   outError              => outError);          
                                               
                                                                                                   
            
                vEstadoSolicitud        := 'P';
                vEstado_documentacion   := 'P';
                vEstado                 := 'P';                    
            EXCEPTION WHEN OTHERS THEN
                IF outError IS NULL THEN
                    outError := SUBSTR(SQLERRM,1, 3000);
                END IF;
                RAISE_APPLICATION_ERROR(-20100, SUBSTR(outError,1,3000));           
            END;
                        
            
            vSolicitudNumero := Verifica_Existe_Solicitud (pTipoId           => vCodTipoId,
                                                           pNumId            => vNumId,
                                                           pTipoProd         => inTipoProducto,
                                                           outFechaSolicitud => vFechaSolicitud,
                                                           outOficina        => vOficina,
                                                           outEstado         => vEstadoSolicitud,
                                                           outError          => outError);
            IF outError IS NOT NULL THEN
                RAISE_APPLICATION_ERROR(-20100, outError);                
            END IF; 
            
            IF vSolicitudNumero > 0 THEN
                RAISE_APPLICATION_ERROR(-20100, outError);                
            ELSE
                BEGIN
                    Solicitud_Empleado( pCodPersona       => vCodPersona,
                                        pEmpresa          => 1,
                                        pAgencia          => vOficina,
                                        pOficina          => vOficina,
                                        pDescOficina      => vDescOficina,
                                        pPromotor         => vCodPromotor,
                                        pDescPromotor     => vDescPromotor,
                                        pEmpleado         => vEmpleadoAdemi,
                                        outError          => outError);
                   
                    IF vEmpleadoAdemi = 'S' THEN
                        IF outError IS NOT NULL THEN
                            RAISE_APPLICATION_ERROR(-20100, outError);
                        END IF;                    
                    END IF; 
                EXCEPTION WHEN OTHERS THEN
                    IF outError IS NULL THEN
                        outError := SUBSTR(SQLERRM,1, 3000);
                    END IF;
                    RAISE_APPLICATION_ERROR(-20100, SUBSTR(outError,1,3000));           
                END;
                
                BEGIN
                    Buscar_actividad(  inSegregacionRD             => inSegregacionRD,
                                       outCodigoActividad          => vCodigoActividad,
                                       outCodigoSubactividad       => vCodigoSubactividad,
                                       outCodigoSubClase           => vCodigoSubClase,
                                       outDescactividad_ciiu       => vDescactividad_ciiu,
                                       outDescactividad            => vDescactividad,
                                       outDescsubactividad         => vDescsubactividad, 
                                       outDescsubclase             => vDescsubclase,  
                                       outError                    => outError);
                                        
                    IF outError IS NOT NULL THEN
                        RAISE_APPLICATION_ERROR(-20100, outError);                    
                    END IF;
                EXCEPTION WHEN OTHERS THEN
                    IF outError IS NULL THEN
                        outError := SUBSTR(SQLERRM,1, 3000);
                    END IF;
                    RAISE_APPLICATION_ERROR(-20100, SUBSTR(outError,1,3000));           
                END;
                
                BEGIN
                    Oficina_entrega( inOficinaEntregaTarj       => vOficinaEntrega,
                                     outDesAgencia              => vDescAgencia, 
                                     outCodPais_est             => vCodPais_Est,
                                     outDescPais_est            => vDescPais_Est,
                                     outCodRegion_est           => vCodRegion_Est,
                                     outDescRegion_est          => vDesRegion_Est,
                                     outCodProvincia_est        => vCodProvincia_Est,
                                     outDescProvincia_est       => vDescProvincia_Est,
                                     outCodCiudad_est           => vCodCiudad_Est,
                                     outDescCiudad_est          => vDescCiudad_Est,
                                     outCodMunicipio_est        => vCodMunicipio_est,
                                     outDescMunicipio_est       => vDescMunicipio_Est,
                                     outError                   => outError );
                    
                    IF outError IS NOT NULL THEN
                        RAISE_APPLICATION_ERROR(-20100, outError);                    
                    END IF;                                        
                    
                EXCEPTION WHEN OTHERS THEN
                    IF outError IS NULL THEN
                        outError := SUBSTR(SQLERRM,1, 3000);
                    END IF;
                    RAISE_APPLICATION_ERROR(-20100, SUBSTR(outError,1,3000));           
                END;                                           
                                   
                vCodEmisor := Param.parametro_x_empresa(1, 'COD_EMISOR', 'TC');
                
                begin
                   select tip_restricc_uso
                     into vTipoMonedaTarjeta                          
                     from tc_prod_emis_tjt
                    where cod_emisor      = vCodEmisor
                      and cod_prod_emisor = inTipoProducto
                      and cod_empresa     = 1;
                      
                exception
                    when no_data_found then
                   IF outError IS NULL THEN
                        outError := SUBSTR('Datos Tipo de producto no encontrados. '||vCodEmisor||' '||inTipoProducto||' '||SQLERRM,1, 3000);
                   END IF;
                   RAISE_APPLICATION_ERROR(-20100, SUBSTR(outError,1,3000));
                end;
                
                vValidaLimite := TC.TC_Solicitud.Valida_Monto_Solicitado(pTipoMonedaTarjeta    =>  vTipoMonedaTarjeta,
                                                                         pCupoSolicitadoRD     =>  inMontoSolicitadoRD,
                                                                         pCupoSolicitadoUS     =>  inMontoSolicitadoUS,
                                                                         pTipoCampo            =>  pa_utl.obtiene_tipo_cambio(1, 1, SYSDATE),
                                                                         pTipoProducto         =>  inTipoProducto,
                                                                         pCodEmisor            =>  vCodEmisor,
                                                                         outError              =>  outError);
        
        
                IF vValidaLimite = FALSE THEN
                    IF outError IS NULL THEN
                        outError := SUBSTR(SQLERRM,1, 3000);
                    END IF;
                    RAISE_APPLICATION_ERROR(-20100, SUBSTR(outError,1,3000));
                END IF;
                
                IF inNombrePlastico IS NOT NULL THEN
                
                    IF LENGTH(inNombrePlastico) > 21 THEN
                        outError := 'La longitud del nombre del plastico sobrepasa los 21 caracteres.';
                        RAISE_APPLICATION_ERROR(-20100, SUBSTR(outError,1,3000));
                    END IF;
                    vNombrePlastico := UPPER(REPLACE(inNombrePlastico,' ',','));
                ELSE 
                    vNombrePlastico := SUBSTR(REPLACE(outPrimerNombre,' ',',')||','||REPLACE(outApellido1,' ',','),1,21);
                END IF;
                
                BEGIN
                     BEGIN
                         select c.cod_provincia
                           into outCodProvincia
                           from PA.CANTONES c
                          where c.cod_pais = NVL(outCodPais,1)
                            and C.COD_CANTON = outCodCanton;
                     EXCEPTION WHEN NO_DATA_FOUND THEN
                            outError := 'Codigo de la region en la solicitud no encontrados '||outCodCanton;
                            RAISE_APPLICATION_ERROR(-20100, SUBSTR(outError,1,3000));
                        WHEN TOO_MANY_ROWS THEN
                            outError := 'Codigo de la region en la solicitud no determinados '||outCodCanton;
                        RAISE_APPLICATION_ERROR(-20100, SUBSTR(outError,1,3000));
                     END;                     
                     vDescSector     := PA.OBT_DESC_SECTOR ( NVL(outCodPais,1), outCodProvincia, outCodCanton, outCodDistrito, outCodCiudad, inSector_Res);
                     
                     IF vDescSector IS NULL THEN
                        outError := 'Datos del sector en la solicitud no encontrados Pais='||outCodPais||' Provincia='||outCodProvincia||' Canton='||outCodCanton||' Distrito='||outCodDistrito||' Ciudad='||outCodCiudad||' Sector='||inSector_Res;
                        RAISE_APPLICATION_ERROR(-20100, SUBSTR(outError,1,3000));
                     END IF;
                     
                EXCEPTION WHEN OTHERS THEN
                    outError := 'Datos del sector en la solicitud no encontrados Pais='||outCodPais||' Provincia='||outCodProvincia||' Canton='||outCodCanton||' Distrito='||outCodDistrito||' Ciudad='||outCodCiudad||' Sector='||inSector_Res||' '||SQLERRM;
                    RAISE_APPLICATION_ERROR(-20100, SUBSTR(outError,1,3000));
                END;
                
                /*DBMS_OUTPUT.PUT_LINE(' pCOD_PERSONA = '|| vCodPersona||
                     ' pNO_SOLICITUD = '|| vSolicitudNumero||
                     ' pNUM_ID = '|| vNumId||
                     ' pCOD_TIPO_PRODUCTO = '|| inTipoProducto||
                     ' pFECHA_SOLICITUD = '|| vFechaSolicitud||
                     ' pCOD_TIPO_ID = '|| vCodTipoId||
                     ' pNOMBRE_PLASTICO = '|| UPPER(NVL(inNombrePlastico,vNombrePlastico))||
                     ' pCOD_CICLO_FACT = '|| LPAD(inCodCicloFact,2, '0')||
                     ' pCUPO_SOLICITADO_RD = '|| inMontoSolicitadoRD||
                     ' pESTADO_DOCUMENTACION = '|| vEstado_documentacion||
                     ' pOFICINA = '|| vOficina||
                     ' pOFICINA_ENTREGA_TARJ = '|| vOficinaEntrega||
                     ' pCOD_PAIS = '|| NVL(outCodPais,1)||
                     ' pCOD_PROVINCIA = '|| TRIM(outCodProvincia)||
                     ' pCOD_CANTON = '|| TRIM(outCodCanton)||
                     ' pCOD_DISTRITO = '|| TRIM(outCodDistrito)||
                     ' pCOD_CIUDAD = '|| TRIM(outCodCiudad)||
                     ' pTELEFONO_CORRESP = '|| outTELEFONO_CORRESP||
                     ' pEXT_TELEFONO = '|| outExtTelefono||
                     ' pZPOSTAL_CORRESP = '|| outZPostalCorresp||
                     ' pTIPO_EMISION = '|| inTipoEmision||
                     ' pIND_TIPO_TARJETA = '|| inTipoTarjeta||
                     ' pESTADO = '|| vEstado||
                     ' pLIMITE_ASIGNADO_RD = '|| inMontoSolicitadoRD||
                     ' pLIMITE_ASIGNADO_US = '|| inMontoSolicitadoUS||
                     ' pESTADO_SOLICITUD = '|| vEstadoSolicitud||
                     ' pCOD_PAIS_EST = '|| vCodPais_Est||
                     ' pCOD_REGION_EST = '|| vCodRegion_Est||
                     ' pCOD_PROVINCIA_EST = '|| vCodProvincia_Est||
                     ' pCOD_CIUDAD_EST = '|| vCodCiudad_Est||
                     ' pCOD_MUNICIPIO_EST = '|| vCodMunicipio_est||
                     ' pSECTOR_RES = '|| UPPER(vDescSector)||
                     ' pBARRIO_RES = '|| UPPER(inBarrio_Res)||
                     ' pCALLE_RES = '|| UPPER(inCalle_Res)||
                     ' pNUMERO_RES = '|| UPPER(inNumero_Res)||
                     ' pDETALLE_RES = '|| UPPER(inDetalle_Res)||
                     ' pSEGREGACION_RD = '|| inSegregacionRD||
                     ' pCODIGO_ACTIVIDAD = '|| vCodigoActividad||
                     ' pCODIGO_SUBACTIVIDAD = '|| vCodigoSubActividad||
                     ' pCODIGO_SUB_CLASE = '|| vCodigoSubClase||
                     ' pCUPO_SOLICITADO_US = '|| inMontoSolicitadoUS||
                     ' pCOD_PROMOTOR = '|| inCodPromotor);*/
                
                DBMS_OUTPUT.PUT_LINE('ANTES CREAR SOLICITUD');
                
                BEGIN
                    Crear_Solicitud(  pCOD_PERSONA             => vCodPersona,
                                      pNO_SOLICITUD            => vSolicitudNumero,
                                      pNUM_ID                  => vNumId,
                                      pCOD_TIPO_PRODUCTO       => inTipoProducto,
                                      pFECHA_SOLICITUD         => vFechaSolicitud,
                                      pCOD_TIPO_ID             => vCodTipoId,
                                      pAMPARADA_POR            => NULL,
                                      pNOMBRE_PLASTICO         => UPPER(NVL(inNombrePlastico,vNombrePlastico)),
                                      pCOD_MOTIVO_NEGACION     => NULL,
                                      pCUPO_INDEPENDIENTE      => 'N',
                                      pCOD_CICLO_FACT          => LPAD(inCodCicloFact,2, '0'),
                                      pCOD_TIPO_MERCADO        => NULL,
                                      pCUPO_SOLICITADO_RD      => inMontoSolicitadoRD,
                                      pESTADO_DOCUMENTACION    => vEstado_documentacion,
                                      pCOD_TIPO_CLIENTE        => '1',
                                      pOFICINA                 => vOficina,
                                      pIND_PLASTICO            => 'S',
                                      pIND_DIFIERE             => 'N',
                                      pCOD_DESPACHO            => NULL,
                                      pOFICINA_ENTREGA_TARJ    => vOficinaEntrega,
                                      pIND_CARGO_AUTOMATICO    => 0,
                                      pCOD_COMPENSACION        => NULL,
                                      pCTA_CARGO_AUTOMATICO    => NULL,
                                      pCTA_ALTERNA             => NULL,
                                      pNUM_ID_CODEUDOR         => NULL,
                                      pTIPO_GARANTIA           => NULL,--inTipoGarantia,
                                      pVALOR_GARANTIA          => NULL,--inValorGarantia,
                                      pMODO_AMORTIZACION       => NULL,
                                      pCLIENTE_PRE_EMBOZO      => NULL,
                                      pMES_INICIAL_AMORT       => NULL,
                                      pEMPRESA_AGENTES         => NULL,
                                      pCOD_AGENTE              => NULL,
                                      pEMP_ASIGNADA_AGTE       => NULL,
                                      pDIRECCION_CORRESP1      => NULL,
                                      pDIRECCION_CORRESP2      => NULL,
                                      pDIRECCION_CORRESP3      => NULL,
                                      pDIRECCION_CORRESP4      => NULL,
                                      pCOD_PAIS                => NVL(outCodPais,1),
                                      pCOD_PROVINCIA           => TRIM(outCodProvincia),
                                      pCOD_CANTON              => TRIM(outCodCanton),
                                      pCOD_DISTRITO            => TRIM(outCodDistrito),
                                      pCOD_CIUDAD              => TRIM(outCodCiudad),
                                      pTELEFONO_CORRESP        => outTELEFONO_CORRESP,
                                      pEXT_TELEFONO            => outExtTelefono,
                                      pZPOSTAL_CORRESP         => outZPostalCorresp,
                                      pTIPO_EMISION            => inTipoEmision,
                                      pIND_TIPO_TARJETA        => inTipoTarjeta,
                                      pESTADO                  => vEstado,
                                      pLIMITE_ASIGNADO_RD      => inMontoSolicitadoRD,
                                      pLIMITE_ASIGNADO_US      => inMontoSolicitadoUS,
                                      pESTADO_SOLICITUD        => vEstadoSolicitud,
                                      pFECHA_NEGACION          => NULL,
                                      pBIN                     => NULL,
                                      pCOD_PAIS_EST            => vCodPais_Est,
                                      pCOD_REGION_EST          => vCodRegion_Est,
                                      pCOD_PROVINCIA_EST       => vCodProvincia_Est,
                                      pCOD_CIUDAD_EST          => vCodCiudad_Est,
                                      pCOD_MUNICIPIO_EST       => vCodMunicipio_est,
                                      pCOD_SECTOR_EST          => NULL,
                                      pCOD_BARRIO_EST          => NULL,
                                      pCOD_CALLE_EST           => NULL,
                                      pNUMERO_EST              => NULL,
                                      pDETALLE_EST             => NULL,
                                      pRES_APR_INMED           => NULL,
                                      pSECTOR_RES              => UPPER(TRIM(vDescSector)),
                                      pBARRIO_RES              => UPPER(inBarrio_Res),
                                      pCALLE_RES               => UPPER(inCalle_Res),
                                      pNUMERO_RES              => UPPER(inNumero_Res),
                                      pDETALLE_RES             => UPPER(inDetalle_Res),
                                      pSEGREGACION_RD          => inSegregacionRD,
                                      pCODIGO_ACTIVIDAD        => vCodigoActividad,
                                      pCODIGO_SUBACTIVIDAD     => vCodigoSubActividad,
                                      pCODIGO_SUB_CLASE        => vCodigoSubClase,
                                      pFEC_DIGITACION          => SYSDATE,
                                      pFEC_RECIBO              => NULL,
                                      pLIMITE_APROBADO_RD      => NULL,
                                      pCUPO_SOLICITADO_US      => inMontoSolicitadoUS,
                                      pLIMITE_APROBADO_US      => NULL,
                                      pFECHA_APROBACION        => NULL,
                                      pUSUARIO_APROBACION      => NULL,
                                      pCOD_PROMOTOR            => inCodPromotor,
                                      pJUSTIF_DENEGADA         => NULL,
                                      pNUMERO_ASIENTO          => NULL,
                                      pCOD_TIPO_ID_CODEUDOR    => NULL,
                                      outError                 => outError);

                    outSolicitudNumero :=  vSolicitudNumero;
                EXCEPTION WHEN OTHERS THEN
                    IF outError IS NULL THEN
                        outError := SUBSTR(SQLERRM,1, 3000);
                    END IF;
                    RAISE_APPLICATION_ERROR(-20100, SUBSTR(outError,1,3000));                                     
                END;
                DBMS_OUTPUT.PUT_LINE('DESPUES CREAR SOLICITUD');
            END IF;            
            
      ELSE
          RAISE_APPLICATION_ERROR(-20100, outError);
      END IF;              
   EXCEPTION WHEN OTHERS THEN
      IF outError IS NULL THEN
        outError := SUBSTR(SQLERRM,1, 3000);
      END IF;
      RAISE_APPLICATION_ERROR(-20100, outError);
                                  
   END procesar_solicitud2; 
   
   --  Verificar que esa persona esté creado como cliente.
   FUNCTION existe_cliente(pCodPersona      IN VARCHAR2) RETURN NUMBER  IS
   
       vExisteCliente   NUMBER := 0;
   BEGIN
        SELECT COUNT(1)
          INTO vExisteCliente
          FROM clientes_b2000
         WHERE codigo_empresa = 1
           AND codigo_cliente = pCodPersona;

        RETURN vExisteCliente;
   END existe_cliente;  
   
   PROCEDURE procesar_adicional(pNo_Solicitud           IN     NUMBER,                                                                
                                pTipo_Identificacion    IN     VARCHAR2,
                                pIdentificacion         IN     VARCHAR2,
                                pPrimer_Nombre          IN OUT VARCHAR2,
                                pSegundo_Nombre         IN OUT VARCHAR2,
                                pPrimer_Apellido        IN OUT VARCHAR2,
                                pSegundo_Apellido       IN OUT VARCHAR2,
                                pNombre_Plastico        IN OUT VARCHAR2,
                                pFechaNacimiento        IN OUT DATE,
                                pSexo                   IN OUT VARCHAR2,
                                pEstado_civil           IN OUT VARCHAR2,
                                pEmail                  IN OUT VARCHAR2,
                                pTelefono               IN OUT VARCHAR2,
                                pCod_Parentesco         IN     NUMBER,                                
                                pSecuencia              IN     NUMBER,
                                pLimite_Solicitado_Rd   IN     NUMBER,
                                pLimite_Solicitado_Us   IN     NUMBER,
                                outNo_Solicitud_Adi     IN OUT NUMBER, 
                                outError                IN OUT VARCHAR2) IS
                                
        vCodPersona            TC.TC_SOLICITUD_TARJETA.COD_PERSONA%TYPE;
        vCodPersonaAdic        TC.TC_SOLICITUD_TARJETA.COD_PERSONA%TYPE;
        vTipoId                TC.TC_SOLICITUD_TARJETA.COD_TIPO_ID%TYPE;
        vTipoIdAdic            TC.TC_SOLICITUD_TARJETA.COD_TIPO_ID%TYPE;
        vNumId                 TC.TC_SOLICITUD_TARJETA.NUM_ID%TYPE;
        vIdentificacion        TC.TC_SOLICITUD_TAR_ADICIONALES.IDENTIFICACION%TYPE;
        vLimiteRD              TC.TC_SOLICITUD_TARJETA.CUPO_SOLICITADO_RD%TYPE;
        vLimiteUS              TC.TC_SOLICITUD_TARJETA.CUPO_SOLICITADO_US%TYPE;                          
        vDescripcion           tipos_id.Descripcion%type; 
        vMascara               PA.TIPOS_ID.MASCARA%TYPE;
        vIdTamanoFijo          PA.TIPOS_ID.ID_TAMANO_FIJO%TYPE;
        vProfesion             VARCHAR2(200);
        vTipoVivienda          VARCHAR2(200);
        vApellidoCasada        PA.PERSONAS_FISICAS.APELLIDO_CASADA%TYPE;
        vNumDependientes       NUMBER := 0; 
        vCasadaApellido        VARCHAR2(60);
        vError                 TC.TC_SOLICITUD_TAR_ADIC.resultado;
        
        
        
   BEGIN
      --  Datos de la solicitud
      BEGIN
          SELECT S.COD_PERSONA, S.COD_TIPO_ID, S.NUM_ID, S.CUPO_SOLICITADO_RD, S.CUPO_SOLICITADO_US
            INTO vCodPersona, vTipoId, vNumId, vLimiteRD, vLimiteUS
            FROM TC.TC_SOLICITUD_TARJETA s
           WHERE NO_SOLICITUD = pNo_Solicitud;
      EXCEPTION WHEN NO_DATA_FOUND THEN
          outError := 'Error Datos de la Solicitud no encontrados.  Debe crearse la solicitud primero.';
          RAISE_APPLICATION_ERROR(-20404, outError);
      END;  
      
      --  Tipo Identificacion      
      TIPOS_ID_PERSONAS (pTipo_Identificacion,
                         vDescripcion,
                         vMascara,
                         vIdTamanoFijo,
                         outError) ;
      
      IF REPLACE(pTipo_Identificacion,'-') = REPLACE(vTipoId,'-')
          and REPLACE(pIdentificacion,'-') = REPLACE(vNumId,'-') then
          outError := 'Error: el número de identificación del adicional no puede ser la misma que la del solicitante principal';
          RAISE_APPLICATION_ERROR(-20404, outError);
      END IF;
      
      if vMascara IS NOT NULL THEN 
          vIdentificacion := pa.formatear_identificacion (pIdentificacion,vMascara,'ES');
          IF  NOT validar_formato(vIdentificacion,vMascara,'ES',vIdTamanoFijo) THEN    
              outError := 'Error: El número de identificación del adicional no es valido.';
              RAISE_APPLICATION_ERROR(-20404, outError);
          END IF;    
      END IF; 
      
      IF pTipo_Identificacion = '1' then -- Para Cedula de Identidad Electoral            
          IF p_digito_verificador(vIdentificacion, pTipo_Identificacion)!= 'S' then                   
             outError := 'Error: El número de Identificación Inválida, Verifíque.'; 
             RAISE_APPLICATION_ERROR(-20404, outError);
          END IF;                    
      ELSIF pTipo_Identificacion  = '2' then -- [2] Para Registro Nacional de Contribuyentes
           IF p_digito_verificador(vIdentificacion, pTipo_Identificacion)!= 'S' then     
                outError := 'Error: El número de RNC Inválido, Verifíque.'; 
                RAISE_APPLICATION_ERROR(-20404, outError);
           END IF;
      END IF;
        
      IF pTipo_Identificacion = '1' THEN
          IF pa_utl.consulta_padron_rd (REPLACE(vIdentificacion,'-')) = 0 THEN
             outError := 'Error: El número de Identificación no se encuentra en el padrón.'; 
             RAISE_APPLICATION_ERROR(-20404, outError);
          ELSE
             BEGIN
             
                pa_utl.obtiene_info_padron_rd (REPLACE(vIdentificacion,'-'),
                                               pPrimer_Apellido,
                                               pSegundo_Apellido,
                                               vApellidoCasada,
                                               pPrimer_Nombre,
                                               pSexo,
                                               pFechaNacimiento);
                                               
                IF INSTR(pPrimer_Nombre,' ') > 0 THEN
                    pSegundo_Nombre := SUBSTR(pPrimer_Nombre,INSTR(pPrimer_Nombre,' ')+1,30);
                    pPrimer_Nombre  := SUBSTR(SUBSTR(pPrimer_Nombre,1,INSTR(pPrimer_Nombre,' ')-1),1,30);
                ELSE
                    pPrimer_Nombre := SUBSTR(pPrimer_Nombre,1,30);
                END IF;
                pNombre_Plastico := SUBSTR(pPrimer_Nombre || ' ' ||pPrimer_Apellido,1,21);
             END;
          END IF;
      END IF; 
      
      --  Buscar Cod_persona 
      BEGIN
         vTipoIdAdic := pTipo_Identificacion;
         CodPersonaById(outCodPersona    => vCodPersonaAdic,
                        outTipoId        => vTipoIdAdic,                                                        
                        outNumId         => vIdentificacion,
                        outError         => outError);
                        
      EXCEPTION WHEN OTHERS THEN
         NULL;
      END;
       
      IF vCodPersonaAdic IS NOT NULL THEN
          BEGIN   
             TC.TC_SOLICITUD.Datos_per_fisica( 
                               inCodPersona          => vCodPersonaAdic,
                               outEstado_civil       => pEstado_civil,
                               outSexo               => pSexo,
                               OutFecha_nacimiento   => pFechaNacimiento,
                               OutApellido1          => pPrimer_Apellido,
                               OutApellido2          => pSegundo_Apellido,
                               OutPrimerNombre       => pPrimer_Nombre,
                               OutSegundoNombre      => pSegundo_Nombre,
                               OutCasadaApellido     => vCasadaApellido,
                               OutNum_dependientes   => vNumDependientes,
                               OutProfesion          => vProfesion,
                               OutTipoVivienda       => vTipoVivienda,
                               outEmail              => pEmail,
                               outTelefono           => pTelefono,
                               outError              => outError);
          EXCEPTION WHEN OTHERS THEN
             IF outError IS NULL THEN
                outError := 'Error: Los datos de la persona no se encuentran.';
             END IF; 
             RAISE_APPLICATION_ERROR(-20404, outError);
          END;
      END IF;                               

      TC.TC_SOLICITUD_TAR_ADIC.Generar( pCod_Persona            => vCodPersona,
                                        pTipo_Solicitud         => '0001',
                                        pNo_Solicitud           => pNo_Solicitud,
                                        pPrimer_Nombre          => pPrimer_Nombre,
                                        pSegundo_Nombre         => pSegundo_Nombre,
                                        pPrimer_Apellido        => pPrimer_Apellido,
                                        pSegundo_Apellido       => pSegundo_Apellido,
                                        pNombre_Plastico        => pNombre_Plastico,
                                        pCod_Parentesco         => pCod_Parentesco,
                                        pFecha_Nacimiento       => pFechaNacimiento,
                                        pTipo_Identificacion    => pTipo_Identificacion,
                                        pIdentificacion         => vIdentificacion,
                                        pNum_Tarjeta            => NULL,
                                        pEstado                 => 'P',
                                        pEmail                  => pEmail,
                                        pSexo                   => pSexo,
                                        pEstado_Civil           => pEstado_civil,
                                        pSecuencia              => pSecuencia,
                                        pCod_Persona_Adi        => vCodPersonaAdic,
                                        pNumero_Sol_Proveedor   => pNo_Solicitud,
                                        pNo_Solicitud_Adi       => outNo_Solicitud_Adi,
                                        pLimite_Solicitado_Rd   => pLimite_Solicitado_Rd,
                                        pLimite_Solicitado_Us   => pLimite_Solicitado_Us,
                                        pResultado              => vError);

        IF vError.descripcion IS NOT NULL THEN
            outError := vError.descripcion;
        END IF;                                        
                                          
   END procesar_adicional;
   
   Procedure TIPOS_ID_PERSONAS (pTipo_Identificacion IN VARCHAR2,
                               pDescripcion          IN OUT VARCHAR2,
                               PMascara              IN OUT varchar2,
                               pIdTamanoFijo         IN OUT VARCHAR2,
                               outError              IN OUT VARCHAR2) IS--  Tipo Identificacion      
   BEGIN
          SELECT descripcion, mascara, id_tamano_fijo
            INTO pDescripcion, pMascara, pIdTamanoFijo
            FROM Pa.tipos_id
           WHERE Cod_tipo_id = pTipo_Identificacion;      
   EXCEPTION 
         WHEN NO_DATA_FOUND THEN
              outError := 'Este tipo de identificación no existe, favor verifique...';
              RAISE_APPLICATION_ERROR(-20404, outError);
         WHEN OTHERS THEN
              outError := 'Error buscando el tipo de identificación:'||sqlerrm;
              RAISE_APPLICATION_ERROR(-20404, outError);
   END TIPOS_ID_PERSONAS;
  
   FUNCTION Validar_Formato (  pIdentificacion IN VARCHAR2,
                               pFormato        IN VARCHAR2,
                               pCodIdioma      IN VARCHAR2,
                               pValideTamano   IN VARCHAR2 DEFAULT 'S'
                            ) 
     RETURN BOOLEAN IS

       Cont       number(2);
       Len        number(2);
       CarpFormato VARCHAR2(1);
       CarIdent   VARCHAR2(1);
       vError       VARCHAR2(4000);


          -- ESTE PROCEDIMIENTO RECIBE COMO PARAMETRO UN STRING CONTENIENDO UN
          -- NUMERO DE pIdentificacion Y OTRO CONTENIENDO EL pFormato QUE DEBERIA
          -- TENER DICHO NUMERO DE pIdentificacion.
          -- RETORNA EN UN PARAMETRO NUMERICO 1 SI CUMPLE CON EL PARAMETRO 
          -- O 0 SI NO CUMPLE.
          --
      
          -- REQUIERE:
          --   Los parametros no pueden ser nulos.
          --
          -- MODIFICACIONES
          --   GVIQ, 6-JUL-1994
          --     Ahora no es un procedure sino una funcion que devuelve un valor
          --     booleano: TRUE si no hay problema o FALSE en contrario.  Ademas,
          --     en caso de error, devuelve un mensaje.

          -- Erick Villalobos, 3-FEB-1995
          -- Incorporacion de la funcion a BANCA3000
          --
          -- YMUR : 22/feb/1995
          --       Los mensajes de error se registraron en la base de datos
          --       para que Banca*3000 lo maneje.  Consecuentemente elimine
          --       parametros MENSAJE_P, ya que no es necesario, y el codigo
          --       del idioma (pCodIdioma).

          --   MPRE, 28-NOV-1997
          --     Ahora se permite que la mascara sea nula, en cuyo caso no se realiza
          --     validacion.  Tambien se pasa parametro nuevo qie permite que no se
          --     valide el tamaño del numero de identificacion, de tal manera que
          --     la identificacion pueda tener menos digitos que la mascara

    begin
       -- No se realiza validacion si la mascara es nula
       if pFormato is not null
       then
          -- Se obtiene la longitud de la identificacion a validar
          Len := NVL(length(pIdentificacion), 0);

          -- Se realiza la validacion del tamaño si es del caso
          if ( Len < NVL(length(pFormato), 0) and pValideTamano = 'S' )
          or ( Len > NVL(length(pFormato), 0) )
          then
             vError := 'Hacen falta o sobran caracteres de acuerdo al formato de la identificacion.'|| pFormato;
             return FALSE;
          else
             Cont := 1;
             while (Cont <= Len) loop
                CarpFormato := substr(pFormato, Cont, 1);
                CarIdent := substr(pIdentificacion, Cont, 1);

                if (CarpFormato = 'X' and CarIdent not between 'A' and 'Z')
                or (CarpFormato = 'N' and CarIdent not between '0' and '9')
                or (CarpFormato = 'A' and CarIdent not between '0' and '9' 
                                      and CarIdent not between 'A' and 'Z')
                or (CarpFormato = '-' and CarIdent <> '-') 
                then
                    vError := 'Caracter invalido de acuerdo al formato de la identificacion.'|| pFormato ;
                   return FALSE;
                end if;

                Cont := Cont + 1;
             end loop;
          end if;
       end if;

       return TRUE;
    end Validar_Formato; -- Valida_Formato

   
   PROCEDURE buscar_actividad(  inSegregacionRD             IN     VARCHAR2,
                                outCodigoActividad          IN OUT VARCHAR2,
                                outCodigoSubactividad       IN OUT VARCHAR2,
                                outCodigoSubClase           IN OUT VARCHAR2,
                                outDescactividad_ciiu       IN OUT VARCHAR2,
                                outDescactividad            IN OUT VARCHAR2,
                                outDescsubactividad         IN OUT VARCHAR2,
                                outDescsubclase             IN OUT VARCHAR2,
                                outError                    IN OUT VARCHAR2
                             ) IS
   
    Begin
        SELECT act.division, act.grupo, act.rama,
               act.concepto, ae.descripcion desc_div, sae.descripcion desc_grupo, ssae.descripcion desc_rama
          INTO outCodigoActividad, outCodigoSubactividad, outCodigoSubClase, 
               outDescactividad_ciiu, outDescactividad, outDescsubactividad, outDescsubclase 
          FROM pa.actividades_economicas_bc_ciiu act,
               actividades_economicas ae,
               sub_actividades_economicas sae,
               sub_sub_actividades_economicas ssae
         WHERE segregacion_rd                = inSegregacionRD
           AND ae.codigo_actividad        (+)= act.division
           AND sae.codigo_actividad       (+)= act.division
           AND sae.codigo_subactividad    (+)= act.grupo
           AND ssae.codigo_actividad      (+)= act.division
           AND ssae.codigo_subactividad   (+)= act.grupo
           AND ssae.codigo_subsubactividad(+)= act.rama;
                
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
        outError := 'Código Actividad CIIU no existe, favor verificar...';
        RAISE_APPLICATION_ERROR(-20404, outError);
    End buscar_actividad;
   
    PROCEDURE oficina_entrega(inOficinaEntregaTarj      IN     VARCHAR2,
                             outDesAgencia              IN OUT VARCHAR2,
                             outCodPais_est             IN OUT VARCHAR2,
                             outDescPais_est            IN OUT VARCHAR2,
                             outCodRegion_est           IN OUT VARCHAR2,
                             outDescRegion_est          IN OUT VARCHAR2,
                             outCodProvincia_est        IN OUT VARCHAR2,
                             outDescProvincia_est       IN OUT VARCHAR2,
                             outCodCiudad_est           IN OUT VARCHAR2,
                             outDescCiudad_est          IN OUT VARCHAR2,
                             outCodMunicipio_est        IN OUT VARCHAR2,
                             outDescMunicipio_est       IN OUT VARCHAR2,
                             outError                   IN OUT VARCHAR2 ) IS
    Begin
        select age.cod_pais, age.descripcion, pai.pais desc_pais,
               age.cod_provincia cod_region, pro.descripcion desc_region,  
               age.cod_canton cod_provincia, can.descripcion desc_provincia,
               age.cod_distrito, ciu.descripcion desc_ciudad,
               age.cod_pueblo, mun.descripcion desc_municipio
          into outCodPais_est, outDesAgencia, outDescPais_est,               
               outCodRegion_est, outDescRegion_est,
               outCodProvincia_est, outDescProvincia_est,
               outCodCiudad_est,  outDescCiudad_est, 
               outCodMunicipio_est, outDescMunicipio_est
          from agencia    age,
               pais       pai,
               provincias pro,
               cantones   can,
               distritos  ciu,
               pueblos    mun
         where age.cod_empresa      = 1 
           and age.cod_agencia      = inOficinaEntregaTarj
           and pai.cod_pais      (+)= age.cod_pais
           and pro.cod_pais      (+)= age.cod_pais
           and pro.cod_provincia (+)= age.cod_provincia 
           and can.cod_pais      (+)= age.cod_pais
           and can.cod_provincia (+)= age.cod_provincia
           and can.cod_canton    (+)= age.cod_canton
           and ciu.cod_pais      (+)= age.cod_pais 
           and ciu.cod_provincia (+)= age.cod_provincia
           and ciu.cod_canton    (+)= age.cod_canton
           and ciu.cod_distrito  (+)= age.cod_distrito
           and mun.cod_pais      (+)= age.cod_pais 
           and mun.cod_provincia (+)= age.cod_provincia
           and mun.cod_canton    (+)= age.cod_canton
           and mun.cod_distrito  (+)= age.cod_distrito
           and mun.cod_pueblo    (+)= age.cod_pueblo;
           
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
        outError := 'Oficina de entrega ('||inOficinaEntregaTarj||') no existe, favor verificar...';
        RAISE_APPLICATION_ERROR(-20404, outError);
    END oficina_entrega;

   FUNCTION Verifica_Existe_Solicitud (pTipoId   IN VARCHAR2, 
                                       pNumId    IN VARCHAR2,
                                       pTipoProd IN VARCHAR2,
                                       outFechaSolicitud IN OUT DATE,
                                       outOficina        IN OUT VARCHAR2,
                                       outEstado         IN OUT VARCHAR2,
                                       outError          IN OUT VARCHAR2)
     RETURN NUMBER IS
            
      CURSOR c_Solicitud IS 
      SELECT s.no_solicitud, s.fecha_solicitud, s.oficina, s.estado_solicitud
        FROM tc.tc_solicitud_tarjeta s
       WHERE s.estado_solicitud NOT IN ('E', 'F', 'R')
         AND REPLACE(s.num_id,'-','') = REPLACE(pNumId,'-','');
      
      TYPE tSolicitud IS TABLE OF c_Solicitud%ROWTYPE;      
      vSolicitud            tSolicitud := tSolicitud();      
      vDescripcionSolicitud PA.PA_CATALOGO_CODIGOS.DESCRIPCION%TYPE;
      nSolicitud            NUMBER := 0;
    BEGIN
        vSolicitud.DELETE;
        
        OPEN c_Solicitud;
        
        LOOP
        
            vSolicitud.DELETE;
            FETCH c_Solicitud BULK COLLECT INTO vSolicitud LIMIT 500;
            
            FOR i IN 1 .. vSolicitud.COUNT LOOP
                
                outFechaSolicitud   := vSolicitud(i).fecha_solicitud;
                outEstado           := vSolicitud(i).estado_solicitud;
                outOficina          := vSolicitud(i).oficina;
                
                vDescripcionSolicitud := desc_estado_solicitud(outEstado);
                outError              := 'Cliente ya tiene una solicitud en el Sistema, Solicitud # ' || TO_CHAR (vSolicitud(i).no_solicitud) || 
                                         ' del día ' || TO_CHAR (outFechaSolicitud, 'DD/MM/YYYY') || ' en la agencia ' || outOficina || ', estado de la solicitud: ' || vDescripcionSolicitud||' debe completar el proceso.';
                nSolicitud := vSolicitud(i).no_solicitud;
                EXIT;                
                
            END LOOP;
            
            EXIT WHEN c_Solicitud%NOTFOUND;
        END LOOP;        
        CLOSE c_Solicitud;
        
        IF nSolicitud = 0 THEN    
        
            --  Si el cliente no tiene solicitudes pendientes verifica las tarjetas existentes
            IF Verifica_Existe_Tarjeta (pTipoId, pNumId, pTipoProd, outError) = FALSE THEN
                nSolicitud := 0;
            END IF;  
                  
        END IF;
                            
        RETURN nSolicitud;
        
    END Verifica_Existe_Solicitud;    
    
    FUNCTION desc_estado_solicitud(outEstado IN OUT VARCHAR2)
      RETURN VARCHAR2 IS
        vDescripcionSolicitud PA.PA_CATALOGO_CODIGOS.DESCRIPCION%TYPE := NULL;
    BEGIN
    
        BEGIN
           SELECT DESCRIPCION
             INTO vDescripcionSolicitud
             FROM PA.PA_CATALOGO_CODIGOS
            WHERE COD_GEN = '002' 
              AND COD_SEC = outEstado;
        
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
              outEstado := 'P';
              vDescripcionSolicitud := 'PENDIENTE';
        END;
        
        RETURN vDescripcionSolicitud;
        
    END desc_estado_solicitud;
                
    
    FUNCTION Verifica_Existe_Tarjeta (pTipoId   IN VARCHAR2, 
                                      pNumId    IN VARCHAR2,
                                      pTipoProd IN VARCHAR2,
                                      outError  IN OUT VARCHAR2)
      RETURN BOOLEAN IS
        
      
      CURSOR c_tarjetas IS
      SELECT t.codigo_tipo_producto, t.estado
        FROM tc.tc_tarjetas t
       WHERE t.cod_cliente = (SELECT DISTINCT x.cod_persona
                                FROM pa.id_personas x
                               WHERE x.cod_tipo_id = pTipoId 
                                 AND REPLACE(x.num_id,'-','') = REPLACE(pNumId,'-',''));

      TYPE t_Tarjetas IS TABLE OF c_tarjetas%ROWTYPE;
      vTarjetas  t_Tarjetas := t_Tarjetas();       
      vRetorno   BOOLEAN := FALSE;
      
   BEGIN
        -- Determinar si el cliente tiene tarjetas canceladas anteriormente del mismo tipo de producto
        OPEN c_tarjetas;
        vTarjetas.DELETE;
        vRetorno := TRUE;
        LOOP
            FETCH c_tarjetas BULK COLLECT INTO vTarjetas LIMIT 500;
            
            FOR i IN 1 .. vTarjetas.COUNT LOOP
            
                IF vTarjetas(i).codigo_tipo_producto = pTipoProd THEN 
                    IF vTarjetas(i).estado IN (1, 2, 5) THEN                
                        outError := 'Cliente ya tiene una Tarjeta Activa en el Sistema de este mismo Tipo de Producto '||pTipoProd ||'.';
                        vRetorno := FALSE;
                        EXIT;                    
                    ELSIF vTarjetas(i).estado IN (8) THEN
                        vRetorno := TRUE;                        
                    END IF;
                END IF;
                    
            END LOOP;
            EXIT WHEN c_tarjetas%NOTFOUND;
        END LOOP;
        CLOSE c_tarjetas;
        
        RETURN vRetorno;
        
   END;

   FUNCTION f_get_estado(p_codigo IN pa_catalogo_codigos.cod_sec%TYPE) 
     RETURN  pa_catalogo_codigos.descripcion%TYPE IS
        v_descripcion   pa_catalogo_codigos.descripcion %type;
        
        CURSOR c_datos IS
        SELECT cod_sec,descripcion 
          FROM pa_catalogo_codigos
         WHERE cod_gen = '002'
           AND cod_sec = p_codigo;  
                 
        TYPE tDatos IS TABLE OF c_datos%ROWTYPE;
        vDatos tDatos;                                   
   BEGIN        
        OPEN c_datos;
        FETCH c_datos BULK COLLECT INTO vDatos LIMIT 100;
        CLOSE c_datos;        
        v_descripcion := vDatos(1).descripcion;                        
        RETURN  v_descripcion; 
   END; 

   FUNCTION Valida_Campos(inOficina             IN      VARCHAR2,
                          inNombrePlastico      IN      VARCHAR2,
                          inCodTipoProducto     IN      VARCHAR2,
                          inTipoEmision         IN      VARCHAR2,
                          inFechaSolicitud      IN OUT  DATE,
                          inIndTipoTarjeta      IN      VARCHAR2,
                          inIndPlastico         IN      VARCHAR2,
                          inCupoIndependiente   IN      VARCHAR2,
                          inOficinaEntregaTarj  IN      VARCHAR2,
                          inCodPromotor         IN      VARCHAR2,
                          inCodSistema          IN      VARCHAR2,
                          inCodCicloFact        IN      VARCHAR2,
                          inCupoSolicitadoRD    IN      NUMBER, 
                          inCupoSolicitadoUS    IN      NUMBER,
                          inTipoMonedaTarjeta   IN      VARCHAR2,
                          inMensaje             IN OUT  VARCHAR2)     
     RETURN BOOLEAN IS
        vRetorno        BOOLEAN;
   BEGIN
        vRetorno := TRUE;
        inMensaje := NULL;
        
        IF inOficina IS NULL THEN
            inMensaje := 'Oficina Tramite no puede estar nula.';            
            vRetorno := FALSE;
            RETURN vRetorno;
            
        ELSIF inNombrePlastico IS NULL THEN    
            inMensaje := 'Nombre del Plastico no puede estar nulo.';
            vRetorno := FALSE;
            RETURN vRetorno;
            
        ELSIF inCodTipoProducto IS NULL THEN    
            inMensaje := 'Debe especificar el Tipo de Producto.';            
            vRetorno := FALSE;
            RETURN vRetorno;
            
        ELSIF inTipoEmision IS NULL THEN    
            inMensaje := 'El campo tipo de emisión no puede estar nulo.';        
            vRetorno := FALSE;
            RETURN vRetorno;
        
        ELSIF inFechaSolicitud IS NULL THEN    
            inFechaSolicitud := SYSDATE;
        
        ELSIF inIndTipoTarjeta IS NULL THEN    
            inMensaje := 'El campo indicador del tipo de tarjeta no puede estar nulo.';        
            vRetorno := FALSE;
            RETURN vRetorno;
            
        ELSIF inCupoIndependiente IS NULL THEN    
            inMensaje := 'El campo cupo independiente no puede estar nulo.';        
            vRetorno := FALSE;
            RETURN vRetorno;
            
        ELSIF inIndPlastico IS NULL THEN    
            inMensaje := 'El campo Indicador de plástico no puede estar nulo.';        
            vRetorno := FALSE;
            RETURN vRetorno;
        
        ELSIF inOficinaEntregaTarj IS NULL THEN    
            inMensaje := 'Oficina donde se entregará la Tarjeta no puede estar nula.';            
            vRetorno := FALSE;
            RETURN vRetorno;
        
        ELSIF inCodPromotor IS NULL THEN    
            inMensaje := 'El promotor no puede estar nulo.';        
            vRetorno := FALSE;
            RETURN vRetorno;
        END IF;
        
        IF inCodSistema = 'TC' THEN
        
            IF inCodCicloFact IS NULL THEN    
                inMensaje := 'Debe especificar el día de corte de la tarjeta.';            
                vRetorno := FALSE;
                RETURN vRetorno;
            ELSIF (NVL(inCupoSolicitadoRD,0) + NVL(inCupoSolicitadoUS,0)) <= 0 THEN
                inMensaje := 'No se puede crear Solicitud de Tarjeta sin definir el Límite Solicitado en Pesos y/o Dólares';
                vRetorno := FALSE;
                RETURN vRetorno;
            ELSIF (inTipoMonedaTarjeta = 'A' OR inTipoMonedaTarjeta = 'I') AND NVL(inCupoSolicitadoUS,0) <= 0 THEN
                inMensaje := 'No se puede crear Solicitud de Tarjeta sin definir el Límite Solicitado en Dólares';
                vRetorno := FALSE;
                RETURN vRetorno;
            END IF;            
                    
        END IF;
            
      RETURN(vRetorno);
        
    END Valida_Campos;
    
    FUNCTION Valida_Monto_Solicitado(pTipoMonedaTarjeta     IN VARCHAR2,
                                     pCupoSolicitadoRD      IN NUMBER,
                                     pCupoSolicitadoUS      IN NUMBER,
                                     pTipoCampo             IN NUMBER,
                                     pTipoProducto          IN VARCHAR2,
                                     pCodEmisor             IN VARCHAR2,
                                     outError               IN OUT VARCHAR2) 
      RETURN BOOLEAN IS
       vn_monminimo   NUMBER;
       vn_monmaximo   NUMBER;
       vn_mtosolrd    NUMBER := pCupoSolicitadoRD;
       vn_mtosolus    NUMBER := pCupoSolicitadoUS * NVL(pTipoCampo, 0);
       vn_mtotsoli    NUMBER := 0;
       vn_correcto    NUMBER := 0;
    BEGIN
        outError := NULL;
       IF pTipoMonedaTarjeta = 'A' OR pTipoMonedaTarjeta = 'I' THEN
          IF vn_mtosolrd > 0 AND vn_mtosolus > 0 THEN
             vn_correcto := 1;
          END IF;
       ELSE
          IF vn_mtosolrd > 0 THEN
             vn_correcto := 1;
          END IF;
       END IF;

       IF vn_correcto = 1 THEN
          IF pTipoProducto IS NULL THEN
             outError := 'Debe seleccionar el tipo de producto.';
             RETURN FALSE;
          END IF;

          vn_mtotsoli := vn_mtosolrd + vn_mtosolus;

          BEGIN
             SELECT mon_minimo, mon_maximo
               INTO vn_monminimo, vn_monmaximo
               FROM TC_CUPOS_X_EMISOR
              WHERE     cod_emisor = pCodEmisor
                    AND cod_cupo = pTipoProducto;
          EXCEPTION
             WHEN OTHERS THEN
                outError := 'No existen los parámetros de Montos Límites configurados.';
                RETURN FALSE;
          END;

          IF NOT vn_mtotsoli BETWEEN vn_monminimo AND vn_monmaximo THEN
             outError := 'Monto ingresado Total(RD) ' || TO_CHAR (vn_mtotsoli, 'FM999,999,999,990.00') || ' no está dentro de lo establecido para el Producto: '
                || pTipoProducto || ' con Rango: ' || TO_CHAR (vn_monminimo, 'FM999,999,999,990.00') || ' - ' || TO_CHAR (vn_monmaximo, 'FM999,999,999,990.00');
                                          
             RETURN FALSE;
          END IF;
       END IF;

       RETURN TRUE;
    EXCEPTION
       WHEN OTHERS THEN
          outError := 'Error. ' || SQLERRM;
          RETURN FALSE;
    END Valida_Monto_Solicitado;
    
    
    FUNCTION Valida_Monto_Aprobado(pMonto        IN NUMBER,
                                   pEstadoSol    IN VARCHAR2,
                                   pUsuario      IN VARCHAR2) 
        RETURN BOOLEAN IS
            vExiste        NUMBER := 0;
    BEGIN
       BEGIN
           SELECT DISTINCT 1
             INTO vExiste
                 FROM (  SELECT A.ESTADO_TARJETA ESTADO_TARJETA, B.DESCRIPCION DESCRIPCION, NVL(B.ORDEN, 0) ORDEN
                           FROM TC_NIVELES_APROBACION A, 
                                TC_NIVELES_DETALLE C,
                                PA_CATALOGO_CODIGOS B,
                                TC_NIVELES_X_ANALISTA D
                           WHERE C.CODIGO_NIVEL_APROBACION = 1
                           AND B.COD_GEN = '002'
                           AND A.ESTADO_TARJETA = B.COD_SEC
                           AND A.CODIGO_NIVEL_APROBACION = C.CODIGO_NIVEL_SIGUIENTE
                           AND C.ATRAS_ADELANTE = 'A'
                           AND C.CODIGO_NIVEL_APROBACION = D.CODIGO_NIVEL_APROBACION
                           --AND D.CODIGO_PERSONA IN (SELECT U.COD_PER_FISICA FROM PA.USUARIOS U WHERE U.COD_USUARIO = pUsuario)
                           AND (D.CODIGO_PERSONA IN (SELECT U.COD_PER_FISICA FROM PA.USUARIOS U WHERE U.COD_USUARIO = pUsuario) OR
                             D.CODIGO_PERSONA IN (SELECT E.ID_EMPLEADO FROM PA.EMPLEADOS E, PA.USUARIOS U WHERE E.COD_PER_FISICA = U.COD_PER_FISICA AND U.COD_USUARIO = pUsuario))
                           UNION
                           SELECT A.ESTADO_TARJETA ESTADO_TARJETA, B.DESCRIPCION DESCRIPCION, NVL(B.ORDEN, 0) ORDEN
                           FROM TC_NIVELES_APROBACION A, 
                                TC_NIVELES_DETALLE C,
                                PA_CATALOGO_CODIGOS B,
                                TC_NIVELES_X_ANALISTA D
                           WHERE C.CODIGO_NIVEL_APROBACION = 1
                           AND B.COD_GEN = '002'
                           AND A.ESTADO_TARJETA = B.COD_SEC
                           AND A.CODIGO_NIVEL_APROBACION = C.CODIGO_NIVEL_SIGUIENTE
                           AND C.ATRAS_ADELANTE = 'D'
                           AND C.CODIGO_NIVEL_APROBACION = D.CODIGO_NIVEL_APROBACION
                           --AND D.CODIGO_PERSONA IN (SELECT U.COD_PER_FISICA FROM PA.USUARIOS U WHERE U.COD_USUARIO = pUsuario)
                           AND (D.CODIGO_PERSONA IN (SELECT U.COD_PER_FISICA FROM PA.USUARIOS U WHERE U.COD_USUARIO = pUsuario) OR
                             D.CODIGO_PERSONA IN (SELECT E.ID_EMPLEADO FROM PA.EMPLEADOS E, PA.USUARIOS U WHERE E.COD_PER_FISICA = U.COD_PER_FISICA AND U.COD_USUARIO = pUsuario))
                           UNION
                           SELECT COD_SEC ESTADO_TARJETA, DESCRIPCION DESCRIPCION, NVL(ORDEN, 0) ORDEN
                           FROM PA_CATALOGO_CODIGOS
                           WHERE COD_GEN = '002'
                           AND (COD_SEC = 'R' or COD_SEC = decode(upper('C'),'D','D')) ) x,
                      (SELECT codigo_nivel_aprobacion
                         FROM tc_niveles_aprobacion
                        WHERE estado_tarjeta = 'A' 
                          AND (pMonto >= limite_inferior AND pMonto <= limite_superior)) a
                      WHERE ESTADO_TARJETA = pEstadoSol;

       EXCEPTION WHEN OTHERS THEN
           vExiste := 0;
       END;
      
    RETURN (vExiste > 0);
  
    END Valida_Monto_Aprobado;

   PROCEDURE CodPersonaById(outCodPersona    IN OUT VARCHAR2,
                            outTipoId        IN OUT NUMBER,                                                        
                            outNumId         IN OUT VARCHAR2,
                            outError         IN OUT VARCHAR2) IS
        vIdent      PA.ID_PERSONAS.NUM_ID%TYPE ;
   BEGIN
      BEGIN
          vIdent := PA.Formato_Cedula(REPLACE(outNumId,'-'), outTipoId, outError);
      
          SELECT cod_persona, num_id, cod_tipo_id
            INTO outCodPersona, outNumId, outTipoId
            FROM pa.id_personas
           WHERE (cod_persona = outCodPersona OR outCodPersona IS NULL)
             AND (cod_tipo_id = outTipoId OR outTipoId IS NULL)
             AND (NUM_ID = vIdent or vIdent IS NULL)
             --AND ((REPLACE(num_id,'-') = REPLACE(outNumId,'-')) OR outNumId IS NULL)
             AND ROWNUM = 1;
      EXCEPTION
          WHEN NO_DATA_FOUND THEN
             outError := 'Datos de Identificación no encontrados.  '||outNumId;
             RAISE_APPLICATION_ERROR(-20100, outError);
      END;
      
   END CodPersonaById;

   PROCEDURE notificar_solicitud(pNoSolicitud       IN NUMBER,
                                 outError           IN OUT VARCHAR2) IS
     vURL               VARCHAR2(2000);                         
     vReporte           VARCHAR2(60);
     vParams            VARCHAR2(2000);
     vNombre            VARCHAR2(120);
     vIdentificacion    VARCHAR2(30);
     vCodCliente        VARCHAR2(30);  
     vLimiteRD          NUMBER;
     vLimiteUS          NUMBER;
     vFecSol            DATE;
   BEGIN
   
        BEGIN
            SELECT S.COD_CLIENTE, S.PRIMER_NOMBRE||' '||S.SEGUNDO_NOMBRE||' '||S.PRIMER_APELLIDO||' '||S.SEGUNDO_APELLIDO,
                   S.CEDULA, S.LIMITE_ASIGNADO_RD, S.LIMITE_ASIGNADO_US, S.FECHA_SOLICITUD
              INTO vCodCliente, vNombre, vIdentificacion, vLimiteRD, vLimiteUS, vFecSol
              FROM TC.SOLICITUD_TARJETA_V s
             WHERE S.NO_SOLICITUD = pNoSolicitud;
             
        EXCEPTION WHEN NO_DATA_FOUND THEN
            outError := 'La Solicitud '||pNoSolicitud||' no está registrada';
            RAISE_APPLICATION_ERROR(-201404, outError);
        END;
   
        vReporte := 'SolicitudTarjeta';
        vParams     := 'p_NoSolicitud='||pNoSolicitud;                
        vURL := ia.f_reporte_ssrs ('TC', vReporte, 'PDF', vParams); 
   
        -- Envia email al grupo de usuarios correspondientes
        pa.send_mail (
                       p_mailhost     =>   Param.Parametro_X_Empresa('1','SERVIDOR_SMTP','PA'),
                       p_sender       =>   'SistemaB2000',
                       p_recipient    =>   Param.Parametro_X_Empresa('1','CORREO_NOTIF_TC','PA'),
                       p_subject      =>   'Solicitud de Tarjeta de Crédito',
                       p_message      =>   'Se ha registrado la solicitud No.'||pNoSolicitud||' de fecha '||vFecSol||' son los siguientes datos:'||CHR(13)||
                                           '     Cliente ('||vCodCliente||') '||vNombre||CHR(13)||
                                           '     Identificación: '||vIdentificacion||CHR(13)||
                                           '     Límite RD$: '||vLimiteRD||CHR(13)||
                                           '     Límite US$: '||vLimiteUS||CHR(13)||CHR(13)||
                                           'Favor de entrar al link para imprimir el Formulario de Solicitud de Tarjeta de Crédito TC-001 '||CHR(13)||vUrl||CHR(13)||CHR(13)||
                                           'Saludos');
   EXCEPTION WHEN OTHERS THEN
       outError := 'Error enviando la Notificación de la Solicitud '||SQLERRM;
       RAISE_APPLICATION_ERROR(-201404, outError);                                            
   END; 

   PROCEDURE Datos_per_fisica( inCodPersona          IN     VARCHAR2,
                               outEstado_civil       IN OUT VARCHAR2,
                               outSexo               IN OUT VARCHAR2,
                               OutFecha_nacimiento   IN OUT DATE,
                               OutApellido1          IN OUT VARCHAR2,
                               OutApellido2          IN OUT VARCHAR2,
                               OutPrimerNombre       IN OUT VARCHAR2,
                               OutSegundoNombre      IN OUT VARCHAR2,
                               OutCasadaApellido     IN OUT VARCHAR2,
                               OutNum_dependientes   IN OUT NUMBER,
                               OutProfesion          IN OUT VARCHAR2,
                               OutTipoVivienda       IN OUT VARCHAR2,
                               outEmail              IN OUT VARCHAR2,
                               outTelefono           IN OUT VARCHAR2,
                               outError              IN OUT VARCHAR2) IS
        CURSOR CUR_Cedula IS
           SELECT REPLACE(IPE.NUM_ID,'-'), IPE.COD_TIPO_ID
            FROM pa.id_personas ipe
            WHERE ipe.cod_persona = inCodPersona
            AND IPE.COD_TIPO_ID in ( '1','2','5','6')
            and rownum<=1;
            --order by IPE.COD_TIPO_ID;                   
                               
        vCedula         PA.ID_PERSONAS.NUM_ID%TYPE;  
        vc_apecasada    VARCHAR2(60);         
        vc_primnombre   VARCHAR2(60);  
        pPPP            PA.PROCESO_PENDIENTE_PERSONA_OBJ;
        vtipoId    id_personas.COD_TIPO_ID%TYPE;              
    BEGIN
       BEGIN
            OPEN CUR_Cedula;
            FETCH CUR_Cedula INTO vCedula, vtipoId;
            CLOSE CUR_Cedula;
--            SELECT REPLACE(IPE.NUM_ID,'-'), IPE.COD_TIPO_ID
--            INTO 
--            FROM pa.id_personas ipe
--            WHERE ipe.cod_persona = inCodPersona
--            AND IPE.COD_TIPO_ID in ( '1','2','5','6')
--            and rownum<=1 ;
       EXCEPTION
           WHEN NO_DATA_FOUND THEN
              RAISE_APPLICATION_ERROR(-20100, 'Datos de Identificación de la persona no encontrados.  '||inCodPersona||'. '||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE );
       END;
       
       pPPP             := PA.PROCESO_PENDIENTE_PERSONA_OBJ();
       pPPP.COD_PERSONA := inCodPersona;
       pPPP.PROCESO     := 'PADRON';       
       
       IF pPPP.Existe() = FALSE AND vtipoId IN ('1','2') THEN
           
            -- Buscar Datos en el padron 
            pa_utl.obtiene_info_padron_rd (vCedula,
                                           outApellido1,
                                           outApellido2,
                                           vc_apecasada,
                                           vc_primnombre,
                                           outSexo,
                                           outFecha_nacimiento);

            IF vc_primnombre IS NOT NULL THEN
                IF INSTR(vc_primnombre,' ') > 0 THEN
                    outSegundoNombre := UPPER(SUBSTR(vc_primnombre,INSTR(vc_primnombre,' ')+1,30));
                    outPrimerNombre  := UPPER(SUBSTR(SUBSTR(vc_primnombre,1,INSTR(vc_primnombre,' ')-1),1,30));
                ELSE
                    outPrimerNombre := UPPER(SUBSTR(vc_primnombre,1,30));
                END IF; 
            END IF;
       END IF;  

--dbms_output.put_line('PADRON: '||outApellido1||','||outApellido2||', '||outPrimerNombre||','||outSegundoNombre);                                                   
       
       SELECT DECODE(per.est_civil, 'C', per.est_civil, 'S') est_civil,
              NVL(NVL(outSexo, per.sexo), 'F') sexo,
              NVL(outFecha_nacimiento, per.fec_nacimiento),
              UPPER(NVL(outApellido1, per.primer_apellido)),
              UPPER(NVL(outApellido2, per.segundo_apellido)),
              UPPER(NVL(outPrimerNombre, per.primer_nombre)),
              UPPER(NVL(outSegundoNombre, per.segundo_nombre)),
              per.num_dependientes,
              per.profesion,
              per.tipo_vivienda,
              per.email_usuario || per.email_servidor email              
         INTO outEstado_civil,
              outSexo,
              outFecha_nacimiento,
              outApellido1,
              outApellido2,
              outPrimerNombre,
              outSegundoNombre,
              outNum_dependientes,
              outProfesion,
              outTipoVivienda,
              outEmail              
         FROM pa.personas_fisicas per 
        WHERE per.cod_per_fisica = inCodPersona;
        
        outTelefono := Datos_telefono(inCodPersona, outError);
        
--dbms_output.put_line('PERSONA_FISICA: '||outApellido1||','||outApellido2||', '||outPrimerNombre||','||outSegundoNombre);
    EXCEPTION
       WHEN NO_DATA_FOUND THEN
          outError := 'Datos de persona fisica no encontrados.  '||inCodPersona||'. '||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ;
          RAISE_APPLICATION_ERROR(-20100, outError);
    END Datos_per_fisica;
    
    PROCEDURE Datos_Per_Juridica(inCodPersona    IN     VARCHAR2,
                                 OutNombre       IN OUT VARCHAR2,
                                 outEmail        IN OUT VARCHAR2,
                                 outDesc_tipo_id IN OUT VARCHAR2,
                                 outError        IN OUT VARCHAR2) IS
    BEGIN
       SELECT per.nom_comercial,          
              per.email_usuario || per.email_servidor email,
              pa.obt_desc_tiposid(ipe.cod_tipo_id) desc_tipo_id    
         INTO outNombre, outEmail, outDesc_Tipo_id
         FROM pa.personas_juridicas per, pa.id_personas ipe
        WHERE per.cod_per_juridica = inCodPersona
          AND ipe.cod_persona = per.cod_per_juridica;
    EXCEPTION
       WHEN NO_DATA_FOUND THEN
          outError := 'Datos de persona Jurídica no encontrados.  '||inCodPersona||'. '||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
          RAISE_APPLICATION_ERROR(-20100, outError);
    END; 

   PROCEDURE Datos_Direccion( p_codigo_cliente        IN VARCHAR2,
                              pCodPais                IN OUT VARCHAR2,
                              pDescPais               IN OUT VARCHAR2,
                              pCodProvincia           IN OUT VARCHAR2,
                              pDescProvincia          IN OUT VARCHAR2,
                              pCodCanton              IN OUT VARCHAR2,
                              pDescCanton             IN OUT VARCHAR2,
                              pCodDistrito            IN OUT VARCHAR2,
                              pDescDistrito           IN OUT VARCHAR2,
                              pCodPueblo              IN OUT VARCHAR2,
                              pDescPueblo             IN OUT VARCHAR2,
                              outError                IN OUT VARCHAR2) IS
   BEGIN
            
       SELECT cod_pais, cod_provincia, cod_canton, cod_distrito, cod_pueblo,
              pa.obt_desc_pais(cod_pais) DescPais,
              pa.obt_desc_provincia(cod_pais, Cod_Provincia) DescProvincia,
              pa.obt_desc_canton(cod_pais, Cod_Provincia, Cod_Canton) DescCanton,
              pa.obt_desc_distrito(cod_pais, cod_provincia, cod_canton, cod_distrito) DescDistrito,
              pa.obt_desc_pueblo(cod_pais, cod_provincia, cod_canton, cod_distrito, cod_pueblo) DescPueblo
         INTO pCodPais, pCodProvincia, pCodCanton, pCodDistrito, pCodPueblo, pDescPais, pDescProvincia, 
              pDescCanton, pDescDistrito, pDescPueblo
         FROM dir_personas d
        WHERE d.cod_persona = p_codigo_cliente
           AND d.cod_direccion = (SELECT MAX( x.cod_direccion ) from PA.DIR_PERSONAS x where x.cod_persona = d.cod_persona AND x.TIP_DIRECCION = d.tip_direccion and x.es_default  = 'S') 
           AND d.es_default  = 'S'
           AND ROWNUM = 1;
                
   EXCEPTION
       WHEN NO_DATA_FOUND THEN
          outError :=  'Datos de dirección no encontrados.  '||p_codigo_cliente;
          RAISE_APPLICATION_ERROR(-20100, outError);
   END; 
    
   FUNCTION Datos_telefono(p_codigo_cliente   IN VARCHAR2,
                           outError           IN OUT VARCHAR2)
     RETURN VARCHAR2 IS
     
     pTelefono   VARCHAR2(60);
     
   BEGIN
       BEGIN
            SELECT SUBSTR(cod_area||'-'|| num_telefono,1,12)
              INTO pTelefono
              FROM tel_personas
             WHERE (cod_persona = p_codigo_cliente
                    AND es_default  = 'S'
                    AND ROWNUM <= 1)
             OR
             (cod_persona = p_codigo_cliente
                    AND ROWNUM <= 1);
               
       EXCEPTION
           WHEN NO_DATA_FOUND THEN
               pTelefono := '000-000-0000';
               outError := 'Datos de Teléfono no encontrados.  '||p_codigo_cliente||'. '||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
               RAISE_APPLICATION_ERROR(-20100, outError);
       END;
       
       RETURN NVL(pTelefono, '000-000-0000');
    
   END;
   
   FUNCTION f_Es_Empleado_Ademi(p_cod_empresa in cuenta_efectivo.cod_empresa%type,
                                p_cod_cliente in cuenta_efectivo.cod_cliente%type) 
     RETURN BOOLEAN IS
       
        v_es_empleado  BOOLEAN := FALSE;
       
        CURSOR c_empleados IS 
        SELECT DISTINCT 1
          FROM pa.empleados e
         WHERE e.cod_empresa    = p_cod_empresa
           AND e.cod_per_fisica = p_cod_cliente
           AND e.esta_activo    = 'S'
         UNION
        SELECT DISTINCT 1
          FROM ac.ac_accionista a
         WHERE a.cod_empresa = p_cod_empresa
           AND a.cod_persona = p_cod_cliente
           AND a.estado          = 'A';
    BEGIN
      
       for cc in c_empleados loop
           v_es_empleado := true;
       end loop;             
      
       return v_es_empleado;
       
    END;
    
    FUNCTION es_empleado_ademi(p_cod_empresa in cuenta_efectivo.cod_empresa%type,
                              p_cod_cliente in cuenta_efectivo.cod_cliente%type) 
     RETURN VARCHAR IS
     vRetorno   VARCHAR2(10);
    BEGIN
        IF (f_Es_Empleado_Ademi(p_cod_empresa, p_cod_cliente)) THEN
            vRetorno := 'TRUE';
        ELSE
            vRetorno := 'FALSE';
        END IF;
        
        RETURN vRetorno;
        
    END;
    
    FUNCTION clasificacion_tipo_producto(pCodTipoProducto        TC_PROD_EMIS_TJT.COD_PROD_EMISOR%TYPE,
                                         pDescTipo               VARCHAR2)
     RETURN VARCHAR2 IS
        vRetorno                VARCHAR2(2);
    BEGIN
        -- Temporalmente hardcode hasta tanto se cree una tabla de clasificacion de tipos de productos.
        IF pDescTipo = 'Clásica Local' THEN
            IF pCodTipoProducto IN (401, 425, 420, 428) THEN
                vRetorno := 'X';
            ELSE
                vRetorno := NULL;
            END IF;
        ELSIF pDescTipo = 'Clásica Internac.' THEN
            IF pCodTipoProducto IN (418, 415, 410) THEN
                vRetorno := 'X';
            ELSE
                vRetorno := NULL;
            END IF;
        ELSIF pDescTipo = 'Gold' THEN
            IF pCodTipoProducto IN (448, 445, 440) THEN
                vRetorno := 'X';
            ELSE
                vRetorno := NULL;
            END IF;
        ELSIF pDescTipo = 'Empresarial Local' THEN
            IF pCodTipoProducto IN (495, 461, 460, 491, 490, 498, 496, 471, 493, 407) THEN
                vRetorno := 'X';
            ELSE
                vRetorno := NULL;
            END IF;
        ELSIF pDescTipo = 'Empresarial Internac.' THEN
            IF pCodTipoProducto IN (485, 488, 480, 479, 476) THEN
                vRetorno := 'X';
            ELSE
                vRetorno := NULL;
            END IF;
        ELSIF pDescTipo = 'Flexible' THEN
            IF pCodTipoProducto IN (458, 455, 450) THEN
                vRetorno := 'X';
            ELSE
                vRetorno := NULL;
            END IF;
        ELSIF pDescTipo = 'Olé' THEN
            IF pCodTipoProducto IN (435, 430) THEN
                vRetorno := 'X';
            ELSE
                vRetorno := NULL;
            END IF;
        ELSIF pDescTipo = 'Blue Country' THEN
            IF pCodTipoProducto IN (453, 464) THEN
                vRetorno := 'X';
            ELSE
                vRetorno := NULL;
            END IF;
        END IF;
       
        RETURN vRetorno;
        
    END;
    
    FUNCTION p_digito_verificador (num_id IN VARCHAR2, tipo_id IN VARCHAR2)
      RETURN VARCHAR2 IS
       Cont       NUMBER (2);
       Len        NUMBER (2);
       CarIdent   VARCHAR2 (1);
       vEs        VARCHAR2 (1) := 'N';
       vRNC_ID    VARCHAR2 (2) := NULL;
       vPos       NUMBER;
       vReturn    VARCHAR2(1);
    BEGIN
       Len := NVL (LENGTH (REPLACE (num_id, '-', '')), 0);

       IF tipo_id = '1' THEN                                           -- Cedula
          vRNC_ID := 'P1';
          vPos := 13;
       ELSIF tipo_id = '2' THEN                                        -- RNC
          vRNC_ID := 'E1';
          vPos := 12;
       END IF;

       Cont := 1;

       WHILE (Cont <= Len) LOOP
          CarIdent := SUBSTR (REPLACE (num_id, '-', ''), Cont, 1);

          IF (CarIdent BETWEEN '0' AND '9') THEN
             vEs := 'S';
          ELSE
             vEs := 'N';
             EXIT;
          END IF;

          Cont := Cont + 1;
       END LOOP;

       IF vEs = 'S' THEN
       
          IF pa.valida_identificacion (vRNC_ID, num_id) = TO_NUMBER (SUBSTR (num_id, vPos, 1)) THEN
             vReturn := 'S';
          ELSE
             vReturn := 'N';             
          END IF;
          
       ELSE
       
          vReturn := 'N';   
               
       END IF;
              
       vRNC_ID := NULL;
       vPos := NULL;
       
       RETURN vReturn;

    END p_digito_verificador;    
    
    PROCEDURE Solicitud_Empleado(pCodPersona       IN     VARCHAR2,
                                 pEmpresa          IN     VARCHAR2,
                                 pAgencia          IN OUT VARCHAR2,
                                 pOficina          IN OUT VARCHAR2,
                                 pDescOficina      IN OUT VARCHAR2,
                                 pPromotor         IN OUT VARCHAR2,
                                 pDescPromotor     IN OUT VARCHAR2,
                                 pEmpleado         IN OUT VARCHAR2,
                                 outError          IN OUT VARCHAR2) IS
        vEmpleado       BOOLEAN;
        vUsuario        PA.USUARIOS.COD_USUARIO%TYPE;
        vRolEmpleados   BOOLEAN := FALSE;
    BEGIN
       
       outError := NULL;
       
       --- Verifica si el cliente es un empleado
       vEmpleado := f_es_empleado_ademi (pEmpresa, pCodPersona);

       IF vEmpleado = FALSE THEN
          BEGIN
           SELECT ANA.CODIGO_PERSONA, NVL(pAgencia, CLI.COD_AGENCIA), 
                  ANA.NOMBRE_ANALISTA
             INTO pPromotor, pOficina,
                  pDescPromotor
             FROM PA.CLIENTE CLI, PR.PR_ANALISTAS ANA
            WHERE CLI.COD_CLIENTE = pCodPersona
              AND CLI.COD_OFICIAL = ANA.CODIGO_PERSONA;
           
          EXCEPTION
              WHEN NO_DATA_FOUND THEN
                 pOficina := NVL(pAgencia, 0);
          END;
         
          pEmpleado := 'N';          
          pDescOficina := pa.obt_descripcion_agencia(pEmpresa, pOficina);
       
       ELSE
          pEmpleado := 'S';
            
          BEGIN
             -- Busca Oficial encargado de Empleados
             SELECT ANA.CODIGO_PERSONA, ANA.NOMBRE_ANALISTA
               INTO pPromotor, pDescPromotor
               FROM PR.PR_ANALISTAS ANA
              WHERE ANA.CODIGO_PERSONA = PA.PARAM.PARAMETRO_GENERAL ('OFICIAL_EMP_TC', 'TC');                                            
          EXCEPTION
              WHEN OTHERS THEN
                outError := 'Datos del Oficial de este empleado '||pCodPersona||' no encontrado'||'. '||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
                RETURN;
          END;   
          
          BEGIN
             -- Busca Oficina Asignada para empleados.
             SELECT AGE.COD_AGENCIA, AGE.DESCRIPCION
               INTO pOficina, pDescOficina
               FROM PA.AGENCIA AGE
              WHERE AGE.COD_AGENCIA = PA.PARAM.PARAMETRO_GENERAL ('OFICINA_EMP_TC', 'TC');

          EXCEPTION
              WHEN OTHERS THEN
                outError := 'Datos de la Oficina asignada para empleados no encontrado.';
                RETURN;
          END;  
        
          BEGIN

              SELECT U.COD_USUARIO
                INTO vUsuario
                FROM PA.USUARIOS u 
               WHERE U.COD_PER_FISICA = pPromotor;
          
          EXCEPTION
              WHEN OTHERS THEN
                vUsuario := NULL;
          END;
          
          vRolEmpleados := Permiso_Autoriza_Empleado(pUsuario     => vUsuario,  pPermiso     => NULL);
          
          IF vRolEmpleados = FALSE THEN
             outError := 'Este Oficial no tiene autorización a solicitar tarjetas de crédito para empleados  '||pCodPersona||'. '||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
             RETURN;
          END IF;
          
       END IF;
     
    END Solicitud_Empleado;

    FUNCTION Permiso_Autoriza_Empleado(pUsuario     IN VARCHAR2,
                                       pPermiso     IN VARCHAR2)
     RETURN BOOLEAN IS
        vAplica NUMBER := 0;
    BEGIN
   
       SELECT DISTINCT COUNT(1) 
         INTO vAplica  
         FROM PA.USUARIOS_X_ROLES
        WHERE cod_usuario = NVL(pUsuario, USER)
          AND cod_rol = (SELECT VALOR 
                           FROM PA.PARAMETROS_X_EMPRESA PAEM 
                          WHERE PAEM.COD_SISTEMA     = 'TC' 
                            AND PAEM.ABREV_PARAMETRO = NVL(pPermiso, 'SOL_TARJ_EMPLEADO') );
       RETURN (vAplica > 0);        
        
    END;

    PROCEDURE Crear_Solicitud(pCOD_PERSONA             VARCHAR2,
                              pNO_SOLICITUD            IN OUT NUMBER,
                              pNUM_ID                  VARCHAR2,
                              pCOD_TIPO_PRODUCTO       VARCHAR2,
                              pFECHA_SOLICITUD         DATE,
                              pCOD_TIPO_ID             VARCHAR2,
                              pAMPARADA_POR            VARCHAR2,
                              pNOMBRE_PLASTICO         VARCHAR2,
                              pCOD_MOTIVO_NEGACION     VARCHAR2,
                              pCUPO_INDEPENDIENTE      VARCHAR2,
                              pCOD_CICLO_FACT          VARCHAR2,
                              pCOD_TIPO_MERCADO        VARCHAR2,
                              pCUPO_SOLICITADO_RD      NUMBER,
                              pESTADO_DOCUMENTACION    VARCHAR2,
                              pCOD_TIPO_CLIENTE        VARCHAR2,
                              pOFICINA                 VARCHAR2,
                              pIND_PLASTICO            VARCHAR2,
                              pIND_DIFIERE             VARCHAR2,
                              pCOD_DESPACHO            VARCHAR2,
                              pOFICINA_ENTREGA_TARJ    VARCHAR2,
                              pIND_CARGO_AUTOMATICO    VARCHAR2,
                              pCOD_COMPENSACION        VARCHAR2,
                              pCTA_CARGO_AUTOMATICO    VARCHAR2,
                              pCTA_ALTERNA             NUMBER,
                              pNUM_ID_CODEUDOR         VARCHAR2,
                              pTIPO_GARANTIA           VARCHAR2,
                              pVALOR_GARANTIA          NUMBER,
                              pMODO_AMORTIZACION       VARCHAR2,
                              pCLIENTE_PRE_EMBOZO      VARCHAR2,
                              pMES_INICIAL_AMORT       NUMBER,
                              pEMPRESA_AGENTES         NUMBER,
                              pCOD_AGENTE              NUMBER,
                              pEMP_ASIGNADA_AGTE       NUMBER,
                              pDIRECCION_CORRESP1      VARCHAR2,
                              pDIRECCION_CORRESP2      VARCHAR2,
                              pDIRECCION_CORRESP3      VARCHAR2,
                              pDIRECCION_CORRESP4      VARCHAR2,
                              pCOD_PAIS                VARCHAR2,
                              pCOD_PROVINCIA           VARCHAR2,
                              pCOD_CANTON              VARCHAR2,
                              pCOD_DISTRITO            VARCHAR2,
                              pCOD_CIUDAD              VARCHAR2,
                              pTELEFONO_CORRESP        VARCHAR2,
                              pEXT_TELEFONO            NUMBER,
                              pZPOSTAL_CORRESP         NUMBER,
                              pTIPO_EMISION            VARCHAR2,
                              pIND_TIPO_TARJETA        VARCHAR2,
                              pESTADO                  VARCHAR2,
                              pLIMITE_ASIGNADO_RD      NUMBER,
                              pLIMITE_ASIGNADO_US      NUMBER,
                              pESTADO_SOLICITUD        VARCHAR2,
                              pFECHA_NEGACION          DATE,
                              pBIN                     VARCHAR2,
                              pCOD_PAIS_EST            VARCHAR2,
                              pCOD_REGION_EST          VARCHAR2,
                              pCOD_PROVINCIA_EST       VARCHAR2,
                              pCOD_CIUDAD_EST          VARCHAR2,
                              pCOD_MUNICIPIO_EST       VARCHAR2,
                              pCOD_SECTOR_EST          VARCHAR2,
                              pCOD_BARRIO_EST          VARCHAR2,
                              pCOD_CALLE_EST           VARCHAR2,
                              pNUMERO_EST              VARCHAR2,
                              pDETALLE_EST             VARCHAR2,
                              pRES_APR_INMED           VARCHAR2,
                              pSECTOR_RES              VARCHAR2,
                              pBARRIO_RES              VARCHAR2,
                              pCALLE_RES               VARCHAR2,
                              pNUMERO_RES              VARCHAR2,
                              pDETALLE_RES             VARCHAR2,
                              pSEGREGACION_RD          VARCHAR2,
                              pCODIGO_ACTIVIDAD        NUMBER,
                              pCODIGO_SUBACTIVIDAD     NUMBER,
                              pCODIGO_SUB_CLASE        NUMBER,
                              pFEC_DIGITACION          DATE,
                              pFEC_RECIBO              DATE,
                              pLIMITE_APROBADO_RD      NUMBER,
                              pCUPO_SOLICITADO_US      NUMBER,
                              pLIMITE_APROBADO_US      NUMBER,
                              pFECHA_APROBACION        DATE,
                              pUSUARIO_APROBACION      VARCHAR2,
                              pCOD_PROMOTOR            VARCHAR2,
                              pJUSTIF_DENEGADA         VARCHAR2,
                              pNUMERO_ASIENTO          NUMBER,
                              pCOD_TIPO_ID_CODEUDOR    VARCHAR2,
                              outError              IN OUT VARCHAR2) IS
      vSolicitudTarjeta     TC.TC_SOLICITUD_TARJETA_OBJ;
      vUsuario      VARCHAR2(30) := USER;
   BEGIN
      
      IF vUsuario = 'IA' THEN
        vUsuario := 'TC';
      END IF;
        
      SELECT MAX(NVL(no_solicitud,0)) + 1 INTO pNO_SOLICITUD FROM TC.TC_SOLICITUD_TARJETA;
                
      vSolicitudTarjeta :=
         TC.TC_SOLICITUD_TARJETA_OBJ (
              COD_PERSONA              =>    pCOD_PERSONA,
              NO_SOLICITUD             =>    pNO_SOLICITUD,
              NUM_ID                   =>    pNUM_ID,
              COD_TIPO_PRODUCTO        =>    pCOD_TIPO_PRODUCTO,
              FECHA_SOLICITUD          =>    pFECHA_SOLICITUD,
              COD_TIPO_ID              =>    pCOD_TIPO_ID,
              AMPARADA_POR             =>    pAMPARADA_POR,
              NOMBRE_PLASTICO          =>    pNOMBRE_PLASTICO,
              COD_MOTIVO_NEGACION      =>    pCOD_MOTIVO_NEGACION,
              CUPO_INDEPENDIENTE       =>    pCUPO_INDEPENDIENTE,
              COD_CICLO_FACT           =>    pCOD_CICLO_FACT,
              COD_TIPO_MERCADO         =>    pCOD_TIPO_MERCADO,
              CUPO_SOLICITADO_RD       =>    pCUPO_SOLICITADO_RD,
              ESTADO_DOCUMENTACION     =>    pESTADO_DOCUMENTACION,
              COD_TIPO_CLIENTE         =>    pCOD_TIPO_CLIENTE,
              OFICINA                  =>    pOFICINA,
              IND_PLASTICO             =>    pIND_PLASTICO,
              IND_DIFIERE              =>    pIND_DIFIERE,
              COD_DESPACHO             =>    pCOD_DESPACHO,
              OFICINA_ENTREGA_TARJ     =>    pOFICINA_ENTREGA_TARJ,
              IND_CARGO_AUTOMATICO     =>    pIND_CARGO_AUTOMATICO,
              COD_COMPENSACION         =>    pCOD_COMPENSACION,
              CTA_CARGO_AUTOMATICO     =>    pCTA_CARGO_AUTOMATICO,
              CTA_ALTERNA              =>    pCTA_ALTERNA,
              NUM_ID_CODEUDOR          =>    pNUM_ID_CODEUDOR,
              TIPO_GARANTIA            =>    pTIPO_GARANTIA,
              VALOR_GARANTIA           =>    pVALOR_GARANTIA,
              MODO_AMORTIZACION        =>    pMODO_AMORTIZACION,
              CLIENTE_PRE_EMBOZO       =>    pCLIENTE_PRE_EMBOZO,
              MES_INICIAL_AMORT        =>    pMES_INICIAL_AMORT,
              EMPRESA_AGENTES          =>    pEMPRESA_AGENTES,
              COD_AGENTE               =>    pCOD_AGENTE,
              EMP_ASIGNADA_AGTE        =>    pEMP_ASIGNADA_AGTE,
              DIRECCION_CORRESP1       =>    pDIRECCION_CORRESP1,
              DIRECCION_CORRESP2       =>    pDIRECCION_CORRESP2,
              DIRECCION_CORRESP3       =>    pDIRECCION_CORRESP3,
              DIRECCION_CORRESP4       =>    pDIRECCION_CORRESP4,
              COD_PAIS                 =>    pCOD_PAIS,
              COD_PROVINCIA            =>    pCOD_PROVINCIA,
              COD_CANTON               =>    pCOD_CANTON,
              COD_DISTRITO             =>    pCOD_DISTRITO,
              COD_CIUDAD               =>    pCOD_CIUDAD,
              TELEFONO_CORRESP         =>    pTELEFONO_CORRESP,
              EXT_TELEFONO             =>    pEXT_TELEFONO,
              ZPOSTAL_CORRESP          =>    pZPOSTAL_CORRESP,
              TIPO_EMISION             =>    pTIPO_EMISION,
              IND_TIPO_TARJETA         =>    pIND_TIPO_TARJETA,
              ESTADO                   =>    pESTADO,
              LIMITE_ASIGNADO_RD       =>    pLIMITE_ASIGNADO_RD,
              LIMITE_ASIGNADO_US       =>    pLIMITE_ASIGNADO_US,
              ESTADO_SOLICITUD         =>    pESTADO_SOLICITUD,
              FECHA_NEGACION           =>    pFECHA_NEGACION,
              MODIFICADO_POR           =>    NULL,
              FECHA_MODIFICACION       =>    NULL,
              BIN                      =>    pBIN,
              COD_PAIS_EST             =>    pCOD_PAIS_EST,
              COD_REGION_EST           =>    pCOD_REGION_EST,
              COD_PROVINCIA_EST        =>    pCOD_PROVINCIA_EST,
              COD_CIUDAD_EST           =>    pCOD_CIUDAD_EST,
              COD_MUNICIPIO_EST        =>    pCOD_MUNICIPIO_EST,
              COD_SECTOR_EST           =>    pCOD_SECTOR_EST,
              COD_BARRIO_EST           =>    pCOD_BARRIO_EST,
              COD_CALLE_EST            =>    pCOD_CALLE_EST,
              NUMERO_EST               =>    pNUMERO_EST,
              DETALLE_EST              =>    pDETALLE_EST,
              RES_APR_INMED            =>    pRES_APR_INMED,
              SECTOR_RES               =>    pSECTOR_RES,
              BARRIO_RES               =>    pBARRIO_RES,
              CALLE_RES                =>    pCALLE_RES,
              NUMERO_RES               =>    pNUMERO_RES,
              DETALLE_RES              =>    pDETALLE_RES,
              SEGREGACION_RD           =>    pSEGREGACION_RD,
              CODIGO_ACTIVIDAD         =>    pCODIGO_ACTIVIDAD,
              CODIGO_SUBACTIVIDAD      =>    pCODIGO_SUBACTIVIDAD,
              CODIGO_SUB_CLASE         =>    pCODIGO_SUB_CLASE,
              FEC_DIGITACION           =>    pFEC_DIGITACION,
              FEC_RECIBO               =>    pFEC_RECIBO,
              LIMITE_APROBADO_RD       =>    pLIMITE_APROBADO_RD,
              ADICIONADO_POR           =>    vUsuario,
              FECHA_ADICION            =>    SYSDATE,
              CUPO_SOLICITADO_US       =>    pCUPO_SOLICITADO_US,
              LIMITE_APROBADO_US       =>    pLIMITE_APROBADO_US,
              FECHA_APROBACION         =>    pFECHA_APROBACION,
              USUARIO_APROBACION       =>    pUSUARIO_APROBACION,
              COD_PROMOTOR             =>    pCOD_PROMOTOR,
              JUSTIF_DENEGADA          =>    pJUSTIF_DENEGADA,
              NUMERO_ASIENTO           =>    pNUMERO_ASIENTO,
              COD_TIPO_ID_CODEUDOR     =>    pCOD_TIPO_ID_CODEUDOR);
DBMS_OUTPUT.PUT_LINE('ANTES vSolicitudTarjeta.Crear');
      vSolicitudTarjeta.Crear ();
   EXCEPTION WHEN OTHERS THEN
      outError := SQLERRM;
      RAISE_APPLICATION_ERROR(-20104, outError);
   END Crear_Solicitud;

   PROCEDURE Actualiza_Solicitud (pCOD_PERSONA             VARCHAR2,
                                  pNO_SOLICITUD            NUMBER,
                                  pNUM_ID                  VARCHAR2,
                                  pCOD_TIPO_PRODUCTO       VARCHAR2,
                                  pFECHA_SOLICITUD         DATE,
                                  pCOD_TIPO_ID             VARCHAR2,
                                  pAMPARADA_POR            VARCHAR2,
                                  pNOMBRE_PLASTICO         VARCHAR2,
                                  pCOD_MOTIVO_NEGACION     VARCHAR2,
                                  pCUPO_INDEPENDIENTE      VARCHAR2,
                                  pCOD_CICLO_FACT          VARCHAR2,
                                  pCOD_TIPO_MERCADO        VARCHAR2,
                                  pCUPO_SOLICITADO_RD      NUMBER,
                                  pESTADO_DOCUMENTACION    VARCHAR2,
                                  pCOD_TIPO_CLIENTE        VARCHAR2,
                                  pOFICINA                 VARCHAR2,
                                  pIND_PLASTICO            VARCHAR2,
                                  pIND_DIFIERE             VARCHAR2,
                                  pCOD_DESPACHO            VARCHAR2,
                                  pOFICINA_ENTREGA_TARJ    VARCHAR2,
                                  pIND_CARGO_AUTOMATICO    VARCHAR2,
                                  pCOD_COMPENSACION        VARCHAR2,
                                  pCTA_CARGO_AUTOMATICO    VARCHAR2,
                                  pCTA_ALTERNA             NUMBER,
                                  pNUM_ID_CODEUDOR         VARCHAR2,
                                  pTIPO_GARANTIA           VARCHAR2,
                                  pVALOR_GARANTIA          NUMBER,
                                  pMODO_AMORTIZACION       VARCHAR2,
                                  pCLIENTE_PRE_EMBOZO      VARCHAR2,
                                  pMES_INICIAL_AMORT       NUMBER,
                                  pEMPRESA_AGENTES         NUMBER,
                                  pCOD_AGENTE              NUMBER,
                                  pEMP_ASIGNADA_AGTE       NUMBER,
                                  pDIRECCION_CORRESP1      VARCHAR2,
                                  pDIRECCION_CORRESP2      VARCHAR2,
                                  pDIRECCION_CORRESP3      VARCHAR2,
                                  pDIRECCION_CORRESP4      VARCHAR2,
                                  pCOD_PAIS                VARCHAR2,
                                  pCOD_PROVINCIA           VARCHAR2,
                                  pCOD_CANTON              VARCHAR2,
                                  pCOD_DISTRITO            VARCHAR2,
                                  pCOD_CIUDAD              VARCHAR2,
                                  pTELEFONO_CORRESP        VARCHAR2,
                                  pEXT_TELEFONO            NUMBER,
                                  pZPOSTAL_CORRESP         NUMBER,
                                  pTIPO_EMISION            VARCHAR2,
                                  pIND_TIPO_TARJETA        VARCHAR2,
                                  pESTADO                  VARCHAR2,
                                  pLIMITE_ASIGNADO_RD      NUMBER,
                                  pLIMITE_ASIGNADO_US      NUMBER,
                                  pESTADO_SOLICITUD        VARCHAR2,
                                  pFECHA_NEGACION          DATE,
                                  pBIN                     VARCHAR2,
                                  pCOD_PAIS_EST            VARCHAR2,
                                  pCOD_REGION_EST          VARCHAR2,
                                  pCOD_PROVINCIA_EST       VARCHAR2,
                                  pCOD_CIUDAD_EST          VARCHAR2,
                                  pCOD_MUNICIPIO_EST       VARCHAR2,
                                  pCOD_SECTOR_EST          VARCHAR2,
                                  pCOD_BARRIO_EST          VARCHAR2,
                                  pCOD_CALLE_EST           VARCHAR2,
                                  pNUMERO_EST              VARCHAR2,
                                  pDETALLE_EST             VARCHAR2,
                                  pRES_APR_INMED           VARCHAR2,
                                  pSECTOR_RES              VARCHAR2,
                                  pBARRIO_RES              VARCHAR2,
                                  pCALLE_RES               VARCHAR2,
                                  pNUMERO_RES              VARCHAR2,
                                  pDETALLE_RES             VARCHAR2,
                                  pSEGREGACION_RD          VARCHAR2,
                                  pCODIGO_ACTIVIDAD        NUMBER,
                                  pCODIGO_SUBACTIVIDAD     NUMBER,
                                  pCODIGO_SUB_CLASE        NUMBER,
                                  pFEC_DIGITACION          DATE,
                                  pFEC_RECIBO              DATE,
                                  pLIMITE_APROBADO_RD      NUMBER,
                                  pCUPO_SOLICITADO_US      NUMBER,
                                  pLIMITE_APROBADO_US      NUMBER,
                                  pFECHA_APROBACION        DATE,
                                  pUSUARIO_APROBACION      VARCHAR2,
                                  pCOD_PROMOTOR            VARCHAR2,
                                  pJUSTIF_DENEGADA         VARCHAR2,
                                  pNUMERO_ASIENTO          NUMBER,
                                  pCOD_TIPO_ID_CODEUDOR    VARCHAR2,
                                  outError              IN OUT VARCHAR2) IS
      vSolicitudTarjeta   TC.TC_SOLICITUD_TARJETA_OBJ;
   BEGIN
      vSolicitudTarjeta :=
         TC.TC_SOLICITUD_TARJETA_OBJ (pCOD_PERSONA,
                                      pNO_SOLICITUD,
                                      pNUM_ID,
                                      pCOD_TIPO_PRODUCTO,
                                      pFECHA_SOLICITUD,
                                      pCOD_TIPO_ID,
                                      pAMPARADA_POR,
                                      pNOMBRE_PLASTICO,
                                      pCOD_MOTIVO_NEGACION,
                                      pCUPO_INDEPENDIENTE,
                                      pCOD_CICLO_FACT,
                                      pCOD_TIPO_MERCADO,
                                      pCUPO_SOLICITADO_RD,
                                      pESTADO_DOCUMENTACION,
                                      pCOD_TIPO_CLIENTE,
                                      pOFICINA,
                                      pIND_PLASTICO,
                                      pIND_DIFIERE,
                                      pCOD_DESPACHO,
                                      pOFICINA_ENTREGA_TARJ,
                                      pIND_CARGO_AUTOMATICO,
                                      pCOD_COMPENSACION,
                                      pCTA_CARGO_AUTOMATICO,
                                      pCTA_ALTERNA,
                                      pNUM_ID_CODEUDOR,
                                      pTIPO_GARANTIA,
                                      pVALOR_GARANTIA,
                                      pMODO_AMORTIZACION,
                                      pCLIENTE_PRE_EMBOZO,
                                      pMES_INICIAL_AMORT,
                                      pEMPRESA_AGENTES,
                                      pCOD_AGENTE,
                                      pEMP_ASIGNADA_AGTE,
                                      pDIRECCION_CORRESP1,
                                      pDIRECCION_CORRESP2,
                                      pDIRECCION_CORRESP3,
                                      pDIRECCION_CORRESP4,
                                      pCOD_PAIS,
                                      pCOD_PROVINCIA,
                                      pCOD_CANTON,
                                      pCOD_DISTRITO,
                                      pCOD_CIUDAD,
                                      pTELEFONO_CORRESP,
                                      pEXT_TELEFONO,
                                      pZPOSTAL_CORRESP,
                                      pTIPO_EMISION,
                                      pIND_TIPO_TARJETA,
                                      pESTADO,
                                      pLIMITE_ASIGNADO_RD,
                                      pLIMITE_ASIGNADO_US,
                                      pESTADO_SOLICITUD,
                                      pFECHA_NEGACION,
                                      NULL,
                                      NULL,
                                      pBIN,
                                      pCOD_PAIS_EST,
                                      pCOD_REGION_EST,
                                      pCOD_PROVINCIA_EST,
                                      pCOD_CIUDAD_EST,
                                      pCOD_MUNICIPIO_EST,
                                      pCOD_SECTOR_EST,
                                      pCOD_BARRIO_EST,
                                      pCOD_CALLE_EST,
                                      pNUMERO_EST,
                                      pDETALLE_EST,
                                      pRES_APR_INMED,
                                      pSECTOR_RES,
                                      pBARRIO_RES,
                                      pCALLE_RES,
                                      pNUMERO_RES,
                                      pDETALLE_RES,
                                      pSEGREGACION_RD,
                                      pCODIGO_ACTIVIDAD,
                                      pCODIGO_SUBACTIVIDAD,
                                      pCODIGO_SUB_CLASE,
                                      pFEC_DIGITACION,
                                      pFEC_RECIBO,
                                      pLIMITE_APROBADO_RD,
                                      USER,
                                      SYSDATE,
                                      pCUPO_SOLICITADO_US,
                                      pLIMITE_APROBADO_US,
                                      pFECHA_APROBACION,
                                      pUSUARIO_APROBACION,
                                      pCOD_PROMOTOR,
                                      pJUSTIF_DENEGADA,
                                      pNUMERO_ASIENTO,
                                      pCOD_TIPO_ID_CODEUDOR);

      vSolicitudTarjeta.Actualizar ();
   EXCEPTION WHEN OTHERS THEN
      outError := SQLERRM;
      RAISE_APPLICATION_ERROR(-20100, outError);
   END Actualiza_Solicitud;

   PROCEDURE Borrar_Solicitud (pNO_SOLICITUD      NUMBER,
                               pTIPO_SOLICITUD    VARCHAR2) IS
      vSolicitudTarjeta   TC.TC_SOLICITUD_TARJETA_OBJ;
   BEGIN
      vSolicitudTarjeta :=
         TC.TC_SOLICITUD_TARJETA_OBJ (NULL,
                                      pNO_SOLICITUD,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL);

      vSolicitudTarjeta.Borrar ();
   EXCEPTION WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20100, 'Error '||SQLERRM);
   END;

   FUNCTION Consultar_Solicitud (pCOD_PERSONA          VARCHAR2,
                                 pNO_SOLICITUD         NUMBER,
                                 pNUM_ID               VARCHAR2,
                                 pCOD_TIPO_PRODUCTO    VARCHAR2,
                                 pFECHA_SOLICITUD      DATE,
                                 pTIPO_SOLICITUD       VARCHAR2)
      RETURN TC.TC_SOLICITUD_TARJETA_LIST IS
      vSolicitudTarjetaList   TC.TC_SOLICITUD_TARJETA_LIST
                                 := TC.TC_SOLICITUD_TARJETA_LIST ();
   BEGIN
      SELECT TC.TC_SOLICITUD_TARJETA_OBJ (COD_PERSONA,
                                          NO_SOLICITUD,
                                          NUM_ID,
                                          COD_TIPO_PRODUCTO,
                                          FECHA_SOLICITUD,
                                          COD_TIPO_ID,
                                          AMPARADA_POR,
                                          NOMBRE_PLASTICO,
                                          COD_MOTIVO_NEGACION,
                                          CUPO_INDEPENDIENTE,
                                          COD_CICLO_FACT,
                                          COD_TIPO_MERCADO,
                                          CUPO_SOLICITADO_RD,
                                          ESTADO_DOCUMENTACION,
                                          COD_TIPO_CLIENTE,
                                          OFICINA,
                                          IND_PLASTICO,
                                          IND_DIFIERE,
                                          COD_DESPACHO,
                                          OFICINA_ENTREGA_TARJ,
                                          IND_CARGO_AUTOMATICO,
                                          COD_COMPENSACION,
                                          CTA_CARGO_AUTOMATICO,
                                          CTA_ALTERNA,
                                          NUM_ID_CODEUDOR,
                                          TIPO_GARANTIA,
                                          VALOR_GARANTIA,
                                          MODO_AMORTIZACION,
                                          CLIENTE_PRE_EMBOZO,
                                          MES_INICIAL_AMORT,
                                          EMPRESA_AGENTES,
                                          COD_AGENTE,
                                          EMP_ASIGNADA_AGTE,
                                          DIRECCION_CORRESP1,
                                          DIRECCION_CORRESP2,
                                          DIRECCION_CORRESP3,
                                          DIRECCION_CORRESP4,
                                          COD_PAIS,
                                          COD_PROVINCIA,
                                          COD_CANTON,
                                          COD_DISTRITO,
                                          COD_CIUDAD,
                                          TELEFONO_CORRESP,
                                          EXT_TELEFONO,
                                          ZPOSTAL_CORRESP,
                                          TIPO_EMISION,
                                          IND_TIPO_TARJETA,
                                          ESTADO,
                                          LIMITE_ASIGNADO_RD,
                                          LIMITE_ASIGNADO_US,
                                          ESTADO_SOLICITUD,
                                          FECHA_NEGACION,
                                          MODIFICADO_POR,
                                          FECHA_MODIFICACION,
                                          BIN,
                                          COD_PAIS_EST,
                                          COD_REGION_EST,
                                          COD_PROVINCIA_EST,
                                          COD_CIUDAD_EST,
                                          COD_MUNICIPIO_EST,
                                          COD_SECTOR_EST,
                                          COD_BARRIO_EST,
                                          COD_CALLE_EST,
                                          NUMERO_EST,
                                          DETALLE_EST,
                                          RES_APR_INMED,
                                          SECTOR_RES,
                                          BARRIO_RES,
                                          CALLE_RES,
                                          NUMERO_RES,
                                          DETALLE_RES,
                                          SEGREGACION_RD,
                                          CODIGO_ACTIVIDAD,
                                          CODIGO_SUBACTIVIDAD,
                                          CODIGO_SUB_CLASE,
                                          FEC_DIGITACION,
                                          FEC_RECIBO,
                                          LIMITE_APROBADO_RD,
                                          ADICIONADO_POR,
                                          FECHA_ADICION,
                                          CUPO_SOLICITADO_US,
                                          LIMITE_APROBADO_US,
                                          FECHA_APROBACION,
                                          USUARIO_APROBACION,
                                          COD_PROMOTOR,
                                          JUSTIF_DENEGADA,
                                          NUMERO_ASIENTO,
                                          COD_TIPO_ID_CODEUDOR)
        BULK COLLECT INTO vSolicitudTarjetaList
        FROM TC.TC_SOLICITUD_TARJETA T
       WHERE T.COD_PERSONA = NVL (pCOD_PERSONA, COD_PERSONA)
         AND T.NO_SOLICITUD = NVL (pNO_SOLICITUD, NO_SOLICITUD)
         AND T.NUM_ID = NVL (pNUM_ID, NUM_ID)
         AND T.COD_TIPO_PRODUCTO = NVL (pCOD_TIPO_PRODUCTO, COD_TIPO_PRODUCTO)
         AND T.FECHA_SOLICITUD = NVL (pFECHA_SOLICITUD, FECHA_SOLICITUD);

      RETURN vSolicitudTarjetaList;
   END Consultar_Solicitud;
   
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
   
END TC_SOLICITUD;
/