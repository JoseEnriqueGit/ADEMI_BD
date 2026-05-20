procedure inserturlreporte(
    pcodigoreferencia in varchar2,
    pfechareporte in date,
    pid_aplicacion in number,
    pidtipodocumento in varchar2,
    porigenpkm in varchar2,
    purlreporte in varchar2,
    pformatodocumento in varchar2,
    pnombrearchivo in varchar2,
    pestado in varchar2 default 'P',
    prespuesta in out varchar2
) is vdirectorio varchar2(256) := nvl(
    pa.param.parametro_x_empresa('1', 'DIR_REPORTES', 'IA'),
    'RPT_REGULATORIOS'
);

venviarapi varchar2(2);

v_codigo_reporte number;

v_tipo_identificacion varchar2(5);

v_identificacion varchar2(30);

v_num_prestamo varchar2(40);

v_prest_anterior varchar2(40);

v_id_tempfud varchar2(30);

v_tipo_archivo varchar2(40);

v_nombre_archivo varchar2(60);

v_codigo_agencia varchar2(60);

v_nombre_agencia varchar2(60);

v_primer_nombre varchar2(60);

v_segundo_nombre varchar2(60);

v_primer_apellido varchar2(60);

v_segundo_apellido varchar2(60);

v_nacionalidad varchar2(60);

begin begin
select
    t.enviar_api into venviarapi
from
    pa.pa_tipo_documento_pkm t
where
    t.id_aplicacion = pid_aplicacion
    and t.id_tipo_documento = pidtipodocumento;

exception
when no_data_found then venviarapi := 'S';

end;

begin
insert into
    pa.pa_reportes_automaticos(
        codigo_referencia,
        fecha_reporte,
        id_aplicacion,
        id_tipo_documento,
        origen_pkm,
        url_reporte,
        formato_documento,
        directorio_destino,
        nombre_archivo,
        enviar_api,
        estado_reporte,
        fecha_proceso
    )
values
    (
        pcodigoreferencia,
        pfechareporte,
        pid_aplicacion,
        pidtipodocumento,
        porigenpkm,
        purlreporte,
        pformatodocumento,
        vdirectorio,
        pnombrearchivo,
        nvl(venviarapi, 'S'),
        nvl(pestado, 'P'),
        sysdate
    );

exception
when others then prespuesta := 'Error: ' || sqlerrm;

raise_application_error(-20100, prespuesta);

end;

