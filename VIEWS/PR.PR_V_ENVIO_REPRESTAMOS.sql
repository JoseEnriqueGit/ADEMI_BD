DROP VIEW PR.PR_V_ENVIO_REPRESTAMOS;
 
CREATE OR REPLACE FORCE VIEW PR.PR_V_ENVIO_REPRESTAMOS
( ID_REPRESTAMO,
  NUMERO_IDENTIFICACION,
  CANAL,
  NOMBRES,
  APELLIDOS,
  MTO_PREAPROBADO,
  CONTACTO,
  SUBJECT_EMAIL,
  TEXTO_MENSAJE,
  FECHA_PROCESO,
  FECHA_VENCIMIENTO,
  ESTADO )
BEQUEATH DEFINER
AS
WITH params AS (
  SELECT UPPER(TRIM(column_value)) AS val
  FROM   TABLE(pr.pr_pkg_represtamos.f_obt_valor_parametros('CANALES_HABILITADOS'))
)
SELECT
    r.id_represtamo,
    c.numero_identificacion,
    cr.canal,
    c.nombres,
    c.primer_apellido || ' ' || c.segundo_apellido AS apellidos,
    r.mto_preaprobado,
    cr.valor AS contacto,
    CASE
      WHEN cr.canal = pr.pr_pkg_represtamos.f_obt_parametro_represtamo('CANAL_EMAIL')
      THEN pr.pr_pkg_represtamos.f_obt_subject_email(r.id_represtamo)
      ELSE NULL
    END AS subject_email,
    pr.pr_pkg_represtamos.f_obt_body_mensaje(r.id_represtamo, cr.canal) AS texto_mensaje,
    r.fecha_proceso,
    TRUNC(LAST_DAY(r.fecha_proceso)) AS fecha_vencimiento,
    r.estado
FROM pr.pr_represtamos r
JOIN clientes_b2000 c
  ON c.codigo_empresa = r.codigo_empresa
AND c.codigo_cliente = r.codigo_cliente
JOIN pr.pr_canales_represtamo cr
  ON cr.codigo_empresa = r.codigo_empresa
AND cr.id_represtamo = r.id_represtamo
WHERE r.codigo_empresa = pr.pr_pkg_represtamos.f_obt_empresa_represtamo
  AND r.id_represtamo = r.id_represtamo || ''   -- mismo control que tenía la vista
  AND cr.canal       = cr.canal || ''
  AND r.estado       = 'NP'
  AND EXISTS (
        SELECT 1 FROM pr.pr_solicitud_represtamo o
        WHERE o.codigo_empresa = r.codigo_empresa
          AND o.id_represtamo  = r.id_represtamo
      )
  AND (
      /* EMAIL normal */
      ( cr.canal = pr.pr_pkg_represtamos.f_obt_parametro_represtamo('CANAL_EMAIL')
        AND r.id_carga_dirigida IS NULL
        AND r.id_repre_campana_especiales IS NULL
        AND EXISTS (SELECT 1 FROM params p WHERE p.val = 'CANAL_EMAIL')
      )
      OR
      /* SMS normal */
      ( cr.canal = pr.pr_pkg_represtamos.f_obt_parametro_represtamo('CANAL_SMS')
        AND r.id_carga_dirigida IS NULL
        AND r.id_repre_campana_especiales IS NULL
        AND EXISTS (SELECT 1 FROM params p WHERE p.val = 'CANAL_SMS')
      )
      OR
      /* SMS por CARGA DIRIGIDA */
      ( cr.canal = pr.pr_pkg_represtamos.f_obt_parametro_represtamo('CANAL_SMS')
        AND r.id_carga_dirigida IS NOT NULL
        AND EXISTS (SELECT 1 FROM params p WHERE p.val = 'CANAL_CARGA_DIRIGIDA')
      )
      OR
      /* SMS por CAMPANA ESPECIAL */
      ( cr.canal = pr.pr_pkg_represtamos.f_obt_parametro_represtamo('CANAL_SMS')
        AND r.id_repre_campana_especiales IS NOT NULL
        AND EXISTS (SELECT 1 FROM params p WHERE p.val = 'CANAL_CAMPANA_ESPECIAL')
      )
  );
 
-- Sinónimo público
DROP PUBLIC SYNONYM PR_V_ENVIO_REPRESTAMOS;
CREATE OR REPLACE PUBLIC SYNONYM PR_V_ENVIO_REPRESTAMOS FOR PR.PR_V_ENVIO_REPRESTAMOS;