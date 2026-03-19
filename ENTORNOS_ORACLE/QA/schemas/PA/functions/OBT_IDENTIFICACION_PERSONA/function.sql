CREATE OR REPLACE FUNCTION PA.OBT_IDENTIFICACION_PERSONA(
    inCodPersona   IN VARCHAR2,
    inTipoId       IN VARCHAR2
) RETURN VARCHAR2 IS
    vNumId        PA.ID_PERSONAS.NUM_ID%TYPE;
    vCodTipoId    PA.ID_PERSONAS.COD_TIPO_ID%TYPE;
    vFormato      PA.TIPOS_ID.MASCARA%TYPE;
BEGIN

    /*
        Cedula               -   1
        Cedula extranjero    -   5
        Licencia             -   7
        Licencia extranjero  -   3
        Pasaporte Dominicano -   4
        Pasaporte extranjero -   6
    */

    IF inTipoId IN ('1', '5', '7', '3', '4', '6') THEN

        BEGIN
            SELECT num_id, cod_tipo_id
              INTO vNumId, vCodTipoid
              FROM id_personas
             WHERE cod_persona = inCodPersona
               AND cod_tipo_id in (inTipoId)
               AND ROWNUM = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                BEGIN
                    SELECT num_id, cod_tipo_id
                      INTO vNumId, vCodTipoid
                      FROM id_personas
                     WHERE cod_persona = inCodPersona
                       AND ROWNUM <= 1;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        vNumId := null;
                        vCodTipoid := null;
                END;
            WHEN OTHERS THEN
                NULL;
        END;

        BEGIN
            SELECT mascara
              INTO vFormato
              FROM tipos_id
             WHERE cod_tipo_id = vCodTipoid;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                vFormato := null;
            WHEN OTHERS THEN
                vFormato := null;
        END;

        IF vNumId IS NOT NULL THEN
            IF vFormato IS NOT NULL THEN
                vNumId := formatear_identificacion (vNumId, vFormato, 'ESPA');
            END IF;
        END IF;

    ELSE
        vNumId := NULL;
    END IF;

    RETURN vNumId;

END OBT_IDENTIFICACION_PERSONA;
/
