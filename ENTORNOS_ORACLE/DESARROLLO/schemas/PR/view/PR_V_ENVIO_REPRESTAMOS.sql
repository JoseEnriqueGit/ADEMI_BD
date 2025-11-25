CREATE OR REPLACE FORCE VIEW PR.PR_V_ENVIO_REPRESTAMOS (
        ID_REPRESTAMO,
        NUMERO_IDENTIFICACION,
        CANAL,
        CANAL_DESC,
        NOMBRES,
        APELLIDOS,
        MTO_PREAPROBADO,
        CONTACTO,
        SUBJECT_EMAIL,
        TEXTO_MENSAJE,
        FECHA_PROCESO,
        FECHA_VENCIMIENTO,
        ESTADO
    ) BEQUEATH DEFINER AS
-- Precalculamos una sola vez los valores de los parámetros y la lista de canales habilitados
WITH cfg AS (
    SELECT pr.pr_pkg_represtamos.f_obt_parametro_represtamo('CANAL_EMAIL') AS canal_email,
           pr.pr_pkg_represtamos.f_obt_parametro_represtamo('CANAL_SMS')   AS canal_sms
    FROM dual
),
params AS (
    SELECT UPPER(TRIM(column_value)) AS val
    FROM TABLE(pr.pr_pkg_represtamos.f_obt_valor_parametros('CANALES_HABILITADOS'))
),
base AS (
    SELECT r.id_represtamo,
           r.codigo_empresa,
           r.codigo_cliente,
           r.id_carga_dirigida,
           r.id_repre_campana_especiales,
           r.mto_preaprobado,
           r.fecha_proceso,
           r.estado,
           c.numero_identificacion,
           c.nombres,
           c.primer_apellido,
           c.segundo_apellido,
           cr.canal,
           cr.valor,
           CASE
               WHEN cr.canal = cfg.canal_email
                    AND r.id_carga_dirigida IS NULL
                    AND r.id_repre_campana_especiales IS NULL THEN 'CANAL_EMAIL'
               WHEN cr.canal = cfg.canal_sms
                    AND r.id_carga_dirigida IS NOT NULL THEN 'CANAL_CARGA_DIRIGIDA'
               WHEN cr.canal = cfg.canal_sms
                    AND r.id_repre_campana_especiales IS NOT NULL THEN 'CANAL_CAMPANA_ESPECIAL'
               WHEN cr.canal = cfg.canal_sms
                    AND r.id_carga_dirigida IS NULL
                    AND r.id_repre_campana_especiales IS NULL THEN 'CANAL_SMS'
           END AS canal_desc
    FROM pr.pr_represtamos r
    JOIN clientes_b2000 c
      ON c.codigo_empresa = r.codigo_empresa
     AND c.codigo_cliente = r.codigo_cliente
    JOIN pr.pr_canales_represtamo cr
      ON cr.codigo_empresa = r.codigo_empresa
     AND cr.id_represtamo = r.id_represtamo
    CROSS JOIN cfg
    WHERE r.codigo_empresa = pr.pr_pkg_represtamos.f_obt_empresa_represtamo
      AND r.estado = 'NP'
      AND EXISTS (
          SELECT 1
          FROM pr.pr_solicitud_represtamo o
          WHERE o.codigo_empresa = r.codigo_empresa
            AND o.id_represtamo = r.id_represtamo
      )
)
SELECT b.id_represtamo,
       b.numero_identificacion,
       b.canal,
       b.canal_desc,
       b.nombres,
       b.primer_apellido || ' ' || b.segundo_apellido AS apellidos,
       b.mto_preaprobado,
       b.valor AS contacto,
       CASE
           WHEN b.canal_desc = 'CANAL_EMAIL' THEN pr.pr_pkg_represtamos.f_obt_subject_email(b.id_represtamo)
       END AS subject_email,
       pr.pr_pkg_represtamos.f_obt_body_mensaje(b.id_represtamo, b.canal) AS texto_mensaje,
       b.fecha_proceso,
       TRUNC(LAST_DAY(b.fecha_proceso)) AS fecha_vencimiento,
       b.estado
FROM base b
WHERE b.canal_desc IS NOT NULL
  AND EXISTS (
      SELECT 1
      FROM params p
      WHERE p.val = b.canal_desc
  );
