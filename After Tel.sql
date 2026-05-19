CREATE
OR REPLACE FUNCTION PR.obt_telefono_persona(
    inCodPersona IN VARCHAR2,
    inTipoTelefono IN VARCHAR2
) RETURN VARCHAR2 AUTHID DEFINER IS vLabTel VARCHAR2(30);

BEGIN -- C: Celular
-- R: Central Telefonica
-- F: Fax
-- D: Linea Directa
-- O: Otro
-- T: Telefax
-- X: Telefono/Fax
IF inTipoTelefono IN ('X', 'O') THEN BEGIN
SELECT
    DECODE(
        l.cod_area,
        NULL,
        l.num_telefono,
        DECODE(
            l.extension_tel,
            NULL,
            '(' || l.cod_area || ')' || l.num_telefono,
            '(' || l.cod_area || ')' || l.num_telefono || ' ' || l.extension_tel
        )
    ) telefono INTO vLabTel
FROM
    PA.info_laboral l
WHERE
    l.cod_per_fisica = inCodPersona
    AND l.cod_laboral = (
        SELECT
            MAX(x.cod_laboral)
        FROM
            PA.info_laboral x
        WHERE
            x.cod_per_fisica = inCodPersona
    );

EXCEPTION
WHEN NO_DATA_FOUND THEN vLabTel := NULL;

WHEN OTHERS THEN vLabTel := NULL;

END;

ELSE BEGIN
SELECT
    DECODE(
        cod_area,
        NULL,
        num_telefono,
        DECODE(
            extension,
            NULL,
            '(' || cod_area || ')' || num_telefono,
            '(' || cod_area || ')' || num_telefono || ' ' || extension
        )
    ) telefono INTO vLabTel
FROM
    PA.tel_personas
WHERE
    cod_persona = inCodPersona
    AND tip_telefono = inTipoTelefono
    AND es_default = 'S'
    AND ROWNUM = 1;

EXCEPTION
WHEN OTHERS THEN vLabTel := NULL;

END;

IF vLabTel IS NULL THEN BEGIN
SELECT
    DECODE(
        cod_area,
        NULL,
        num_telefono,
        DECODE(
            extension,
            NULL,
            '(' || cod_area || ')' || num_telefono,
            '(' || cod_area || ')' || num_telefono || ' ' || extension
        )
    ) telefono INTO vLabTel
FROM
    PA.tel_personas
WHERE
    cod_persona = inCodPersona
    AND tip_telefono = inTipoTelefono
    AND es_default = 'N'
    AND ROWNUM = 1;

EXCEPTION
WHEN OTHERS THEN vLabTel := NULL;

END;

END IF;

END IF;

RETURN vLabTel;

END obt_telefono_persona;

/