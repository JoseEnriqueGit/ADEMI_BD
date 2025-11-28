FUNCTION F_Obt_Body_Mensaje(pIdReprestamo     IN VARCHAR2,
                           pCanal            IN VARCHAR2)
RETURN VARCHAR2 IS
   vBody       VARCHAR2(4000);
   vNombres    VARCHAR2(400);
   vFecha      DATE;      
   vUltimoDia  DATE;  
BEGIN
   BEGIN
      SELECT PF.PRIMER_NOMBRE,R.fecha_proceso --PA.OBT_NOMBRE_PERSONA(R.CODIGO_CLIENTE) Nombres
         INTO vNombres,vFecha
         FROM PR.PR_REPRESTAMOS r, PA.PERSONAS_FISICAS pf
         WHERE r.ID_REPRESTAMO = pIdReprestamo
         AND R.CODIGO_CLIENTE = PF.COD_PER_FISICA;
   EXCEPTION WHEN NO_DATA_FOUND THEN
      vNombres := NULL;  
   END;
   
   IF vNombres IS NOT NULL THEN
   
            SELECT TO_DATE(TO_CHAR(LAST_DAY(R.FECHA_PROCESO), 'DD/MM/YYYY') || ' 11:59:59 PM', 'DD/MM/YYYY HH:MI:SS AM')
            INTO vUltimoDia
            FROM PR.PR_REPRESTAMOS R
            WHERE R.ID_REPRESTAMO = pIdReprestamo;
   
      IF pCanal = 1 THEN  -- SMS
            --vBody := REPLACE(REPLACE(f_obt_parametro_Represtamo('TEXTO_SMS'), '[NOMBRES]', vNombres),'[FECHA]',to_char(trunc(vFecha)+PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('DIA_CADUCA_LINK'),'DD/MM/YYYY'));
            vBody := REPLACE(REPLACE(f_obt_parametro_Represtamo('TEXTO_SMS'), '[NOMBRES]', vNombres), '[FECHA]', TO_CHAR(vUltimoDia, 'DD/MM/YYYY HH:MI:SS AM'));
      ELSIF pCanal = 2 THEN  -- EMAIL
            vBody := REPLACE(REPLACE(f_obt_parametro_Represtamo('TEXTO_EMAIL'), '[NOMBRES]', vNombres),'[FECHA]',to_char(trunc(vFecha)+PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('DIA_CADUCA_LINK'),'DD/MM/YYYY'));
      END IF;
   END IF;
   
   RETURN vBody;
EXCEPTION WHEN OTHERS THEN

   DECLARE
      vIdError      PLS_INTEGER := 0;
   BEGIN
                              
      IA.LOGGER.ADDPARAMVALUEV('pIdReprestamo',     pIdReprestamo);
      IA.LOGGER.ADDPARAMVALUEV('pCanal',            pCanal);          
                                       
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
   
END F_Obt_Body_Mensaje; 