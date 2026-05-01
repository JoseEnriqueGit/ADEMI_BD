SELECT
    p.NOMBRE AS NOMBRE_CLIENTE,
    ce.NUM_CUENTA,
    ce.COD_CLIENTE,
    TRUNC(MONTHS_BETWEEN(SYSDATE, pf.FEC_NACIMIENTO) / 12) AS EDAD,
    CASE
        WHEN p.ES_FISICA = 'N' THEN 'N/A (JURIDICO)'
        WHEN pf.SEXO = 'M' THEN 'MASCULINO'
        WHEN pf.SEXO = 'F' THEN 'FEMENINO'
        ELSE NVL(pf.SEXO, 'NO DEFINIDO')
    END AS GENERO,
    CASE TO_CHAR(ce.IND_ESTADO)
        WHEN '0' THEN 'PENDIENTE DE APROBAR'
        WHEN '1' THEN 'ACTIVA'
        WHEN '2' THEN 'CANCELADA'
        WHEN '3' THEN 'BLOQUEADA PARCIALMENTE'
        WHEN '4' THEN 'BLOQUEADA TOTALMENTE'
        WHEN '5' THEN 'EMBARGADA'
        WHEN '6' THEN 'INACTIVA'
        WHEN '7' THEN 'ABANDONADA'
        WHEN '8' THEN 'TRANSFERIDA AL BC'
        ELSE 'OTRO (' || ce.IND_ESTADO || ')'
    END AS ESTADO_CUENTA,
    NVL(prod.DESCRIPCION, 'PRODUCTO ' || ce.COD_PRODUCTO) AS NOMBRE_PRODUCTO,
    ce.FEC_APERTURA,
    ce.FEC_CANCELAC AS FECHA_CANCELACION,
    ce.SAL_TOTAL_CTA AS SALDO_ACTUAL,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM PA.EMPLEADOS emp
            WHERE emp.COD_PER_FISICA = ce.COD_CLIENTE
              AND emp.COD_EMPRESA = ce.COD_EMPRESA
              AND emp.ESTA_ACTIVO = 'S'
        ) THEN 'Empleado (Interno)'
        ELSE 'Cliente Externo'
    END AS TIPO_CLIENTE,
    (
        SELECT NUM_ID
        FROM PA.ID_PERSONAS idp
        WHERE idp.COD_PERSONA = ce.COD_CLIENTE
          AND ROWNUM = 1
    ) AS IDENTIFICACION,
    CASE
        WHEN p.ES_FISICA = 'N' THEN 'PERSONA JURIDICA'
        WHEN il.TIPO_INGRESO IS NULL THEN 'DESEMPLEADO'
        WHEN il.TIPO_INGRESO = 'S' THEN 'EMPLEADO'
        WHEN il.TIPO_INGRESO = 'H' THEN 'INDEPENDIENTE'
        WHEN il.TIPO_INGRESO = 'O' THEN 'OTROS INGRESOS'
        ELSE 'OTRO (' || il.TIPO_INGRESO || ')'
    END AS CONDICION_LABORAL,
    ag.DESCRIPCION AS OFICINA,
    CASE zn.COD_ZONA
        WHEN '1' THEN 'METRO ESTE'
        WHEN '2' THEN 'SUR'
        WHEN '3' THEN 'ESTE'
        WHEN '4' THEN 'NORDESTE'
        WHEN '5' THEN 'METRO SUR'
        WHEN '6' THEN 'CIBAO CENTRAL'
        WHEN '7' THEN 'NOROESTE'
        WHEN '8' THEN 'METRO SUR'
        WHEN '9' THEN 'SANTIAGO'
        ELSE zn.DESCRIPCION
    END AS ZONA,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM CC.CUENTA_EFECTIVO c2
            WHERE c2.COD_CLIENTE = ce.COD_CLIENTE
              AND c2.NUM_CUENTA <> ce.NUM_CUENTA
            UNION ALL
            SELECT 1
            FROM PR.PR_CREDITOS pr
            WHERE TO_CHAR(pr.CODIGO_CLIENTE) = ce.COD_CLIENTE
            UNION ALL
            SELECT 1
            FROM CD.CD_CERTIFICADO cd
            WHERE cd.CLIENTE = ce.COD_CLIENTE
            UNION ALL
            SELECT 1
            FROM TC.TC_TARJETAS tc
            WHERE tc.COD_CLIENTE = ce.COD_CLIENTE
        ) THEN 'CLIENTE EXISTENTE'
        ELSE 'CLIENTE NUEVO'
    END AS TIPO_VINCULACION
