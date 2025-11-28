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
        
        -- Estas variables ya no son las principales, pero las dejamos por si acaso
        vLinuxPath      VARCHAR2(4000) := TRIM(PA.PARAM.PARAMETRO_X_EMPRESA('1', 'RUTALINUX_IMG_PKM', 'PA'));
        -- vBasePath       VARCHAR2(300)  := TRIM(PA.PARAM.PARAMETRO_X_EMPRESA('1', 'RUTABASE_IMG_PKM', 'PA')); -- YA NO SE USA
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
        --DBMS_OUTPUT.PUT_LINE ( 'vEmail = ' || vEmail );
        IF vEmail IS NOT NULL THEN      
            -- Inserta el Registro de la solicitud
            Generar(pCodigo_Empresa, pNo_Credito, 'P', pResultado); 
            --DBMS_OUTPUT.PUT_LINE ( 'SOLICITUD_DOC_FIRMADOS Generar pResultado = ' || pResultado );        
            
            -- Usuario y password de PKM
            vUsuarioPkm := PA.PARAM.PARAMETRO_X_EMPRESA(pCodigo_Empresa, 'USUARIO_API_PKM', 'IA');
            vPasswordPkm := PA.PARAM.PARAMETRO_X_EMPRESA(pCodigo_Empresa, 'PASSWORD_API_PKM', 'IA');  
            /*DBMS_OUTPUT.PUT_LINE ( 'vUsuarioPkm = ' || vUsuarioPkm );
            DBMS_OUTPUT.PUT_LINE ( 'vPasswordPkm = ' || vPasswordPkm );*/
            
            -- Obtiene el Token      
            vToken := PA.PKG_API_PKM.OBTENER_TOKEN(vUsuarioPkm, vPasswordPkm);
            DBMS_OUTPUT.PUT_LINE ( 'vToken = ' || vToken );
            
            -- Obtiene los ID de los documentos firmados        
            vDocumentos := PA.PKG_API_PKM.Obtiene_Documentos_Firmados(pNo_Credito, TRUE, vToken);      
            DBMS_OUTPUT.PUT_LINE ( 'Obtiene_id Documentos_Firmados = ' || vDocumentos.COUNT );  
            IF vDocumentos.COUNT > 0 THEN
                -- Actualiza la solicitud a W = WebServices
                Actualizar(pCodigo_Empresa, pNo_Credito, 'W', pResultado);  
                --DBMS_OUTPUT.PUT_LINE ( 'SOLICITUD_DOC_FIRMADOS Actualizar a W pResultado = ' || pResultado );    
                FOR i IN 1 .. vDocumentos.COUNT LOOP
                    -- Descarga los documentos firmados
                    vDescargas.DELETE;
                    vDescargas := PA.PKG_API_PKM.Descarga_Documentos_Firmados(vDocumentos(i), vToken);
                    DBMS_OUTPUT.PUT_LINE ( 'vDocumentos('||i||') = ' || vDocumentos(i)  ||' vDescargas.COUNT = ' || vDescargas.COUNT );
                    IF vDescargas.COUNT > 0 THEN
                        -- Actualiza la solicitud a D = Download
                        Actualizar(pCodigo_Empresa, pNo_Credito, 'D', pResultado);
                        --DBMS_OUTPUT.PUT_LINE ( 'SOLICITUD_DOC_FIRMADOS Actualizar a D pResultado = ' || pResultado );    
                        --DBMS_OUTPUT.PUT_LINE ( 'Desde PKM Documentos Descargados = ' || vDescargas.COUNT );
                                      
                        FOR d IN 1 .. vDescargas.COUNT LOOP  
                          
                            -- Asigna Directory lógico
                            vDescargas(d).DirectoryName := vDirectory; 
                            
                            -- =========================================================================
                            -- INICIO NUEVA LÓGICA: TABLA DE MAPEO
                            -- =========================================================================
                            DECLARE
                                vRutaMountDB  VARCHAR2(200);
                                vKeyWindowDB  VARCHAR2(100);
                            BEGIN
                                -- 1. Buscamos en la tabla de configuración si la ruta actual contiene alguna KEY conocida (Imagenes_7, 8, etc)
                                BEGIN
                                    SELECT PATH_LINUX, KEY_WINDOWS
                                      INTO vRutaMountDB, vKeyWindowDB
                                      FROM PR.CONFIG_RUTAS_PKM
                                     WHERE INSTR(vDescargas(d).FilePath, KEY_WINDOWS) > 0
                                     FETCH FIRST 1 ROWS ONLY;
                                EXCEPTION WHEN NO_DATA_FOUND THEN
                                    -- Fallback: Si no encuentra coincidencia, usamos un default seguro (Imagenes 8)
                                    vRutaMountDB := '/mnt/pkm_Imagenes8';
                                    vKeyWindowDB := 'Imagenes_8';
                                END;

                                -- 2. Reconstruir el Directory de acuerdo a la ruta del archivo y la tabla
                                -- Convertimos slashes
                                vPathConv := REPLACE(vDescargas(d).FilePath, '\', '/');
                                
                                -- Cortamos la ruta usando la KEY encontrada en la DB
                                -- Esto extrae todo lo que está DESPUES de 'Imagenes_X'
                                vPathConv := SUBSTR(vPathConv, INSTR(vPathConv, vKeyWindowDB) + LENGTH(vKeyWindowDB));
                                
                                -- Concatenamos el Mount Point de Linux + la ruta relativa
                                vPathConv := vRutaMountDB || vPathConv;
                                
                                -- Quitamos el nombre del archivo para dejar solo el path del directorio
                                vPathConv := REPLACE(vPathConv, vDescargas(d).Name, '');
                                
                                -- Limpieza de dobles slashes si quedaron
                                vPathConv := REPLACE(vPathConv, '//', '/');
                                
                            END;
                            -- =========================================================================
                            -- FIN NUEVA LÓGICA
                            -- =========================================================================

                            BEGIN
                                vSQLDir := 'CREATE OR REPLACE DIRECTORY ' || vDirectory || ' AS ''' || vPathConv|| '''';            
                                EXECUTE IMMEDIATE vSQLDir;
                            EXCEPTION WHEN OTHERS THEN
                                DBMS_OUTPUT.PUT_LINE ('Error Recreando el directorio '||vDirectory||' con la ruta '||vPathConv);
                            END;
                            
                            -- Inserta los documentos firmados encontrados
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
                    
                -- DBMS_OUTPUT.PUT_LINE ( 'vDescarga('||vIndex||') = ' || vDescarga.Name||' '||vDescarga.Extension||' '||vDescarga.FilePath ||' '||vDescarga.DirectoryName);
            END LOOP;    
            
            -- Descargar los documentos de Seguros (Comentado en el original)
                   
            DBMS_OUTPUT.PUT_LINE ( 'Total de Documentos = ' || vDescargas.COUNT );
            IF vDescargas.COUNT > 0 THEN
                
                -- Enviar Email al cliente de los documentos firmados
                Email_Docs_Firmados(LOWER(vEmail), vDescargas, pResultado);    
                      
                -- Actualiza la solicitud a S = Send to Email
                Actualizar(pCodigo_Empresa, pNo_Credito, 'S', pResultado);
                --DBMS_OUTPUT.PUT_LINE ( 'SOLICITUD_DOC_FIRMADOS Actualizar a S pResultado = ' || pResultado );  
                
                -- OJO: AQUÍ TAMBIÉN SE DEBERÍA USAR LA VARIABLE CALCULADA, 
                -- PERO COMO ESTO ESTA FUERA DEL LOOP, USAREMOS EL ÚLTIMO PATH CALCULADO O EL DEFAULT LINUXPATH
                -- SI ESTE BLOQUE ES CRÍTICO, DEBERÍA MOVERSE O RECALCULARSE. 
                -- POR AHORA SE MANTIENE EL ORIGINAL PERO APUNTANDO A vLinuxPath SI EXISTE.
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