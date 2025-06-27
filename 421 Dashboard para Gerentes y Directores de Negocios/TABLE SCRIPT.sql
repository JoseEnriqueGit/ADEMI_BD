WITH latest_bitacora AS (
    SELECT
        b.id_represtamo,
        b.codigo_estado,
        b.fecha_adicion,
        b.adicionado_por,
        ROW_NUMBER() OVER (
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
base_table AS (
    SELECT
        r.fecha_proceso,
        s.id_represtamo                                        AS "ID Représtamo",
        r.codigo_cliente                                       AS "Código Cliente",
        pa.obt_nombre_persona(r.codigo_cliente)                AS "Cliente",
        s.identificacion                                       AS "Identificación",
        a_canal.valor                                          AS "Celular",
        r.no_credito                                           AS "Crédito Anterior",
        s.no_credito                                           AS "Crédito Nuevo",
        r.mto_preaprobado                                      AS "Monto Preaprobado",
        tc.tipo_credito || ' - ' || tc.descripcion             AS "Tipo de Crédito",
        pr.pr_pkg_represtamos.f_obt_descripcion_estado(r.estado) AS "Estado",
        c.f_primer_desembolso                                  AS "Fecha de Desembolso",
        c.monto_desembolsado                                   AS "Monto Desembolsado",
        CASE
            WHEN r.id_carga_dirigida IS NOT NULL          THEN 'Carga Dirigida'
            WHEN r.id_repre_campana_especiales IS NOT NULL THEN 'Campañas Especiales'
            ELSE 'Représtamo Digital'
        END                                                   AS "Tipo de Préstamo",
        CASE
            WHEN s.email IS NOT NULL THEN 'Sí' ELSE 'No'
        END                                                   AS "Correo Electrónico",
        CASE
            WHEN r.estado = 'CRD' THEN
                CASE
                    WHEN hcs.id_represtamo IS NOT NULL THEN 'Digital (con firma)'
                    ELSE 'Sucursal (tradicional)'
                END
        END                                                   AS "Tipo de Desembolso",
        NVL(c.codigo_agencia,   h.codigo_agencia)             AS "Código Sucursal",
        ag.descripcion                                        AS "Oficina",
        pa.obt_desc_zona(1, ag.cod_zona)                      AS "Zona",
        NVL(c.codigo_ejecutivo, h.codigo_ejecutivo)           AS "Código Oficial",
        pa.obt_nombre_empleado(NVL(c.codigo_empresa, h.codigo_empresa),
                               NVL(c.codigo_ejecutivo, h.codigo_ejecutivo)) AS "Oficial",
        pa.obt_nombre_empleado(r.codigo_empresa, lb.adicionado_por)         AS "Atendido Por",
        r.estado                                              AS codigo_estado_para_filtro,
        lb.fecha_adicion                                      AS "FECHA_ESTADO"
    FROM pr.pr_represtamos r
    LEFT JOIN pr.pr_solicitud_represtamo s
        ON s.id_represtamo = r.id_represtamo
        AND s.codigo_empresa = r.codigo_empresa
    LEFT JOIN pr.pr_creditos c
        ON c.no_credito   = r.no_credito
        AND c.codigo_empresa = r.codigo_empresa
    LEFT JOIN pr.pr_creditos_hi h
        ON h.no_credito   = r.no_credito
        AND h.codigo_empresa = r.codigo_empresa
    LEFT JOIN pa.agencia ag
        ON ag.cod_empresa = r.codigo_empresa
        AND ag.cod_agencia = NVL(c.codigo_agencia, h.codigo_agencia)
    LEFT JOIN pr.pr_tipo_credito tc
        ON tc.codigo_empresa = r.codigo_empresa
        AND tc.tipo_credito  = NVL(s.tipo_credito, NVL(c.tipo_credito, h.tipo_credito))
    LEFT JOIN pr.pr_canales_represtamo a_canal
        ON a_canal.id_represtamo = r.id_represtamo
        AND a_canal.canal = 1
    JOIN pa.empleados p
        ON ag.gerente = p.id_empleado
        AND ag.cod_empresa = TO_NUMBER(p.cod_empresa)
    LEFT JOIN latest_bitacora lb
        ON lb.id_represtamo = r.id_represtamo
        AND lb.rn = 1
    LEFT JOIN has_cry_status hcs
        ON hcs.id_represtamo = r.id_represtamo
    WHERE
        SUBSTR(p.email1, 1, INSTR(p.email1, '@') - 1) = 'MAMATOS'
        AND p.esta_activo = 'S'
        AND NOT EXISTS (
            SELECT 1
            FROM   pr_carga_direccionada cd
            WHERE  cd.no_credito = r.no_credito
            AND    cd.estado = 'F'
            AND    TRUNC(cd.fecha_adicion) = TRUNC(r.fecha_adicion)
        )
        AND (
            :P133_FROM_DATE IS NULL
            OR lb.fecha_adicion >= TRUNC(TO_DATE(:P133_FROM_DATE, 'DD/MM/YYYY HH24:MI:SS'))
        )
        AND (
            :P133_TO_DATE IS NULL
            OR lb.fecha_adicion <  TRUNC(TO_DATE(:P133_TO_DATE,   'DD/MM/YYYY HH24:MI:SS')) + 1
        )
)
SELECT
    "FECHA_PROCESO",
    "ID Représtamo",
    "Código Cliente",
    "Cliente",
    "Identificación",
    "Celular",
    "Crédito Anterior",
    "Crédito Nuevo",
    "Monto Preaprobado",
    "Tipo de Crédito",
    "Estado",
    "Fecha de Desembolso",
    "Monto Desembolsado",
    "Tipo de Préstamo",
    "Correo Electrónico",
    "Tipo de Desembolso",
    "Código Sucursal",
    "Oficina",
    "Zona",
    "Código Oficial",
    "Oficial"
FROM base_table
WHERE (
        :P133_ESTADO IS NULL
        OR codigo_estado_para_filtro IN (
               SELECT column_value
               FROM   TABLE(apex_string.split(:P133_ESTADO, ','))
           )
    )
  AND (
        :P133_TIPO_DESEMBOLSO IS NULL
        OR "Tipo de Desembolso" = :P133_TIPO_DESEMBOLSO
    )
ORDER BY
    "FECHA_ESTADO" DESC,
    "ID Représtamo" DESC;
