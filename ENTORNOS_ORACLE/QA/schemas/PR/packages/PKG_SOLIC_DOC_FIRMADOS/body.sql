create or replace PACKAGE BODY    PKG_SOLIC_DOC_FIRMADOS IS
    PROCEDURE Generar(pCodigo_Empresa       IN     NUMBER,
                      pNo_Credito           IN     NUMBER,
                      pEstado               IN     VARCHAR2,
                      pResultado            IN OUT VARCHAR2) IS
        pData      PR.PR_SOLIC_DOC_FIRMADOS_OBJ;
        vIdError   NUMBER := 0;
    BEGIN
        pData := PR.PR_SOLIC_DOC_FIRMADOS_OBJ();
        pData.CODIGO_EMPRESA := pCodigo_Empresa;
        pData.NO_CREDITO := pNo_Credito;
        pData.ESTADO := pEstado;

        IF pData.Validar('G', pResultado) THEN
            -- Existe
            IF pData.Existe() = FALSE THEN
                -- Insertar
                pData.crear();
            ELSE
                -- Modificar
                pData.Actualizar();
            END IF;

            pResultado := 'Exitoso.';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pResultado := SQLCODE || ': ' || SQLERRM;
            PR.PKG_SOLIC_DOC_FIRMADOS.LogError(
                pData                => pData,
                inProgramUnit        => 'Generar',
                inErrorDescription   => pResultado,
                inErrorTrace         => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,
                outIdError           => vIdError);
            RAISE_APPLICATION_ERROR(-20100, 'Error ' || SQLERRM);
    END Generar;

    PROCEDURE Crear(pCodigo_Empresa       IN     NUMBER,
                    pNo_Credito           IN     NUMBER,
                    pEstado               IN     VARCHAR2,
                    pResultado            IN OUT VARCHAR2) IS
        pData      PR.PR_SOLIC_DOC_FIRMADOS_OBJ;
        vIdError   NUMBER := 0;
    BEGIN
        pData := PR.PR_SOLIC_DOC_FIRMADOS_OBJ();
        pData.CODIGO_EMPRESA := pCodigo_Empresa;
        pData.NO_CREDITO := pNo_Credito;
        pData.ESTADO := pEstado;

        IF pData.Validar('C', pResultado) THEN
            -- Existe
            IF pData.Existe() = FALSE THEN
                pData.Crear();
                pResultado := 'Exitoso.';
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pResultado := SQLCODE || ': ' || SQLERRM;
            PR.PKG_SOLIC_DOC_FIRMADOS.LogError(
                pData                => pData,
                inProgramUnit        => 'Crear',
                inErrorDescription   => pResultado,
                inErrorTrace         => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,
                outIdError           => vIdError);
            RAISE_APPLICATION_ERROR(-20100, 'Error ' || SQLERRM);
    END Crear;

    PROCEDURE Actualizar(pCodigo_Empresa       IN     NUMBER,
                         pNo_Credito           IN     NUMBER,
                         pEstado               IN     VARCHAR2,
                         pResultado            IN OUT VARCHAR2) IS
        pData      PR.PR_SOLIC_DOC_FIRMADOS_OBJ;
        vIdError   NUMBER := 0;
    BEGIN
        pData := PR.PR_SOLIC_DOC_FIRMADOS_OBJ();
        pData.CODIGO_EMPRESA := pCodigo_Empresa;
        pData.NO_CREDITO := pNo_Credito;
        pData.ESTADO := pEstado;

        IF pData.Validar('U', pResultado) THEN
            -- Existe
            IF pData.Existe() = TRUE THEN
                pData.Actualizar();
                pResultado := 'Exitoso.';
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pResultado := SQLCODE || ': ' || SQLERRM;
            PR.PKG_SOLIC_DOC_FIRMADOS.LogError(
                pData                => pData,
                inProgramUnit        => 'Actualizar',
                inErrorDescription   => pResultado,
                inErrorTrace         => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,
                outIdError           => vIdError);
            RAISE_APPLICATION_ERROR(-20100, 'Error ' || SQLERRM);
    END Actualizar;

    PROCEDURE ProcesarSolicitud(pCodigo_Empresa       IN      NUMBER,
                                pNo_Credito           IN      NUMBER,
                                pArchivos             IN PA.PKG_API_PKM.tDescargaList,
                                pResultado            IN OUT VARCHAR2) IS        
        vEmail          VARCHAR2(300);
        vToken          VARCHAR2(4000);
        vUsuarioPkm     VARCHAR2(100);
        vPasswordPkm    VARCHAR2(100);
        vDocumentos     PA.PKG_API_PKM.tDocumentos := PA.PKG_API_PKM.tDocumentos();
        vDescargas      PA.PKG_API_PKM.tDescargaList := PA.PKG_API_PKM.tDescargaList(); 
        vDescarga       PA.PKG_API_PKM.tDescarga;
        vDirectory      VARCHAR2(256) := PA.PARAM.PARAMETRO_X_EMPRESA('1', 'EMAIL_DIRECTORY_DF', 'PR');
        vComma          VARCHAR2(5) := ',';  
        vIndex          PLS_INTEGER := 0;          
        vPathConv       VARCHAR2(4000) := NULL;
        
        -- Variables de respaldo (aunque la lógica principal ahora está en la tabla)
        vLinuxPath      VARCHAR2(4000) := TRIM(PA.PARAM.PARAMETRO_X_EMPRESA('1', 'RUTALINUX_IMG_PKM', 'PA'));
        vSQLDir         VARCHAR2(500);        
        
        CURSOR c_EmailMancomunado IS
        SELECT PA.F_DEVUELVE_EMAIL_CLIENTE (C.CODIGO_CLIENTE) email
          FROM PA.CUENTA_CLIENTE_RELACION c           
          WHERE C.COD_SISTEMA = 'PR'
            AND c.NUM_CUENTA = TO_CHAR(pNo_Credito);  
        TYPE tEmail IS TABLE OF c_EmailMancomunado%ROWTYPE; 
        vEmailMan       tEmail := tEmail();    
       
        --nTime           IA.LOGGER.TTIME;        
        vDocSeguros     PA.PKG_API_PKM.tDescargaList := PA.PKG_API_PKM.tDescargaList();
    BEGIN
        -- Obtiene el correo del cliente.
        BEGIN
            OPEN c_EmailMancomunado;
            LOOP
                FETCH c_EmailMancomunado BULK COLLECT INTO vEmailMan LIMIT 50;
                FOR i IN 1 .. vEmailMan.COUNT LOOP
                    IF vEmailMan.COUNT = i OR vEmailMan.COUNT = 1 THEN
                        vComma := NULL;
                    END IF;
                    
                    IF vEmailMan(I).EMAIL IS NOT NULL THEN
                        vEmail := vEmail||vEmailMan(i).EMAIL||vComma;
                    END IF;
                    
                END LOOP;
                EXIT WHEN c_EmailMancomunado%NOTFOUND;
            END LOOP;
            CLOSE c_EmailMancomunado;
            
        EXCEPTION WHEN NO_DATA_FOUND THEN
            BEGIN
                SELECT PA.F_DEVUELVE_EMAIL_CLIENTE (C.CODIGO_CLIENTE) INTO vEmail FROM PR.PR_CREDITOS C WHERE C.NO_CREDITO = pNo_Credito;
            EXCEPTION WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20100, 'Error Datos del crédito no encontrado .'||SQLERRM);
            END;
        END;           

        IF vEmail IS NOT NULL THEN      
            -- Inserta el Registro de la solicitud
            Generar(pCodigo_Empresa, pNo_Credito, 'P', pResultado); 
            
            -- Usuario y password de PKM
            vUsuarioPkm := PA.PARAM.PARAMETRO_X_EMPRESA(pCodigo_Empresa, 'USUARIO_API_PKM', 'IA');
            vPasswordPkm := PA.PARAM.PARAMETRO_X_EMPRESA(pCodigo_Empresa, 'PASSWORD_API_PKM', 'IA');  
            
            -- Obtiene el Token      
            vToken := PA.PKG_API_PKM.OBTENER_TOKEN(vUsuarioPkm, vPasswordPkm);
            DBMS_OUTPUT.PUT_LINE ( 'vToken = ' || vToken );
            
            -- Obtiene los ID de los documentos firmados        
            vDocumentos := PA.PKG_API_PKM.Obtiene_Documentos_Firmados(pNo_Credito, TRUE, vToken);      
            DBMS_OUTPUT.PUT_LINE ( 'Obtiene_id Documentos_Firmados = ' || vDocumentos.COUNT ); 
             
            IF vDocumentos.COUNT > 0 THEN
                -- Actualiza la solicitud a W = WebServices
                Actualizar(pCodigo_Empresa, pNo_Credito, 'W', pResultado);  
                 
                FOR i IN 1 .. vDocumentos.COUNT LOOP
                    -- Descarga los documentos firmados
                    vDescargas.DELETE;
                    vDescargas := PA.PKG_API_PKM.Descarga_Documentos_Firmados(vDocumentos(i), vToken);
                    DBMS_OUTPUT.PUT_LINE ( 'vDocumentos('||i||') = ' || vDocumentos(i)  ||' vDescargas.COUNT = ' || vDescargas.COUNT );
                    
                    IF vDescargas.COUNT > 0 THEN
                        Actualizar(pCodigo_Empresa, pNo_Credito, 'D', pResultado);
                                      
                        FOR d IN 1 .. vDescargas.COUNT LOOP  
                          
                            vDescargas(d).DirectoryName := vDirectory; 
                            
                            DECLARE
                                vRutaMountDB  VARCHAR2(4000);
                                vKeyWindowDB  VARCHAR2(50);
                            BEGIN
                                -- 1. Buscamos en PA_PARAMETROS_MVP filtrando por el grupo 'PKM_PATHS'
                                BEGIN
                                    SELECT VALOR, CODIGO_PARAMETRO
                                      INTO vRutaMountDB, vKeyWindowDB
                                      FROM PA.PA_PARAMETROS_MVP
                                     WHERE CODIGO_EMPRESA = 1
                                       AND CODIGO_MVP = 'PKM_PATHS'
                                       AND INSTR(vDescargas(d).FilePath, CODIGO_PARAMETRO) > 0
                                     FETCH FIRST 1 ROWS ONLY;
                                EXCEPTION WHEN NO_DATA_FOUND THEN
                                    vRutaMountDB := '/mnt/pkm_Imagenes8';
                                    vKeyWindowDB := 'Imagenes_8';
                                END;

                                vPathConv := REPLACE(vDescargas(d).FilePath, '\', '/');
                                
                                -- Cortamos la ruta usando la KEY encontrada (CODIGO_PARAMETRO)
                                vPathConv := SUBSTR(vPathConv, INSTR(vPathConv, vKeyWindowDB) + LENGTH(vKeyWindowDB));
                                
                                -- Concatenamos el Mount Point de Linux (VALOR) + la ruta relativa
                                vPathConv := vRutaMountDB || vPathConv;
                                
                                -- Quitamos el nombre del archivo
                                vPathConv := REPLACE(vPathConv, vDescargas(d).Name, '');
                                
                                vPathConv := REPLACE(vPathConv, '//', '/');
                                
                            END;

                            BEGIN
                                vSQLDir := 'CREATE OR REPLACE DIRECTORY ' || vDirectory || ' AS ''' || vPathConv|| '''';            
                                EXECUTE IMMEDIATE vSQLDir;
                            EXCEPTION WHEN OTHERS THEN
                                DBMS_OUTPUT.PUT_LINE ('Error Recreando el directorio '||vDirectory||' con la ruta '||vPathConv);
                            END;
                            
                            PR.PKG_PR_DOCUMENTOS_FIRMADOS.Generar(pId                 => NULL,
                                                                  pCodigo_Empresa     => pCodigo_Empresa,
                                                                  pNo_Credito         => pNo_Credito,
                                                                  pId_Documento_Pkm   => vDocumentos(i),
                                                                  pRuta_Archivo       => vDescargas(d).FilePath,
                                                                  pNombre_Archivo     => vDescargas(d).Name,
                                                                  pEmail_Solicitante  => LOWER(vEmail),
                                                                  pEstado             => 'D',
                                                                  pComentario         => 'Descargado',
                                                                  pResultado          => pResultado);
                            DBMS_OUTPUT.PUT_LINE ( 'Insertar Documentos Firmados pResultado = ' || pResultado );
                        END LOOP;  
                    END IF;        
                    
                END LOOP; 
            END IF;    
                    
            vIndex := vDescargas.COUNT;                        
                        
            DBMS_OUTPUT.PUT_LINE ( 'Archivos Adicionales = ' || pArchivos.COUNT ||'     Documentos Descargados = '||vDescargas.COUNT||' Index='||vIndex);
            
            -- Anexa/Unificar los demás documentos 
            FOR d IN 1 .. pArchivos.COUNT LOOP                    
                vDescarga.Name := pArchivos(d).Name;                
                vDescarga.FilePath := pArchivos(d).FilePath;
                vDescarga.DirectoryName := pArchivos(d).DirectoryName;
                vDescarga.Extension := pArchivos(d).Extension;      
                vDescargas.EXTEND;
                vIndex := vIndex + 1;
                vDescargas(vIndex) := vDescarga;
            END LOOP;    
            
            DBMS_OUTPUT.PUT_LINE ( 'Total de Documentos = ' || vDescargas.COUNT );
            
            IF vDescargas.COUNT > 0 THEN
                
                -- Enviar Email al cliente
                Email_Docs_Firmados(LOWER(vEmail), vDescargas, pResultado);    
                      
                -- Actualiza la solicitud a S = Send to Email
                Actualizar(pCodigo_Empresa, pNo_Credito, 'S', pResultado);
                
                -- Mantener la lógica original de restaurar el directorio al default (opcional pero recomendado)
                BEGIN
                    vSQLDir := 'CREATE OR REPLACE DIRECTORY ' || vDirectory || ' AS ''' || vLinuxPath|| '''';            
                    EXECUTE IMMEDIATE vSQLDir;
                EXCEPTION WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE ('Error Recreando el directorio '||vDirectory||' con la ruta '||vLinuxPath);
                END; 
            END IF;                                    
        ELSE
            pResultado := 'Error los clientes del crédito '||pNo_Credito||' no tienen email';    
        END IF;
    EXCEPTION WHEN OTHERS THEN    
        -- Actualiza la solicitud a E = Error
        Actualizar(pCodigo_Empresa, pNo_Credito, 'E', pResultado);
        pResultado := 'Error '||SQLERRM;
        RAISE_APPLICATION_ERROR(-20100, pResultado);        
    END ProcesarSolicitud;
    
    PROCEDURE DescargarDocumentosSeguro(
        pCodigo_Empresa   IN     NUMBER,
        pNo_Credito       IN     NUMBER,
        pArchivos         IN OUT PA.PKG_API_PKM.tDescargaList,
        pResultado        IN OUT VARCHAR2) IS
        vJson       CLOB;
        vDocumento  PA.PKG_API_PKM.tDescarga := PA.PKG_API_PKM.tDescarga();
        vTotal      PLS_INTEGER := 0;
        j           APEX_JSON.T_VALUES;
        vData       BLOB;
    BEGIN
        vJson := '{
	"documentos": [
		{
			"code": "19",
			"name": "Hoja resumen del seguro de Vida Menor ¿ Póliza requerida",
			"archivo": "HRSeguroVidaMenor",
			"directorio": "RPT_REGULATORIO"
		},
		{
			"code": "20",
			"name": "Hoja resumen del seguro de Vida Mayor",
			"archivo": "HRSeguroVidaMayor",
			"directorio": "RPT_REGULATORIO"
		},
		{
			"code": "21",
			"name": "Hoja resumen del seguro Hipotecario (Incendio y Líneas Aliadas)",
			"archivo": "HRSeguroHipotecario",
			"directorio": "RPT_REGULATORIO"
		},
		{
			"code": "22",
			"name": "Hoja resumen del seguro de vehículo Full",
			"archivo": "HRSeguroVehiculoFull",
			"directorio": "RPT_REGULATORIO"
		},
		{
			"code": "23",
			"name": "Hoja resumen de la póliza de vehículo Interés Simple",
			"archivo": "HRSeguroVehiculoInteresSimple",
			"directorio": "RPT_REGULATORIO"
		},
		{
			"code": "24",
			"name": "Hoja resumen del seguro Protección Cuota",
			"archivo": "HRSeguroProteccionCuota",
			"directorio": "RPT_REGULATORIO"
		},
		{
			"code": "25",
			"name": "Hoja resumen del seguro Incendio Contenido",
			"archivo": "HRSeguroIncendio",
			"directorio": "RPT_REGULATORIO"
		}
	]
}';
    
        APEX_JSON.parse(j, vJson);    
        vTotal  := APEX_JSON.get_count(p_values => j, p_path => 'documentos');
        FOR i  IN 1 .. vTotal LOOP
            vDocumento  := PA.PKG_API_PKM.tDescarga();
            vDocumento.ID    := APEX_JSON.get_varchar2(p_values => j, p_path => 'documentos[%d].code',  p0 => i);
            vDocumento.Name  := APEX_JSON.get_varchar2(p_values => j, p_path => 'documentos[%d].archivo',  p0 => i);
            vDocumento.DirectoryName := APEX_JSON.get_varchar2(p_values => j, p_path => 'documentos[%d].directorio',  p0 => i);
            vDocumento.Extension  := '.pdf';
            SELECT PA.PKG_DOCUMENTO_SEGURO.IMPRIMEDOCSEGUROS(vDocumento.ID, pNo_Credito) INTO vData  FROM DUAL;
            PA.PKG_REPORTS.EscribeArchivo(vData, vDocumento.DirectoryName, vDocumento.Name||'_'||pNo_Credito||vDocumento.Extension);            
            pArchivos.EXTEND;
            pArchivos(i)    := vDocumento;                             
        END LOOP;
    EXCEPTION WHEN OTHERS THEN    
        -- Actualiza la solicitud a E = Error
        Actualizar(pCodigo_Empresa, pNo_Credito, 'E', pResultado);
        pResultado := 'Error '||SQLERRM;
        RAISE_APPLICATION_ERROR(-20100, pResultado);  
    END;
    /*PROCEDURE CopiarArchivo(pOrigen     IN VARCHAR2,
                            pDestino    IN VARCHAR2, 
                            pResultado  IN OUT VARCHAR2) IS
        vResponse       CLOB;
        vURL            VARCHAR2(300);
        --vBody           CLOB;
        vKey            RAW(2000);
        vRutaWallet     VARCHAR2(1000); 
        vPassWallet     VARCHAR2(200);
    BEGIN
        vURL := PA.PARAM.PARAMETRO_X_EMPRESA('1', 'URL_API_MESAAYUDA', 'IA') || 'copyFile';
        vURL := vURL ||'/'||APEX_UTIL.URL_ENCODE(pOrigen)||'/'||APEX_UTIL.URL_ENCODE(pDestino);
        DBMS_OUTPUT.PUT_LINE('vURL = ' || vURL);

        APEX_WEB_SERVICE.g_request_headers.delete();
        APEX_WEB_SERVICE.g_request_headers(1).name := 'Content-Type';
        APEX_WEB_SERVICE.g_request_headers(1).VALUE := 'application/json';                

        IF LOWER(vUrl) LIKE 'https%' THEN
            -- Desencriptar ruta y pass
            vKey := PR.PR_PKG_REPRESTAMOS.F_Obt_Parametro_Represtamo_Raw('CIFRADO_MASTERKEY');
            vRutaWallet := PA.DECIFRAR(PR.PR_PKG_REPRESTAMOS.F_Obt_Parametro_Represtamo_Raw('RUTA_WALLET'), vKey);
            vPassWallet := PA.DECIFRAR(PR.PR_PKG_REPRESTAMOS.F_Obt_Parametro_Represtamo_Raw('CLAVE_WALLET'), vKey);  
        
            vResponse := apex_web_service.make_rest_request
                      (
                          p_url           => vUrl,
                          p_http_method   => 'POST',
                          p_wallet_path   => vRutaWallet,
                          p_wallet_pwd    => vPassWallet
                      );
        ELSE
             vResponse := apex_web_service.make_rest_request
                      (
                          p_url           => vUrl,
                          p_http_method   => 'POST'
                      );
        END IF;

        DBMS_OUTPUT.PUT_LINE(' Copiar v_response = ' || vResponse);
                
    EXCEPTION WHEN OTHERS THEN    
        -- Actualiza la solicitud a E = Error
        pResultado := 'Error '||SQLERRM;
        RAISE_APPLICATION_ERROR(-20100, pResultado);
    END;*/                                
    
    PROCEDURE Email_Docs_Firmados(pDestino      IN VARCHAR2,
                                  pArchivos     IN PA.PKG_API_PKM.tDescargaList,
                                  pResultado    IN OUT VARCHAR2) IS

        vOrigen         VARCHAR2(600);   
        vAsunto         VARCHAR2(600);
        vMensaje        VARCHAR2(4000);
        vDirectory      VARCHAR2(60);
        vAttach         PA.tAttach_obj;
        vAttachments    PA.tAttachments := PA.tattachments();
        vData           BLOB;
        vIndx           PLS_INTEGER := 0; 
        
        
             
        --vServer         VARCHAR2(600) := PARAM.PARAMETRO_X_EMPRESA ('1', 'SERVIDOR_SMTP', 'PA');
    BEGIN    

        vOrigen     := PA.PARAM.PARAMETRO_X_EMPRESA('1', 'EMAIL_ORIGEN_DF', 'PR');
        vAsunto     := PA.PARAM.PARAMETRO_X_EMPRESA('1', 'EMAIL_SUBJECT_DF', 'PR');
        vDirectory  := PA.PARAM.PARAMETRO_X_EMPRESA('1', 'EMAIL_DIRECTORY_DF', 'PR');          --  'DIR_PKM_IMG';
                
        /*
        DBMS_OUTPUT.PUT_LINE ( 'pDestino = ' || pDestino );
        DBMS_OUTPUT.PUT_LINE ( 'vOrigen = ' || vOrigen );
        DBMS_OUTPUT.PUT_LINE ( 'vAsunto = ' || vAsunto );
        DBMS_OUTPUT.PUT_LINE ( 'vDirectory = ' || vDirectory );    
        */    
        
        SELECT p.DESCRIPCION 
          INTO vMensaje
          FROM PA.PARAMETROS_X_EMPRESA p
         WHERE p.COD_EMPRESA = '1'
           AND p.ABREV_PARAMETRO = 'EMAIL_MENSAJE_DF'
           AND p.COD_SISTEMA = 'PR';   
           
           
        FOR i IN 1 .. pArchivos.COUNT LOOP           
            
            BEGIN
                vData := EMPTY_BLOB();
                vData :=  PA.FILE_TO_BLOB (NVL(pArchivos(i).DirectoryName, vDirectory), pArchivos(i).Name);   
                --DBMS_OUTPUT.PUT_LINE ( 'vData = ' || LENGTH(vData) );                  
            EXCEPTION WHEN OTHERS THEN
                pResultado := 'Error cargando archivo a '||pDestino||' '||SQLERRM||' '||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
                --RAISE_APPLICATION_ERROR(-20100, pResultado);
            END;
            
            --DBMS_OUTPUT.PUT_LINE ( 'Directory = '||pArchivos(i).DirectoryName||'    Filename = '||pArchivos(i).Name||'   vData = ' || LENGTH(vData) );
             
            IF vData IS NOT NULL AND  LENGTH(vData) > 0 THEN                                                                                                                                                                    
                
                vAttach := PA.tAttach_obj();
                vAttach.Filename := pArchivos(i).Name;
                vAttach.Data := vData;            
                vAttach.Extension := pArchivos(i).Extension;                
                vAttachments.EXTEND;
                vIndx := vIndx + 1;
                vAttachments(vIndx) := vAttach;
            ELSE
                DBMS_OUTPUT.PUT_LINE ( 'El archivo '||pArchivos(i).Name||' no contiene datos '||LENGTH(vData) );
            END IF;
        END LOOP;
        
        --DBMS_OUTPUT.PUT_LINE ( 'vAttachments = ' || vAttachments.COUNT );
        IF vAttachments.COUNT > 0 THEN
            pa.Send_Mail_Attachs( vOrigen, pDestino, vAsunto, vMensaje, vAttachments);
        END IF;
                           
    EXCEPTION WHEN OTHERS THEN
        pResultado := 'Error enviando el correo a '||pDestino||' '||SQLERRM||' '||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
        RAISE_APPLICATION_ERROR(-20100, pResultado);
    END Email_Docs_Firmados;
        

    PROCEDURE Borrar(pCodigo_Empresa   IN     NUMBER,
                     pNo_Credito       IN     NUMBER,
                     pResultado        IN OUT VARCHAR2) IS
        pData      PR.PR_SOLIC_DOC_FIRMADOS_OBJ;
        vIdError   NUMBER := 0;
    BEGIN
        pData := PR.PR_SOLIC_DOC_FIRMADOS_OBJ();
        pData.CODIGO_EMPRESA := pCodigo_Empresa;
        pData.NO_CREDITO := pNo_Credito;

        IF pData.Validar('D', pResultado) THEN
            -- Existe
            IF pData.Existe() = TRUE THEN
                pData.Borrar();
                pResultado := 'Exitoso.';
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pResultado := SQLCODE || ': ' || SQLERRM;
            PR.PKG_SOLIC_DOC_FIRMADOS.LogError(
                pData                => pData,
                inProgramUnit        => 'Borrar',
                inErrorDescription   => pResultado,
                inErrorTrace         => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,
                outIdError           => vIdError);
            RAISE_APPLICATION_ERROR(-20100, 'Error ' || SQLERRM);
    END Borrar;

    FUNCTION Consultar(pCodigo_Empresa       IN     NUMBER,
                       pNo_Credito           IN     NUMBER,
                       pFecha_Solicitud      IN     DATE,
                       pAdicionado_Por       IN     VARCHAR2,
                       pFecha_Adicion        IN     DATE,
                       pModificado_Por       IN     VARCHAR2,
                       pFecha_Modificacion   IN     DATE,
                       pEstado               IN     VARCHAR2,
                       pResultado            IN OUT VARCHAR2)
        RETURN PR.PR_SOLIC_DOC_FIRMADOS_LIST IS
        CURSOR cData IS
            SELECT *
              FROM PR.PR_SOLIC_DOC_FIRMADOS t1
             WHERE (t1.CODIGO_EMPRESA = pCodigo_Empresa OR pCodigo_Empresa IS NULL)
               AND (t1.NO_CREDITO = pNo_Credito OR pNo_Credito IS NULL)
               AND (t1.FECHA_SOLICITUD = pFecha_Solicitud OR pFecha_Solicitud IS NULL)
               AND (t1.ADICIONADO_POR = pAdicionado_Por OR pAdicionado_Por IS NULL)
               AND (t1.FECHA_ADICION = pFecha_Adicion OR pFecha_Adicion IS NULL)
               AND (t1.MODIFICADO_POR = pModificado_Por OR pModificado_Por IS NULL)
               AND (t1.FECHA_MODIFICACION = pFecha_Modificacion OR pFecha_Modificacion IS NULL)
               AND (t1.ESTADO = pEstado OR pEstado IS NULL);

        TYPE tData IS TABLE OF cData%ROWTYPE;

        vData       tData;
        vDataList   PR.PR_SOLIC_DOC_FIRMADOS_LIST
                        := PR.PR_SOLIC_DOC_FIRMADOS_LIST();
        pData       PR.PR_SOLIC_DOC_FIRMADOS_OBJ;
        indice      NUMBER := 0;
        vIdError    NUMBER := 0;
    BEGIN
        vDataList.DELETE;

        OPEN cData;

        LOOP
            FETCH cData BULK COLLECT INTO vData LIMIT 5000;

            FOR i IN 1 .. vData.COUNT LOOP
                pData := PR.PR_SOLIC_DOC_FIRMADOS_OBJ();
                pData.CODIGO_EMPRESA := vData(i).CODIGO_EMPRESA;
                pData.NO_CREDITO := vData(i).NO_CREDITO;
                pData.FECHA_SOLICITUD := vData(i).FECHA_SOLICITUD;
                pData.ADICIONADO_POR := vData(i).ADICIONADO_POR;
                pData.FECHA_ADICION := vData(i).FECHA_ADICION;
                pData.MODIFICADO_POR := vData(i).MODIFICADO_POR;
                pData.FECHA_MODIFICACION := vData(i).FECHA_MODIFICACION;
                pData.ESTADO := vData(i).ESTADO;
                indice := indice + i;
                vDataList.EXTEND;
                vDataList(indice) := pData;
            END LOOP;

            EXIT WHEN cData%NOTFOUND;
        END LOOP;

        CLOSE cData;

        pResultado := 'Exitoso.';
        RETURN vDataList;
    EXCEPTION
        WHEN OTHERS THEN
            pResultado := SQLCODE || ': ' || SQLERRM;
            PR.PKG_SOLIC_DOC_FIRMADOS.LogError(
                pData                => pData,
                inProgramUnit        => 'Consultar',
                inErrorDescription   => pResultado,
                inErrorTrace         => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,
                outIdError           => vIdError);
            RAISE_APPLICATION_ERROR(-20404, 'Error ' || SQLERRM);
    END Consultar;

    FUNCTION Comparar(pData1       IN OUT PR.PR_SOLIC_DOC_FIRMADOS_OBJ,
                      pData2       IN OUT PR.PR_SOLIC_DOC_FIRMADOS_OBJ,
                      pModo        IN     VARCHAR2,
                      pResultado   IN OUT VARCHAR2)
        -- O = (Compare between Objects pData1 and pData2),
        -- T = (Compare pData1 and Table data "Must used pData2 like search parameter in table)
        RETURN BOOLEAN IS
        vIgual      BOOLEAN := FALSE;
        vDataList   PR.PR_SOLIC_DOC_FIRMADOS_LIST := PR.PR_SOLIC_DOC_FIRMADOS_LIST();
        vData       PR.PR_SOLIC_DOC_FIRMADOS_OBJ := PR.PR_SOLIC_DOC_FIRMADOS_OBJ();
        vIdError    NUMBER := 0;
    BEGIN
        IF pModo = 'O' THEN
            IF pData1 IS NOT NULL
           AND pData2 IS NOT NULL THEN
                vIgual := pData1.Compare(pData2);
            ELSE
                vIgual := TRUE;
            END IF;
        ELSIF pModo = 'T' THEN
            vDataList :=
                Consultar(pCodigo_Empresa       => pData2.CODIGO_EMPRESA,
                          pNo_Credito           => pData2.NO_CREDITO,
                          pFecha_Solicitud      => pData2.FECHA_SOLICITUD,
                          pAdicionado_Por       => pData2.ADICIONADO_POR,
                          pFecha_Adicion        => pData2.FECHA_ADICION,
                          pModificado_Por       => pData2.MODIFICADO_POR,
                          pFecha_Modificacion   => pData2.FECHA_MODIFICACION,
                          pEstado               => pData2.ESTADO,
                          pResultado            => pResultado);

            IF vDataList.COUNT > 0 THEN
                vData := vDataList(1);
                vIgual := pData1.Compare(vData);
            ELSE
                vIgual := FALSE;
            END IF;
        END IF;

        pResultado := 'Exitoso.';
        RETURN vIgual;
    END Comparar;

    FUNCTION Existe(pCodigo_Empresa   IN     NUMBER,
                    pNo_Credito       IN     NUMBER,
                    pResultado        IN OUT VARCHAR2)
        RETURN BOOLEAN IS
        pData      PR.PR_SOLIC_DOC_FIRMADOS_OBJ;
        vIdError   NUMBER := 0;
    BEGIN
        pData := PR.PR_SOLIC_DOC_FIRMADOS_OBJ();
        pData.CODIGO_EMPRESA := pCodigo_Empresa;
        pData.NO_CREDITO := pNo_Credito;
        pResultado := 'Exitoso.';
        RETURN pData.Existe();
    EXCEPTION
        WHEN OTHERS THEN
            pResultado := SQLCODE || ': ' || SQLERRM;
            PR.PKG_SOLIC_DOC_FIRMADOS.LogError(
                pData                => pData,
                inProgramUnit        => 'Existe',
                inErrorDescription   => pResultado,
                inErrorTrace         => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,
                outIdError           => vIdError);
            RAISE_APPLICATION_ERROR(-20404, 'Error ' || SQLERRM);
    END Existe;

    FUNCTION Validar(pCodigo_Empresa       IN     NUMBER,
                     pNo_Credito           IN     NUMBER,
                     pFecha_Solicitud      IN     DATE,
                     pEstado               IN     VARCHAR2,
                     pOperacion            IN     VARCHAR2, -- G=Generar, C=Crear, U=Actualizar, D=Borrar
                     pError                IN OUT VARCHAR2)
        RETURN BOOLEAN IS
        pData      PR.PR_SOLIC_DOC_FIRMADOS_OBJ;
        vValidar   BOOLEAN := FALSE;
        vIdError   NUMBER := 0;
    BEGIN
        pData := PR.PR_SOLIC_DOC_FIRMADOS_OBJ();
        pData.CODIGO_EMPRESA := pCodigo_Empresa;
        pData.NO_CREDITO := pNo_Credito;
        pData.FECHA_SOLICITUD := pFecha_Solicitud;
        pData.ESTADO := pEstado;
        vValidar := pData.Validar(pOperacion, pError);
        PR.PKG_SOLIC_DOC_FIRMADOS.LogError(
            pData                => pData,
            inProgramUnit        => 'Validar',
            inErrorDescription   => pError,
            inErrorTrace         => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,
            outIdError           => vIdError);
        RETURN vValidar;
    END Validar;

    PROCEDURE LogError(pData                IN OUT PR.PR_SOLIC_DOC_FIRMADOS_OBJ,
                       inProgramUnit        IN     IA.LOG_ERROR.PROGRAMUNIT%TYPE,
                       inErrorDescription   IN     VARCHAR2,
                       inErrorTrace         IN     CLOB,
                       outIdError              OUT NUMBER) IS
        pPackageName   CONSTANT IA.LOG_ERROR.PACKAGENAME%TYPE := 'PR.PKG_SOLIC_DOC_FIRMADOS' ;
    BEGIN
        IA.LOGGER.ADDPARAMVALUEV('pCodigo_Empresa', pData.Codigo_Empresa);
        IA.LOGGER.ADDPARAMVALUEV('pNo_Credito', pData.No_Credito);
        IA.LOGGER.ADDPARAMVALUEV('pEstado', pData.Estado);
        IA.LOGGER.LOG(INOWNER               => SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA'),
                      INPACKAGENAME         => pPackageName,
                      INPROGRAMUNIT         => inProgramUnit,
                      INPIECECODENAME       => NULL,
                      INERRORDESCRIPTION    => inErrorDescription,
                      INERRORTRACE          => inErrorTrace,
                      INEMAILNOTIFICATION   => NULL,
                      INPARAMLIST           => IA.LOGGER.vPARAMLIST,
                      INOUTPUTLOGGER        => FALSE,
                      INEXECUTIONTIME       => NULL,
                      outIdError            => outIdError);

        IF IA.LOGGER.VPARAMLIST.COUNT > 0 THEN
            IA.LOGGER.VPARAMLIST.DELETE;
        END IF;
    END LogError;
END PKG_SOLIC_DOC_FIRMADOS;