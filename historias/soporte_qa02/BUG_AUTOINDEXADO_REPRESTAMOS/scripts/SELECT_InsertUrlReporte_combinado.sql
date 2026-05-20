-- =============================================================================
-- SELECT corregido para InsertUrlReporte (inner subquery)
--
-- Cambios sobre el original de QA02:
--   1. Agregar 'Represtamo' al IN('Normal') en todos los campos
--   2. Agregar CASE por url_reporte en tipo_identificacion, identificacion
--      y f_num_prestamo (mismo patron que codigo_agencia ya tenia)
--
-- El campo codigo_agencia ya manejaba los dos formatos correctamente.
-- Solo faltaba aplicar la misma logica a los otros 3 campos.
-- =============================================================================

-- INNER SUBQUERY (reemplazar dentro del FROM):

SELECT r.CODIGO_REPORTE,
       r.CODIGO_REFERENCIA,
       r.ORIGEN_PKM,
       -- tipo_identificacion
       -- FIX: agregar CASE por url_reporte (antes parseaba siempre igual)
       case when r.ORIGEN_PKM in ('Normal','Represtamo') then
                case when r.url_reporte is null then  -- estado 'R', referencia larga
                    nvl(ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1), '1')
                else null end                         -- estado 'P', referencia corta → no parsear
            WHEN R.ORIGEN_PKM IN ('Onboarding', 'TarjetaPC', 'Tarjeta') THEN
              CASE WHEN r.URL_REPORTE is not null THEN
                (SELECT st.COD_TIPO_ID
                   FROM TC.TC_SOLICITUD_TARJETA st
                  WHERE st.no_solicitud = ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1))
              ELSE
                nvl(ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1), '1')
              END
       end as tipo_identificacion,
       -- identificacion
       -- FIX: agregar CASE por url_reporte (antes parseaba siempre igual)
       case when r.ORIGEN_PKM in ('Normal','Represtamo') then
                case when r.url_reporte is null then  -- estado 'R', referencia larga
                    pa.formatear_identificacion(ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 2),
                                                (select mascara from tipos_id where cod_tipo_id = ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1)),
                                                'ESPA')
                else null end                         -- estado 'P', referencia corta → no parsear
            WHEN R.ORIGEN_PKM IN ('Onboarding', 'TarjetaPC', 'Tarjeta') THEN
                case when r.url_reporte is not null then
                    (select st.num_id
                       from tc.tc_solicitud_tarjeta st
                      WHERE st.no_solicitud = ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1))
                ELSE
                    pa.formatear_identificacion(ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 2),
                                                (select mascara from tipos_id where cod_tipo_id = ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1)),
                                                'ESPA')
                END
       end as identificacion,
       -- f_num_prestamo
       -- FIX: agregar CASE por url_reporte (antes siempre usaba parte 3)
       case when r.ORIGEN_PKM in ('Normal','Represtamo') then
                ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', case when r.url_reporte is null then 3 else 1 end)
            WHEN R.ORIGEN_PKM IN ('Onboarding', 'TarjetaPC', 'Tarjeta') THEN
                ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', CASE WHEN r.url_reporte is not null THEN 1 ELSE 3 END)
       end as f_num_prestamo,
       -- f_prest_anterior (sin cambios)
       ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 4) as f_prest_anterior,
       -- tipo_archivo (sin cambios)
       substr(replace(r.nombre_archivo, ':', '_'), 1, instr(replace(r.nombre_archivo, ':', '_'), '_') - 1) as tipo_archivo,
       -- id_tempfud (sin cambios)
       ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 6) as id_tempfud,
       -- nombre_archivo (sin cambios)
       replace(r.nombre_archivo, ':', '_') as nombre_archivo,
       -- codigo_agencia (sin cambios - este ya estaba bien)
       case when r.origen_pkm in ('Normal','Represtamo') then
                (select cr.codigo_agencia
                   from pr.pr_creditos cr
                  where cr.codigo_empresa = '1'
                    and cr.no_credito = ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', case when r.url_reporte is null then 3 else 1 end))
            WHEN R.ORIGEN_PKM IN ('Onboarding', 'TarjetaPC', 'Tarjeta') THEN
                (SELECT to_number(st.oficina)
                   FROM TC.TC_SOLICITUD_TARJETA st
                  WHERE st.no_solicitud = ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', CASE WHEN r.url_reporte is not null THEN 1 ELSE 3 END))
       END as codigo_agencia
    FROM PA.PA_REPORTES_AUTOMATICOS r
