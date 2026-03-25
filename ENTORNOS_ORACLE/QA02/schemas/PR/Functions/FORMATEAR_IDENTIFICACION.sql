CREATE OR REPLACE FUNCTION PA.Formatear_Identificacion ( pIdentificacion  IN VARCHAR2,
                                                         pFormato         IN VARCHAR2,
                                                         pCodIdioma       IN VARCHAR2)
   RETURN VARCHAR2 IS

   resultado       TIPOS_ID.MASCARA%TYPE;
   posicion_guion  NUMBER(4);
   existen_guiones BOOLEAN := TRUE;
   i               NUMBER(4) := 1;

BEGIN
    resultado := pIdentificacion;
    IF (INSTR(pIdentificacion, '-', 1, 1) = 0) AND (pFormato IS NOT NULL) THEN 
        WHILE (existen_guiones) LOOP
            posicion_guion := INSTR(pFormato, '-', 1, i);
            IF (posicion_guion = 0) THEN
                existen_guiones := FALSE;
            ELSE
                resultado := SUBSTR(resultado, 1, posicion_guion - 1) || '-' || SUBSTR(resultado, posicion_guion);
                i := i + 1;
            END IF;
        END LOOP;
    END IF;
    RETURN resultado;
END Formatear_Identificacion; 

--grant select on Pa.Formatear_Identificacion to public;
/

