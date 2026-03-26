CREATE OR REPLACE package body PA.pkg_tipo_documento_pkm is
    procedure generar(pid_aplicacion in     number,
                      pid_tipo_documento in varchar2,
                      pdescripcion   in     varchar2,
                      pnombre_reporte in    varchar2,
                      preutilizable  in     varchar2,
                      pautomatico    in     varchar2,
                      padicionado_por in    varchar2,
                      pfecha_adicion in     date,
                      pmodificado_por in    varchar2,
                      pfecha_modificacion in date,
                      pestado_tipo_documento in varchar2,
                      penviar_api    in     varchar2,
                      presultado     in out varchar2) is
        pdata pa.tipo_documento_pkm_obj;
        viderror number := 0;
    begin
        pdata := pa.tipo_documento_pkm_obj();
        pdata.id_aplicacion := pid_aplicacion;
        pdata.id_tipo_documento := pid_tipo_documento;
        pdata.descripcion := pdescripcion;
        pdata.nombre_reporte := pnombre_reporte;
        pdata.reutilizable := preutilizable;
        pdata.automatico := pautomatico;
        pdata.adicionado_por := padicionado_por;
        pdata.fecha_adicion := pfecha_adicion;
        pdata.modificado_por := pmodificado_por;
        pdata.fecha_modificacion := pfecha_modificacion;
        pdata.estado_tipo_documento := pestado_tipo_documento;
        pdata.enviar_api := penviar_api;

        if pdata.validar('G', presultado) then
            -- Existe
            if pdata.existe() = false then
                -- Insertar
                pdata.crear();
            else
                -- Modificar
                pdata.actualizar();
            end if;

            presultado := 'Exitoso.';
        end if;
    exception
        when others then
            presultado := sqlcode || ': ' || sqlerrm;
            pa.pkg_tipo_documento_pkm.logerror(pdata => pdata,
                                               inprogramunit => 'Generar',
                                               inerrordescription => presultado,
                                               inerrortrace => dbms_utility.format_error_backtrace,
                                               outiderror => viderror);
            raise_application_error(-20100, 'Error ' || sqlerrm);
    end generar;


    procedure crear(pid_aplicacion in     number,
                    pid_tipo_documento in varchar2,
                    pdescripcion   in     varchar2,
                    pnombre_reporte in    varchar2,
                    preutilizable  in     varchar2,
                    pautomatico    in     varchar2,
                    padicionado_por in    varchar2,
                    pfecha_adicion in     date,
                    pmodificado_por in    varchar2,
                    pfecha_modificacion in date,
                    pestado_tipo_documento in varchar2,
                    penviar_api    in     varchar2,
                    presultado     in out varchar2) is
        pdata pa.tipo_documento_pkm_obj;
        viderror number := 0;
    begin
        pdata := pa.tipo_documento_pkm_obj();
        pdata.id_aplicacion := pid_aplicacion;
        pdata.id_tipo_documento := pid_tipo_documento;
        pdata.descripcion := pdescripcion;
        pdata.nombre_reporte := pnombre_reporte;
        pdata.reutilizable := preutilizable;
        pdata.automatico := pautomatico;
        pdata.adicionado_por := padicionado_por;
        pdata.fecha_adicion := pfecha_adicion;
        pdata.modificado_por := pmodificado_por;
        pdata.fecha_modificacion := pfecha_modificacion;
        pdata.estado_tipo_documento := pestado_tipo_documento;
        pdata.enviar_api := penviar_api;

        if pdata.validar('C', presultado) then
            -- Existe
            if pdata.existe() = false then
                pdata.crear();
                presultado := 'Exitoso.';
            end if;
        end if;
    exception
        when others then
            presultado := sqlcode || ': ' || sqlerrm;
            pa.pkg_tipo_documento_pkm.logerror(pdata => pdata, inprogramunit => 'Crear', inerrordescription => presultado, inerrortrace => dbms_utility.format_error_backtrace, outiderror => viderror);
            raise_application_error(-20100, 'Error ' || sqlerrm);
    end crear;


    procedure actualizar(pid_aplicacion in     number,
                         pid_tipo_documento in varchar2,
                         pdescripcion   in     varchar2,
                         pnombre_reporte in    varchar2,
                         preutilizable  in     varchar2,
                         pautomatico    in     varchar2,
                         padicionado_por in    varchar2,
                         pfecha_adicion in     date,
                         pmodificado_por in    varchar2,
                         pfecha_modificacion in date,
                         pestado_tipo_documento in varchar2,
                         penviar_api    in     varchar2,
                         presultado     in out varchar2) is
        pdata pa.tipo_documento_pkm_obj;
        viderror number := 0;
    begin
        pdata := pa.tipo_documento_pkm_obj();
        pdata.id_aplicacion := pid_aplicacion;
        pdata.id_tipo_documento := pid_tipo_documento;
        pdata.descripcion := pdescripcion;
        pdata.nombre_reporte := pnombre_reporte;
        pdata.reutilizable := preutilizable;
        pdata.automatico := pautomatico;
        pdata.adicionado_por := padicionado_por;
        pdata.fecha_adicion := pfecha_adicion;
        pdata.modificado_por := pmodificado_por;
        pdata.fecha_modificacion := pfecha_modificacion;
        pdata.estado_tipo_documento := pestado_tipo_documento;
        pdata.enviar_api := penviar_api;

        if pdata.validar('U', presultado) then
            -- Existe
            if pdata.existe() = true then
                pdata.actualizar();
                presultado := 'Exitoso.';
            end if;
        end if;
    exception
        when others then
            presultado := sqlcode || ': ' || sqlerrm;
            pa.pkg_tipo_documento_pkm.logerror(pdata => pdata,
                                               inprogramunit => 'Actualizar',
                                               inerrordescription => presultado,
                                               inerrortrace => dbms_utility.format_error_backtrace,
                                               outiderror => viderror);
            raise_application_error(-20100, 'Error ' || sqlerrm);
    end actualizar;

    procedure borrar(pid_aplicacion in number, pid_tipo_documento in varchar2, presultado in out varchar2) is
        pdata pa.tipo_documento_pkm_obj;
        viderror number := 0;
    begin
        pdata := pa.tipo_documento_pkm_obj();
        pdata.id_aplicacion := pid_aplicacion;
        pdata.id_tipo_documento := pid_tipo_documento;

        if pdata.validar('D', presultado) then
            -- Existe
            if pdata.existe() = true then
                pdata.borrar();
                presultado := 'Exitoso.';
            end if;
        end if;
    exception
        when others then
            presultado := sqlcode || ': ' || sqlerrm;
            pa.pkg_tipo_documento_pkm.logerror(pdata => pdata,
                                               inprogramunit => 'Borrar',
                                               inerrordescription => presultado,
                                               inerrortrace => dbms_utility.format_error_backtrace,
                                               outiderror => viderror);
            raise_application_error(-20100, 'Error ' || sqlerrm);
    end borrar;


    function consultar(pid_aplicacion in     number,
                       pid_tipo_documento in varchar2,
                       pdescripcion   in     varchar2,
                       pnombre_reporte in    varchar2,
                       preutilizable  in     varchar2,
                       pautomatico    in     varchar2,
                       padicionado_por in    varchar2,
                       pfecha_adicion in     date,
                       pmodificado_por in    varchar2,
                       pfecha_modificacion in date,
                       pestado_tipo_documento in varchar2,
                       penviar_api    in     varchar2,
                       presultado     in out varchar2)
        return pa.tipo_documento_pkm_list is
        cursor cdata is
            select *
            from pa.pa_tipo_documento_pkm t1
            where (t1.id_aplicacion = pid_aplicacion
            or     pid_aplicacion is null)
            and   (t1.id_tipo_documento = pid_tipo_documento
            or     pid_tipo_documento is null)
            and   (t1.descripcion = pdescripcion
            or     pdescripcion is null)
            and   (t1.nombre_reporte = pnombre_reporte
            or     pnombre_reporte is null)
            and   (t1.reutilizable = preutilizable
            or     preutilizable is null)
            and   (t1.automatico = pautomatico
            or     pautomatico is null)
            and   (t1.adicionado_por = padicionado_por
            or     padicionado_por is null)
            and   (t1.fecha_adicion = pfecha_adicion
            or     pfecha_adicion is null)
            and   (t1.modificado_por = pmodificado_por
            or     pmodificado_por is null)
            and   (t1.fecha_modificacion = pfecha_modificacion
            or     pfecha_modificacion is null)
            and   (t1.estado_tipo_documento = pestado_tipo_documento
            or     pestado_tipo_documento is null)
            and   (t1.enviar_api = penviar_api
            or     penviar_api is null);

        type tdata is table of cdata%rowtype;

        vdata tdata;
        vdatalist pa.tipo_documento_pkm_list := pa.tipo_documento_pkm_list();
        pdata pa.tipo_documento_pkm_obj;
        indice number := 0;
        viderror number := 0;
    begin
        vdatalist.delete;

        open cdata;

        loop
            fetch cdata bulk   collect into vdata limit 5000;

            for i in 1 .. vdata.count
            loop
                pdata := pa.tipo_documento_pkm_obj();
                pdata.id_aplicacion := vdata(i).id_aplicacion;
                pdata.id_tipo_documento := vdata(i).id_tipo_documento;
                pdata.descripcion := vdata(i).descripcion;
                pdata.nombre_reporte := vdata(i).nombre_reporte;
                pdata.reutilizable := vdata(i).reutilizable;
                pdata.automatico := vdata(i).automatico;
                pdata.adicionado_por := vdata(i).adicionado_por;
                pdata.fecha_adicion := vdata(i).fecha_adicion;
                pdata.modificado_por := vdata(i).modificado_por;
                pdata.fecha_modificacion := vdata(i).fecha_modificacion;
                pdata.estado_tipo_documento := vdata(i).estado_tipo_documento;
                pdata.enviar_api := vdata(i).enviar_api;
                indice := indice + i;
                vdatalist.extend;
                vdatalist(indice) := pdata;
            end loop;

            exit when cdata%notfound;
        end loop;

        close cdata;

        presultado := 'Exitoso.';
        return vdatalist;
    exception
        when others then
            presultado := sqlcode || ': ' || sqlerrm;
            pa.pkg_tipo_documento_pkm.logerror(pdata => pdata,
                                               inprogramunit => 'Consultar',
                                               inerrordescription => presultado,
                                               inerrortrace => dbms_utility.format_error_backtrace,
                                               outiderror => viderror);
            raise_application_error(-20404, 'Error ' || sqlerrm);
    end consultar;

    function comparar(pdata1 in out pa.tipo_documento_pkm_obj, pdata2 in out pa.tipo_documento_pkm_obj, pmodo in varchar2, presultado in out varchar2)
        -- O = (Compare between Objects pData1 and pData2),
        -- T = (Compare pData1 and Table data "Must used pData2 like search parameter in table)
        return boolean is
        vigual boolean := false;
        vdatalist pa.tipo_documento_pkm_list := pa.tipo_documento_pkm_list();
        vdata pa.tipo_documento_pkm_obj := pa.tipo_documento_pkm_obj();
        viderror number := 0;
    begin
        if pmodo = 'O' then
            if pdata1 is not null
               and pdata2 is not null then
                vigual := pdata1.compare(pdata2);
            else
                vigual := true;
            end if;
        elsif pmodo = 'T' then
            vdatalist := consultar(pid_aplicacion => pdata2.id_aplicacion,
                                   pid_tipo_documento => pdata2.id_tipo_documento,
                                   pdescripcion => pdata2.descripcion,
                                   pnombre_reporte => pdata2.nombre_reporte,
                                   preutilizable => pdata2.reutilizable,
                                   pautomatico => pdata2.automatico,
                                   padicionado_por => pdata2.adicionado_por,
                                   pfecha_adicion => pdata2.fecha_adicion,
                                   pmodificado_por => pdata2.modificado_por,
                                   pfecha_modificacion => pdata2.fecha_modificacion,
                                   pestado_tipo_documento => pdata2.estado_tipo_documento,
                                   penviar_api => pdata2.enviar_api,
                                   presultado => presultado);

            if vdatalist.count > 0 then
                vdata := vdatalist(1);
                vigual := pdata1.compare(vdata);
            else
                vigual := false;
            end if;
        end if;

        presultado := 'Exitoso.';
        return vigual;
    end comparar;

    function existe(pid_aplicacion in number, pid_tipo_documento in varchar2, presultado in out varchar2)
        return boolean is
        pdata pa.tipo_documento_pkm_obj;
        viderror number := 0;
    begin
        pdata := pa.tipo_documento_pkm_obj();
        pdata.id_aplicacion := pid_aplicacion;
        pdata.id_tipo_documento := pid_tipo_documento;
        presultado := 'Exitoso.';
        return pdata.existe();
    exception
        when others then
            presultado := sqlcode || ': ' || sqlerrm;
            pa.pkg_tipo_documento_pkm.logerror(pdata => pdata,
                                               inprogramunit => 'Existe',
                                               inerrordescription => presultado,
                                               inerrortrace => dbms_utility.format_error_backtrace,
                                               outiderror => viderror);
            raise_application_error(-20404, 'Error ' || sqlerrm);
    end existe;

    function validar(pid_aplicacion in     number,
                     pid_tipo_documento in varchar2,
                     pdescripcion   in     varchar2,
                     pnombre_reporte in    varchar2,
                     preutilizable  in     varchar2,
                     pautomatico    in     varchar2,
                     padicionado_por in    varchar2,
                     pfecha_adicion in     date,
                     pmodificado_por in    varchar2,
                     pfecha_modificacion in date,
                     pestado_tipo_documento in varchar2,
                     penviar_api    in     varchar2,
                     poperacion     in     varchar2, -- G=Generar, C=Crear, U=Actualizar, D=Borrar
                     perror         in out varchar2)
        return boolean is
        pdata pa.tipo_documento_pkm_obj;
        vvalidar boolean := false;
        viderror number := 0;
    begin
        pdata := pa.tipo_documento_pkm_obj();
        pdata.id_aplicacion := pid_aplicacion;
        pdata.id_tipo_documento := pid_tipo_documento;
        pdata.descripcion := pdescripcion;
        pdata.nombre_reporte := pnombre_reporte;
        pdata.reutilizable := preutilizable;
        pdata.automatico := pautomatico;
        pdata.adicionado_por := padicionado_por;
        pdata.fecha_adicion := pfecha_adicion;
        pdata.modificado_por := pmodificado_por;
        pdata.fecha_modificacion := pfecha_modificacion;
        pdata.estado_tipo_documento := pestado_tipo_documento;
        pdata.enviar_api := penviar_api;
        vvalidar := pdata.validar(poperacion, perror);

        pa.pkg_tipo_documento_pkm.logerror(pdata => pdata, inprogramunit => 'Validar', inerrordescription => perror, inerrortrace => dbms_utility.format_error_backtrace, outiderror => viderror);

        return vvalidar;
    end validar;

    function urlconozcasucliente(pcodcliente in varchar2, pempresa in varchar2)
        return varchar2 is
        vurl varchar2(2000);
        vparametros varchar2(2000) := null;
        vformato_salida varchar2(20) := 'PDF';
    begin
        vparametros := 'CustomerId=' || pcodcliente || chr(38) || 'CompanyId=' || pempresa;
        vurl := ia.f_reporte_ssrs('LV', 'FCSCPF', vformato_salida, vparametros);
        return vurl;
    end urlconozcasucliente;

    function urlconozcasucliente2(pcodcliente in varchar2, pempresa in varchar2)
        return varchar2 is
        vurl varchar2(2000);
        vparametros varchar2(2000) := null;
        vformato_salida varchar2(20) := 'PDF';
    begin
        vparametros := 'CustomerId=' || pcodcliente || chr(38) || 'CompanyId=' || pempresa;
        vurl := ia.f_reporte_ssrs('LV', 'FCSCPF_OnBoarding', vformato_salida, vparametros);
        return vurl;
    end urlconozcasucliente2;

    function urlmatrizriesgo(pcodcliente in varchar2)
        return varchar2 is
        vurl varchar2(2000);
        vparametros varchar2(2000) := null;
        vformato_salida varchar2(20) := 'PDF';
    begin
        vparametros := 'pCodPersona=' || pcodcliente;
        vurl := ia.f_reporte_ssrs('LV', 'MRAVPF', vformato_salida, vparametros);
        return vurl;
    end urlmatrizriesgo;

    function urlsolicitudtarjeta(pnosolicitud in number)
        return varchar2 is
        vurl varchar2(2000);
        vparametros varchar2(2000) := null;
        vformato_salida varchar2(20) := 'PDF';
    begin
        vparametros := 'p_NoSolicitud=' || pnosolicitud;
        vurl := ia.f_reporte_ssrs('TC', 'SolicitudTarjeta', vformato_salida, vparametros);
        return vurl;
    end urlsolicitudtarjeta;

    function urlfec(pid_tempfec in number, p_nomarchivo in varchar2)
        return varchar2 is
        vurl varchar2(2000);
        vparametros varchar2(2000) := null;
        vformato_salida varchar2(20) := 'PDF';
    begin
        vparametros := 'P_IDTEMPFEC=' || pid_tempfec || chr(38) || 'P_NOMARCHIVO=' || p_nomarchivo;
        vurl := ia.f_reporte_ssrs('PR', 'FEC_CLIENTE', vformato_salida, vparametros);
        return vurl;
    end urlfec;

    function urlfecfiador(pid_tempfec in number, p_nomarchivo in varchar2)
        return varchar2 is
        vurl varchar2(2000);
        vparametros varchar2(2000) := null;
        vformato_salida varchar2(20) := 'PDF';
    begin
        vparametros := 'P_IDTEMPFEC=' || pid_tempfec || chr(38) || 'P_NOMARCHIVO=' || p_nomarchivo;
        vurl := ia.f_reporte_ssrs('PR', 'FEC_FI', vformato_salida, vparametros);
        return vurl;
    end urlfecfiador;

    function urlfudreprestamos(pid_tempfud in number, p_nomarchivo in varchar2)
        return varchar2 is
        vurl varchar2(2000);
        vparametros varchar2(2000) := null;
        vformato_salida varchar2(20) := 'PDF';
    begin
        vparametros := 'p_IDTEMPFUD=' || pid_tempfud || chr(38) || 'p_NOMARCHIVO=' || p_nomarchivo;
        vurl := ia.f_reporte_ssrs('PR', 'FUD', vformato_salida, vparametros);
        return vurl;
    end urlfudreprestamos;

    function urlfecreprestamos(pidreprestamo in number)
        return varchar2 is
        vurl varchar2(2000);
        vparametros varchar2(2000) := null;
        vformato_salida varchar2(20) := 'PDF';
    begin
        vparametros := 'p_ID_REPRESTAMO=' || pidreprestamo;
        vurl := ia.f_reporte_ssrs('PR', 'rptFEC_Represtamos', vformato_salida, vparametros);
        return vurl;
    end urlfecreprestamos;

    function urllexisnexis(pnombres in varchar2, papellidos in varchar2, pidentificacion in varchar2)
        return varchar2 is
        vurl varchar2(2000);
        vparametros varchar2(2000) := null;
        vformato_salida varchar2(20) := 'PDF';
    begin
        vparametros := 'NATIONALID=' || pidentificacion || chr(38) || 'FIRSTNAME=' || pnombres || chr(38) || 'LASTNAME=' || papellidos;
        vurl := ia.f_reporte_ssrs('PR', 'rptLexisNexis', vformato_salida, vparametros);
        return vurl;
    end;

    procedure inserturlreporte(pcodigoreferencia in  varchar2,
                               pfechareporte  in     date,
                               pid_aplicacion in     number,
                               pidtipodocumento in   varchar2,
                               porigenpkm     in     varchar2,
                               purlreporte    in     varchar2,
                               pformatodocumento in  varchar2,
                               pnombrearchivo in     varchar2,
                               pestado        in     varchar2 default 'P',
                               prespuesta     in out varchar2) is
        vdirectorio varchar2(256) := nvl(pa.param.parametro_x_empresa('1', 'DIR_REPORTES', 'IA'), 'RPT_REGULATORIOS'); --IA.EVERTEC_FCP_v2.getRutaFisica( NVL(PA.PARAM.PARAMETRO_X_EMPRESA('DIR_REPORTES'), 'RPT_REGULATORIOS'));
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
    begin
        begin
            select t.enviar_api
            into venviarapi
            from pa.pa_tipo_documento_pkm t
            where t.id_aplicacion = pid_aplicacion
            and   t.id_tipo_documento = pidtipodocumento;
        exception
            when no_data_found then
                venviarapi := 'S';
        end;

        begin
            insert into pa.pa_reportes_automaticos(codigo_referencia,
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
                                                   fecha_proceso)
            values (pcodigoreferencia,
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
                    sysdate);
        exception
            when others then
                prespuesta := 'Error: ' || sqlerrm;
                raise_application_error(-20100, prespuesta);
        end;

        select r.codigo_reporte,
               case when r.estado_reporte = 'R' then ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1) else null end
                   tipo_identificacion,
               case
                   when r.estado_reporte = 'R' then
                       pa.formatear_identificacion(ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 2),
                                                   (select mascara
                                                    from tipos_id
                                                    where cod_tipo_id = ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1)),
                                                   'ESPA')
                   else
                       null
               end
                   identificacion,
               case when r.estado_reporte = 'R' then ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 3) else ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1) end
                   f_num_prestamo,
               case when r.estado_reporte = 'R' then ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 4) else ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 2) end
                   f_prest_anterior,
               substr(replace(r.nombre_archivo, ':', '_'), 1, instr(replace(r.nombre_archivo, ':', '_'), '_') - 1)
                   tipo_archivo,
               case when r.estado_reporte = 'R' then ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 6) else null end
                   id_tempfud,
               replace(r.nombre_archivo, ':', '_')
                   nombre_archivo,
               (select cr.codigo_agencia
                from pr.pr_creditos cr
                where cr.codigo_empresa = '1'
                and   cr.no_credito =
                      case
                          when r.estado_reporte = 'R' then ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 3)
                          else ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1)
                      end)
                   codigo_agencia,
               (select a.descripcion
                from pr.pr_creditos cr, pa.agencia a
                where cr.codigo_empresa = '1'
                and   cr.no_credito =
                      case
                          when r.estado_reporte = 'R' then ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 3)
                          else ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1)
                      end
                and   a.cod_empresa = to_char(cr.codigo_empresa)
                and   a.cod_agencia = to_char(cr.codigo_agencia))
                   nombre_agencia,
               (select pf.primer_nombre
                from pa.personas_fisicas pf, pa.id_personas i
                where pf.cod_per_fisica = i.cod_persona
                and   i.cod_tipo_id = case when r.estado_reporte = 'R' then ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1) else '1' end
                and   i.num_id = case
                                     when r.estado_reporte = 'R' then
                                         pa.formatear_identificacion(ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 2),
                                                                     (select mascara
                                                                      from tipos_id
                                                                      where cod_tipo_id = ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1)),
                                                                     'ESPA')
                                     else
                                         null
                                 end)
                   primer_nombre,
               (select pf.segundo_nombre
                from pa.personas_fisicas pf, pa.id_personas i
                where pf.cod_per_fisica = i.cod_persona
                and   i.cod_tipo_id = case when r.estado_reporte = 'R' then ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1) else '1' end
                and   i.num_id = case
                                     when r.estado_reporte = 'R' then
                                         pa.formatear_identificacion(ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 2),
                                                                     (select mascara
                                                                      from tipos_id
                                                                      where cod_tipo_id = ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1)),
                                                                     'ESPA')
                                     else
                                         null
                                 end)
                   segundo_nombre,
               (select pf.primer_apellido
                from pa.personas_fisicas pf, pa.id_personas i
                where pf.cod_per_fisica = i.cod_persona
                and   i.cod_tipo_id = case when r.estado_reporte = 'R' then ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1) else '1' end
                and   i.num_id = case
                                     when r.estado_reporte = 'R' then
                                         pa.formatear_identificacion(ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 2),
                                                                     (select mascara
                                                                      from tipos_id
                                                                      where cod_tipo_id = ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1)),
                                                                     'ESPA')
                                     else
                                         null
                                 end)
                   primer_apellido,
               (select pf.segundo_apellido
                from pa.personas_fisicas pf, pa.id_personas i
                where pf.cod_per_fisica = i.cod_persona
                and   i.cod_tipo_id = case when r.estado_reporte = 'R' then ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1) else '1' end
                and   i.num_id = case
                                     when r.estado_reporte = 'R' then
                                         pa.formatear_identificacion(ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 2),
                                                                     (select mascara
                                                                      from tipos_id
                                                                      where cod_tipo_id = ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1)),
                                                                     'ESPA')
                                     else
                                         null
                                 end)
                   segundo_apellido,
               (select nvl(i.nacionalidad, pf.nacionalidad)
                from pa.personas_fisicas pf, pa.id_personas i
                where pf.cod_per_fisica = i.cod_persona
                and   i.cod_tipo_id = case when r.estado_reporte = 'R' then ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1) else '1' end
                and   i.num_id = case
                                     when r.estado_reporte = 'R' then
                                         pa.formatear_identificacion(ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 2),
                                                                     (select mascara
                                                                      from tipos_id
                                                                      where cod_tipo_id = ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1)),
                                                                     'ESPA')
                                     else
                                         null
                                 end)
                   nacionalidad
        into v_codigo_reporte,
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
        from pa.pa_reportes_automaticos r
        where r.codigo_reporte = (select max(x.codigo_reporte)
                                  from pa.pa_reportes_automaticos x);

        insertautoindexado(v_codigo_reporte,
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
                           prespuesta);
    end inserturlreporte;

    procedure insertautoindexado(p_codigo_reporte      number,
                                 p_applicationid       number,
                                 p_f_document_type     varchar2,
                                 p_tipo_identificacion varchar2,
                                 p_identificacion      varchar2,
                                 p_f_num_prestamo      varchar2,
                                 p_f_prest_anterior    varchar2,
                                 p_tipo_archivo        varchar2,
                                 p_id_tempfud          varchar2,
                                 p_f_origen            varchar2,
                                 p_url_reporte         varchar2,
                                 p_nombre_archivo      varchar2,
                                 p_codigo_referencia   varchar2,
                                 p_enviar_api          varchar2,
                                 p_codigo_agencia      number,
                                 p_nombre_agencia      varchar2,
                                 p_estado_reporte      varchar2,
                                 p_primer_nombre       varchar2,
                                 p_segundo_nombre      varchar2,
                                 p_primer_apellido     varchar2,
                                 p_segundo_apellido    varchar2,
                                 p_nacionalidad        varchar2,
                                 p_idproceso           varchar2,
                                 prespuesta     in out varchar2) is
        pragma autonomous_transaction;
        vexiste number := 0;
    begin
        select count(1)
        into vexiste
        from pa.pa_auto_indexado a
        where a.codigo_reporte = p_codigo_reporte;

        if nvl(vexiste, 0) = 0 then
            insert into pa.pa_auto_indexado(codigo_reporte,
                                            applicationid,
                                            f_document_type,
                                            tipo_identificacion,
                                            identificacion,
                                            f_num_prestamo,
                                            f_prest_anterior,
                                            tipo_archivo,
                                            id_tempfud,
                                            f_origen,
                                            url_reporte,
                                            nombre_archivo,
                                            codigo_referencia,
                                            enviar_api,
                                            codigo_agencia,
                                            nombre_agencia,
                                            estado_reporte,
                                            primer_nombre,
                                            segundo_nombre,
                                            primer_apellido,
                                            segundo_apellido,
                                            nacionalidad,
                                            idproceso)
            values (p_codigo_reporte,
                    p_applicationid,
                    p_f_document_type,
                    p_tipo_identificacion,
                    p_identificacion,
                    p_f_num_prestamo,
                    p_f_prest_anterior,
                    p_tipo_archivo,
                    p_id_tempfud,
                    p_f_origen,
                    p_url_reporte,
                    p_nombre_archivo,
                    p_codigo_referencia,
                    p_enviar_api,
                    p_codigo_agencia,
                    p_nombre_agencia,
                    p_estado_reporte,
                    p_primer_nombre,
                    p_segundo_nombre,
                    p_primer_apellido,
                    p_segundo_apellido,
                    p_nacionalidad,
                    p_idproceso);
        end if;

        commit;
    exception
        when others then
            rollback;
            prespuesta := 'Error: ' || sqlerrm;
            raise_application_error(-20100, prespuesta);
    end;

    procedure logerror(pdata in out pa.tipo_documento_pkm_obj, inprogramunit in ia.log_error.programunit%type, inerrordescription in varchar2, inerrortrace in clob, outiderror out number) is
        ppackagename constant ia.log_error.packagename%type := 'PA.PKG_TIPO_DOCUMENTO_PKM';
    begin
        ia.logger.addparamvaluev('pId_Aplicacion', pdata.id_aplicacion);
        ia.logger.addparamvaluev('pId_Tipo_Documento', pdata.id_tipo_documento);
        ia.logger.addparamvaluev('pDescripcion', pdata.descripcion);
        ia.logger.addparamvaluev('pNombre_Reporte', pdata.nombre_reporte);
        ia.logger.addparamvaluev('pReutilizable', pdata.reutilizable);
        ia.logger.addparamvaluev('pAutomatico', pdata.automatico);
        ia.logger.addparamvaluev('pAdicionado_Por', pdata.adicionado_por);
        ia.logger.addparamvaluev('pFecha_Adicion', pdata.fecha_adicion);
        ia.logger.addparamvaluev('pModificado_Por', pdata.modificado_por);
        ia.logger.addparamvaluev('pFecha_Modificacion', pdata.fecha_modificacion);
        ia.logger.addparamvaluev('pEstado_Tipo_Documento', pdata.estado_tipo_documento);
        ia.logger.addparamvaluev('pEnviar_Api', pdata.enviar_api);
        ia.logger.log(inowner => sys_context('USERENV', 'CURRENT_SCHEMA'),
                      inpackagename => ppackagename,
                      inprogramunit => inprogramunit,
                      inpiececodename => null,
                      inerrordescription => inerrordescription,
                      inerrortrace => inerrortrace,
                      inemailnotification => null,
                      inparamlist => ia.logger.vparamlist,
                      inoutputlogger => false,
                      inexecutiontime => null,
                      outiderror => outiderror);


        if ia.logger.vparamlist.count > 0 then
            ia.logger.vparamlist.delete;
        end if;
    end logerror;
end pkg_tipo_documento_pkm;
/