FROM
    CC.CUENTA_EFECTIVO ce
LEFT JOIN PA.PRODUCTOS prod
    ON ce.COD_PRODUCTO = prod.COD_PRODUCTO
   AND ce.COD_EMPRESA = prod.COD_EMPRESA
LEFT JOIN PA.PERSONAS p
    ON ce.COD_CLIENTE = p.COD_PERSONA
LEFT JOIN PA.PERSONAS_FISICAS pf
    ON p.COD_PER_FISICA = pf.COD_PER_FISICA
LEFT JOIN PA.AGENCIA ag
    ON ce.COD_AGENCIA = ag.COD_AGENCIA
   AND ce.COD_EMPRESA = ag.COD_EMPRESA
LEFT JOIN PA.AREAS_MERCADO zn
    ON ag.COD_ZONA = zn.COD_ZONA
   AND ag.COD_EMPRESA = zn.COD_EMPRESA
OUTER APPLY (
    SELECT il_sub.TIPO_INGRESO
    FROM PA.INFO_LABORAL il_sub
    WHERE il_sub.COD_PER_FISICA = p.COD_PER_FISICA
      AND il_sub.EMPLEO_ACTUAL = 'S'
    ORDER BY il_sub.FEC_INGRESO DESC
    FETCH FIRST 1 ROW ONLY
) il
WHERE
    ce.COD_PRODUCTO IN ('210', '211')
    AND (
        (
            :P134_LOGICA_FECHA = 'AND'
            AND TRUNC(ce.FEC_APERTURA) BETWEEN TO_DATE(:P134_FROM_DATE, 'DD-MM-YYYY') AND TO_DATE(:P134_TO_DATE, 'DD-MM-YYYY')
            AND ce.FEC_CANCELAC IS NOT NULL
            AND TRUNC(ce.FEC_CANCELAC) BETWEEN TO_DATE(:P134_FROM_CANC, 'DD-MM-YYYY') AND TO_DATE(:P134_TO_CANC, 'DD-MM-YYYY')
        )
        OR
        (
            :P134_LOGICA_FECHA = 'OR'
            AND (
                TRUNC(ce.FEC_APERTURA) BETWEEN TO_DATE(:P134_FROM_DATE, 'DD-MM-YYYY') AND TO_DATE(:P134_TO_DATE, 'DD-MM-YYYY')
                OR
                (
                    ce.FEC_CANCELAC IS NOT NULL
                    AND TRUNC(ce.FEC_CANCELAC) BETWEEN TO_DATE(:P134_FROM_CANC, 'DD-MM-YYYY') AND TO_DATE(:P134_TO_CANC, 'DD-MM-YYYY')
                )
            )
        )
    )
    AND (
        :P134_FILTRO_CARD IS NULL
        OR (
            :P134_FILTRO_CARD = 'Total cuentas activas'
            AND ce.FEC_CANCELAC IS NULL
        )
        OR (
            :P134_FILTRO_CARD = 'Total cuentas activas empleados'
            AND ce.FEC_CANCELAC IS NULL
            AND EXISTS (
                SELECT 1
                FROM PA.EMPLEADOS e
                WHERE e.COD_PER_FISICA = ce.COD_CLIENTE
                  AND e.ESTA_ACTIVO = 'S'
            )
        )
        OR (
            :P134_FILTRO_CARD = 'Total cuentas activas cliente'
            AND ce.FEC_CANCELAC IS NULL
            AND NOT EXISTS (
                SELECT 1
                FROM PA.EMPLEADOS e
                WHERE e.COD_PER_FISICA = ce.COD_CLIENTE
                  AND e.ESTA_ACTIVO = 'S'
            )
        )
        OR (
            :P134_FILTRO_CARD = 'Total Cuentas Canceladas'
            AND ce.FEC_CANCELAC IS NOT NULL
        )
    )
ORDER BY
    ce.FEC_APERTURA DESC;
