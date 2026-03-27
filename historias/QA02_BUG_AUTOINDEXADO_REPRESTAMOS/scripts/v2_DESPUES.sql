-- DESPUES: SELECT interno de InsertUrlReporte (QA02 con fix Represtamo)
-- Cambios: agregar 'Represtamo' al IN() + deteccion de formato por parte(3)
-- Archivo: PA.PKG_TIPO_DOCUMENTO_PKM body.sql, lineas 584-638

        from (
                SELECT r.CODIGO_REPORTE,
                       r.CODIGO_REFERENCIA,
                       r.ORIGEN_PKM,
                           case when r.ORIGEN_PKM in ('Normal','Represtamo') then
                                case when ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 3) is not null then
                                    nvl(ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1), '1')
                                else null end
                                WHEN R.ORIGEN_PKM IN ('Onboarding', 'TarjetaPC', 'Tarjeta') THEN
                                  CASE WHEN r.URL_REPORTE is not null THEN
                                    (SELECT st.COD_TIPO_ID
                                       FROM TC.TC_SOLICITUD_TARJETA st
                                      WHERE st.no_solicitud =  ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1)
                                    )
                                    ELSE
                                        nvl(ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1), '1')
                                  END
                           end as tipo_identificacion,
                           case when r.ORIGEN_PKM in ('Normal','Represtamo') then
                                    case when ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 3) is not null then
                                        pa.formatear_identificacion(ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 2),
                                                                    (select mascara from tipos_id where cod_tipo_id = ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1)),
                                                                    'ESPA')
                                    else null end
                                WHEN R.ORIGEN_PKM IN ('Onboarding', 'TarjetaPC', 'Tarjeta') THEN
                                    case when r.url_reporte is not null then
                                        (select st.num_id
                                           from tc.tc_solicitud_tarjeta st
                                          WHERE st.no_solicitud =  ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1)
                                        )
                                    ELSE
                                        pa.formatear_identificacion(ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 2),
                                                                    (select mascara from tipos_id where cod_tipo_id = ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1)),
                                                                    'ESPA')
                                    END
                           end as identificacion,
                           case when r.ORIGEN_PKM in ('Normal','Represtamo') then
                                    ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', case when ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 3) is not null then 3 else 1 end)
                                WHEN R.ORIGEN_PKM IN ('Onboarding', 'TarjetaPC', 'Tarjeta') THEN
                                    ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', CASE WHEN r.url_reporte is not null THEN 1 ELSE 3 END)
                           end as f_num_prestamo,
                           ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 4) as f_prest_anterior,
                           substr(replace(r.nombre_archivo, ':', '_'), 1, instr(replace(r.nombre_archivo, ':', '_'), '_') - 1) as tipo_archivo,
                           ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 6) as id_tempfud,
                           replace(r.nombre_archivo, ':', '_') as nombre_archivo,
                           case when r.origen_pkm in ('Normal','Represtamo') then
                                    (select cr.codigo_agencia
                                       from pr.pr_creditos cr
                                      where cr.codigo_empresa = '1'
                                        and cr.no_credito = ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', case when ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 3) is not null then 3 else 1 end)
                                    )
                                WHEN R.ORIGEN_PKM IN ('Onboarding', 'TarjetaPC', 'Tarjeta') THEN
                                    (SELECT to_number(st.oficina)
                                       FROM TC.TC_SOLICITUD_TARJETA st
                                      WHERE st.no_solicitud =  ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', CASE WHEN r.url_reporte is not null THEN 1 ELSE 3 END)
                                    )
                           END  as codigo_agencia
                        from PA.PA_REPORTES_AUTOMATICOS r) r
        WHERE R.CODIGO_REPORTE = (SELECT MAX(x.codigo_reporte) FROM PA.PA_REPORTES_AUTOMATICOS X);
