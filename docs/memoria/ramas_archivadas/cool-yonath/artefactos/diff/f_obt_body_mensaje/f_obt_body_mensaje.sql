FUNCTION F_Obt_Body_Mensaje(pNombres IN VARCHAR2, 
                                pFecha   IN DATE, 
                                pCanal   IN VARCHAR2) RETURN VARCHAR2 IS
        PRAGMA UDF; -- Optimización para Vistas
        
        vBody           VARCHAR2(4000);
        vTextoTemplate  VARCHAR2(4000);
        vDiaCaduca      NUMBER;
        vFechaVencSMS   VARCHAR2(50);
        vFechaVencEmail VARCHAR2(50);
        vIdError        PLS_INTEGER := 0; 
    BEGIN
        -- Si no hay nombres, no hay nada que procesar
        IF pNombres IS NULL THEN RETURN NULL; END IF;

        IF pCanal = '1' THEN -- SMS
             vTextoTemplate := f_obt_parametro_Represtamo('TEXTO_SMS');
             
             -- Lógica SMS: Fin de mes + Hora fija
             vFechaVencSMS := TO_CHAR(LAST_DAY(pFecha), 'DD/MM/YYYY') || ' 11:59:59 PM';
             
             vBody := REPLACE(REPLACE(vTextoTemplate, '[NOMBRES]', pNombres), '[FECHA]', vFechaVencSMS);

        ELSIF pCanal = '2' THEN -- EMAIL
             vTextoTemplate := f_obt_parametro_Represtamo('TEXTO_EMAIL');
             vDiaCaduca := TO_NUMBER(PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('DIA_CADUCA_LINK'));
             
             -- Lógica Email: Fecha proceso + Días configurados
             vFechaVencEmail := TO_CHAR(TRUNC(pFecha) + vDiaCaduca, 'DD/MM/YYYY');
             
             vBody := REPLACE(REPLACE(vTextoTemplate, '[NOMBRES]', pNombres), '[FECHA]', vFechaVencEmail);
        END IF;

        RETURN vBody;

    EXCEPTION WHEN OTHERS THEN
        -- Manejo de errores seguro
        BEGIN
            IA.LOGGER.ADDPARAMVALUEV('pNombres', SUBSTR(pNombres, 1, 200));
            IA.LOGGER.ADDPARAMVALUEV('pFecha', TO_CHAR(pFecha, 'DD/MM/YYYY'));
            IA.LOGGER.ADDPARAMVALUEV('pCanal', pCanal);
            
            setError(pProgramUnit => 'F_Obt_Body_Mensaje',
                     pPieceCodeName => NULL,
                     pErrorDescription => SQLERRM,
                     pErrorTrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,
                     pEmailNotification => NULL,
                     pParamList => IA.LOGGER.vPARAMLIST,
                     pOutputLogger => FALSE,
                     pExecutionTime => NULL,
                     pIdError => vIdError);
        END;
        RETURN NULL;
    END F_Obt_Body_Mensaje;