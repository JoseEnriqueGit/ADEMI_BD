WITH latest_bitacora AS (
    SELECT
        b.id_represtamo,
        b.codigo_estado,
        b.observaciones,
        b.adicionado_por,
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
), base_data AS (
    SELECT
        s.id_represtamo,
        r.mto_preaprobado,
        lb.fecha_adicion AS fecha_estado,
        c.monto_desembolsado,
        c.f_primer_desembolso AS fecha_desembolso,
        lb.codigo_estado AS codigo_estado_actual,
        CASE
            WHEN lb.codigo_estado = 'CRD' THEN CASE
                WHEN hcs.id_represtamo IS NOT NULL THEN 'Digital (con firma)'
                ELSE 'Sucursal (tradicional)'
            END
        END AS canal_desembolso_determinado
    FROM
        pa.empleados p
    JOIN pa.agencia a
        ON TO_NUMBER(p.cod_empresa) = a.cod_empresa AND TO_NUMBER(p.cod_agencia_labora) = a.cod_agencia
    JOIN pr.pr_solicitud_represtamo s
        ON TO_NUMBER(p.cod_empresa) = s.codigo_empresa AND TO_NUMBER(p.cod_agencia_labora) = s.codigo_agencia
    JOIN pr.pr_represtamos r
        ON r.id_represtamo = s.id_represtamo AND r.codigo_empresa = s.codigo_empresa
    JOIN latest_bitacora lb
        ON lb.id_represtamo = s.id_represtamo AND lb.rn = 1
    LEFT JOIN has_cry_status hcs
        ON hcs.id_represtamo = s.id_represtamo
    LEFT JOIN pr.pr_creditos c
        ON c.no_credito = s.no_credito AND c.codigo_empresa = s.codigo_empresa
    WHERE
        -- SUBSTR(P.EMAIL1, 1, INSTR(P.EMAIL1, '@') - 1) = V('APP_USER')
        SUBSTR(p.email1, 1, INSTR(p.email1, '@') - 1) = 'MAMATOS'
        AND p.id_empleado = a.gerente
        AND p.esta_activo = 'S'
        AND (
            :P133_FROM_DATE IS NULL
            OR lb.fecha_adicion >= TRUNC(CAST(:P133_FROM_DATE AS DATE))
        )
        AND (
            :P133_TO_DATE IS NULL
            OR lb.fecha_adicion <= TRUNC(CAST(:P133_TO_DATE AS DATE))
        )
), efectividad_rango AS (
    SELECT
        (
            SELECT
                COUNT(DISTINCT id_represtamo)
            FROM
                base_data
            WHERE
                codigo_estado_actual = 'CRD'
        ) AS desembolsados_r,
        (
            SELECT
                COUNT(DISTINCT id_represtamo)
            FROM
                base_data
        ) AS preaprobados_r
    FROM
        dual
)
SELECT
    *
FROM
    (
        SELECT
            'Total Preaprobados' AS card_title,
            TO_CHAR(COUNT(DISTINCT id_represtamo)) AS card_text,
            'Monto RD$ ' || TO_CHAR(
                NVL(SUM(mto_preaprobado), 0),
                'FM9G999G999G990D00',
                'NLS_NUMERIC_CHARACTERS=''.,'''
            ) AS card_subtext,
            'fa-file-invoice-dollar' AS card_icon,
            'u-color-1' AS card_color,
            1 AS order_col
        FROM
            base_data
        UNION ALL
        SELECT
            'Total Desembolsos',
            TO_CHAR(COUNT(DISTINCT id_represtamo)),
            'Monto RD$ ' || TO_CHAR(
                NVL(SUM(monto_desembolsado), 0),
                'FM9G999G999G990D00',
                'NLS_NUMERIC_CHARACTERS=''.,'''
            ),
            'fa-check-circle',
            'u-color-5',
            2
        FROM
            base_data
        WHERE
            codigo_estado_actual = 'CRD'
        UNION ALL
        SELECT
            'Efectividad',
            CASE
                WHEN preaprobados_r = 0 THEN '0.00%'
                ELSE TO_CHAR(TRUNC(desembolsados_r / preaprobados_r * 100, 2), 'FM990.00') || '%'
            END,
            'Des: ' || desembolsados_r || ' / Pre: ' || preaprobados_r,
            'fa-percent',
            'u-color-10',
            3
        FROM
            efectividad_rango
        UNION ALL
        SELECT
            'Desembolsos Firma Electrónica',
            TO_CHAR(COUNT(DISTINCT id_represtamo)),
            'Monto RD$ ' || TO_CHAR(
                NVL(SUM(monto_desembolsado), 0),
                'FM9G999G999G990D00',
                'NLS_NUMERIC_CHARACTERS=''.,'''
            ),
            'fa-mobile-alt',
            'u-color-15',
            4
        FROM
            base_data
        WHERE
            codigo_estado_actual = 'CRD'
            AND canal_desembolso_determinado = 'Digital (con firma)'
        UNION ALL
        SELECT
            'Desembolsos Firma Tradicional',
            TO_CHAR(COUNT(DISTINCT id_represtamo)),
            'Monto RD$ ' || TO_CHAR(
                NVL(SUM(monto_desembolsado), 0),
                'FM9G999G999G990D00',
                'NLS_NUMERIC_CHARACTERS=''.,'''
            ),
            'fa-building',
            'u-color-16',
            5
        FROM
            base_data
        WHERE
            codigo_estado_actual = 'CRD'
            AND canal_desembolso_determinado = 'Sucursal (tradicional)'
        UNION ALL
        SELECT
            'Créditos Cancelados',
            TO_CHAR(COUNT(DISTINCT id_represtamo)),
            'Monto RD$ ' || TO_CHAR(
                NVL(SUM(mto_preaprobado), 0),
                'FM9G999G999G990D00',
                'NLS_NUMERIC_CHARACTERS=''.,'''
            ),
            'fa-times-circle-o',
            'u-color-7',
            6
        FROM
            base_data
        WHERE
            codigo_estado_actual = 'CC'
        UNION ALL
        SELECT
            'Link Vencido',
            TO_CHAR(COUNT(DISTINCT id_represtamo)),
            'Monto RD$ ' || TO_CHAR(
                NVL(SUM(mto_preaprobado), 0),
                'FM9G999G999G990D00',
                'NLS_NUMERIC_CHARACTERS=''.,'''
            ),
            'fa-chain-broken',
            'u-color-8',
            7
        FROM
            base_data
        WHERE
            codigo_estado_actual = 'AN'
        UNION ALL
        SELECT
            'Créditos Anulados',
            TO_CHAR(COUNT(DISTINCT id_represtamo)),
            'Monto RD$ ' || TO_CHAR(
                NVL(SUM(mto_preaprobado), 0),
                'FM9G999G999G990D00',
                'NLS_NUMERIC_CHARACTERS=''.,'''
            ),
            'fa-ban',
            'u-color-9',
            8
        FROM
            base_data
        WHERE
            codigo_estado_actual = 'CRN'
    )
ORDER BY
    order_col;