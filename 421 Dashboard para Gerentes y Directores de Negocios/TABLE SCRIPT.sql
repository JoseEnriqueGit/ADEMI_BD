WITH latest_bitacora AS (
    SELECT
        b.id_represtamo,
        b.codigo_estado,
        b.fecha_adicion,
        ROW_NUMBER() OVER(
            PARTITION BY
                b.id_represtamo
            ORDER BY
                b.id_bitacora DESC,
                b.fecha_adicion DESC
        ) AS rn
    FROM
        pr.pr_bitacora_represtamo b
), has_cry_status AS (
    SELECT DISTINCT
        id_represtamo
    FROM
        pr.pr_bitacora_represtamo
    WHERE
        codigo_estado = 'CRY'
)
SELECT
    lb.fecha_adicion AS "FECHA_ESTADO",
    s.id_represtamo AS "ID Représtamo",
    r.codigo_cliente AS "Código Cliente",
    s.nombres || ' ' || s.apellidos AS "Cliente",
    s.identificacion AS "Identificación",
    a_canal.valor AS "Celular",
    r.no_credito AS "Crédito Anterior",
    s.no_credito AS "Crédito Nuevo",
    r.mto_preaprobado AS "Monto Preaprobado",
    tc.tipo_credito || ' - ' || tc.descripcion AS "Tipo de Crédito",
    pr.pr_pkg_represtamos.f_obt_descripcion_estado(lb.codigo_estado) AS "Estado",
    c.f_primer_desembolso AS "Fecha de Desembolso",
    c.monto_desembolsado AS "Monto Desembolsado",
    CASE
        WHEN r.id_carga_dirigida IS NOT NULL THEN 'Carga Dirigida'
        WHEN r.id_repre_campana_especiales IS NOT NULL THEN 'Campañas Especiales'
        ELSE 'Représtamo Digital'
    END AS "Tipo de Préstamo",
    CASE
        WHEN s.email IS NULL THEN 'No'
        ELSE 'Sí'
    END AS "Correo Electrónico",
    CASE
        WHEN lb.codigo_estado = 'CRD' THEN CASE
            WHEN hcs.id_represtamo IS NOT NULL THEN 'Digital (con firma)'
            ELSE 'Sucursal (tradicional)'
        END
    END AS "Tipo de Desembolso",
    NVL(c.codigo_agencia, h.codigo_agencia) AS "Código Sucursal",
    ag.descripcion AS "Oficina",
    pa.obt_desc_zona(1, ag.cod_zona) AS "Zona",
    NVL(c.codigo_ejecutivo, h.codigo_ejecutivo) AS "Código Oficial",
    pa.obt_nombre_empleado(
        NVL(c.codigo_empresa, h.codigo_empresa),
        NVL(c.codigo_ejecutivo, h.codigo_ejecutivo)
    ) AS "Oficial"
FROM
    pa.empleados p
JOIN pa.agencia a_emp
    ON TO_NUMBER(p.cod_empresa) = a_emp.cod_empresa AND TO_NUMBER(p.cod_agencia_labora) = a_emp.cod_agencia
JOIN pr.pr_solicitud_represtamo s
    ON TO_NUMBER(p.cod_empresa) = s.codigo_empresa AND TO_NUMBER(p.cod_agencia_labora) = s.codigo_agencia
JOIN pr.pr_represtamos r
    ON r.id_represtamo = s.id_represtamo AND r.codigo_empresa = s.codigo_empresa
JOIN latest_bitacora lb
    ON lb.id_represtamo = s.id_represtamo AND lb.rn = 1
LEFT JOIN has_cry_status hcs
    ON hcs.id_represtamo = s.id_represtamo
LEFT JOIN pr.pr_creditos c
    ON c.no_credito = r.no_credito AND c.codigo_empresa = r.codigo_empresa
LEFT JOIN pr.pr_creditos_hi h
    ON h.no_credito = r.no_credito AND h.codigo_empresa = r.codigo_empresa
LEFT JOIN pa.agencia ag
    ON ag.cod_empresa = r.codigo_empresa AND ag.cod_agencia = NVL(c.codigo_agencia, h.codigo_agencia)
LEFT JOIN pr.pr_tipo_credito tc
    ON tc.tipo_credito = NVL(s.tipo_credito, NVL(c.tipo_credito, h.tipo_credito)) AND tc.codigo_empresa = r.codigo_empresa
LEFT JOIN pr.pr_canales_represtamo a_canal
    ON a_canal.id_represtamo = r.id_represtamo AND a_canal.canal = 1
WHERE
    -- SUBSTR(P.EMAIL1, 1, INSTR(P.EMAIL1, '@') - 1) = V('APP_USER')
    SUBSTR(p.email1, 1, INSTR(p.email1, '@') - 1) = 'MAMATOS'
    AND p.id_empleado = a_emp.gerente
    AND p.esta_activo = 'S'
    AND NOT EXISTS (
        SELECT
            1
        FROM
            pr_carga_direccionada cd
        WHERE
            cd.no_credito = r.no_credito
            AND cd.estado = 'F'
            AND TRUNC(cd.fecha_adicion) = TRUNC(r.fecha_adicion)
    )
    AND (
        :P133_FROM_DATE IS NULL
        OR lb.fecha_adicion >= TRUNC(CAST(:P133_FROM_DATE AS DATE))
    )
    AND (
        :P133_TO_DATE IS NULL
        OR lb.fecha_adicion <= TRUNC(CAST(:P133_TO_DATE AS DATE))
    )
    AND (
        :P133_ESTADO IS NULL OR lb.codigo_estado IN (
            SELECT
                column_value
            FROM
                TABLE(apex_string.split(:P133_ESTADO, ','))
        )
    )
ORDER BY
    lb.fecha_adicion DESC,
    s.id_represtamo DESC;