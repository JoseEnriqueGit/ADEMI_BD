create or replace PACKAGE BODY    PKG_API_PKM IS

    FUNCTION Obtener_Token(p_Username    IN VARCHAR2,
                           p_Password    IN VARCHAR2) 
      RETURN VARCHAR2 IS
      vURL            VARCHAR2(300);
      vBody           VARCHAR2(4000);
      v_response      CLOB;
    BEGIN
        
        vURL := NVL(vUrlBase,PA.PARAM.PARAMETRO_X_EMPRESA('1', 'URL_API_PKM', 'IA'))||'fcwebapi/v2/authenticate/'; 
        -- http://bma0039/fcwebapi/v2/authenticate/
        --DBMS_OUTPUT.PUT_LINE ( 'Obtener_Token vURL = ' || vURL );
        
        APEX_WEB_SERVICE.g_request_headers.delete();
        APEX_WEB_SERVICE.g_request_headers (1).name  := 'Content-Type';
        APEX_WEB_SERVICE.g_request_headers (1).value := 'application/json';
        
        vBody := '{"username": "'||p_Username||'","password": "'||p_Password||'"}';
        -- DBMS_OUTPUT.PUT_LINE('Body:  '||vBody);
        
        -- GET Response with Token
        v_response := apex_web_service.make_rest_request(
              p_url           => vURL,
              p_http_method   => 'POST',
              p_body          =>  vBody                                      
        );        
        --DBMS_OUTPUT.PUT_LINE('Respose:  '|| v_response);
             
        --UTL_TCP.CLOSE_ALL_CONNECTIONS();
        RETURN REPLACE(v_response, '"','');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(SQLERRM||' '||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
    END Obtener_Token;
                                  
    FUNCTION Obtener_Aplicaciones(p_Token        IN VARCHAR2) 
      RETURN IA.PKM_APLICACION_LIST IS
        vAplicacionObj IA.PKM_APLICACION_OBJ;
        vRetorno        IA.PKM_APLICACION_LIST := IA.PKM_APLICACION_LIST();
        vURL            VARCHAR2(300) := NVL(vUrlBase,PA.PARAM.PARAMETRO_X_EMPRESA('1', 'URL_API_PKM', 'IA'))||'fcwebapi/control/getapplications?token='||p_Token;
        v_response      CLOB;  
        
        CURSOR cAplicacion(v_Json   CLOB) IS
        SELECT Col001 Name, Col002 Id, Col003 Description, Col004 Fields
         FROM table( 
              apex_data_parser.parse(
                  p_content         => PA.PA_CLOB_TO_BLOB (v_Json),
                  p_file_name       => 'test.json') ) ;
       
        TYPE tAplicacion IS TABLE OF cAplicacion%ROWTYPE;
        vAplicacion tAplicacion := tAplicacion();
        
    BEGIN
        APEX_WEB_SERVICE.g_request_headers.delete();
        APEX_WEB_SERVICE.g_request_headers (1).name  := 'Content-Type';
        APEX_WEB_SERVICE.g_request_headers (1).value := 'application/json';
        -- GET Response with Token
        v_response := apex_web_service.make_rest_request(
              p_url           => vURL,
              p_http_method   => 'GET'                                         
        );   
        
        OPEN cAplicacion(v_response);        
        LOOP
            FETCH cAplicacion BULK COLLECT INTO vAplicacion LIMIT 5000;
            FOR i IN 1 .. vAplicacion.COUNT LOOP
                vAplicacionObj := IA.PKM_APLICACION_OBJ();
                vAplicacionObj.IdAplicacion := vAplicacion(i).Id;
                vAplicacionObj.Nombre := vAplicacion(i).Name;
                vAplicacionObj.Descripcion := vAplicacion(i).Description;
                vAplicacionObj.Campos := vAplicacion(i).Fields;
                vRetorno.EXTEND;
                vRetorno(i) := vAplicacionObj;
            END LOOP;
            
            EXIT WHEN cAplicacion%NOTFOUND;
        END LOOP;                 
        CLOSE cAplicacion;
        UTL_TCP.CLOSE_ALL_CONNECTIONS();
        RETURN vRetorno;
        
    END Obtener_Aplicaciones;
      
    FUNCTION Obtener_Campos(p_Token          IN VARCHAR2,
                            p_Id_Aplicacion  IN NUMBER)
      RETURN IA.PKM_CAMPO_LIST IS
        vRetorno    IA.PKM_CAMPO_LIST := IA.PKM_CAMPO_LIST();        
        vCampoObj   IA.PKM_CAMPO_OBJ;
        vURL        VARCHAR2(4000) := vUrlBase||'fcwebapi/control/getapplicationfields?applicationid='||p_Id_Aplicacion||'&token='||p_Token;
        v_response  CLOB;          
                
        vValor   IA.PKM_VALOR_OBJ;
        vValores IA.PKM_VALOR_LIST := IA.PKM_VALOR_LIST();
        --l_paths     APEX_T_VARCHAR2 := APEX_T_VARCHAR2();
        v_TotalCampos       NUMBER := 0;
        v_TotalValores      NUMBER := 0;
        l_exists            BOOLEAN;
        
    BEGIN
        APEX_WEB_SERVICE.g_request_headers.delete();
        APEX_WEB_SERVICE.g_request_headers (1).name  := 'Content-Type';
        APEX_WEB_SERVICE.g_request_headers (1).value := 'application/json';
        
        BEGIN
            -- GET Response with Token
            v_response := apex_web_service.make_rest_request(
                  p_url           => vURL,
                  p_http_method   => 'GET'                                         
            );
        EXCEPTION WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20100, v_response||' '||SQLERRM);
        END;
        
        APEX_JSON.parse(v_response);
        v_TotalCampos := APEX_JSON.get_count(p_path => '.');
        
        FOR i IN 1 .. v_TotalCampos LOOP
            vCampoObj := IA.PKM_CAMPO_OBJ();
            vCampoObj.IdCampo   := APEX_JSON.get_number(p_path => '[%d].Id', p0 => i);            
            vCampoObj.Nombre    := APEX_JSON.get_varchar2(p_path => '[%d].Name', p0 => i);
            vCampoObj.Tipo      := APEX_JSON.get_number(p_path => '[%d].Type', p0 => i);
            vCampoObj.Alias     := APEX_JSON.get_varchar2(p_path => '[%d].Alias', p0 => i);
            l_exists := APEX_JSON.does_exist (p_path => '[%d].Values[1].Id', p0 => i);
            IF l_exists THEN
                v_TotalValores      := NVL(APEX_JSON.get_count(p_path   => '[%d].Values', p0 => i),0);
                FOR v IN 1 .. v_TotalValores LOOP
                    vValor := IA.PKM_VALOR_OBJ();
                    vValor.IdValor      := APEX_JSON.get_number(p_path => '[%d].Values[%d].Id', p0 => i, p1 => v);
                    vValor.Valor        := APEX_JSON.get_varchar2(p_path => '[%d].Values[%d].Value', p0 => i, p1 => v);
                    vValor.ValorExterno := APEX_JSON.get_varchar2(p_path => '[%d].Values[%d].ExternalValue', p0 => i, p1 => v);
                    vValores.EXTEND;
                    vValores(v) := vValor;
                END LOOP;
            ELSE
                v_TotalValores      := 0;
            END IF;   
            vCampoObj.Valores := vValores;
            vRetorno.EXTEND;
            vRetorno(i) := vCampoObj;                       
            
        END LOOP;                
        UTL_TCP.CLOSE_ALL_CONNECTIONS();
        RETURN vRetorno;
        
    END Obtener_Campos;      

    PROCEDURE Crear_Documento_Prestamo(p_Token          IN VARCHAR2,
                                       p_Id_Aplicacion  IN VARCHAR2,
                                       p_No_Credito     IN VARCHAR2,
                                       p_Tipo_Documento IN VARCHAR2,
                                       p_No_Credito_ant IN VARCHAR2,
                                       P_Origen         IN VARCHAR2,
                                       p_Directorio     IN VARCHAR2,
                                       p_Archivo1       IN VARCHAR2,
                                       p_Archivo2       IN VARCHAR2,
                                       p_Respuesta      IN OUT CLOB) IS
        vURL            VARCHAR2(4000);
        vFile1          BLOB;
        vFile2          BLOB;
        vExtension      VARCHAR2(15);
        vMimeType       PA.MIMETYPES_LISTADO.MIMETYPE_NOMBRE%TYPE;
        v_response      CLOB;
        
        v_Body          BLOB;
        v_multipart     apex_web_service.t_multipart_parts;
         
        --l_request_body_length   pls_integer := 0;                             
    BEGIN       
        --DBMS_OUTPUT.PUT_LINE('token='||p_Token||'&applicationid='||p_Id_Aplicacion||'&F_NUM_PRESTAMO='||p_No_Credito||'&F_DOCUMENT_TYPE='||p_Tipo_Documento||'&F_PREST_ANTERIOR='||p_No_Credito_ant||'&F_ORIGEN='||p_Origen);
        
        -- Construir el URL
        vURL := NVL(vUrlBase,PA.PARAM.PARAMETRO_X_EMPRESA('1', 'URL_API_PKM', 'IA'))||'fcwebapi/v2/apps/49/index/create?token='||p_Token||'&applicationid='||p_Id_Aplicacion||'&F_NUM_PRESTAMO='||p_No_Credito||'&F_DOCUMENT_TYPE='||p_Tipo_Documento||'&F_PREST_ANTERIOR='||p_No_Credito_ant||'&F_ORIGEN='||p_Origen;        
        DBMS_OUTPUT.PUT_LINE ( 'vURL = ' || vURL );
        
        -- Set Headers
        APEX_WEB_SERVICE.g_request_headers.delete();
        APEX_WEB_SERVICE.g_request_headers (1).name  := 'Content-Type';
        APEX_WEB_SERVICE.g_request_headers (1).value := 'multipart/form-data';
        
        -- Body
        IF p_Archivo1 IS NOT NULL THEN   
            vExtension := SUBSTR(p_Archivo1, INSTR(p_Archivo1, '.', -1));            
            BEGIN        
                SELECT DISTINCT m.MIMETYPE_NOMBRE 
                  INTO vMimeType
                  FROM PA.MIMETYPES_LISTADO m 
                  WHERE m.EXTENSION = vExtension;
            EXCEPTION WHEN NO_DATA_FOUND THEN
                vMimeType := 'application/pdf';
            END;
            
            vFile1 := ReadFileToBlob (in_Filename    => p_Archivo1,
                                      in_Directory   => p_Directorio,
                                      out_Error      => p_Respuesta);
            
            apex_web_service.append_to_multipart (
               p_multipart    => v_multipart,
               p_name         => 'Temp',
               p_filename     => p_Archivo1,
               p_content_type => vMimeType,
               p_body_blob    => vFile1 );
        END IF;
        
        IF p_Archivo2 IS NOT NULL THEN   
            vExtension := SUBSTR(p_Archivo2, INSTR(p_Archivo2, '.', -1));
            
            BEGIN        
                SELECT DISTINCT m.MIMETYPE_NOMBRE 
                  INTO vMimeType
                  FROM PA.MIMETYPES_LISTADO m 
                  WHERE m.EXTENSION = vExtension;
            EXCEPTION WHEN NO_DATA_FOUND THEN
                vMimeType := 'application/pdf';
            END;
            
            vFile2 := PA.PKG_API_PKM.ReadFileToBlob (in_Filename    => p_Archivo2,
                                                     in_Directory   => p_Directorio,
                                                     out_Error      => p_Respuesta);
            
            apex_web_service.append_to_multipart (
               p_multipart    => v_multipart,
               p_name         => 'Temp1',
               p_filename     => p_Archivo2,
               p_content_type => vMimeType,
               p_body_blob    => vFile2 );
        END IF;        
        
        v_Body := apex_web_service.generate_request_body (p_multipart    => v_multipart );        
                      
        -- POST Response with Token
        v_response := apex_web_service.make_rest_request(
              p_url           => vURL,
              p_http_method   => 'POST',
              p_body_blob     => v_Body                                         
        );
        
        --DBMS_OUTPUT.PUT_LINE ( 'v_response = ' || v_response );
        p_Respuesta := v_response;--'Sucessfull';
        
        UTL_TCP.CLOSE_ALL_CONNECTIONS();
    EXCEPTION WHEN OTHERS THEN
        p_Respuesta := SQLERRM;
        DBMS_OUTPUT.PUT_LINE(p_Respuesta);
        UTL_TCP.CLOSE_ALL_CONNECTIONS();
        RAISE_APPLICATION_ERROR(-20100, p_Respuesta);        
    END Crear_Documento_Prestamo;
           
    
    FUNCTION ObtieneParteReferencia(pCodigoReferencia IN VARCHAR2, 
                                    pDelimitador      IN VARCHAR2, 
                                    pNumeroParte      IN NUMBER)
      RETURN VARCHAR2 IS
      
        CURSOR cPartes IS
        with rws as ( select pCodigoReferencia str from dual )
          select regexp_substr (str, '[^'||pDelimitador||']+', 1, level ) value
            from   rws
          connect by level <= length ( str ) - length ( replace ( str, pDelimitador ) ) + 1;
        TYPE tParte IS TABLE OF cPartes%ROWTYPE;
        vPartes      tParte := tParte();
        v_Retorno   VARCHAR2(4000) := NULL;
    BEGIN
       OPEN cPartes;
       FETCH cPartes BULK COLLECT INTO vPartes LIMIT 50;    
    
       FOR i IN 1 .. vPartes.COUNT LOOP        
           IF i = pNumeroParte THEN
              v_Retorno := vPartes(i).VALUE;
           END IF;           
       END LOOP;
        
       RETURN v_Retorno;
        
    END; 
    
    PROCEDURE EnviarPKM(pOrigenPkm     IN     VARCHAR2, 
                        pRespuesta     IN OUT VARCHAR2) IS
        CURSOR cReportes IS
        SELECT * 
          FROM PA.V_REPORTES_AUTOM_SEND_PEND r 
         WHERE R.F_ORIGEN = pOrigenPkm;
        TYPE tReportes IS TABLE OF cReportes%ROWTYPE;
        vReportes   tReportes := tReportes();
        vToken       VARCHAR2(4000);
        vUsuario     VARCHAR2(30) := NVL(PA.PARAM.PARAMETRO_X_EMPRESA('1', 'USUARIO_API_PKM', 'IA'), 'Aapi');
        vPass        VARCHAR2(30) := NVL(PA.PARAM.PARAMETRO_X_EMPRESA('1', 'PASSWORD_API_PKM', 'IA'), 'A123456789*');
    BEGIN
        vToken := PA.PKG_API_PKM.Obtener_Token(vUsuario, vPass);
        DBMS_OUTPUT.PUT_LINE ( 'vToken = ' || vToken );
        OPEN cReportes;
        LOOP
            FETCH cReportes BULK COLLECT INTO vReportes LIMIT 500;
            FOR i IN 1 .. vReportes.COUNT LOOP
                
                PA.PKG_API_PKM.Crear_Documento_Prestamo(
                                       p_Token          => vToken,
                                       p_Id_Aplicacion  => vReportes(i).APPLICATIONID,
                                       p_No_Credito     => vReportes(i).F_NUM_PRESTAMO,
                                       p_Tipo_Documento => vReportes(i).F_DOCUMENT_TYPE,
                                       p_No_Credito_ant => vReportes(i).F_PREST_ANTERIOR,
                                       p_Origen         => vReportes(i).F_ORIGEN,
                                       p_Directorio     => 'RPT_REGULATORIOS',
                                       p_Archivo1       => vReportes(i).NOMBRE_ARCHIVO,
                                       p_Archivo2       => NULL,
                                       p_Respuesta      => pRespuesta);
                
                BEGIN
                    UPDATE PA.PA_REPORTES_AUTOMATICOS r
                       SET R.ESTADO_REPORTE = 'S', r.MENSAJE = 'ARCHIVO ENVIADO A PKM'
                     WHERE R.CODIGO_REPORTE = vReportes(i).CODIGO_REPORTE
                       AND R.ORIGEN_PKM = pOrigenPkm;
                EXCEPTION WHEN OTHERS THEN
                    pRespuesta := 'Error: '||SQLERRM;
                END;    
                null;                                   
            END LOOP;
            EXIT WHEN cReportes%NOTFOUND;
        END LOOP;
        CLOSE cReportes;
    END EnviarPKM;        
    
    
    FUNCTION Obtiene_Documentos_Firmados(p_NoCredito        IN NUMBER,
                                         p_FiltrarFirmados  IN BOOLEAN,
                                         p_Token            IN VARCHAR2)
      RETURN tDocumentos IS
      v_response        CLOB;
      vURL              VARCHAR2(1000);
      vApplicationId    VARCHAR2(2) := '2';      
      vDocumentType     VARCHAR2(200) ;--:= '="'||REPLACE('DOCUMENTOS FIRMADOS', ' ', '%20')||'"';
      v_TotalRegistros  PLS_INTEGER := 0;        
      v_Registros       PLS_INTEGER := 0;
      j                 apex_json.t_values;
      v_IdDocumento     tDocumentos := tDocumentos();  
      vId               PLS_INTEGER := 0;
      vDocumentId       PLS_INTEGER := 0;
      vDocumentName     VARCHAR2(2000);
      vDocumentValue    VARCHAR2(1000);  
      vIndex            PLS_INTEGER := 0;    
      
    BEGIN
        
        IF p_FiltrarFirmados THEN
            vDocumentType := '&F_DOCUMENT_TYPE="'||REPLACE('DOCUMENTOS FIRMADOS', ' ', '%20')||'"';
        ELSE
            vDocumentType := NULL;
        END IF;
    
        vURL := NVL(vUrlBase,PA.PARAM.PARAMETRO_X_EMPRESA('1', 'URL_API_PKM', 'IA'))||'fcwebapi/query/searchindices/?applicationid='||vApplicationId||''||vDocumentType||'&F_NUM_PRESTAMO='||p_NoCredito||'&token='||p_Token; 
        --DBMS_OUTPUT.PUT_LINE ( 'DOCUMENTOS FIRMADOS vURL = ' || vURL );
        
        APEX_WEB_SERVICE.g_request_headers.delete();
        APEX_WEB_SERVICE.g_request_headers (1).name  := 'Content-Type';
        APEX_WEB_SERVICE.g_request_headers (1).value := 'application/json; charset=utf-8';
        
        -- GET Response with Token
        v_response := apex_web_service.make_rest_request(
              p_url           => vURL,
              p_http_method   => 'GET'                      
        );
           
        --DBMS_OUTPUT.PUT_LINE ( 'v_response = ' || v_response );
        IF v_response IS NOT NULL THEN
            apex_json.parse(j, v_response);   
            v_TotalRegistros := APEX_JSON.get_count(p_values => j, p_path => '.');
            --DBMS_OUTPUT.PUT_LINE ( 'v_TotalRegistros = ' || v_TotalRegistros );
            FOR i IN 1 .. v_TotalRegistros LOOP
                
                vId := APEX_JSON.get_number(p_values => j, p_path => '[%d].DocumentId', p0 => i);
                --DBMS_OUTPUT.PUT_LINE ( 'vId = ' || vId );
                v_Registros := APEX_JSON.get_count(p_values => j, p_path => '[%d].DynamicFields', p0 => i);            
                --DBMS_OUTPUT.PUT_LINE ( 'v_Registros = ' || v_Registros );
                FOR y IN 1 .. v_Registros LOOP
                    vDocumentId     := APEX_JSON.get_varchar2(p_values => j, p_path => '[%d].DynamicFields[%d].Id',     p0 => i, p1 => y);
                    vDocumentName   := APEX_JSON.get_varchar2(p_values => j, p_path => '[%d].DynamicFields[%d].Name',   p0 => i, p1 => y);
                    vDocumentValue  := APEX_JSON.get_varchar2(p_values => j, p_path => '[%d].DynamicFields[%d].Value',  p0 => i, p1 => y);                    
                    --DBMS_OUTPUT.PUT_LINE ( '>>>>>>vDocumentId = '||vDocumentId||'           vDocumentName = ' || vDocumentName ||'            vDocumentValue = ' || vDocumentValue );
                    IF vDocumentName LIKE '%DOCUMENT_TYPE%' AND vDocumentValue LIKE '%DOCUMENTOS FIRMADOS%' THEN
                        --DBMS_OUTPUT.PUT_LINE ( 'DOCUMENTOS FIRNADOS >>>>>>vDocumentId = '||vDocumentId||'           vDocumentName = ' || vDocumentName ||'            vDocumentValue = ' || vDocumentValue );
                        v_IdDocumento.EXTEND; vIndex := vIndex + 1;
                        v_IdDocumento(vIndex)  := vId;
                    END IF;
                END LOOP;             
            END LOOP;        
        END IF;
        --DBMS_OUTPUT.PUT_LINE ( 'TOTAL v_IdDocumento = ' || v_IdDocumento.COUNT );
        --UTL_TCP.CLOSE_ALL_CONNECTIONS();
        RETURN v_IdDocumento;
    EXCEPTION WHEN OTHERS THEN
        --UTL_TCP.CLOSE_ALL_CONNECTIONS();
        RAISE_APPLICATION_ERROR(-20100, 'Error obteniendo datos del documentos firmados '||SQLERRM||' '||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
    END Obtiene_Documentos_Firmados; 
    
    FUNCTION Descarga_Documentos_Firmados(pDocumentId   IN NUMBER, 
                                          pToken        IN VARCHAR2)
      RETURN tDescargaList IS
            
      v_response        CLOB;
      vURL              VARCHAR2(1000);
      vApplicationId    VARCHAR2(2) := '2';
      vDescargas        PKG_API_PKM.tDescargaList := PKG_API_PKM.tDescargaList();
      v_TotalRegistros  PLS_INTEGER := 0;              
    BEGIN        
        
        vURL := NVL(vUrlBase,PA.PARAM.PARAMETRO_X_EMPRESA('1', 'URL_API_PKM', 'IA'))||'fcwebapi/documents/getdocumentpages/?applicationid='||vApplicationId||'&documentid='||pDocumentId||'&token='||pToken; 
        --DBMS_OUTPUT.PUT_LINE ( 'vURL = ' || vURL );
        
        APEX_WEB_SERVICE.g_request_headers.delete();
        APEX_WEB_SERVICE.g_request_headers (1).name  := 'Content-Type';
        APEX_WEB_SERVICE.g_request_headers (1).value := 'application/json; charset=utf-8';
        
        -- GET Response with Token
        v_response := apex_web_service.make_rest_request(
              p_url           => vURL,
              p_http_method   => 'GET'                      
        );
           
        --DBMS_OUTPUT.PUT_LINE ( 'v_response = ' || v_response );
        APEX_JSON.parse(v_response);
        v_TotalRegistros := APEX_JSON.get_count(p_path => '.');
        
        FOR i IN 1 .. v_TotalRegistros LOOP
            vDescargas.EXTEND;
            vDescargas(i).Id  := APEX_JSON.get_number(p_path => '[%d].Id', p0 => i);
            vDescargas(i).Name  := APEX_JSON.get_varchar2(p_path => '[%d].Name', p0 => i);
            vDescargas(i).FilePath := APEX_JSON.get_varchar2 (p_path => '[%d].Path', p0 => i);
            vDescargas(i).Extension  := APEX_JSON.get_varchar2(p_path => '[%d].Extension', p0 => i);
            --DBMS_OUTPUT.PUT_LINE ( 'vDescargas('||i||') = ' ||vDescargas(i).Id ||' '||vDescargas(i).FilePath);            
        END LOOP;        
        UTL_TCP.CLOSE_ALL_CONNECTIONS();
        RETURN vDescargas;
    END Descarga_Documentos_Firmados;

    FUNCTION ReadFileToBlob (in_Filename    IN     VARCHAR2,
                             in_Directory   IN     VARCHAR2,
                             out_Error         OUT VARCHAR2)
        RETURN BLOB IS
        v_lob           BLOB;
        v_BFile         BFILE;
        v_src_offset    NUMBER := 1;
        v_dest_offset   NUMBER := 1;
    BEGIN
        DBMS_LOB.createtemporary (v_lob, FALSE, DBMS_LOB.SESSION);

        v_BFile := BFILENAME (in_Directory, in_Filename);

        DBMS_LOB.fileOpen (v_BFile);
        DBMS_LOB.loadblobfromfile (dest_lob      => v_lob,
                                   src_bfile     => v_BFile,
                                   amount        => DBMS_LOB.getLength (v_BFile),
                                   dest_offset   => v_dest_offset,
                                   src_offset    => v_src_offset);

        DBMS_LOB.fileClose (v_BFile);
        RETURN v_lob;
    EXCEPTION WHEN OTHERS THEN
        DBMS_LOB.fileClose (v_BFile);
        out_Error := 'Error - ReadFileToBlob '||SQLERRM||' '||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
        RETURN v_lob;
    END ReadFileToBlob;
    

END PKG_API_PKM;