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
        r.fecha_proceso,
        c.monto_desembolsado,
        c.f_primer_desembolso AS fecha_desembolso,
        r.estado AS codigo_estado_actual,
        CASE
            WHEN r.estado = 'CRD' THEN CASE
                WHEN hcs.id_represtamo IS NOT NULL THEN 'Digital (con firma)'
                ELSE 'Sucursal (tradicional)'
            END
        END AS canal_desembolso_determinado
    FROM
        pr.pr_represtamos r
    LEFT JOIN pr.pr_solicitud_represtamo s
        ON r.id_represtamo = s.id_represtamo AND r.codigo_empresa = s.codigo_empresa
    LEFT JOIN pr.pr_creditos c
        ON c.no_credito = r.no_credito AND c.codigo_empresa = r.codigo_empresa
    LEFT JOIN pa.agencia ag
        ON ag.cod_empresa = r.codigo_empresa AND ag.cod_agencia = c.codigo_agencia
    JOIN pa.empleados p
        ON ag.gerente = p.id_empleado AND ag.cod_empresa = TO_NUMBER(p.cod_empresa)
    LEFT JOIN latest_bitacora lb
        ON lb.id_represtamo = r.id_represtamo AND lb.rn = 1
    LEFT JOIN has_cry_status hcs
        ON hcs.id_represtamo = r.id_represtamo
    WHERE
        SUBSTR(p.email1, 1, INSTR(p.email1, '@') - 1) = 'MAMATOS'
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
            OR lb.fecha_adicion >= TRUNC(TO_DATE(:P133_FROM_DATE, 'DD/MM/YYYY HH24:MI:SS'))
        )
        AND (
            :P133_TO_DATE IS NULL
            OR lb.fecha_adicion < TRUNC(TO_DATE(:P133_TO_DATE, 'DD/MM/YYYY HH24:MI:SS')) + 1
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
    card_modifiers,
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
            NULL AS card_modifiers,
            'javascript:apex.item("P133_TIPO_DESEMBOLSO").setValue(null);apex.item("P133_ESTADO").setValue(''' || (SELECT LISTAGG(column_value, ',') WITHIN GROUP(ORDER BY NULL) FROM TABLE(pr.pr_pkg_represtamos.f_obt_valor_parametros('ESTADOS_PREAPROBADOS'))) || ''');apex.event.trigger("#TABLE_133","apexrefresh");' AS card_link,
            1 AS order_col
        FROM DUAL
        UNION ALL
        SELECT
            'Total Desembolsos',
            (SELECT TO_CHAR(COUNT(DISTINCT id_represtamo)) FROM base_data WHERE codigo_estado_actual = 'CRD'),
            (SELECT 'Monto RD$ ' || TO_CHAR(NVL(SUM(monto_desembolsado), 0), 'FM9G999G999G990D00', 'NLS_NUMERIC_CHARACTERS=''.,''') FROM base_data WHERE codigo_estado_actual = 'CRD'),
            'fa-check-circle',
            'u-color-5',
            NULL,
            'javascript:apex.item("P133_TIPO_DESEMBOLSO").setValue(null);apex.item("P133_ESTADO").setValue(''CRD'');apex.event.trigger("#TABLE_133","apexrefresh");',
            2
        FROM DUAL
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
            NULL,
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
            'card-desembolso' AS card_modifiers,
            'javascript:apex.item("P133_ESTADO").setValue(null);apex.item("P133_TIPO_DESEMBOLSO").setValue(''Digital (con firma)'');apex.event.trigger("#TABLE_133","apexrefresh");',
            4
        FROM DUAL
        UNION ALL
        SELECT
            'Desembolsos firma Tradicional',
            (SELECT TO_CHAR(COUNT(DISTINCT id_represtamo)) FROM base_data WHERE codigo_estado_actual = 'CRD' AND canal_desembolso_determinado = 'Sucursal (tradicional)'),
            (SELECT 'Monto RD$ ' || TO_CHAR(NVL(SUM(monto_desembolsado), 0), 'FM9G999G999G990D00', 'NLS_NUMERIC_CHARACTERS=''.,''') FROM base_data WHERE codigo_estado_actual = 'CRD' AND canal_desembolso_determinado = 'Sucursal (tradicional)'),
            'fa-building',
            'u-color-16',
            'card-desembolso' AS card_modifiers,
            'javascript:apex.item("P133_ESTADO").setValue(null);apex.item("P133_TIPO_DESEMBOLSO").setValue(''Sucursal (tradicional)'');apex.event.trigger("#TABLE_133","apexrefresh");',
            5
        FROM DUAL
        UNION ALL
        SELECT
            'Créditos Cancelados',
            (SELECT TO_CHAR(COUNT(DISTINCT id_represtamo)) FROM base_data WHERE codigo_estado_actual = 'CC'),
            (SELECT 'Monto RD$ ' || TO_CHAR(NVL(SUM(mto_preaprobado), 0), 'FM9G999G999G990D00', 'NLS_NUMERIC_CHARACTERS=''.,''') FROM base_data WHERE codigo_estado_actual = 'CC'),
            'fa-times-circle-o',
            'u-color-7',
            NULL,
            'javascript:apex.item("P133_TIPO_DESEMBOLSO").setValue(null);apex.item("P133_ESTADO").setValue(''CC'');apex.event.trigger("#TABLE_133","apexrefresh");',
            6
        FROM DUAL
        UNION ALL
        SELECT
            'Link Vencido',
            (SELECT TO_CHAR(COUNT(DISTINCT id_represtamo)) FROM base_data WHERE codigo_estado_actual = 'AN'),
            (SELECT 'Monto RD$ ' || TO_CHAR(NVL(SUM(mto_preaprobado), 0), 'FM9G999G999G990D00', 'NLS_NUMERIC_CHARACTERS=''.,''') FROM base_data WHERE codigo_estado_actual = 'AN'),
            'fa-chain-broken',
            'u-color-8',
            NULL,
            'javascript:apex.item("P133_TIPO_DESEMBOLSO").setValue(null);apex.item("P133_ESTADO").setValue(''AN'');apex.event.trigger("#TABLE_133","apexrefresh");',
            7
        FROM DUAL
        UNION ALL
        SELECT
            'Créditos Anulados',
            (SELECT TO_CHAR(COUNT(DISTINCT id_represtamo)) FROM base_data WHERE codigo_estado_actual = 'CRN'),
            (SELECT 'Monto RD$ ' || TO_CHAR(NVL(SUM(mto_preaprobado), 0), 'FM9G999G999G990D00', 'NLS_NUMERIC_CHARACTERS=''.,''') FROM base_data WHERE codigo_estado_actual = 'CRN'),
            'fa-ban',
            'u-color-9',
            NULL,
            'javascript:apex.item("P133_TIPO_DESEMBOLSO").setValue(null);apex.item("P133_ESTADO").setValue(''CRN'');apex.event.trigger("#TABLE_133","apexrefresh");',
            8
        FROM DUAL
    )
ORDER BY
    order_col;