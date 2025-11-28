PROCEDURE P_Notificar_Reenvio_Link(pIdReprestamo  IN      NUMBER,
                                   pRespuesta     IN OUT  VARCHAR2) IS
    
    vNombreCliente  VARCHAR2(400);
    vFechaProceso   DATE;
    
    CURSOR cCanal(pIdReprestamo IN NUMBER) IS
        SELECT c.CANAL, c.VALOR, S.NOMBRES, S.APELLIDOS 
          FROM PR.PR_CANALES_REPRESTAMO c
          JOIN PR.PR_SOLICITUD_REPRESTAMO s ON S.CODIGO_EMPRESA = C.CODIGO_EMPRESA 
                                           AND S.ID_REPRESTAMO = C.ID_REPRESTAMO
         WHERE C.CODIGO_EMPRESA = PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
           AND C.ID_REPRESTAMO = pIdReprestamo; 
           
    TYPE tCanal IS TABLE OF cCanal%ROWTYPE;
    vCanal tCanal := tCanal(); 
    
    vMensaje      VARCHAR2(4000); 
    vSubject      VARCHAR2(4000);
    vSMS          VARCHAR2(10); 
    vEMAIL        VARCHAR2(10);    
    vTipoCanal    VARCHAR2(5) := 'SMS';                                   

BEGIN
    --
    BEGIN
        SELECT PF.PRIMER_NOMBRE, R.FECHA_PROCESO
          INTO vNombreCliente, vFechaProceso
          FROM PR.PR_REPRESTAMOS r
          JOIN PA.PERSONAS_FISICAS pf ON R.CODIGO_CLIENTE = PF.COD_PER_FISICA
         WHERE r.ID_REPRESTAMO = pIdReprestamo;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        vNombreCliente := NULL;
        pRespuesta := 'Error: No se encontraron datos para el préstamo ' || pIdReprestamo;
        RETURN;
    END;

    vSMS   := NVL(f_obt_parametro_Represtamo('CANAL_SMS'), '1');
    vEMAIL := NVL(f_obt_parametro_Represtamo('CANAL_EMAIL'), '2');

    OPEN cCanal(pIdReprestamo);
    LOOP
        FETCH cCanal BULK COLLECT INTO vCanal LIMIT 500;        
        FOR x IN 1 .. vCanal.COUNT LOOP
            
            vMensaje := PR_PKG_REPRESTAMOS.F_Obt_Body_Mensaje(
                            pNombres => vNombreCliente, 
                            pFecha   => vFechaProceso, 
                            pCanal   => vCanal(x).CANAL
                        );

            IF vCanal(x).CANAL = vSMS THEN                      
                vTipoCanal := 'SMS';
                PR_PKG_REPRESTAMOS.Reenviar_Sms_Api(pIdReprestamo, vCanal(x).VALOR, vCanal(x).NOMBRES, vCanal(x).APELLIDOS, vTipoCanal, 'TXT', vMensaje, pRespuesta);
                
                IF pRespuesta IS NULL THEN
                   pRespuesta := 'Notificacion Enviada';
                   DBMS_OUTPUT.PUT_LINE(pRespuesta);
                END IF;
            
            ELSIF vCanal(x).CANAL = vEMAIL THEN
                 /* vTipoCanal := 'MAIL';
                 vSubject := PR.PR_PKG_REPRESTAMOS.f_OBT_subject_email(pIdReprestamo);
                 
                 PR_PKG_REPRESTAMOS.Reenviar_Correo_Api(
                     pIdReprestamo, 
                     vCanal(x).VALOR, 
                     vCanal(x).NOMBRES, 
                     vCanal(x).APELLIDOS, 
                     vSubject, 
                     'TXT',
                     vMensaje,  -- Aquí reutilizamos el mensaje ya calculado
                     pRespuesta
                 );           
                 
                 IF pRespuesta IS NULL THEN
                    pRespuesta := 'Notificacion Enviada';
                 END IF;
                 */
                 NULL;
            END IF;                  
            
            DBMS_OUTPUT.PUT_LINE(vMensaje);
        END LOOP;
        EXIT WHEN cCanal%NOTFOUND;
    END LOOP;
    CLOSE cCanal; 
END P_Notificar_Reenvio_Link;