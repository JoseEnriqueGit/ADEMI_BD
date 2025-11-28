PROCEDURE P_Notificar_Reenvio_Link(pIdReprestamo    IN      NUMBER,
                                    pRespuesta       IN OUT  VARCHAR2) IS
    
    CURSOR cCanal(pIdReprestamo    IN      NUMBER) IS
    SELECT c.CANAL, c.VALOR, S.NOMBRES, S.APELLIDOS 
        FROM PR.PR_CANALES_REPRESTAMO c, PR_SOLICITUD_REPRESTAMO s 
        WHERE C.CODIGO_EMPRESA = PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
        AND C.ID_REPRESTAMO = pIdReprestamo
        AND C.CANAL = C.CANAL ||''
        AND S.CODIGO_EMPRESA = C.CODIGO_EMPRESA
        AND S.ID_REPRESTAMO = C.ID_REPRESTAMO;  
    TYPE tCanal IS TABLE OF cCanal%ROWTYPE;
    vCanal tCanal := tCanal(); 
    vMensaje      VARCHAR2(4000); 
    vSubject      VARCHAR2(4000);
    vSMS          NUMBER := NVL(f_obt_parametro_Represtamo('CANAL_SMS'), 1);
    vEMAIL        NUMBER := NVL(f_obt_parametro_Represtamo('CANAL_EMAIL'), 2);   
    vTipoCanal    VARCHAR2(5) := 'SMS';                                         
BEGIN
        OPEN cCanal(pIdReprestamo);
        LOOP
            FETCH cCanal BULK COLLECT INTO vCanal LIMIT 500;       
            FOR x IN 1 .. vCanal.COUNT LOOP
                vMensaje :=   PR_PKG_REPRESTAMOS.F_Obt_Body_Mensaje(pIdReprestamo, vCanal(x).CANAL);
                IF vCanal(x).CANAL = vSMS THEN                    
                    vTipoCanal := 'SMS';
                    PR_PKG_REPRESTAMOS.Reenviar_Sms_Api(pIdReprestamo, vCanal(x).VALOR, vCanal(x).NOMBRES, vCanal(x).APELLIDOS, vTipoCanal, 'TXT',vMensaje, pRespuesta);
                    IF pRespuesta IS NULL THEN
                    pRespuesta := 'Notificacion Enviada';
                    DBMS_OUTPUT.PUT_LINE ( pRespuesta );
                    END IF;
                /*ELSIF vCanal(x).CANAL = vEMAIL THEN
                    vTipoCanal := 'MAIL';
                    vSubject := PR.PR_PKG_REPRESTAMOS.f_OBT_subject_email(pIdReprestamo);
                    PR_PKG_REPRESTAMOS.Reenviar_Correo_Api(pIdReprestamo, vCanal(x).VALOR, vCanal(x).NOMBRES, vCanal(x).APELLIDOS, vSubject, 'TXT',vMensaje, pRespuesta);            
                    IF pRespuesta IS NULL THEN
                    pRespuesta := 'Notificacion Enviada';
                    END IF;*/
                END IF;                 
                DBMS_OUTPUT.PUT_LINE (vMensaje);
            END LOOP;
            EXIT WHEN cCanal%NOTFOUND;
        END LOOP;
        CLOSE cCanal; 
        
END;   