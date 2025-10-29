CREATE
OR REPLACE FUNCTION obt_telefono_persona(
    inCodPersona IN NUMBER,
    inTipoTelefono IN VARCHAR2
) RETURN VARCHAR2 IS PRAGMA UDF;

vLabTel VARCHAR2(30);

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
    CASE
        WHEN l.cod_area IS NULL THEN l.num_telefono
        WHEN l.extension_tel IS NULL THEN '(' || l.cod_area || ')' || l.num_telefono
        ELSE '(' || l.cod_area || ')' || l.num_telefono || ' ' || l.extension_tel
    END INTO vLabTel
FROM
    (
        SELECT
            l.cod_area,
            l.num_telefono,
            l.extension_tel
        FROM
            info_laboral l
        WHERE
            l.cod_per_fisica = inCodPersona
        ORDER BY
            l.cod_laboral DESC
    ) l
WHERE
    ROWNUM = 1;

EXCEPTION
WHEN NO_DATA_FOUND THEN vLabTel := NULL;

WHEN OTHERS THEN vLabTel := NULL;

END;

ELSE BEGIN
SELECT
    CASE
        WHEN t.cod_area IS NULL THEN t.num_telefono
        WHEN t.extension IS NULL THEN '(' || t.cod_area || ')' || t.num_telefono
        ELSE '(' || t.cod_area || ')' || t.num_telefono || ' ' || t.extension
    END INTO vLabTel
FROM
    tel_personas t
WHERE
    t.cod_persona = inCodPersona
    AND t.tip_telefono = inTipoTelefono
    AND ROWNUM = 1;

EXCEPTION
WHEN OTHERS THEN vLabTel := NULL;

END;

END IF;

RETURN vLabTel;

END;

/