-- ============================================================================
-- ANTES: Query original del dashboard de Represtamo Digital (BackOffice)
-- ============================================================================
-- Estado: Reemplazado
-- Cambios respecto a este: Ver after.sql
--   1. Card 1 "Total Preaprobados": lista de estados de 8 -> 17 elementos
--   2. Card 9 "CANAL PENDIENTE" -> renombrada a "Disponible", filtro de 1 -> 3 estados
-- ============================================================================

WITH latest_bitacora AS (
    SELECT
        b.id_represtamo,
        b.codigo_estado,
        b.fecha_adicion,
        ROW_NUMBER() OVER(
            PARTITION BY b.id_represtamo
            ORDER BY b.id_bitacora DESC, b.fecha_adicion DESC
        ) AS rn
    FROM pr.pr_bitacora_represtamo b
),
has_cry_status AS (
    SELECT DISTINCT id_represtamo
    FROM pr.pr_bitacora_represtamo
    WHERE codigo_estado = 'CRY'
),
base_data AS (
    SELECT
        r.id_represtamo,
        r.mto_preaprobado,
        r.fecha_proceso,
        NVL(c.monto_desembolsado, h.monto_desembolsado) AS monto_desembolsado,
        NVL(c.f_primer_desembolso, h.f_primer_desembolso) AS fecha_desembolso,
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
               ON r.id_represtamo  = s.id_represtamo
              AND r.codigo_empresa = s.codigo_empresa
        LEFT JOIN pr.pr_creditos c
               ON c.no_credito     = r.no_credito
              AND c.codigo_empresa = r.codigo_empresa
        LEFT JOIN pr.pr_creditos_hi h
               ON h.no_credito     = r.no_credito
              AND h.codigo_empresa = r.codigo_empresa
        LEFT JOIN pa.agencia ag
               ON ag.cod_empresa   = r.codigo_empresa
              AND ag.cod_agencia   = NVL(c.codigo_agencia, h.codigo_agencia)

        LEFT JOIN pa.empleados p
          ON ag.gerente     = p.id_empleado
         AND ag.cod_empresa = TO_NUMBER(p.cod_empresa)

        LEFT JOIN has_cry_status hcs
               ON hcs.id_represtamo = r.id_represtamo
    WHERE
        (:P133_FROM_DATE IS NULL OR r.fecha_proceso >= TRUNC(TO_DATE(:P133_FROM_DATE,'DD/MM/YYYY HH24:MI:SS')))
        AND (:P133_TO_DATE IS NULL OR r.fecha_proceso   <  TRUNC(TO_DATE(:P133_TO_DATE  ,'DD/MM/YYYY HH24:MI:SS')) + 1)

        AND (
              /* CASO A: ES DIRECTOR O ES VIP (Inmunidad) */
              (
                ( :P133_IS_DIRECTOR = 'Y'
                  OR (SELECT COUNT(*) FROM PA.PA_PARAMETROS_MVP
                       WHERE CODIGO_PARAMETRO = 'USUARIOS_VIP_DASHBOARD'
                       AND INSTR(',' || VALOR || ',', ',' || UPPER(:APP_USER) || ',') > 0) > 0
                )
                AND ( :P133_ZONA    IS NULL OR ag.cod_zona    = :P133_ZONA )
                AND ( :P133_FILTRO_AGENCIA IS NULL OR ag.cod_agencia = :P133_FILTRO_AGENCIA )
              )
           OR
              /* CASO B: ES GERENTE (NO es Director Y NO es VIP) */
              (
                :P133_IS_DIRECTOR <> 'Y'
                AND (SELECT COUNT(*) FROM PA.PA_PARAMETROS_MVP
                       WHERE CODIGO_PARAMETRO = 'USUARIOS_VIP_DASHBOARD'
                       AND INSTR(',' || VALOR || ',', ',' || UPPER(:APP_USER) || ',') > 0) = 0

                AND UPPER(SUBSTR(p.email1, 1, INSTR(p.email1,'@')-1)) = UPPER(V('APP_USER'))
                AND p.esta_activo = 'S'
              )
            )
),
efectividad_rango AS (
    SELECT
        (SELECT COUNT(DISTINCT id_represtamo) FROM base_data WHERE codigo_estado_actual = 'CRD') AS desembolsados_r,
        (SELECT COUNT(DISTINCT id_represtamo) FROM base_data) AS preaprobados_r
    FROM dual
)
SELECT *
FROM (
    /* 1. TOTAL PREAPROBADOS (Estados Pendientes) */
    SELECT
        'Total Preaprobados' AS card_title,
        (SELECT TO_CHAR(COUNT(DISTINCT id_represtamo))
           FROM base_data
          WHERE codigo_estado_actual IN ('RE', 'VR', 'NP', 'CP', 'LA', 'EP', 'A', 'SC')) AS card_text,

        (SELECT 'Monto RD$ ' || TO_CHAR(NVL(SUM(mto_preaprobado), 0), 'FM9G999G999G990D00', 'NLS_NUMERIC_CHARACTERS=''.,''')
           FROM base_data
          WHERE codigo_estado_actual IN ('RE', 'VR', 'NP', 'CP', 'LA', 'EP', 'A', 'SC')) AS card_subtext,

        'fa-file-invoice-dollar' AS card_icon,
        'u-color-1' AS card_color,
        NULL AS card_modifiers,

        'javascript:apex.item("P133_TIPO_DESEMBOLSO").setValue(null);apex.item("P133_ESTADO").setValue(''RE,VR,NP,CP,LA,EP,A,SC'');apex.event.trigger("#TABLE_133","apexrefresh");' AS card_link,

        1 AS order_col
    FROM dual
    UNION ALL
    /* 2. TOTAL DESEMBOLSOS */
    SELECT
        'Total Desembolsos' AS card_title,
        (SELECT TO_CHAR(COUNT(DISTINCT id_represtamo)) FROM base_data WHERE codigo_estado_actual = 'CRD') AS card_text,
        (SELECT 'Monto RD$ ' || TO_CHAR(NVL(SUM(monto_desembolsado), 0), 'FM9G999G999G990D00', 'NLS_NUMERIC_CHARACTERS=''.,''') FROM base_data WHERE codigo_estado_actual = 'CRD') AS card_subtext,
        'fa-check-circle' AS card_icon, 'u-color-5' AS card_color, NULL AS card_modifiers,
        'javascript:apex.item("P133_TIPO_DESEMBOLSO").setValue(null);apex.item("P133_ESTADO").setValue(''CRD'');apex.event.trigger("#TABLE_133","apexrefresh");' AS card_link,
        2 AS order_col
    FROM dual
    UNION ALL
    /* 3. EFECTIVIDAD */
    SELECT
        'Efectividad' AS card_title,
        CASE WHEN preaprobados_r = 0 THEN '0.00%' ELSE TO_CHAR(TRUNC(desembolsados_r / preaprobados_r * 100, 2), 'FM990.00') || '%' END AS card_text,
        'Des: ' || desembolsados_r || ' / Pre: ' || preaprobados_r AS card_subtext,
        'fa-percent' AS card_icon, 'u-color-10' AS card_color, NULL AS card_modifiers,
        'javascript:void(0);' AS card_link, 3 AS order_col
    FROM efectividad_rango
    UNION ALL
    /* 4. DIGITAL */
    SELECT
        'Desembolsos Firma Electronica' AS card_title,
        (SELECT TO_CHAR(COUNT(DISTINCT id_represtamo)) FROM base_data WHERE codigo_estado_actual = 'CRD' AND canal_desembolso_determinado = 'Digital (con firma)') AS card_text,
        (SELECT 'Monto RD$ ' || TO_CHAR(NVL(SUM(monto_desembolsado), 0), 'FM9G999G999G990D00', 'NLS_NUMERIC_CHARACTERS=''.,''') FROM base_data WHERE codigo_estado_actual = 'CRD' AND canal_desembolso_determinado = 'Digital (con firma)') AS card_subtext,
        'fa-mobile-alt' AS card_icon, 'u-color-15' AS card_color, 'card-desembolso' AS card_modifiers,
        'javascript:apex.item("P133_ESTADO").setValue(null);apex.item("P133_TIPO_DESEMBOLSO").setValue(''Digital (con firma)'');apex.event.trigger("#TABLE_133","apexrefresh");' AS card_link,
        4 AS order_col
    FROM dual
    UNION ALL
    /* 5. TRADICIONAL */
    SELECT
        'Desembolsos firma Tradicional' AS card_title,
        (SELECT TO_CHAR(COUNT(DISTINCT id_represtamo)) FROM base_data WHERE codigo_estado_actual = 'CRD' AND canal_desembolso_determinado = 'Sucursal (tradicional)') AS card_text,
        (SELECT 'Monto RD$ ' || TO_CHAR(NVL(SUM(monto_desembolsado), 0), 'FM9G999G999G990D00', 'NLS_NUMERIC_CHARACTERS=''.,''') FROM base_data WHERE codigo_estado_actual = 'CRD' AND canal_desembolso_determinado = 'Sucursal (tradicional)') AS card_subtext,
        'fa-building' AS card_icon, 'u-color-16' AS card_color, 'card-desembolso' AS card_modifiers,
        'javascript:apex.item("P133_ESTADO").setValue(null);apex.item("P133_TIPO_DESEMBOLSO").setValue(''Sucursal (tradicional)'');apex.event.trigger("#TABLE_133","apexrefresh");' AS card_link,
        5 AS order_col
    FROM dual
    UNION ALL
    /* 6. CANCELADOS */
    SELECT
        'Creditos Cancelados' AS card_title,
        (SELECT TO_CHAR(COUNT(DISTINCT id_represtamo)) FROM base_data WHERE codigo_estado_actual = 'CC') AS card_text,
        (SELECT 'Monto RD$ ' || TO_CHAR(NVL(SUM(mto_preaprobado), 0), 'FM9G999G999G990D00', 'NLS_NUMERIC_CHARACTERS=''.,''') FROM base_data WHERE codigo_estado_actual = 'CC') AS card_subtext,
        'fa-times-circle-o' AS card_icon, 'u-color-7' AS card_color, NULL AS card_modifiers,
        'javascript:apex.item("P133_TIPO_DESEMBOLSO").setValue(null);apex.item("P133_ESTADO").setValue(''CC'');apex.event.trigger("#TABLE_133","apexrefresh");' AS card_link,
        6 AS order_col
    FROM dual
    UNION ALL
    /* 7. VENCIDOS */
    SELECT
        'Link Vencido' AS card_title,
        (SELECT TO_CHAR(COUNT(DISTINCT id_represtamo)) FROM base_data WHERE codigo_estado_actual = 'AN') AS card_text,
        (SELECT 'Monto RD$ ' || TO_CHAR(NVL(SUM(mto_preaprobado), 0), 'FM9G999G999G990D00', 'NLS_NUMERIC_CHARACTERS=''.,''') FROM base_data WHERE codigo_estado_actual = 'AN') AS card_subtext,
        'fa-chain-broken' AS card_icon, 'u-color-8' AS card_color, NULL AS card_modifiers,
        'javascript:apex.item("P133_TIPO_DESEMBOLSO").setValue(null);apex.item("P133_ESTADO").setValue(''AN'');apex.event.trigger("#TABLE_133","apexrefresh");' AS card_link,
        7 AS order_col
    FROM dual
    UNION ALL
    /* 8. ANULADOS */
    SELECT
        'Creditos Anulados' AS card_title,
        (SELECT TO_CHAR(COUNT(DISTINCT id_represtamo)) FROM base_data WHERE codigo_estado_actual = 'CRN') AS card_text,
        (SELECT 'Monto RD$ ' || TO_CHAR(NVL(SUM(mto_preaprobado), 0), 'FM9G999G999G990D00', 'NLS_NUMERIC_CHARACTERS=''.,''') FROM base_data WHERE codigo_estado_actual = 'CRN') AS card_subtext,
        'fa-ban' AS card_icon, 'u-color-9' AS card_color, NULL AS card_modifiers,
        'javascript:apex.item("P133_TIPO_DESEMBOLSO").setValue(null);apex.item("P133_ESTADO").setValue(''CRN'');apex.event.trigger("#TABLE_133","apexrefresh");' AS card_link,
        8 AS order_col
    FROM dual

    /* === NUEVAS CARDS AGREGADAS === */

    UNION ALL
    /* 9. CANALES PENDIENTE (CP) */
    SELECT
        'CANAL PENDIENTE (ACTUALIZAR TELEFONO)
' AS card_title,
        (SELECT TO_CHAR(COUNT(DISTINCT id_represtamo)) FROM base_data WHERE codigo_estado_actual = 'CP') AS card_text,
        (SELECT 'Monto RD$ ' || TO_CHAR(NVL(SUM(mto_preaprobado), 0), 'FM9G999G999G990D00', 'NLS_NUMERIC_CHARACTERS=''.,''') FROM base_data WHERE codigo_estado_actual = 'CP') AS card_subtext,
        'fa-share-alt' AS card_icon,
        'u-color-2' AS card_color,
        'card-pendiente' AS card_modifiers,
        'javascript:apex.item("P133_TIPO_DESEMBOLSO").setValue(null);apex.item("P133_ESTADO").setValue(''CP'');apex.event.trigger("#TABLE_133","apexrefresh");' AS card_link,
        9 AS order_col
    FROM dual
    UNION ALL
    /* 10. NOTIFICACION PENDIENTE (NP) */
    SELECT
        'Notificacion Pendiente' AS card_title,
        (SELECT TO_CHAR(COUNT(DISTINCT id_represtamo)) FROM base_data WHERE codigo_estado_actual = 'NP') AS card_text,
        (SELECT 'Monto RD$ ' || TO_CHAR(NVL(SUM(mto_preaprobado), 0), 'FM9G999G999G990D00', 'NLS_NUMERIC_CHARACTERS=''.,''') FROM base_data WHERE codigo_estado_actual = 'NP') AS card_subtext,
        'fa-bell-o' AS card_icon,
        'u-color-3' AS card_color,
        'card-pendiente' AS card_modifiers,
        'javascript:apex.item("P133_TIPO_DESEMBOLSO").setValue(null);apex.item("P133_ESTADO").setValue(''NP'');apex.event.trigger("#TABLE_133","apexrefresh");' AS card_link,
        10 AS order_col
    FROM dual
)
ORDER BY order_col;