select
    r.codigo_reporte,
    case
        when r.estado_reporte = 'R' then ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1)
        else null
    end tipo_identificacion,
    case
        when r.estado_reporte = 'R' then pa.formatear_identificacion(
            ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 2),
            (
                select
                    mascara
                from
                    tipos_id
                where
                    cod_tipo_id = ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1)
            ),
            'ESPA'
        )
        else null
    end identificacion,
    case
        when r.estado_reporte = 'R' then ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 3)
        else ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1)
    end f_num_prestamo,
    case
        when r.estado_reporte = 'R' then ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 4)
        else ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 2)
    end f_prest_anterior,
    substr(
        replace(r.nombre_archivo, ':', '_'),
        1,
        instr(replace(r.nombre_archivo, ':', '_'), '_') - 1
    ) tipo_archivo,
    case
        when r.estado_reporte = 'R' then ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 6)
        else null
    end id_tempfud,
    replace(r.nombre_archivo, ':', '_') nombre_archivo,
    (
        select
            cr.codigo_agencia
        from
            pr.pr_creditos cr
        where
            cr.codigo_empresa = '1'
            and cr.no_credito = case
                when r.estado_reporte = 'R' then ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 3)
                else ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1)
            end
    ) codigo_agencia,
    (
        select
            a.descripcion
        from
            pr.pr_creditos cr,
            pa.agencia a
        where
            cr.codigo_empresa = '1'
            and cr.no_credito = case
                when r.estado_reporte = 'R' then ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 3)
                else ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1)
            end
            and a.cod_empresa = to_char(cr.codigo_empresa)
            and a.cod_agencia = to_char(cr.codigo_agencia)
    ) nombre_agencia,
    (
        select
            pf.primer_nombre
        from
            pa.personas_fisicas pf,
            pa.id_personas i
        where
            pf.cod_per_fisica = i.cod_persona
            and i.cod_tipo_id = case
                when r.estado_reporte = 'R' then ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1)
                else '1'
            end
            and i.num_id = case
                when r.estado_reporte = 'R' then pa.formatear_identificacion(
                    ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 2),
                    (
                        select
                            mascara
                        from
                            tipos_id
                        where
                            cod_tipo_id = ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1)
                    ),
                    'ESPA'
                )
                else null
            end
    ) primer_nombre,
    (
        select
            pf.segundo_nombre
        from
            pa.personas_fisicas pf,
            pa.id_personas i
        where
            pf.cod_per_fisica = i.cod_persona
            and i.cod_tipo_id = case
                when r.estado_reporte = 'R' then ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1)
                else '1'
            end
            and i.num_id = case
                when r.estado_reporte = 'R' then pa.formatear_identificacion(
                    ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 2),
                    (
                        select
                            mascara
                        from
                            tipos_id
                        where
                            cod_tipo_id = ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1)
                    ),
                    'ESPA'
                )
                else null
            end
    ) segundo_nombre,
    (
        select
            pf.primer_apellido
        from
            pa.personas_fisicas pf,
            pa.id_personas i
        where
            pf.cod_per_fisica = i.cod_persona
            and i.cod_tipo_id = case
                when r.estado_reporte = 'R' then ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1)
                else '1'
            end
            and i.num_id = case
                when r.estado_reporte = 'R' then pa.formatear_identificacion(
                    ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 2),
                    (
                        select
                            mascara
                        from
                            tipos_id
                        where
                            cod_tipo_id = ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1)
                    ),
                    'ESPA'
                )
                else null
            end
    ) primer_apellido,
    (
        select
            pf.segundo_apellido
        from
            pa.personas_fisicas pf,
            pa.id_personas i
        where
            pf.cod_per_fisica = i.cod_persona
            and i.cod_tipo_id = case
                when r.estado_reporte = 'R' then ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1)
                else '1'
            end
            and i.num_id = case
                when r.estado_reporte = 'R' then pa.formatear_identificacion(
                    ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 2),
                    (
                        select
                            mascara
                        from
                            tipos_id
                        where
                            cod_tipo_id = ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1)
                    ),
                    'ESPA'
                )
                else null
            end
    ) segundo_apellido,
    (
        select
            nvl(i.nacionalidad, pf.nacionalidad)
        from
            pa.personas_fisicas pf,
            pa.id_personas i
        where
            pf.cod_per_fisica = i.cod_persona
            and i.cod_tipo_id = case
                when r.estado_reporte = 'R' then ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1)
                else '1'
            end
            and i.num_id = case
                when r.estado_reporte = 'R' then pa.formatear_identificacion(
                    ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 2),
                    (
                        select
                            mascara
                        from
                            tipos_id
                        where
                            cod_tipo_id = ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1)
                    ),
                    'ESPA'
                )
                else null
            end
    ) nacionalidad into v_codigo_reporte,
    v_tipo_identificacion,
    v_identificacion,
    v_num_prestamo,
    v_prest_anterior,
    v_tipo_archivo,
    v_id_tempfud,
    v_nombre_archivo,
    v_codigo_agencia,
    v_nombre_agencia,
    v_primer_nombre,
    v_segundo_nombre,
    v_primer_apellido,
    v_segundo_apellido,
    v_nacionalidad
from
    pa.pa_reportes_automaticos r
where
    r.codigo_reporte = (
        select
            max(x.codigo_reporte)
        from
            pa.pa_reportes_automaticos x
    );

insertautoindexado(
    v_codigo_reporte,
    pid_aplicacion,
    pidtipodocumento,
    v_tipo_identificacion,
    v_identificacion,
    v_num_prestamo,
    v_prest_anterior,
    v_tipo_archivo,
    v_id_tempfud,
    porigenpkm,
    purlreporte,
    v_nombre_archivo,
    pcodigoreferencia,
    nvl(venviarapi, 'S'),
    v_codigo_agencia,
    v_nombre_agencia,
    nvl(pestado, 'P'),
    v_primer_nombre,
    v_segundo_nombre,
    v_primer_apellido,
    v_segundo_apellido,
    v_nacionalidad,
    null,
    prespuesta
);

end inserturlreporte;