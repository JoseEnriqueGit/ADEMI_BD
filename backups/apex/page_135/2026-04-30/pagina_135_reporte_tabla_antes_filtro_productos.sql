-- Backup APEX pagina 135
-- Region: reporte/tabla de certificados
-- Estado: ANTES de agregar filtro por productos digitales
-- Fecha: 2026-04-30

SELECT
    p.NOMBRE AS NOMBRE_CLIENTE,
    (SELECT NUM_ID FROM PA.ID_PERSONAS idp WHERE idp.COD_PERSONA = cd.CLIENTE AND ROWNUM = 1) AS "Cédula",
    cd.CLIENTE AS "Código de empleado",
    CASE
      WHEN EXISTS (
        SELECT 1 FROM PA.EMPLEADOS emp
        WHERE emp.COD_PER_FISICA = cd.CLIENTE
          AND emp.COD_EMPRESA = cd.COD_EMPRESA
          AND emp.ESTA_ACTIVO = 'S'
      ) THEN 'Empleado (Interno)'
      ELSE 'Cliente Externo'
    END AS TIPO_CLIENTE,
    CASE 
        WHEN p.ES_FISICA = 'N' THEN 'N/A (JURIDICO)'
        WHEN pf.SEXO = 'M' THEN 'MASCULINO'
        WHEN pf.SEXO = 'F' THEN 'FEMENINO'
        ELSE NVL(pf.SEXO, 'NO DEFINIDO')
    END AS GENERO,
    TRUNC(MONTHS_BETWEEN(SYSDATE, pf.FEC_NACIMIENTO) / 12) AS EDAD,
    
    -- CAMBIO APLICADO: Número con tilde y palabra completa
    cd.NUM_CERTIFICADO AS "Número Certificado",
    
    CASE cd.TIP_CERTIFICADO
        WHEN 'CU' THEN 'Crédito a Cuenta'
        WHEN 'CV' THEN 'Capitalizable'
        WHEN 'CF' THEN 'Capitalizable Fijo'
        ELSE 'Otro (' || cd.TIP_CERTIFICADO || ')'
    END AS MODALIDAD_PAGO,
    CASE cd.COD_MONEDA
        WHEN '1' THEN 'Pesos (DOP)'
        WHEN '2' THEN 'Dólares (USD)'
        ELSE 'Moneda ' || cd.COD_MONEDA
    END AS MONEDA,
    cd.MONTO AS MONTO_CERTIFICADO,
    cd.PLA_DIAS AS PLAZO_DIAS,
    cd.TAS_BRUTA AS "Tasa de Interés",
    cd.FEC_EMISION AS FECHA_APERTURA,
    
    -- CAMBIO APLICADO: Palabra completa
    cd.FEC_VENCIMIENTO AS "Fecha Vencimiento", 
    
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
        WHEN cd.ESTADO = 'A' THEN 'VIGENTE'
        WHEN cd.ESTADO = 'R' THEN 'RETENIDO'
        WHEN cd.ESTADO = 'P' THEN 'PAGADO'
        WHEN cd.ESTADO = 'N' THEN 'ANULADO'
    END AS ESTATUS
FROM
    CD.CD_CERTIFICADO cd
LEFT JOIN PA.PERSONAS p ON cd.CLIENTE = p.COD_PERSONA
LEFT JOIN PA.PERSONAS_FISICAS pf ON p.COD_PER_FISICA = pf.COD_PER_FISICA
LEFT JOIN PA.AGENCIA ag ON cd.COD_AGENCIA = ag.COD_AGENCIA AND cd.COD_EMPRESA = ag.COD_EMPRESA
LEFT JOIN PA.AREAS_MERCADO zn ON ag.COD_ZONA = zn.COD_ZONA AND ag.COD_EMPRESA = zn.COD_EMPRESA
WHERE
    cd.COD_EMPRESA = NVL(:P_COD_EMPRESA, '1')
    AND (
        (:P135_LOGICA_FECHA = 'AND' 
            AND (TRUNC(cd.FEC_EMISION) BETWEEN TO_DATE(:P135_FROM_DATE, 'DD-MM-YYYY') AND TO_DATE(:P135_TO_DATE, 'DD-MM-YYYY'))
            AND (NVL(cd.FEC_VENCIMIENTO, TRUNC(SYSDATE) + 365) BETWEEN TO_DATE(:P135_FROM_CANC, 'DD-MM-YYYY') AND TO_DATE(:P135_TO_CANC, 'DD-MM-YYYY'))
        )
        OR 
        (:P135_LOGICA_FECHA = 'OR' 
            AND (
                (TRUNC(cd.FEC_EMISION) BETWEEN TO_DATE(:P135_FROM_DATE, 'DD-MM-YYYY') AND TO_DATE(:P135_TO_DATE, 'DD-MM-YYYY'))
                OR 
                (NVL(cd.FEC_VENCIMIENTO, TRUNC(SYSDATE) + 365) BETWEEN TO_DATE(:P135_FROM_CANC, 'DD-MM-YYYY') AND TO_DATE(:P135_TO_CANC, 'DD-MM-YYYY'))
            )
        )
    )
    AND (
        :P135_FILTRO_CARD IS NULL 
        OR (:P135_FILTRO_CARD = 'Certificados Vigentes' AND cd.ESTADO IN ('A', 'R') AND (cd.FEC_VENCIMIENTO >= TRUNC(SYSDATE) OR cd.FEC_VENCIMIENTO IS NULL))
        OR (:P135_FILTRO_CARD = 'Certificados Vencidos' AND (cd.ESTADO IN ('C', 'P', 'N', 'I') OR (cd.FEC_VENCIMIENTO < TRUNC(SYSDATE) AND cd.FEC_VENCIMIENTO IS NOT NULL)))
        OR (:P135_FILTRO_CARD = 'Clientes Externos' AND NOT EXISTS (SELECT 1 FROM PA.EMPLEADOS e WHERE e.COD_PER_FISICA = cd.CLIENTE AND e.ESTA_ACTIVO = 'S'))
        OR (:P135_FILTRO_CARD = 'Empleados' AND EXISTS (SELECT 1 FROM PA.EMPLEADOS e WHERE e.COD_PER_FISICA = cd.CLIENTE AND e.ESTA_ACTIVO = 'S'))
        OR (:P135_FILTRO_CARD = 'Monto en Pesos' AND cd.COD_MONEDA = '1' AND cd.ESTADO IN ('A', 'R') AND (cd.FEC_VENCIMIENTO >= TRUNC(SYSDATE) OR cd.FEC_VENCIMIENTO IS NULL))
        OR (:P135_FILTRO_CARD = 'Monto en Dólares' AND cd.COD_MONEDA = '2' AND cd.ESTADO IN ('A', 'R') AND (cd.FEC_VENCIMIENTO >= TRUNC(SYSDATE) OR cd.FEC_VENCIMIENTO IS NULL))
    )
ORDER BY
    cd.FEC_EMISION DESC;
