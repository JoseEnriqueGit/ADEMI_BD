CREATE OR REPLACE package body IA.pkg_api_pkm is
    function obtener_token(p_username in varchar2, p_password in varchar2)
        return varchar2 is
        vurl varchar2(300) := nvl(pa.param.parametro_x_empresa('1', 'URL_API_PKM', 'PA'), vurlbase) || 'fcwebapi/v2/authenticate/'; --'http://bma0039/fcwebapi/v2/authenticate/';
        vbody varchar2(4000);
        v_response clob;
    begin
      --  RETURN 'PRUEBA'; -- PRUEBA
        
        apex_web_service.g_request_headers.delete();
        apex_web_service.g_request_headers(1).name := 'Content-Type';
        apex_web_service.g_request_headers(1).value := 'application/json';

        vbody := '{"username": "' || p_username || '","password": "' || p_password || '"}'; -- '{ "username": "api", "password": "A123456789" }';
        
        DBMS_OUTPUT.PUT_LINE('pkg_api_pkm URL: '||vURL);         -- PRUEBA
        DBMS_OUTPUT.PUT_LINE('pkg_api_pkm Body:  '||vBody);      -- PRUEBA
        
        -- GET Response with Token
        v_response := apex_web_service.make_rest_request(p_url => vurl, p_http_method => 'POST', p_body => vbody);
        dbms_output.put_line('Respose:  ' || v_response);
        utl_tcp.close_all_connections();
        return replace(v_response, '"', '');
    exception
        when others then
            RETURN '';
            dbms_output.put_line(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE||DBMS_UTILITY.FORMAT_ERROR_STACK);
    end obtener_token;

    function obtener_aplicaciones(p_token in varchar2)
        return ia.pkm_aplicacion_list is
        vaplicacionobj ia.pkm_aplicacion_obj;
        vretorno ia.pkm_aplicacion_list := ia.pkm_aplicacion_list();
        vurl varchar2(300) := nvl(pa.param.parametro_x_empresa('1', 'URL_API_PKM', 'PA'), vurlbase) || 'fcwebapi/control/getapplications?token=' || p_token;
        v_response clob;

        cursor caplicacion(v_json clob) is
            select col001 name, col002 id, col003 description, col004 fields from table(apex_data_parser.parse(p_content => pa.pa_clob_to_blob(v_json), p_file_name => 'test.json'));

        type taplicacion is table of caplicacion%rowtype;

        vaplicacion taplicacion := taplicacion();
    begin
        apex_web_service.g_request_headers.delete();
        apex_web_service.g_request_headers(1).name := 'Content-Type';
        apex_web_service.g_request_headers(1).value := 'application/json';
        -- GET Response with Token
        v_response := apex_web_service.make_rest_request(p_url => vurl, p_http_method => 'GET');

        open caplicacion(v_response);

        loop
            fetch caplicacion bulk   collect into vaplicacion limit 5000;

            for i in 1 .. vaplicacion.count
            loop
                vaplicacionobj := ia.pkm_aplicacion_obj();
                vaplicacionobj.idaplicacion := vaplicacion(i).id;
                vaplicacionobj.nombre := vaplicacion(i).name;
                vaplicacionobj.descripcion := vaplicacion(i).description;
                vaplicacionobj.campos := vaplicacion(i).fields;
                vretorno.extend;
                vretorno(i) := vaplicacionobj;
            end loop;

            exit when caplicacion%notfound;
        end loop;

        close caplicacion;

        utl_tcp.close_all_connections();
        return vretorno;
    end obtener_aplicaciones;

    function obtener_campos(p_token in varchar2, p_id_aplicacion in number)
        return ia.pkm_campo_list is
        vretorno ia.pkm_campo_list := ia.pkm_campo_list();
        vcampoobj ia.pkm_campo_obj;
        vurl varchar2(4000) := vurlbase || 'fcwebapi/control/getapplicationfields?applicationid=' || p_id_aplicacion || '=' || p_token;
        v_response clob;

        vvalor ia.pkm_valor_obj;
        vvalores ia.pkm_valor_list := ia.pkm_valor_list();
        --l_paths     APEX_T_VARCHAR2 := APEX_T_VARCHAR2();
        v_totalcampos number := 0;
        v_totalvalores number := 0;
        l_exists boolean;
    begin
        apex_web_service.g_request_headers.delete();
        apex_web_service.g_request_headers(1).name := 'Content-Type';
        apex_web_service.g_request_headers(1).value := 'application/json';

        begin
            -- GET Response with Token
            v_response := apex_web_service.make_rest_request(p_url => vurl, p_http_method => 'GET');
        exception
            when others then
                raise_application_error(-20100, v_response || ' ' || sqlerrm);
        end;

        apex_json.parse(v_response);
        v_totalcampos := apex_json.get_count(p_path => '.');

        for i in 1 .. v_totalcampos
        loop
            vcampoobj := ia.pkm_campo_obj();
            vcampoobj.idcampo := apex_json.get_number(p_path => '[%d].Id', p0 => i);
            vcampoobj.nombre := apex_json.get_varchar2(p_path => '[%d].Name', p0 => i);
            vcampoobj.tipo := apex_json.get_number(p_path => '[%d].Type', p0 => i);
            vcampoobj.alias := apex_json.get_varchar2(p_path => '[%d].Alias', p0 => i);
            l_exists := apex_json.does_exist(p_path => '[%d].Values[1].Id', p0 => i);

            if l_exists then
                v_totalvalores := nvl(apex_json.get_count(p_path => '[%d].Values', p0 => i), 0);

                for v in 1 .. v_totalvalores
                loop
                    vvalor := ia.pkm_valor_obj();
                    vvalor.idvalor := apex_json.get_number(p_path => '[%d].Values[%d].Id', p0 => i, p1 => v);
                    vvalor.valor := apex_json.get_varchar2(p_path => '[%d].Values[%d].Value', p0 => i, p1 => v);
                    vvalor.valorexterno := apex_json.get_varchar2(p_path => '[%d].Values[%d].ExternalValue', p0 => i, p1 => v);
                    vvalores.extend;
                    vvalores(v) := vvalor;
                end loop;
            else
                v_totalvalores := 0;
            end if;

            vcampoobj.valores := vvalores;
            vretorno.extend;
            vretorno(i) := vcampoobj;
        end loop;

        utl_tcp.close_all_connections();
        return vretorno;
    end obtener_campos;
    
    procedure enviar_pkm(pToken             IN VARCHAR2,
                         pNoCredito         IN VARCHAR2,
                         pNoCreditoAnt      IN VARCHAR2,
                         pIdAplicacionPKM   IN NUMBER,
                         pTipoDocpKM        IN VARCHAR2,
                         pArchivos          IN IA.PKG_API_PKM.tListFiles,
                         pRespuesta         OUT VARCHAR2,
                         pError             OUT VARCHAR2
                         ) IS
    
        vFileData       BLOB;  
        vContentType    VARCHAR2(60);
        v_URL           VARCHAR2(4000);
        v_Body          BLOB;
        v_multipart     apex_web_service.t_multipart_parts;
        v_response      CLOB;
    BEGIN
        DBMS_OUTPUT.PUT_LINE ( 'vToken = ' || pToken );
        IF pToken IS NOT NULL THEN 
            BEGIN
                v_URL   :=  PA.PARAM.PARAMETRO_X_EMPRESA('1', 'URL_API_PKM', 'PA')||'fcwebapi/V2/apps/49/index/create?token='||pToken||'='||pIdAplicacionPKM||'='||pNoCredito||'='||pTipoDocpKM||CASE WHEN pNoCreditoAnt IS NOT NULL THEN '='||pNoCreditoAnt ELSE '' END ||'='||CASE WHEN pNoCreditoAnt IS NOT NULL THEN 'Represtamo' ELSE 'Normal' END;
                DBMS_OUTPUT.PUT_LINE ( 'v_URL = ' || v_URL );
                
               -- Set Headers
                APEX_WEB_SERVICE.g_request_headers.delete();
                APEX_WEB_SERVICE.g_request_headers (1).name  := 'Content-Type';
                APEX_WEB_SERVICE.g_request_headers (1).value := 'multipart/form-data';
                
                FOR i IN 1 .. pArchivos.COUNT LOOP                
                    vFileData := ReadFileToBlob (pArchivos(i).ARCHIVO, pArchivos(i).DIRECTORIO, pError);
                    DBMS_OUTPUT.PUT_LINE ( 'vFileData Size = ' || LENGTH(vFileData) );
                    
                    IF LENGTH(vFileData) > 0 THEN
                        BEGIN
                            SELECT m.MIMETYPE_NOMBRE
                              INTO vContentType
                              FROM PA.MIMETYPES_LISTADO m
                             WHERE m.EXTENSION = pArchivos(i).EXTENSION
                               AND ROWNUM = 1;
                        EXCEPTION WHEN NO_DATA_FOUND THEN
                            vContentType := 'application/pdf';
                        END;
                                            
                        -- Body
                        apex_web_service.append_to_multipart (
                           p_multipart    => v_multipart,
                           p_name         => 'Temp'||i,
                           p_filename     => pArchivos(i).ARCHIVO,
                           p_content_type => vContentType,
                           p_body_blob    => vFileData );
                    END IF;
                END LOOP;
                
                v_Body := apex_web_service.generate_request_body (p_multipart    => v_multipart );   
                
                -- POST Response
                v_response := apex_web_service.make_rest_request(
                      p_url           => v_Url,
                      p_http_method   => 'POST',
                      p_body_blob     => v_Body                      
                );
                   
                DBMS_OUTPUT.PUT_LINE ( 'v_response = ' || v_response );
                
                pRespuesta := NVL(v_response, 'Envio Satisfactorio.');
                
                
                UTL_TCP.CLOSE_ALL_CONNECTIONS();
            EXCEPTION WHEN OTHERS THEN
                pError := 'Error enviando a PKM Crediot='||pNoCredito||' Archivo='||pTipoDocPkm||' '||SQLERRM||' '||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE; 
                DBMS_OUTPUT.PUT_LINE(pError);
                UTL_TCP.CLOSE_ALL_CONNECTIONS();
                RAISE_APPLICATION_ERROR(-20100, pError);   
            END;
        ELSE
            pError := 'Error enviando a PKM Credito='||pNoCredito||' Archivo='||pTipoDocPkm||' - Token no autorizado.'; 
            DBMS_OUTPUT.PUT_LINE(pError);
            RAISE_APPLICATION_ERROR(-20100, pError);  
        END IF;
    END;

    function obtienepartereferencia(
        pcodigoreferencia in varchar2,
        pdelimitador     in varchar2,
        pnumeroparte     in number
    ) return varchar2
    is
        v_str   varchar2(32767);
        v_start pls_integer := 1;
        v_pos   pls_integer;
        v_i     pls_integer := 1;
        v_delim varchar2(1);
    begin
        if pcodigoreferencia is null or pdelimitador is null or pnumeroparte is null or pnumeroparte < 1 then
            return null;
        end if;

        v_delim := substr(pdelimitador, 1, 1);
        v_str := replace(pcodigoreferencia,'::',': :');

        loop
            v_pos := instr(v_str, v_delim, v_start);

            if v_i = pnumeroparte then
                if v_pos = 0 then
                    return substr(v_str, v_start);
                else
                    return substr(v_str, v_start, v_pos - v_start);
                end if;
            end if;

            exit when v_pos = 0;

            v_start := v_pos + 1;
            v_i := v_i + 1;
        end loop;

        return null;
    end obtienepartereferencia;
    
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
    END;
end pkg_api_pkm;
/

