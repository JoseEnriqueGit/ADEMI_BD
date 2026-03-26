-- =============================================================================
-- ANTES vs DESPUES - SELECT de InsertUrlReporte
-- Paquete: PA.PKG_TIPO_DOCUMENTO_PKM
-- Entorno: QA02
--
-- Solucion: Reemplazar ORIGEN_PKM por estado_reporte para Normal/Represtamo
--           Mantener ORIGEN_PKM solo para Tarjetas (que usan TC_SOLICITUD_TARJETA)
-- =============================================================================


-- ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
-- ANTES (QA02 original - lineas 534 a 638 del body.sql)
-- Problema: usa ORIGEN_PKM IN ('Normal') para parsear la referencia.
--   'Represtamo' no esta en el IN, asi que todos sus campos caen a NULL.
-- ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀

       SELECT  r.codigo_reporte,
               r.tipo_identificacion,
               r.identificacion,
               r.f_num_prestamo,
               r.f_prest_anterior,
               r.tipo_archivo,
               r.id_tempfud,
               r.nombre_archivo,
               r.codigo_agencia,
               (select a.descripcion from pa.agencia a where a.cod_empresa = '1' and a.cod_agencia = r.codigo_agencia) as nombre_agencia,
               (select pf.primer_nombre
                   from pa.personas_fisicas pf, pa.id_personas i
                  where pf.cod_per_fisica = i.cod_persona
                    and i.cod_tipo_id = r.tipo_identificacion
                    and i.num_id = r.identificacion) as primer_nombre,
               (select pf.segundo_nombre
                   from pa.personas_fisicas pf, pa.id_personas i
                  where pf.cod_per_fisica = i.cod_persona
                    and i.cod_tipo_id = r.tipo_identificacion
                    and i.num_id = r.identificacion) as segundo_nombre,
                (select pf.primer_apellido
                   from pa.personas_fisicas pf, pa.id_personas i
                  where pf.cod_per_fisica = i.cod_persona
                    and i.cod_tipo_id = r.tipo_identificacion
                    and i.num_id = r.identificacion) as primer_apellido,
                (select pf.segundo_apellido
                   from pa.personas_fisicas pf, pa.id_personas i
                  where pf.cod_per_fisica = i.cod_persona
                    and i.cod_tipo_id = r.tipo_identificacion
                    and i.num_id = r.identificacion) as segundo_apellido,
               (select nvl(i.nacionalidad, pf.nacionalidad)
                  from pa.personas_fisicas pf, pa.id_personas i
                 where pf.cod_per_fisica = i.cod_persona
                   and i.cod_tipo_id = r.tipo_identificacion
                   and i.num_id =  r.identificacion) as nacionalidad
       INTO v_codigo_reporte	 ,
            v_tipo_identificacion,
            v_identificacion	 ,
            v_num_prestamo	     ,
            v_prest_anterior	 ,
            v_tipo_archivo	     ,
            v_id_tempfud	     ,
            v_nombre_archivo	 ,
            v_codigo_agencia	 ,
            v_nombre_agencia	 ,
            v_primer_nombre	     ,
            v_segundo_nombre	 ,
            v_primer_apellido	 ,
            v_segundo_apellido	 ,
            v_nacionalidad
        from (
                SELECT r.CODIGO_REPORTE,
                       r.CODIGO_REFERENCIA,
                       r.ORIGEN_PKM,
                           case when r.ORIGEN_PKM in ('Normal') then                              -- ← solo 'Normal', falta 'Represtamo'
                                nvl(ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1), '1')
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
                           case when r.ORIGEN_PKM in ('Normal') then                              -- ← solo 'Normal', falta 'Represtamo'
                                    pa.formatear_identificacion(ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 2),
                                                                (select mascara from tipos_id where cod_tipo_id = ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1)),
                                                                'ESPA')
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
                           case when r.ORIGEN_PKM in ('Normal') then                              -- ← solo 'Normal', falta 'Represtamo'
                                    ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 3)
                                WHEN R.ORIGEN_PKM IN ('Onboarding', 'TarjetaPC', 'Tarjeta') THEN
                                    ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', CASE WHEN r.url_reporte is not null THEN 1 ELSE 3 END)
                           end as f_num_prestamo,
                           ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 4) as f_prest_anterior,
                           substr(replace(r.nombre_archivo, ':', '_'), 1, instr(replace(r.nombre_archivo, ':', '_'), '_') - 1) as tipo_archivo,
                           ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 6) as id_tempfud,
                           replace(r.nombre_archivo, ':', '_') as nombre_archivo,
                           case when r.origen_pkm in ('Normal') then                              -- ← solo 'Normal', falta 'Represtamo'
                                    (select cr.codigo_agencia
                                       from pr.pr_creditos cr
                                      where cr.codigo_empresa = '1'
                                        and cr.no_credito = ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', case when r.url_reporte is null then 3 else 1 end)
                                    )
                                WHEN R.ORIGEN_PKM IN ('Onboarding', 'TarjetaPC', 'Tarjeta') THEN
                                    (SELECT to_number(st.oficina)
                                       FROM TC.TC_SOLICITUD_TARJETA st
                                      WHERE st.no_solicitud =  ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', CASE WHEN r.url_reporte is not null THEN 1 ELSE 3 END)
                                    )
                           END  as codigo_agencia
                        from PA.PA_REPORTES_AUTOMATICOS r) r
        WHERE R.CODIGO_REPORTE = (SELECT MAX(x.codigo_reporte) FROM PA.PA_REPORTES_AUTOMATICOS X);


-- ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
-- DESPUES (solucion con estado_reporte)
-- Cambio: reemplazar ORIGEN_PKM IN ('Normal') por estado_reporte = 'R'
--   - No necesita 'Represtamo' en ningun IN()
--   - Tarjetas mantienen su logica propia con ORIGEN_PKM
--   - estado_reporte identifica el formato de referencia correctamente
-- ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀

       SELECT  r.codigo_reporte,
               r.tipo_identificacion,
               r.identificacion,
               r.f_num_prestamo,
               r.f_prest_anterior,
               r.tipo_archivo,
               r.id_tempfud,
               r.nombre_archivo,
               r.codigo_agencia,
               (select a.descripcion from pa.agencia a where a.cod_empresa = '1' and a.cod_agencia = r.codigo_agencia) as nombre_agencia,
               (select pf.primer_nombre
                   from pa.personas_fisicas pf, pa.id_personas i
                  where pf.cod_per_fisica = i.cod_persona
                    and i.cod_tipo_id = r.tipo_identificacion
                    and i.num_id = r.identificacion) as primer_nombre,
               (select pf.segundo_nombre
                   from pa.personas_fisicas pf, pa.id_personas i
                  where pf.cod_per_fisica = i.cod_persona
                    and i.cod_tipo_id = r.tipo_identificacion
                    and i.num_id = r.identificacion) as segundo_nombre,
                (select pf.primer_apellido
                   from pa.personas_fisicas pf, pa.id_personas i
                  where pf.cod_per_fisica = i.cod_persona
                    and i.cod_tipo_id = r.tipo_identificacion
                    and i.num_id = r.identificacion) as primer_apellido,
                (select pf.segundo_apellido
                   from pa.personas_fisicas pf, pa.id_personas i
                  where pf.cod_per_fisica = i.cod_persona
                    and i.cod_tipo_id = r.tipo_identificacion
                    and i.num_id = r.identificacion) as segundo_apellido,
               (select nvl(i.nacionalidad, pf.nacionalidad)
                  from pa.personas_fisicas pf, pa.id_personas i
                 where pf.cod_per_fisica = i.cod_persona
                   and i.cod_tipo_id = r.tipo_identificacion
                   and i.num_id =  r.identificacion) as nacionalidad
       INTO v_codigo_reporte     ,
            v_tipo_identificacion,
            v_identificacion     ,
            v_num_prestamo       ,
            v_prest_anterior     ,
            v_tipo_archivo       ,
            v_id_tempfud         ,
            v_nombre_archivo     ,
            v_codigo_agencia     ,
            v_nombre_agencia     ,
            v_primer_nombre      ,
            v_segundo_nombre     ,
            v_primer_apellido    ,
            v_segundo_apellido   ,
            v_nacionalidad
        from (
                SELECT r.CODIGO_REPORTE,
                       r.CODIGO_REFERENCIA,
                       r.ORIGEN_PKM,
                       -- =================================================
                       -- tipo_identificacion
                       -- CAMBIO: Tarjetas primero (por ORIGEN_PKM), luego estado_reporte
                       -- =================================================
                           CASE
                                WHEN R.ORIGEN_PKM IN ('Onboarding', 'TarjetaPC', 'Tarjeta') THEN
                                  CASE WHEN r.URL_REPORTE is not null THEN
                                    (SELECT st.COD_TIPO_ID
                                       FROM TC.TC_SOLICITUD_TARJETA st
                                      WHERE st.no_solicitud = ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1))
                                  ELSE
                                    nvl(ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1), '1')
                                  END
                                WHEN r.estado_reporte = 'R' THEN
                                    nvl(ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1), '1')
                                ELSE NULL
                           END as tipo_identificacion,
                       -- =================================================
                       -- identificacion
                       -- CAMBIO: Tarjetas primero, luego estado_reporte
                       -- =================================================
                           CASE
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
                                WHEN r.estado_reporte = 'R' THEN
                                    pa.formatear_identificacion(ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 2),
                                                                (select mascara from tipos_id where cod_tipo_id = ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1)),
                                                                'ESPA')
                                ELSE NULL
                           END as identificacion,
                       -- =================================================
                       -- f_num_prestamo
                       -- CAMBIO: Tarjetas primero, luego estado_reporte
                       -- =================================================
                           CASE
                                WHEN R.ORIGEN_PKM IN ('Onboarding', 'TarjetaPC', 'Tarjeta') THEN
                                    ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', CASE WHEN r.url_reporte is not null THEN 1 ELSE 3 END)
                                WHEN r.estado_reporte = 'R' THEN
                                    ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 3)
                                ELSE
                                    ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1)
                           END as f_num_prestamo,
                       -- =================================================
                       -- f_prest_anterior (sin cambios)
                       -- =================================================
                           ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 4) as f_prest_anterior,
                       -- =================================================
                       -- tipo_archivo (sin cambios)
                       -- =================================================
                           substr(replace(r.nombre_archivo, ':', '_'), 1, instr(replace(r.nombre_archivo, ':', '_'), '_') - 1) as tipo_archivo,
                       -- =================================================
                       -- id_tempfud (sin cambios)
                       -- =================================================
                           ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 6) as id_tempfud,
                       -- =================================================
                       -- nombre_archivo (sin cambios)
                       -- =================================================
                           replace(r.nombre_archivo, ':', '_') as nombre_archivo,
                       -- =================================================
                       -- codigo_agencia
                       -- CAMBIO: Tarjetas primero, luego estado_reporte
                       -- =================================================
                           CASE
                                WHEN R.ORIGEN_PKM IN ('Onboarding', 'TarjetaPC', 'Tarjeta') THEN
                                    (SELECT to_number(st.oficina)
                                       FROM TC.TC_SOLICITUD_TARJETA st
                                      WHERE st.no_solicitud = ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', CASE WHEN r.url_reporte is not null THEN 1 ELSE 3 END))
                                ELSE
                                    (select cr.codigo_agencia
                                       from pr.pr_creditos cr
                                      where cr.codigo_empresa = '1'
                                        and cr.no_credito = ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', case when r.estado_reporte = 'R' then 3 else 1 end))
                           END as codigo_agencia
                        from PA.PA_REPORTES_AUTOMATICOS r) r
        WHERE R.CODIGO_REPORTE = (SELECT MAX(x.codigo_reporte) FROM PA.PA_REPORTES_AUTOMATICOS X);
