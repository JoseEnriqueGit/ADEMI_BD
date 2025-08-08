DROP VIEW PR.PR_V_ENVIO_REPRESTAMOS;
 
CREATE OR REPLACE FORCE VIEW PR.PR_V_ENVIO_REPRESTAMOS
(ID_REPRESTAMO, NUMERO_IDENTIFICACION, CANAL, NOMBRES, APELLIDOS, 
MTO_PREAPROBADO, CONTACTO, SUBJECT_EMAIL, TEXTO_MENSAJE, FECHA_PROCESO, 
FECHA_VENCIMIENTO, ESTADO)
BEQUEATH DEFINER
AS 
select r.id_represtamo,
           c.numero_identificacion,
           cr.canal,
           c.nombres,
           c.primer_apellido || ' ' || c.segundo_apellido apellidos,
           r.mto_preaprobado,
           cr.valor contacto,
           case cr.canal when '2' then pr.pr_pkg_represtamos.f_obt_subject_email(r.id_represtamo) else null end subject_email,
           pr.pr_pkg_represtamos.f_obt_body_mensaje(r.id_represtamo, cr.canal) texto_mensaje,
           r.fecha_proceso,
           --R.FECHA_PROCESO + PR.PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo ('DIA_CADUCA_LINK') Fecha_Vencimiento,
           trunc(last_day(r.fecha_proceso)) fecha_vencimiento,
           r.estado
    from pr.pr_represtamos r, clientes_b2000 c, pr.pr_canales_represtamo cr
    where r.codigo_empresa = pr.pr_pkg_represtamos.f_obt_empresa_represtamo
    and   r.id_represtamo = r.id_represtamo || ''
    and   r.estado = 'NP'
    and   c.codigo_empresa = r.codigo_empresa
    and   c.codigo_cliente = r.codigo_cliente
    and   cr.codigo_empresa = r.codigo_empresa
    and   cr.id_represtamo = r.id_represtamo
    and   cr.canal = cr.canal || ''
    and   exists
              (select 1
               from pr.pr_solicitud_represtamo o
               where o.codigo_empresa = r.codigo_empresa
               and   o.id_represtamo = r.id_represtamo)
    and   cr.canal in (select pr.pr_pkg_represtamos.f_obt_parametro_represtamo(column_value) from table(pr.pr_pkg_represtamos.f_obt_valor_parametros('CANALES_HABILITADOS')));
 
 
DROP PUBLIC SYNONYM PR_V_ENVIO_REPRESTAMOS;
 
CREATE OR REPLACE PUBLIC SYNONYM PR_V_ENVIO_REPRESTAMOS FOR PR.PR_V_ENVIO_REPRESTAMOS;