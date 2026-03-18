CREATE OR REPLACE PACKAGE BODY PA.PKG_PERFILCLIENTE IS
--
-- IVAN BERGES 20/08/2025
-- REQ 42683 Detalles t¿cnicos para el proyecto actualizaci¿n de Datos del Perfil de Cliente
--
    FUNCTION F_VALIDA_CLIENTE(pc_cod_persona         IN  VARCHAR2,
                              pc_tipo_identificacion IN  VARCHAR2,
                              pc_identificacion      IN  VARCHAR2)
    RETURN NUMBER
    --
    -- Funci¿n para validar una persona existe en el core.
    --
    IS
        v_existe NUMBER := 0;
    BEGIN
        SELECT  COUNT(1)
        INTO    v_existe
        FROM    ID_PERSONAS
        WHERE   cod_persona         = pc_cod_persona
        AND     cod_tipo_id         = pc_tipo_identificacion
        AND     replace(num_id,'-') = pc_identificacion
        FETCH FIRST 1 ROWS ONLY;

        RETURN v_existe;
    END F_VALIDA_CLIENTE;

    FUNCTION F_VALIDA_TELEFONO(pc_numero_telefonico IN VARCHAR2)
    RETURN NUMBER
    --
    -- Funci¿n para validar que un n¿mero de tel¿fono sea correcto.
    -- Debe tener 10 caracteres num¿ricos m¿ximos y debe iniciar por 809 o 829 o 849 para ser v¿lido.
    --
    IS
        v_es_valido NUMBER := 0;
    BEGIN
        SELECT  COUNT(1)
        INTO    v_es_valido
        FROM    (SELECT REGEXP_REPLACE(pc_numero_telefonico, '[^[0-9]') telefono_limpio FROM DUAL)
        WHERE   LENGTH(telefono_limpio)      = 10
        AND     LENGTH(pc_numero_telefonico) = 10
        AND     SUBSTR(telefono_limpio,      0, 3) IN ('809', '829', '849')
        AND     SUBSTR(pc_numero_telefonico, 0, 3) IN ('809', '829', '849');


        RETURN v_es_valido;
    END F_VALIDA_TELEFONO;

    PROCEDURE P_VALIDA_ESTRUCTURA_JSON(pc_json           IN  CLOB,
                                       pc_codigo_mensaje OUT VARCHAR2,
                                       pc_mensaje        OUT VARCHAR2)
    IS
    BEGIN
        IF pc_json IS NULL THEN
            pc_codigo_mensaje  := '400';
            pc_mensaje := 'El documento JSON est¿ vac¿o.';            
        END IF;

        IF NOT pc_json IS JSON THEN
            pc_codigo_mensaje  := '400';
            pc_mensaje := 'El formato del documento JSON es inv¿lido.';
        END IF;

        IF pc_codigo_mensaje IS NULL THEN
            IF NOT JSON_EXISTS(pc_json, '$.clientePersonaFisica') THEN
                pc_codigo_mensaje  := '400';
                pc_mensaje := 'Campo requerido no existe o est¿ nulo: $.clientePersonaFisica';                
            END IF;
        END IF;

        IF pc_codigo_mensaje IS NULL THEN
            IF JSON_VALUE(pc_json, '$.clientePersonaFisica.idCliente') IS NULL THEN
                pc_codigo_mensaje  := '400';
                pc_mensaje := 'Campo requerido no existe o est¿ nulo: $.clientePersonaFisica.idCliente';                
            END IF;
        END IF;        

        IF pc_codigo_mensaje IS NULL THEN
            IF JSON_VALUE(pc_json, '$.clientePersonaFisica.esFisica') IS NULL THEN
                pc_codigo_mensaje  := '400';
                pc_mensaje := 'Campo requerido no existe o est¿ nulo: $.clientePersonaFisica.esFisica';                
            END IF;
        END IF;

        IF pc_codigo_mensaje IS NULL THEN
            IF JSON_VALUE(pc_json, '$.clientePersonaFisica.email') IS NULL THEN
                pc_codigo_mensaje  := '400';
                pc_mensaje := 'Campo requerido no existe o est¿ nulo: $.clientePersonaFisica.email';                
            END IF;
        END IF;        

        IF pc_codigo_mensaje IS NULL THEN
            FOR i IN (SELECT ROWNUM,
                             a.*
                      FROM   JSON_TABLE(pc_json,'$.clientePersonaFisica' 
                             COLUMNS(NESTED PATH '$.identificaciones[*]' COLUMNS(tipo_identificacion      VARCHAR2(4000) PATH '$.tipoIdentificacion',
                                                                                 numero_identificacion    VARCHAR2(4000) PATH '$.numeroIdentificacion',
                                                                                 pais_iso3_identificacion VARCHAR2(4000) PATH '$.paisIso3Identificacion'))) a) 
            LOOP
                EXIT WHEN pc_codigo_mensaje IS NOT NULL;

                IF i.tipo_identificacion IS NULL THEN
                    pc_codigo_mensaje  := '400';
                    pc_mensaje         := 'Campo requerido no existe o est¿ nulo: $.clientePersonaFisica.identificaciones['||i.ROWNUM||'].tipoIdentificacion';                
                END IF;

                IF i.numero_identificacion IS NULL THEN
                    pc_codigo_mensaje  := '400';
                    pc_mensaje         := 'Campo requerido no existe o est¿ nulo: $.clientePersonaFisica.identificaciones['||i.ROWNUM||'].numeroIdentificacion';                
                END IF;

                IF i.pais_iso3_identificacion IS NULL THEN
                    pc_codigo_mensaje  := '400';
                    pc_mensaje         := 'Campo requerido no existe o est¿ nulo: $.clientePersonaFisica.identificaciones['||i.ROWNUM||'].paisIso3Identificacion';                
                END IF;                
            END LOOP;
        END IF;

        IF pc_codigo_mensaje IS NULL THEN
            FOR i IN (SELECT ROWNUM,
                             a.*
                      FROM   JSON_TABLE(pc_json,'$.clientePersonaFisica' 
                             COLUMNS(NESTED PATH '$.telefonos[*]' COLUMNS(por_defecto        VARCHAR2(4000) PATH '$.porDefecto',
                                                                          tipo_telefono      VARCHAR2(4000) PATH '$.tipoTelefono',
                                                                          ubicacion_telefono VARCHAR2(4000) PATH '$.ubicacionTelefono',
                                                                          numero_telefono    VARCHAR2(4000) PATH '$.numeroTelefono',
                                                                          pais_iso3_telefono VARCHAR2(4000) PATH '$.paisIso3Telefono'))) a) 
            LOOP
                EXIT WHEN pc_codigo_mensaje IS NOT NULL;

                IF i.por_defecto IS NULL THEN
                    pc_codigo_mensaje  := '400';
                    pc_mensaje         := 'Campo requerido no existe o est¿ nulo: $.clientePersonaFisica.telefonos['||i.ROWNUM||'].porDefecto';                
                END IF;

                IF i.tipo_telefono IS NULL THEN
                    pc_codigo_mensaje  := '400';
                    pc_mensaje         := 'Campo requerido no existe o est¿ nulo: $.clientePersonaFisica.telefonos['||i.ROWNUM||'].tipoTelefono';                
                END IF;

                IF i.ubicacion_telefono IS NULL THEN
                    pc_codigo_mensaje  := '400';
                    pc_mensaje         := 'Campo requerido no existe o est¿ nulo: $.clientePersonaFisica.telefonos['||i.ROWNUM||'].ubicacionTelefono';                
                END IF;       

                IF i.numero_telefono IS NULL THEN
                    pc_codigo_mensaje  := '400';
                    pc_mensaje         := 'Campo requerido no existe o est¿ nulo: $.clientePersonaFisica.telefonos['||i.ROWNUM||'].numeroTelefono';                
                END IF;  

                IF i.pais_iso3_telefono IS NULL THEN
                    pc_codigo_mensaje  := '400';
                    pc_mensaje         := 'Campo requerido no existe o est¿ nulo: $.clientePersonaFisica.telefonos['||i.ROWNUM||'].paisIso3Telefono';                
                END IF;                                           
            END LOOP;
        END IF;

        IF pc_codigo_mensaje IS NULL THEN
            IF NOT JSON_EXISTS(pc_json, '$.clientePersonaFisica.canal') THEN
                pc_codigo_mensaje  := '400';
                pc_mensaje := 'Campo requerido no existe o est¿ nulo: $.clientePersonaFisica.canal';                
            END IF;
        END IF; 

        IF pc_codigo_mensaje IS NULL THEN
            IF JSON_VALUE(pc_json, '$.clientePersonaFisica.canal.idCanal') IS NULL THEN
                pc_codigo_mensaje  := '400';
                pc_mensaje := 'Campo requerido no existe o est¿ nulo: $.clientePersonaFisica.canal.idCanal';                
            END IF;
        END IF;   

        IF pc_codigo_mensaje IS NULL THEN
            IF JSON_VALUE(pc_json, '$.clientePersonaFisica.canal.nombreDispositivo') IS NULL THEN
                pc_codigo_mensaje  := '400';
                pc_mensaje := 'Campo requerido no existe o est¿ nulo: $.clientePersonaFisica.canal.nombreDispositivo';                
            END IF;
        END IF;                

        IF pc_codigo_mensaje IS NULL THEN
            pc_codigo_mensaje := '200';
            pc_mensaje        := 'Documento JSON v¿lido.';      
        END IF;
    END P_VALIDA_ESTRUCTURA_JSON;    

    PROCEDURE P_OBTIENE_DATOS_PERSONA_JSON(pc_json           IN  CLOB,
                                           pr_datos_persona  OUT RECORD_DATOS_PERSONA,
                                           pc_codigo_mensaje OUT VARCHAR2,
                                           pc_mensaje        OUT VARCHAR2)                                    
    IS
        v_identificacion            RECORD_IDENTIFICACION;
        v_telefono                  RECORD_TELEFONO;
        v_lista_identificaciones    LISTA_RECORD_IDENTIFICACIONES;
        v_lista_telefonos           LISTA_RECORD_TELEFONOS;
        v_total_telefonos_default   NUMBER := 0;
    BEGIN
        P_VALIDA_ESTRUCTURA_JSON(pc_json,
                                 pc_codigo_mensaje,
                                 pc_mensaje);

        IF pc_codigo_mensaje != '200' THEN
            RETURN;
        END IF;

        IF PA.VALIDA_EMAIL(JSON_VALUE(pc_json, '$.clientePersonaFisica.email')) = FALSE THEN
            pc_codigo_mensaje   := '400';
            pc_mensaje          := 'El campo email no tiene el formato correcto.';
            RETURN;
        END IF;

        pr_datos_persona.id_cliente          := JSON_VALUE(pc_json, '$.clientePersonaFisica.idCliente'          );
        pr_datos_persona.es_fisica           := JSON_VALUE(pc_json, '$.clientePersonaFisica.esFisica'           );
        pr_datos_persona.email               := JSON_VALUE(pc_json, '$.clientePersonaFisica.email'              );
        pr_datos_persona.id_canal            := JSON_VALUE(pc_json, '$.clientePersonaFisica.canal.idCanal'      );
        pr_datos_persona.nombre_dispositivo  := JSON_VALUE(pc_json, '$.clientePersonaFisica.nombreDispositivo'  );

        v_lista_identificaciones := LISTA_RECORD_IDENTIFICACIONES();

        FOR i IN (SELECT ROWNUM,
                         a.*
                  FROM   JSON_TABLE(pc_json, '$.clientePersonaFisica' 
                         COLUMNS(NESTED PATH '$.identificaciones[*]' COLUMNS(tipo_identificacion      VARCHAR2(4000) PATH '$.tipoIdentificacion',
                                                                             numero_identificacion    VARCHAR2(4000) PATH '$.numeroIdentificacion',
                                                                             pais_iso3_identificacion VARCHAR2(4000) PATH '$.paisIso3Identificacion'))) a)
        LOOP
            IF F_VALIDA_CLIENTE(pr_datos_persona.id_cliente,
                                i.tipo_identificacion,
                                i.numero_identificacion) = 0
            THEN
                pc_codigo_mensaje   := '404';
                pc_mensaje          := 'No existen registros con el idCliente ['||pr_datos_persona.id_cliente||'] y el numeroIdentificacion ['||i.numero_identificacion||'] de tipoIdentificacion ['||i.tipo_identificacion||']';

                RETURN;
            END IF;

            v_identificacion                            := NULL;
            v_identificacion.tipo_identificacion        := i.tipo_identificacion;
            v_identificacion.numero_identificacion      := i.numero_identificacion;
            v_identificacion.pais_iso3_identificacion   := i.pais_iso3_identificacion;

            v_lista_identificaciones.EXTEND;
            v_lista_identificaciones(v_lista_identificaciones.LAST) := v_identificacion;
        END LOOP;

        v_lista_telefonos := LISTA_RECORD_TELEFONOS();

        FOR j IN (SELECT ROWNUM,
                         a.*
                  FROM   JSON_TABLE(pc_json,'$.clientePersonaFisica' 
                         COLUMNS(NESTED PATH '$.telefonos[*]' COLUMNS(por_defecto        VARCHAR2(4000) PATH '$.porDefecto',
                                                                      tipo_telefono      VARCHAR2(4000) PATH '$.tipoTelefono',
                                                                      ubicacion_telefono VARCHAR2(4000) PATH '$.ubicacionTelefono',
                                                                      numero_telefono    VARCHAR2(4000) PATH '$.numeroTelefono',
                                                                      pais_iso3_telefono VARCHAR2(4000) PATH '$.paisIso3Telefono'))) a)
        LOOP
            IF F_VALIDA_TELEFONO(j.numero_telefono) = 0 THEN
                pc_codigo_mensaje   := '400';
                pc_mensaje          := 'El tel¿fono proporcionado ['||j.numero_telefono||'] no tiene el formato correcto: 0000000000';

                RETURN;
            END IF;

            IF j.por_defecto = 'S' THEN
                v_total_telefonos_default := v_total_telefonos_default + 1;
            END IF;

            v_telefono := NULL;
            v_telefono.por_defecto          := j.por_defecto;
            v_telefono.tipo_telefono        := j.tipo_telefono;
            v_telefono.ubicacion_telefono   := j.ubicacion_telefono;
            v_telefono.numero_telefono      := j.numero_telefono;
            v_telefono.pais_iso3_telefono   := j.pais_iso3_telefono;

            v_lista_telefonos.EXTEND;
            v_lista_telefonos(v_lista_telefonos.LAST) := v_telefono;
        END LOOP;

        CASE
            WHEN v_total_telefonos_default > 1 THEN
                pc_codigo_mensaje   := '400';
                pc_mensaje          := 'Existen m¿s de un n¿mero telef¿nico por defecto.';

                RETURN;
            WHEN v_total_telefonos_default = 0 THEN
                pc_codigo_mensaje   := '400';
                pc_mensaje          := 'Debe existir al menos un n¿mero telef¿nico por defecto.';

                RETURN;
            ELSE
                NULL;
        END CASE;   

        pr_datos_persona.identificaciones   := v_lista_identificaciones;
        pr_datos_persona.telefonos          := v_lista_telefonos;
    END P_OBTIENE_DATOS_PERSONA_JSON;

    PROCEDURE P_PROCESA_AUDIT_PERFILCLIENTE(pc_json           IN  CLOB,
                                            pc_codigo_mensaje OUT VARCHAR2,
                                            pc_mensaje        OUT VARCHAR2)
    IS
        pr_datos_persona RECORD_DATOS_PERSONA;
        vnota pa.tel_personas.nota%type;
        TYPE RECORD_DATOS_A_PROCESAR IS RECORD
        (
            email_nuevo         VARCHAR2(80),
            email_anterior      VARCHAR2(80),
            telefono_nuevo      VARCHAR2(10),
            telefono_anterior   VARCHAR2(10)
        );

        v_datos_a_procesar RECORD_DATOS_A_PROCESAR;

        v_telefono_nuevo_default RECORD_TELEFONO;

        v_tipo_identificacion   VARCHAR2(4000);
        v_identificacion        VARCHAR2(4000);
        v_contador              NUMBER := 0;
        v_cambios_realizados    NUMBER := 0;
        v_tel_sms_anterior      PA.PERSONAS_X_NOTIFICACION.num_tel%type;
        v_tel_sms_nuevo         PA.PERSONAS_X_NOTIFICACION.num_tel%type;
    BEGIN
        P_OBTIENE_DATOS_PERSONA_JSON(pc_json,
                                     pr_datos_persona,
                                     pc_codigo_mensaje,
                                     pc_mensaje);

        IF pc_codigo_mensaje != '200' THEN
            RETURN;
        ELSE
            pc_codigo_mensaje   := NULL;
            pc_mensaje          := NULL;
        END IF;

        --------
        -------- L¿GICA PARA DETERMINAR CORREO Y TEL¿FONO A INSERTAR O ACTUALIZAR
        --------              

        --
        -- Correo
        --
        BEGIN
            SELECT nombre_canal
            INTO vnota
            FROM PA.CANAL_APLICACION
            WHERE cod_sistema='CC' AND
            cod_canal=pr_datos_persona.id_canal;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    vnota:='';
        END;
        FOR i IN (SELECT email_usuario
                  FROM   PERSONAS_FISICAS 
                  WHERE  cod_per_fisica = pr_datos_persona.id_cliente) 
        LOOP
            IF NVL(i.email_usuario, 'X') != pr_datos_persona.email THEN
                v_datos_a_procesar.email_nuevo      := pr_datos_persona.email;
                v_datos_a_procesar.email_anterior   := i.email_usuario;
            ELSE
                v_datos_a_procesar.email_nuevo      := NULL;
                v_datos_a_procesar.email_anterior   := NULL;        
            END IF;

            EXIT;
        END LOOP;

        --
        -- Tel¿fono
        --

        -- Del documento JSON obtiene el telefono DEFAULT.
        FOR j IN pr_datos_persona.telefonos.FIRST..pr_datos_persona.telefonos.LAST LOOP
            IF pr_datos_persona.telefonos(j).por_defecto = 'S' THEN
                v_telefono_nuevo_default := pr_datos_persona.telefonos(j);
                EXIT;
            END IF;
        END LOOP;

        -- Valida si el tel¿fono DEFAULT que proviene del JSON ya est¿ registrado en el core
        -- y si est¿ configurado como DEFAULT.
        FOR k IN (SELECT cod_area||num_telefono telefono
                  FROM   TEL_PERSONAS 
                  WHERE  cod_persona           = pr_datos_persona.id_cliente 
                  AND    cod_area              = SUBSTR(v_telefono_nuevo_default.numero_telefono, 1, 3)
                  AND    num_telefono          = SUBSTR(v_telefono_nuevo_default.numero_telefono, 4)
                  AND    NVL(es_default, 'X') != 'S') 
        LOOP
            v_datos_a_procesar.telefono_nuevo    := NULL;
            v_datos_a_procesar.telefono_anterior := v_telefono_nuevo_default.numero_telefono;
            EXIT;
        END LOOP;

        -- Si el tel¿fono proveniente del JSON no existe en el core entonces
        -- procede a ser el nuevo tel¿fono a insertar.
        IF v_datos_a_procesar.telefono_anterior IS NULL THEN
            SELECT  COUNT(1)
            INTO    v_contador
            FROM    TEL_PERSONAS 
            WHERE   cod_persona  = pr_datos_persona.id_cliente 
            AND     cod_area     = SUBSTR(v_telefono_nuevo_default.numero_telefono, 1, 3)
            AND     num_telefono = SUBSTR(v_telefono_nuevo_default.numero_telefono, 4);

            IF v_contador = 0 THEN
                v_datos_a_procesar.telefono_nuevo := v_telefono_nuevo_default.numero_telefono;

                -- Obtiene el ¿ltimo tel¿fono que estaba configurado como DEFAULT en el core.
                FOR z IN (SELECT cod_area||num_telefono telefono 
                          FROM   TEL_PERSONAS 
                          WHERE  cod_persona  = pr_datos_persona.id_cliente
                          AND    es_default   = 'S') 
                LOOP
                    v_datos_a_procesar.telefono_anterior := SUBSTR(z.telefono, 1, 10);
                    EXIT;
                END LOOP;    
            END IF;
        END IF;

        --------
        -------- DML (INSERT y UPDATE)
        --------  

        --
        -- Actualiza campo email_usuario en PERSONAS_FISICAS
        --
        IF v_datos_a_procesar.email_nuevo IS NOT NULL THEN
            UPDATE  PERSONAS_FISICAS 
            SET     email_usuario  = v_datos_a_procesar.email_nuevo 
            WHERE   cod_per_fisica = pr_datos_persona.id_cliente;

            pc_mensaje           := 'Correo actualizado. ';
            v_cambios_realizados := 1;
        END IF;

        --
        -- Actualiza o Inserta telefono en TEL_PERSONAS
        --

        CASE
            ------------------------------------------------------------------------------------------------------------
            WHEN (v_datos_a_procesar.telefono_nuevo IS NULL) AND (v_datos_a_procesar.telefono_anterior IS NOT NULL) THEN
            ------------------------------------------------------------------------------------------------------------
                BEGIN
                UPDATE  TEL_PERSONAS
                SET     es_default       = 'N',
                        notif_digital    = 'N'
                WHERE   cod_persona  = pr_datos_persona.id_cliente;
                END;
                BEGIN
                UPDATE  TEL_PERSONAS
                SET     es_default   = 'S',
                        notif_digital= 'S'
                WHERE   cod_persona  = pr_datos_persona.id_cliente
                AND     cod_area     = SUBSTR(v_datos_a_procesar.telefono_anterior, 1, 3)
                AND     num_telefono = SUBSTR(v_datos_a_procesar.telefono_anterior, 4   );
                END;
                IF v_datos_a_procesar.telefono_anterior IS NOT NULL THEN
                    BEGIN
                        SELECT NUM_TEL
                        INTO v_tel_sms_anterior
                        FROM PA.PERSONAS_X_NOTIFICACION
                        WHERE CODIGO_CLIENTE= pr_datos_persona.id_cliente
                        AND ROWNUM=1;
                    EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        v_tel_sms_anterior:=NULL;
                    END;
                    IF v_tel_sms_anterior IS NOT NULL THEN
                    BEGIN
                        UPDATE PA.PERSONAS_X_NOTIFICACION
                        SET NUM_TEL=v_datos_a_procesar.telefono_anterior
                        WHERE CODIGO_CLIENTE=pr_datos_persona.id_cliente    AND 
                              NUM_TEL!=v_datos_a_procesar.telefono_anterior;
                    END;
                    END IF;
                END IF;
                pc_mensaje           := pc_mensaje||'Tel¿fono por defecto actualizado. ';
                v_cambios_realizados := nvl(v_cambios_realizados,0)+2;
            -------------------------------------------------------
            WHEN v_datos_a_procesar.telefono_nuevo IS NOT NULL THEN
            -------------------------------------------------------
            BEGIN
                UPDATE  TEL_PERSONAS
                SET     es_default       = 'N',
                        notif_digital    = 'N'
                WHERE   cod_persona  = pr_datos_persona.id_cliente;
             END;
             BEGIN            
                INSERT INTO TEL_PERSONAS(COD_PERSONA,
                                         COD_AREA,
                                         NUM_TELEFONO,
                                         TIP_TELEFONO,
                                         TEL_UBICACION,
                                         EXTENSION,
                                         NOTA,
                                         ES_DEFAULT,
                                         NOTIF_DIGITAL,
                                         POSICION,
                                         COD_DIRECCION,
                                         COD_PAIS)

                VALUES                  (pr_datos_persona.id_cliente,
                                         SUBSTR(v_datos_a_procesar.telefono_nuevo, 1, 3),
                                         SUBSTR(v_datos_a_procesar.telefono_nuevo, 4   ),
                                         v_telefono_nuevo_default.tipo_telefono,
                                         v_telefono_nuevo_default.ubicacion_telefono,
                                         NULL,
                                         vnota,
                                         'S',
                                         'S',
                                         NULL,
                                         NULL,
                                         v_telefono_nuevo_default.pais_iso3_telefono);       

                pc_mensaje           := pc_mensaje||'Tel¿fono insertado. ';  
                v_cambios_realizados := nvl(v_cambios_realizados,0)+2;

               END;    
               BEGIN
                    SELECT NUM_TEL
                    INTO v_tel_sms_anterior
                    FROM PA.PERSONAS_X_NOTIFICACION
                    WHERE CODIGO_CLIENTE= pr_datos_persona.id_cliente
                    AND ROWNUM=1;
                    EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                    v_tel_sms_anterior:=NULL;
                    END;
                    IF v_tel_sms_anterior IS NOT NULL THEN
                        BEGIN
                            UPDATE PA.PERSONAS_X_NOTIFICACION
                            SET NUM_TEL=v_datos_a_procesar.telefono_nuevo
                            WHERE CODIGO_CLIENTE=pr_datos_persona.id_cliente;
                        END;
                     END IF;
            ----
            ELSE
            ----
                v_contador := 0;

                FOR d IN (SELECT cod_persona, 
                                 cod_area, 
                                 num_telefono
                         FROM    TEL_PERSONAS 
                         WHERE   cod_persona           = pr_datos_persona.id_cliente
                         AND     cod_area             != SUBSTR(v_telefono_nuevo_default.numero_telefono, 1, 3)
                         AND     num_telefono         != SUBSTR(v_telefono_nuevo_default.numero_telefono   , 4)
                         AND     NVL(es_default, 'X') != 'N') 
                LOOP
                    v_contador := 1;

                    UPDATE  TEL_PERSONAS
                    SET     es_default      = 'N',
                            notif_digital   = 'N',
                            nota            = vnota
                    WHERE   cod_persona  = pr_datos_persona.id_cliente
                    AND     cod_area    != d.cod_area
                    AND     num_telefono!= d.num_telefono;
                END LOOP;

                IF v_contador = 1 THEN
                    pc_mensaje           := pc_mensaje||'Tel¿fono por defecto actualizado9. ';
                    v_cambios_realizados := v_cambios_realizados+2;
                END IF;
                BEGIN
                    SELECT NUM_TEL
                    INTO v_tel_sms_anterior
                    FROM PA.PERSONAS_X_NOTIFICACION
                    WHERE CODIGO_CLIENTE= pr_datos_persona.id_cliente
                    AND ROWNUM=1;
                    EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                    v_tel_sms_anterior:=NULL;
                END;

                IF v_tel_sms_anterior IS NOT NULL THEN
                        BEGIN
                            UPDATE PA.PERSONAS_X_NOTIFICACION
                            SET NUM_TEL=v_datos_a_procesar.telefono_nuevo
                            WHERE CODIGO_CLIENTE=pr_datos_persona.id_cliente;
                        END;
                END IF;
        END CASE;

        v_tipo_identificacion := pr_datos_persona.identificaciones(pr_datos_persona.identificaciones.COUNT).tipo_identificacion;
        v_identificacion  := pr_datos_persona.identificaciones(pr_datos_persona.identificaciones.COUNT).numero_identificacion;


        INSERT INTO AUDIT_PERFILCLIENTE(ID_CLIENTE,
                                        ID_CANAL,
                                        ID_ACCIONPERFIL,
                                        NUMERO_IDENTIFICACION,
                                        TIPO_IDENTIFICACION,
                                        EMAIL_NUEVO,
                                        EMAIL_ANTERIOR,
                                        TEL_NUEVO,
                                        TEL_ANTERIOR,
                                        TEL_SMS_ANTERIOR,
                                        TEL_SMS_NUEVO,
                                        JSON_INPUT,
                                        ESTADO_REGISTRO)

        VALUES                          (pr_datos_persona.id_cliente,                               --ID_CLIENTE
                                         pr_datos_persona.id_canal,                                 --ID_CANAL
                                         v_cambios_realizados,                                      --ACCION EJECUTADA POR EL CLIENTE O TIPO DE CAMBIO REALIZADOS                                                         
                                         v_identificacion,                                          --NUMEOR DE IDENTIFICACION.
                                         v_tipo_identificacion,                                     --TIPO_IDENTIFICACION
                                         v_datos_a_procesar.email_nuevo,                            --EMAIL_NUEVO
                                         v_datos_a_procesar.email_anterior,                         --EMAIL_ANTERIOR
                                         v_datos_a_procesar.telefono_nuevo,                         --TEL_NUEVO
                                         v_datos_a_procesar.telefono_anterior,                      --TEL_ANTERIOR
                                         v_tel_sms_anterior,                                        --TELEFONO PARA ENVIO DE SMS ANTERIOR CONSUMO DE TC
                                         v_datos_a_procesar.telefono_nuevo,                         --TELEFONO NUEVO PARA ENVIO DE SMS CONSUMO DE TC
                                         pc_json,                                                   --JSON_INPUT
                                         CASE  WHEN v_cambios_realizados > 1 THEN 'P' ELSE 'S' END);   --ESTADO_REGISTRO

        COMMIT;

        pc_codigo_mensaje := '200';
        pc_mensaje        := NVL(pc_mensaje, 'No existen cambios por procesar.');
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            pc_codigo_mensaje := '500';
            pc_mensaje        := 'Error al procesar datos del perfil del cliente: '||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE||DBMS_UTILITY.FORMAT_ERROR_STACK;
    END P_PROCESA_AUDIT_PERFILCLIENTE;
END PKG_PERFILCLIENTE;

/