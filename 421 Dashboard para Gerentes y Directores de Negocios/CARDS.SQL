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
        (SELECT COUNT(DISTINCT id_represtamo) FROM base_data WHERE codigo_estado_actual = 'CRD') AS desembolsados_r,
        (SELECT COUNT(DISTINCT id_represtamo) FROM base_data) AS preaprobados_r
    FROM
        dual
)
SELECT
    card_title,
    card_text,
    card_subtext,
    card_icon,
    card_color,
    card_link,
    order_col
FROM
    (
        SELECT
            'Total Preaprobados' AS card_title,
            (SELECT TO_CHAR(COUNT(DISTINCT id_represtamo)) FROM base_data) AS card_text,
            (SELECT 'Monto RD$ ' || TO_CHAR(NVL(SUM(mto_preaprobado), 0), 'FM9G999G999G990D00', 'NLS_NUMERIC_CHARACTERS=''.,''') FROM base_data) AS card_subtext,
            'fa-file-invoice-dollar' AS card_icon,
            'u-color-1' AS card_color,
            'javascript:apex.item("P133_ESTADO").setValue(''' || (SELECT LISTAGG(column_value, ',') WITHIN GROUP(ORDER BY NULL) FROM TABLE(pr.pr_pkg_represtamos.f_obt_valor_parametros('ESTADOS_PREAPROBADOS'))) || ''');apex.event.trigger("#TABLE_133","apexrefresh");' AS card_link,
            1 AS order_col
        FROM DUAL
        UNION ALL
        SELECT
            'Total Desembolsos',
            (SELECT TO_CHAR(COUNT(DISTINCT id_represtamo)) FROM base_data WHERE codigo_estado_actual = 'CRD'),
            (SELECT 'Monto RD$ ' || TO_CHAR(NVL(SUM(monto_desembolsado), 0), 'FM9G999G999G990D00', 'NLS_NUMERIC_CHARACTERS=''.,''') FROM base_data WHERE codigo_estado_actual = 'CRD'),
            'fa-check-circle',
            'u-color-5',
            'javascript:apex.item("P133_ESTADO").setValue(''CRD'');apex.event.trigger("#TABLE_133","apexrefresh");',
            2
        FROM DUAL
        UNION ALL
        SELECT
            'Efectividad (Rango)',
            CASE
                WHEN preaprobados_r = 0 THEN '0.00%'
                ELSE TO_CHAR(TRUNC(desembolsados_r / preaprobados_r * 100, 2), 'FM990.00') || '%'
            END,
            'Des: ' || desembolsados_r || ' / Pre: ' || preaprobados_r,
            'fa-percent',
            'u-color-10',
            'javascript:void(0);',
            3
        FROM efectividad_rango
        UNION ALL
        SELECT
            'Desembolsos Firma Electrónica',
            (SELECT TO_CHAR(COUNT(DISTINCT id_represtamo)) FROM base_data WHERE codigo_estado_actual = 'CRD' AND canal_desembolso_determinado = 'Digital (con firma)'),
            (SELECT 'Monto RD$ ' || TO_CHAR(NVL(SUM(monto_desembolsado), 0), 'FM9G999G999G990D00', 'NLS_NUMERIC_CHARACTERS=''.,''') FROM base_data WHERE codigo_estado_actual = 'CRD' AND canal_desembolso_determinado = 'Digital (con firma)'),
            'fa-mobile-alt',
            'u-color-15',
            'javascript:apex.item("P133_ESTADO").setValue(''CRD'');apex.event.trigger("#TABLE_133","apexrefresh");',
            4
        FROM DUAL
        UNION ALL
        SELECT
            'Desembolsos Tradicionales',
            (SELECT TO_CHAR(COUNT(DISTINCT id_represtamo)) FROM base_data WHERE codigo_estado_actual = 'CRD' AND canal_desembolso_determinado = 'Sucursal (tradicional)'),
            (SELECT 'Monto RD$ ' || TO_CHAR(NVL(SUM(monto_desembolsado), 0), 'FM9G999G999G990D00', 'NLS_NUMERIC_CHARACTERS=''.,''') FROM base_data WHERE codigo_estado_actual = 'CRD' AND canal_desembolso_determinado = 'Sucursal (tradicional)'),
            'fa-building',
            'u-color-16',
            'javascript:apex.item("P133_ESTADO").setValue(''CRD'');apex.event.trigger("#TABLE_133","apexrefresh");',
            5
        FROM DUAL
        UNION ALL
        SELECT
            'Créditos Cancelados',
            (SELECT TO_CHAR(COUNT(DISTINCT id_represtamo)) FROM base_data WHERE codigo_estado_actual = 'CC'),
            (SELECT 'Monto RD$ ' || TO_CHAR(NVL(SUM(mto_preaprobado), 0), 'FM9G999G999G990D00', 'NLS_NUMERIC_CHARACTERS=''.,''') FROM base_data WHERE codigo_estado_actual = 'CC'),
            'fa-times-circle-o',
            'u-color-7',
            'javascript:apex.item("P133_ESTADO").setValue(''CC'');apex.event.trigger("#TABLE_133","apexrefresh");',
            6
        FROM DUAL
        UNION ALL
        SELECT
            'Link Vencido',
            (SELECT TO_CHAR(COUNT(DISTINCT id_represtamo)) FROM base_data WHERE codigo_estado_actual = 'AN'),
            (SELECT 'Monto RD$ ' || TO_CHAR(NVL(SUM(mto_preaprobado), 0), 'FM9G999G999G990D00', 'NLS_NUMERIC_CHARACTERS=''.,''') FROM base_data WHERE codigo_estado_actual = 'AN'),
            'fa-chain-broken',
            'u-color-8',
            'javascript:apex.item("P133_ESTADO").setValue(''AN'');apex.event.trigger("#TABLE_133","apexrefresh");',
            7
        FROM DUAL
        UNION ALL
        SELECT
            'Créditos Anulados',
            (SELECT TO_CHAR(COUNT(DISTINCT id_represtamo)) FROM base_data WHERE codigo_estado_actual = 'CRN'),
            (SELECT 'Monto RD$ ' || TO_CHAR(NVL(SUM(mto_preaprobado), 0), 'FM9G999G999G990D00', 'NLS_NUMERIC_CHARACTERS=''.,''') FROM base_data WHERE codigo_estado_actual = 'CRN'),
            'fa-ban',
            'u-color-9',
            'javascript:apex.item("P133_ESTADO").setValue(''CRN'');apex.event.trigger("#TABLE_133","apexrefresh");',
            8
        FROM DUAL
    )
ORDER BY
    order_col;