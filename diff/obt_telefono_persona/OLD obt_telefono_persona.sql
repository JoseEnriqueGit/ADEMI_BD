create
or replace FUNCTION obt_telefono_persona(
    inCodPersona IN NUMBER,
    inTipoTelefono IN VARCHAR2
) RETURN VARCHAR2 IS vlabtel VARCHAR2(30);

BEGIN -- C: Celular
-- R: Central Telefonica
-- F: Fax
-- D: Linea Directa
-- O: Otro
-- T: Telefax
-- X: Telefono/Fax    
IF inTipoTelefono IN ('X', 'O') THEN -- Telefono Laboral
BEGIN
SELECT
    DECODE (
        l.cod_area,
        NULL,
        l.num_telefono,
        DECODE (
            l.extension_tel,
            NULL,
            '(' || l.cod_area || ')' || l.num_telefono,
            '(' || l.cod_area || ')' || l.num_telefono || ' ' || l.extension_tel
        )
    ) telefono INTO vlabtel
FROM
    info_laboral l
WHERE
    l.cod_per_fisica = inCodPersona
    AND l.cod_laboral = (
        select
            max(x.cod_laboral)
        from
            info_laboral x
        where
            x.cod_per_fisica = l.cod_per_fisica
    );

EXCEPTION
WHEN NO_DATA_FOUND THEN vLabTel := NULL;

WHEN OTHERS THEN vLabTel := NULL;

END;

ELSE BEGIN
SELECT
    DECODE (
        cod_area,
        NULL,
        num_telefono,
        DECODE (
            extension,
            NULL,
            '(' || cod_area || ')' || num_telefono,
            '(' || cod_area || ')' || num_telefono || ' ' || extension
        )
    ) telefono INTO vlabtel
FROM
    tel_personas
WHERE
    cod_persona = inCodPersona
    AND tip_telefono = inTipoTelefono
    AND ROWNUM = 1;

EXCEPTION
WHEN OTHERS THEN vLabTel := NULL;

END;

END IF;

RETURN vLabTel;

END;