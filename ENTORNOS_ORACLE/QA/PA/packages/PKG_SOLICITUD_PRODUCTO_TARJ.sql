CREATE OR REPLACE package body IA.pkg_solicitud_producto_tarj is
    /******************************************************************************
    NAME:       SOLICITUD PRODUCTO TARJ
    PURPOSE: Carga de los productos de la solicitud de tarjeta.

    REVISIONS:
    Ver        Date        Author             Description
    ---------  ----------  ---------------    -----------------------------------
    1.0        14/11/2022    OMAR ARIEL MARIOT  Creacion del Paquete
 ******************************************************************************/

    procedure generar(pcodigo_empresa in    varchar2,
                      pcodigo_agencia in    varchar2,
                      pcodigo_subagencia in varchar2,
                      pnumero_solicitud in  number,
                      pcodigo_oferta in     varchar2,
                      pcodigo_solicitante in varchar2,
                      pcodigo_producto in   varchar2,
                      pcod_tipo_cliente in  varchar2,
                      pcod_ciclo_fact in    varchar2,
                      pnumero_producto in   varchar2,
                      pnombre_plastico in   varchar2,
                      plimite_solicitado_rd in number,
                      plimite_solicitado_us in number,
                      pfecha_solicitud in   date,
                      pfecha_vencimiento in date,
                      pcodigo_oficial in    varchar2,
                      pcod_pais      in     varchar2,
                      pcod_provincia in     varchar2,
                      pcod_canton    in     varchar2,
                      pcod_distrito  in     varchar2,
                      pcod_ciudad    in     varchar2,
                      pdireccion_envio in   varchar2,
                      pgeo_coord_envio in   varchar2,
                      pusuario_valida in    varchar2,
                      pfecha_validacion in  date,
                      pusuario_autoriza in  varchar2,
                      pfecha_autorizacion in date,
                      pusuario_procesa in   varchar2,
                      pfecha_proceso in     date,
                      pestado_solicitud in  varchar2,
                      presultado     in out varchar2) is
        pdata ia.solicitud_producto_tarj_obj;
        vdiavigencia pls_integer := nvl(pa.param.parametro_x_empresa('1', 'VIGENCIA_SOLICITUD', 'IA'), 0);
        vaprobadoauto number := nvl(pa.param.parametro_x_empresa('1', 'XCORE_APROBADO', 'IA'), 0);
        vrechazoauto number := nvl(pa.param.parametro_x_empresa('1', 'XCORE_RECHAZADO', 'IA'), 0);
        viderror number := 0;
        psolicitantes ia.solicitante_list := ia.solicitante_list();
        vsolicitudnumero number := 0;
        vestadosolicitud tc.tc_solicitud_tarjeta.estado_solicitud%type;
        vfecha_solicitud date;
        vcodigo_agencia varchar2(5);
        vtipoidentificacion ia.ia_solicitante.tipo_identificacion%type;
        videntificacion ia.ia_solicitante.numero_identificacion%type;
    begin
        pdata := ia.solicitud_producto_tarj_obj();
        pdata.codigo_empresa := pcodigo_empresa;
        pdata.codigo_agencia := pcodigo_agencia;
        pdata.codigo_subagencia := pcodigo_subagencia;
        pdata.numero_solicitud := pnumero_solicitud;
        pdata.codigo_oferta := pcodigo_oferta;
        pdata.codigo_solicitante := pcodigo_solicitante;
        pdata.codigo_producto := pcodigo_producto;
        pdata.cod_tipo_cliente := pcod_tipo_cliente;
        pdata.cod_ciclo_fact := pcod_ciclo_fact;
        pdata.numero_producto := pnumero_producto;
        pdata.nombre_plastico := pnombre_plastico;
        pdata.limite_solicitado_rd := plimite_solicitado_rd;
        pdata.limite_solicitado_us := plimite_solicitado_us;
        pdata.fecha_solicitud := pfecha_solicitud;
        pdata.fecha_vencimiento := nvl(pfecha_vencimiento, (pfecha_solicitud + vdiavigencia));
        pdata.codigo_oficial := pcodigo_oficial;
        pdata.cod_pais := pcod_pais;
        pdata.cod_provincia := pcod_provincia;
        pdata.cod_canton := pcod_canton;
        pdata.cod_distrito := pcod_distrito;
        pdata.cod_ciudad := pcod_ciudad;
        pdata.direccion_envio := pdireccion_envio;
        pdata.geo_coord_envio := pgeo_coord_envio;
        pdata.usuario_valida := pusuario_valida;
        pdata.fecha_validacion := pfecha_validacion;
        pdata.usuario_autoriza := pusuario_autoriza;
        pdata.fecha_autorizacion := pfecha_autorizacion;
        pdata.usuario_procesa := pusuario_procesa;
        pdata.fecha_proceso := pfecha_proceso;

        psolicitantes := ia.pkg_solicitante.consultar(pcodigo_solicitante,
                                                      null,
                                                      null,
                                                      null,
                                                      null,
                                                      null,
                                                      null,
                                                      null,
                                                      null,
                                                      null,
                                                      null,
                                                      null,
                                                      null,
                                                      null,
                                                      null,
                                                      null,
                                                      null,
                                                      null,
                                                      null,
                                                      null,
                                                      null,
                                                      null,
                                                      null,
                                                      null,
                                                      null,
                                                      null,
                                                      null,
                                                      null,
                                                      null,
                                                      null,
                                                      null,
                                                      null,
                                                      null,
                                                      null,
                                                      null,
                                                      null,
                                                      null,
                                                      null,
                                                      null,
                                                      null,
                                                      null,
                                                      null,
                                                      null,
                                                      null,
                                                      null,
                                                      presultado);

        for i in 1 .. psolicitantes.count
        loop
            vtipoidentificacion := psolicitantes(i).tipo_identificacion;
            videntificacion := psolicitantes(i).numero_identificacion;

            if nvl(psolicitantes(i).xcore, 0) >= vaprobadoauto then
                pdata.estado_solicitud := 'AX';
            elsif nvl(psolicitantes(i).xcore, 0) > 0
                  and nvl(psolicitantes(i).xcore, 0) <= vrechazoauto then
                pdata.estado_solicitud := 'RX';
            else
                pdata.estado_solicitud := pestado_solicitud;
            end if;
        end loop;

        -- Verifica si ya el solicitante tiene una solicitud pendiente previa de ese mismo producto
        vestadosolicitud := 'P';
        presultado := null;
        vsolicitudnumero := 1;
        vsolicitudnumero := tc.tc_solicitud.verifica_existe_solicitud(ptipoid => vtipoidentificacion,
                                                                      pnumid => videntificacion,
                                                                      ptipoprod => pcodigo_producto,
                                                                      outfechasolicitud => vfecha_solicitud,
                                                                      outoficina => vcodigo_agencia,
                                                                      outestado => vestadosolicitud,
                                                                      outerror => presultado);

        if vsolicitudnumero > 0 then
            raise_application_error(-20100, 'Error ' || presultado);
        elsif presultado is not null then
            raise_application_error(-20100, 'Error ' || presultado);
        end if;

        if pdata.validar('G', presultado) then
            -- Existe
            if pdata.existe() = false then
                -- Insertar
                pdata.crear();
                presultado := 'Exitoso.';
            else
                -- Modificar
                pdata.actualizar();
                presultado := 'Exitoso.';
            end if;
        end if;
    exception
        when others then
            presultado := sqlerrm;
            ia.pkg_solicitud_producto_tarj.logerror(pdata => pdata,
                                                    inprogramunit => 'Generar',
                                                    inerrordescription => presultado,
                                                    inerrortrace => dbms_utility.format_error_backtrace,
                                                    outiderror => viderror);
            raise_application_error(-20100, presultado);
    end generar;


    procedure crear(pcodigo_empresa in    varchar2,
                    pcodigo_agencia in    varchar2,
                    pcodigo_subagencia in varchar2,
                    pnumero_solicitud in  number,
                    pcodigo_oferta in     varchar2,
                    pcodigo_solicitante in varchar2,
                    pcodigo_producto in   varchar2,
                    pcod_tipo_cliente in  varchar2,
                    pcod_ciclo_fact in    varchar2,
                    pnumero_producto in   varchar2,
                    pnombre_plastico in   varchar2,
                    plimite_solicitado_rd in number,
                    plimite_solicitado_us in number,
                    pfecha_solicitud in   date,
                    pfecha_vencimiento in date,
                    pcodigo_oficial in    varchar2,
                    pcod_pais      in     varchar2,
                    pcod_provincia in     varchar2,
                    pcod_canton    in     varchar2,
                    pcod_distrito  in     varchar2,
                    pcod_ciudad    in     varchar2,
                    pdireccion_envio in   varchar2,
                    pgeo_coord_envio in   varchar2,
                    pusuario_valida in    varchar2,
                    pfecha_validacion in  date,
                    pusuario_autoriza in  varchar2,
                    pfecha_autorizacion in date,
                    pusuario_procesa in   varchar2,
                    pfecha_proceso in     date,
                    pestado_solicitud in  varchar2,
                    presultado     in out varchar2) is
        pdata ia.solicitud_producto_tarj_obj;
        viderror number := 0;
    begin
        pdata := ia.solicitud_producto_tarj_obj();
        pdata.codigo_empresa := pcodigo_empresa;
        pdata.codigo_agencia := pcodigo_agencia;
        pdata.codigo_subagencia := pcodigo_subagencia;
        pdata.numero_solicitud := pnumero_solicitud;
        pdata.codigo_oferta := pcodigo_oferta;
        pdata.codigo_solicitante := pcodigo_solicitante;
        pdata.codigo_producto := pcodigo_producto;
        pdata.cod_tipo_cliente := pcod_tipo_cliente;
        pdata.cod_ciclo_fact := pcod_ciclo_fact;
        pdata.numero_producto := pnumero_producto;
        pdata.nombre_plastico := pnombre_plastico;
        pdata.limite_solicitado_rd := plimite_solicitado_rd;
        pdata.limite_solicitado_us := plimite_solicitado_us;
        pdata.fecha_solicitud := pfecha_solicitud;
        pdata.fecha_vencimiento := pfecha_vencimiento;
        pdata.codigo_oficial := pcodigo_oficial;
        pdata.cod_pais := pcod_pais;
        pdata.cod_provincia := pcod_provincia;
        pdata.cod_canton := pcod_canton;
        pdata.cod_distrito := pcod_distrito;
        pdata.cod_ciudad := pcod_ciudad;
        pdata.direccion_envio := pdireccion_envio;
        pdata.geo_coord_envio := pgeo_coord_envio;
        pdata.usuario_valida := pusuario_valida;
        pdata.fecha_validacion := pfecha_validacion;
        pdata.usuario_autoriza := pusuario_autoriza;
        pdata.fecha_autorizacion := pfecha_autorizacion;
        pdata.usuario_procesa := pusuario_procesa;
        pdata.fecha_proceso := pfecha_proceso;
        pdata.estado_solicitud := pestado_solicitud;

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
            ia.pkg_solicitud_producto_tarj.logerror(pdata => pdata,
                                                    inprogramunit => 'Crear',
                                                    inerrordescription => presultado,
                                                    inerrortrace => dbms_utility.format_error_backtrace,
                                                    outiderror => viderror);
            raise_application_error(-20100, 'Error ' || sqlerrm);
    end crear;


    procedure actualizar(pcodigo_empresa in    varchar2,
                         pcodigo_agencia in    varchar2,
                         pcodigo_subagencia in varchar2,
                         pnumero_solicitud in  number,
                         pcodigo_oferta in     varchar2,
                         pcodigo_solicitante in varchar2,
                         pcodigo_producto in   varchar2,
                         pcod_tipo_cliente in  varchar2,
                         pcod_ciclo_fact in    varchar2,
                         pnumero_producto in   varchar2,
                         pnombre_plastico in   varchar2,
                         plimite_solicitado_rd in number,
                         plimite_solicitado_us in number,
                         pfecha_solicitud in   date,
                         pfecha_vencimiento in date,
                         pcodigo_oficial in    varchar2,
                         pcod_pais      in     varchar2,
                         pcod_provincia in     varchar2,
                         pcod_canton    in     varchar2,
                         pcod_distrito  in     varchar2,
                         pcod_ciudad    in     varchar2,
                         pdireccion_envio in   varchar2,
                         pgeo_coord_envio in   varchar2,
                         pusuario_valida in    varchar2,
                         pfecha_validacion in  date,
                         pusuario_autoriza in  varchar2,
                         pfecha_autorizacion in date,
                         pusuario_procesa in   varchar2,
                         pfecha_proceso in     date,
                         pestado_solicitud in  varchar2,
                         presultado     in out varchar2) is
        pdata ia.solicitud_producto_tarj_obj;
        viderror number := 0;
    begin
        pdata := ia.solicitud_producto_tarj_obj();
        pdata.codigo_empresa := pcodigo_empresa;
        pdata.codigo_agencia := pcodigo_agencia;
        pdata.codigo_subagencia := pcodigo_subagencia;
        pdata.numero_solicitud := pnumero_solicitud;
        pdata.codigo_oferta := pcodigo_oferta;
        pdata.codigo_solicitante := pcodigo_solicitante;
        pdata.codigo_producto := pcodigo_producto;
        pdata.cod_tipo_cliente := pcod_tipo_cliente;
        pdata.cod_ciclo_fact := pcod_ciclo_fact;
        pdata.numero_producto := pnumero_producto;
        pdata.nombre_plastico := pnombre_plastico;
        pdata.limite_solicitado_rd := plimite_solicitado_rd;
        pdata.limite_solicitado_us := plimite_solicitado_us;
        pdata.fecha_solicitud := pfecha_solicitud;
        pdata.fecha_vencimiento := pfecha_vencimiento;
        pdata.codigo_oficial := pcodigo_oficial;
        pdata.cod_pais := pcod_pais;
        pdata.cod_provincia := pcod_provincia;
        pdata.cod_canton := pcod_canton;
        pdata.cod_distrito := pcod_distrito;
        pdata.cod_ciudad := pcod_ciudad;
        pdata.direccion_envio := pdireccion_envio;
        pdata.geo_coord_envio := pgeo_coord_envio;
        pdata.usuario_valida := pusuario_valida;
        pdata.fecha_validacion := pfecha_validacion;
        pdata.usuario_autoriza := pusuario_autoriza;
        pdata.fecha_autorizacion := pfecha_autorizacion;
        pdata.usuario_procesa := pusuario_procesa;
        pdata.fecha_proceso := pfecha_proceso;
        pdata.estado_solicitud := pestado_solicitud;

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
            ia.pkg_solicitud_producto_tarj.logerror(pdata => pdata,
                                                    inprogramunit => 'Actualizar',
                                                    inerrordescription => presultado,
                                                    inerrortrace => dbms_utility.format_error_backtrace,
                                                    outiderror => viderror);
            raise_application_error(-20100, 'Error ' || sqlerrm);
    end actualizar;

    procedure cambiaestadosolicitud(pcodigo_empresa in    varchar2,
                                    pcodigo_agencia in    varchar2,
                                    pcodigo_subagencia in varchar2,
                                    pnumero_solicitud in  number,
                                    pcodigo_solicitante in varchar2,
                                    pcodigo_producto in   varchar2,
                                    pestado        in     varchar2,
                                    pmotivo        in     varchar2,
                                    presultado     in out varchar2) is
        pragma autonomous_transaction;
    begin
        begin
            update ia.ia_solicitud_producto_tarjeta p
            set p.estado_solicitud = pestado, p.motivo = pmotivo
            where p.codigo_empresa = pcodigo_empresa
            /*AND (p.CODIGO_AGENCIA = pCodigo_Agencia OR pCodigo_Agencia IS NULL)
            AND (p.CODIGO_SUBAGENCIA = pCodigo_Subagencia OR pCodigo_Subagencia IS NULL)*/
            and   p.numero_solicitud = pnumero_solicitud
            and   p.codigo_solicitante = pcodigo_solicitante
            and   p.codigo_producto = pcodigo_producto
            and   p.estado_solicitud in ('AU', 'AX');

            if pestado in ('AU', 'AX') then
                presultado := 'Solicitud No.' || pnumero_solicitud || ' ha sido aprobada.';
            elsif pestado in ('RU', 'RX') then
                presultado := 'Solicitud No.' || pnumero_solicitud || ' ha sido rechazada.';
            else
                presultado := 'Proceso Realizado';
            end if;
        exception
            when others then
                presultado := 'Error actualizando la solicitud del producto.  ' || sqlerrm;
                raise_application_error(-20103, presultado);
        end;

        commit;
    end cambiaestadosolicitud;

    procedure borrar(pcodigo_empresa in    varchar2,
                     pcodigo_agencia in    varchar2,
                     pcodigo_subagencia in varchar2,
                     pnumero_solicitud in  number,
                     pcodigo_solicitante in varchar2,
                     pcodigo_producto in   varchar2,
                     presultado     in out varchar2) is
        pdata ia.solicitud_producto_tarj_obj;
        viderror number := 0;
    begin
        pdata := ia.solicitud_producto_tarj_obj();
        pdata.codigo_empresa := pcodigo_empresa;
        pdata.codigo_agencia := pcodigo_agencia;
        pdata.codigo_subagencia := pcodigo_subagencia;
        pdata.numero_solicitud := pnumero_solicitud;
        pdata.codigo_solicitante := pcodigo_solicitante;
        pdata.codigo_producto := pcodigo_producto;

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
            ia.pkg_solicitud_producto_tarj.logerror(pdata => pdata,
                                                    inprogramunit => 'Borrar',
                                                    inerrordescription => presultado,
                                                    inerrortrace => dbms_utility.format_error_backtrace,
                                                    outiderror => viderror);
            raise_application_error(-20100, 'Error ' || sqlerrm);
    end borrar;


    function consultar(pcodigo_empresa in    varchar2,
                       pcodigo_agencia in    varchar2,
                       pcodigo_subagencia in varchar2,
                       pnumero_solicitud in  number,
                       pcodigo_oferta in     varchar2,
                       pcodigo_solicitante in varchar2,
                       pcodigo_producto in   varchar2,
                       pcod_tipo_cliente in  varchar2,
                       pcod_ciclo_fact in    varchar2,
                       pnumero_producto in   varchar2,
                       pnombre_plastico in   varchar2,
                       plimite_solicitado_rd in number,
                       plimite_solicitado_us in number,
                       pfecha_solicitud in   date,
                       pfecha_vencimiento in date,
                       pcodigo_oficial in    varchar2,
                       pcod_pais      in     varchar2,
                       pcod_provincia in     varchar2,
                       pcod_canton    in     varchar2,
                       pcod_distrito  in     varchar2,
                       pcod_ciudad    in     varchar2,
                       pdireccion_envio in   varchar2,
                       pgeo_coord_envio in   varchar2,
                       pusuario_valida in    varchar2,
                       pfecha_validacion in  date,
                       pusuario_autoriza in  varchar2,
                       pfecha_autorizacion in date,
                       pusuario_procesa in   varchar2,
                       pfecha_proceso in     date,
                       padicionado_por in    varchar2,
                       pfecha_adicion in     date,
                       pmodificado_por in    varchar2,
                       pfecha_modificacion in date,
                       pestado_solicitud in  varchar2,
                       presultado     in out varchar2)
        return ia.solicitud_producto_tarj_list is
        cursor cdata is
            select *
            from ia.ia_solicitud_producto_tarjeta t1
            where (t1.codigo_empresa = pcodigo_empresa
            or     pcodigo_empresa is null)
            and   (t1.codigo_agencia = pcodigo_agencia
            or     pcodigo_agencia is null)
            and   (t1.codigo_subagencia = pcodigo_subagencia
            or     pcodigo_subagencia is null)
            and   (t1.numero_solicitud = pnumero_solicitud
            or     pnumero_solicitud is null)
            and   (t1.codigo_oferta = pcodigo_oferta
            or     pcodigo_oferta is null)
            and   (t1.codigo_solicitante = pcodigo_solicitante
            or     pcodigo_solicitante is null)
            and   (t1.codigo_producto = pcodigo_producto
            or     pcodigo_producto is null)
            and   (t1.cod_tipo_cliente = pcod_tipo_cliente
            or     pcod_tipo_cliente is null)
            and   (t1.cod_ciclo_fact = pcod_ciclo_fact
            or     pcod_ciclo_fact is null)
            and   (t1.numero_producto = pnumero_producto
            or     pnumero_producto is null)
            and   (t1.nombre_plastico = pnombre_plastico
            or     pnombre_plastico is null)
            and   (t1.limite_solicitado_rd = plimite_solicitado_rd
            or     plimite_solicitado_rd is null)
            and   (t1.limite_solicitado_us = plimite_solicitado_us
            or     plimite_solicitado_us is null)
            and   (t1.fecha_solicitud = pfecha_solicitud
            or     pfecha_solicitud is null)
            and   (t1.fecha_vencimiento = pfecha_vencimiento
            or     pfecha_vencimiento is null)
            and   (t1.codigo_oficial = pcodigo_oficial
            or     pcodigo_oficial is null)
            and   (t1.cod_pais = pcod_pais
            or     pcod_pais is null)
            and   (t1.cod_provincia = pcod_provincia
            or     pcod_provincia is null)
            and   (t1.cod_canton = pcod_canton
            or     pcod_canton is null)
            and   (t1.cod_distrito = pcod_distrito
            or     pcod_distrito is null)
            and   (t1.cod_ciudad = pcod_ciudad
            or     pcod_ciudad is null)
            and   (t1.direccion_envio = pdireccion_envio
            or     pdireccion_envio is null)
            and   (t1.geo_coord_envio = pgeo_coord_envio
            or     pgeo_coord_envio is null)
            and   (t1.usuario_valida = pusuario_valida
            or     pusuario_valida is null)
            and   (t1.fecha_validacion = pfecha_validacion
            or     pfecha_validacion is null)
            and   (t1.usuario_autoriza = pusuario_autoriza
            or     pusuario_autoriza is null)
            and   (t1.fecha_autorizacion = pfecha_autorizacion
            or     pfecha_autorizacion is null)
            and   (t1.usuario_procesa = pusuario_procesa
            or     pusuario_procesa is null)
            and   (t1.fecha_proceso = pfecha_proceso
            or     pfecha_proceso is null)
            and   (t1.adicionado_por = padicionado_por
            or     padicionado_por is null)
            and   (t1.fecha_adicion = pfecha_adicion
            or     pfecha_adicion is null)
            and   (t1.modificado_por = pmodificado_por
            or     pmodificado_por is null)
            and   (t1.fecha_modificacion = pfecha_modificacion
            or     pfecha_modificacion is null)
            and   (t1.estado_solicitud = pestado_solicitud
            or     pestado_solicitud is null);

        type tdata is table of cdata%rowtype;

        vdata tdata;
        vdatalist ia.solicitud_producto_tarj_list := ia.solicitud_producto_tarj_list();
        pdata ia.solicitud_producto_tarj_obj;
        indice number := 0;
        viderror number := 0;
    begin
        vdatalist.delete;

        open cdata;

        loop
            fetch cdata bulk   collect into vdata limit 5000;

            for i in 1 .. vdata.count
            loop
                pdata := ia.solicitud_producto_tarj_obj();
                pdata.codigo_empresa := vdata(i).codigo_empresa;
                pdata.codigo_agencia := vdata(i).codigo_agencia;
                pdata.codigo_subagencia := vdata(i).codigo_subagencia;
                pdata.numero_solicitud := vdata(i).numero_solicitud;
                pdata.codigo_oferta := vdata(i).codigo_oferta;
                pdata.codigo_solicitante := vdata(i).codigo_solicitante;
                pdata.codigo_producto := vdata(i).codigo_producto;
                pdata.cod_tipo_cliente := vdata(i).cod_tipo_cliente;
                pdata.numero_producto := vdata(i).numero_producto;
                pdata.nombre_plastico := vdata(i).nombre_plastico;
                pdata.limite_solicitado_rd := vdata(i).limite_solicitado_rd;
                pdata.limite_solicitado_us := vdata(i).limite_solicitado_us;
                pdata.fecha_solicitud := vdata(i).fecha_solicitud;
                pdata.fecha_vencimiento := vdata(i).fecha_vencimiento;
                pdata.codigo_oficial := vdata(i).codigo_oficial;
                pdata.cod_pais := vdata(i).cod_pais;
                pdata.cod_provincia := vdata(i).cod_provincia;
                pdata.cod_canton := vdata(i).cod_canton;
                pdata.cod_distrito := vdata(i).cod_distrito;
                pdata.cod_ciudad := vdata(i).cod_ciudad;
                pdata.direccion_envio := vdata(i).direccion_envio;
                pdata.geo_coord_envio := vdata(i).geo_coord_envio;
                pdata.usuario_valida := vdata(i).usuario_valida;
                pdata.fecha_validacion := vdata(i).fecha_validacion;
                pdata.usuario_autoriza := vdata(i).usuario_autoriza;
                pdata.fecha_autorizacion := vdata(i).fecha_autorizacion;
                pdata.usuario_procesa := vdata(i).usuario_procesa;
                pdata.fecha_proceso := vdata(i).fecha_proceso;
                pdata.adicionado_por := vdata(i).adicionado_por;
                pdata.fecha_adicion := vdata(i).fecha_adicion;
                pdata.modificado_por := vdata(i).modificado_por;
                pdata.fecha_modificacion := vdata(i).fecha_modificacion;
                pdata.estado_solicitud := vdata(i).estado_solicitud;
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
            ia.pkg_solicitud_producto_tarj.logerror(pdata => pdata,
                                                    inprogramunit => 'Consultar',
                                                    inerrordescription => presultado,
                                                    inerrortrace => dbms_utility.format_error_backtrace,
                                                    outiderror => viderror);
            raise_application_error(-20404, 'Error ' || sqlerrm);
    end consultar;

    function comparar(pdata1 in out ia.solicitud_producto_tarj_obj, pdata2 in out ia.solicitud_producto_tarj_obj, pmodo in varchar2, presultado in out varchar2)
        -- O = (Compare between Objects pData1 and pData2),
        -- T = (Compare pData1 and Table data "Must used pData2 like search parameter in table)
        return boolean is
        vigual boolean := false;
        vdatalist ia.solicitud_producto_tarj_list := ia.solicitud_producto_tarj_list();
        vdata ia.solicitud_producto_tarj_obj := ia.solicitud_producto_tarj_obj();
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
            vdatalist := consultar(pcodigo_empresa => pdata2.codigo_empresa,
                                   pcodigo_agencia => pdata2.codigo_agencia,
                                   pcodigo_subagencia => pdata2.codigo_subagencia,
                                   pnumero_solicitud => pdata2.numero_solicitud,
                                   pcodigo_oferta => pdata2.codigo_oferta,
                                   pcodigo_solicitante => pdata2.codigo_solicitante,
                                   pcodigo_producto => pdata2.codigo_producto,
                                   pcod_tipo_cliente => pdata2.cod_tipo_cliente,
                                   pcod_ciclo_fact => pdata2.cod_ciclo_fact,
                                   pnumero_producto => pdata2.numero_producto,
                                   pnombre_plastico => pdata2.nombre_plastico,
                                   plimite_solicitado_rd => pdata2.limite_solicitado_rd,
                                   plimite_solicitado_us => pdata2.limite_solicitado_us,
                                   pfecha_solicitud => pdata2.fecha_solicitud,
                                   pfecha_vencimiento => pdata2.fecha_vencimiento,
                                   pcodigo_oficial => pdata2.codigo_oficial,
                                   pcod_pais => pdata2.cod_pais,
                                   pcod_provincia => pdata2.cod_provincia,
                                   pcod_canton => pdata2.cod_canton,
                                   pcod_distrito => pdata2.cod_distrito,
                                   pcod_ciudad => pdata2.cod_ciudad,
                                   pdireccion_envio => pdata2.direccion_envio,
                                   pgeo_coord_envio => pdata2.geo_coord_envio,
                                   pusuario_valida => pdata2.usuario_valida,
                                   pfecha_validacion => pdata2.fecha_validacion,
                                   pusuario_autoriza => pdata2.usuario_autoriza,
                                   pfecha_autorizacion => pdata2.fecha_autorizacion,
                                   pusuario_procesa => pdata2.usuario_procesa,
                                   pfecha_proceso => pdata2.fecha_proceso,
                                   padicionado_por => pdata2.adicionado_por,
                                   pfecha_adicion => pdata2.fecha_adicion,
                                   pmodificado_por => pdata2.modificado_por,
                                   pfecha_modificacion => pdata2.fecha_modificacion,
                                   pestado_solicitud => pdata2.estado_solicitud,
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

    function existe(pcodigo_empresa in    varchar2,
                    pcodigo_agencia in    varchar2,
                    pcodigo_subagencia in varchar2,
                    pnumero_solicitud in  number,
                    pcodigo_oferta in     varchar2,
                    pcodigo_solicitante in varchar2,
                    pcodigo_producto in   varchar2,
                    presultado     in out varchar2)
        return boolean is
        pdata ia.solicitud_producto_tarj_obj;
        viderror number := 0;
    begin
        pdata := ia.solicitud_producto_tarj_obj();
        pdata.codigo_empresa := pcodigo_empresa;
        pdata.codigo_agencia := pcodigo_agencia;
        pdata.codigo_subagencia := pcodigo_subagencia;
        pdata.numero_solicitud := pnumero_solicitud;
        pdata.codigo_oferta := pcodigo_oferta;
        pdata.codigo_solicitante := pcodigo_solicitante;
        presultado := 'Exitoso.';
        return pdata.existe();
    exception
        when others then
            presultado := sqlcode || ': ' || sqlerrm;
            ia.pkg_solicitud_producto_tarj.logerror(pdata => pdata,
                                                    inprogramunit => 'Existe',
                                                    inerrordescription => presultado,
                                                    inerrortrace => dbms_utility.format_error_backtrace,
                                                    outiderror => viderror);
            raise_application_error(-20404, 'Error ' || sqlerrm);
    end existe;

    function validar(pcodigo_empresa in    varchar2,
                     pcodigo_agencia in    varchar2,
                     pcodigo_subagencia in varchar2,
                     pnumero_solicitud in  number,
                     pcodigo_oferta in     varchar2,
                     pcodigo_solicitante in varchar2,
                     pcodigo_producto in   varchar2,
                     pcod_tipo_cliente in  varchar2,
                     pcod_ciclo_fact in    varchar2,
                     pnumero_producto in   varchar2,
                     pnombre_plastico in   varchar2,
                     plimite_solicitado_rd in number,
                     plimite_solicitado_us in number,
                     pfecha_solicitud in   date,
                     pfecha_vencimiento in date,
                     pcodigo_oficial in    varchar2,
                     pcod_pais      in     varchar2,
                     pcod_provincia in     varchar2,
                     pcod_canton    in     varchar2,
                     pcod_distrito  in     varchar2,
                     pcod_ciudad    in     varchar2,
                     pdireccion_envio in   varchar2,
                     pgeo_coord_envio in   varchar2,
                     pusuario_valida in    varchar2,
                     pfecha_validacion in  date,
                     pusuario_autoriza in  varchar2,
                     pfecha_autorizacion in date,
                     pusuario_procesa in   varchar2,
                     pfecha_proceso in     date,
                     pestado_solicitud in  varchar2,
                     poperacion     in     varchar2, -- G=Generar, C=Crear, U=Actualizar, D=Borrar
                     perror         in out varchar2)
        return boolean is
        pdata ia.solicitud_producto_tarj_obj;
        vvalidar boolean := false;
        viderror number := 0;
    begin
        pdata := ia.solicitud_producto_tarj_obj();
        pdata.codigo_empresa := pcodigo_empresa;
        pdata.codigo_agencia := pcodigo_agencia;
        pdata.codigo_subagencia := pcodigo_subagencia;
        pdata.numero_solicitud := pnumero_solicitud;
        pdata.codigo_oferta := pcodigo_oferta;
        pdata.codigo_solicitante := pcodigo_solicitante;
        pdata.codigo_producto := pcodigo_producto;
        pdata.cod_tipo_cliente := pcod_tipo_cliente;
        pdata.cod_ciclo_fact := pcod_ciclo_fact;
        pdata.numero_producto := pnumero_producto;
        pdata.nombre_plastico := pnombre_plastico;
        pdata.limite_solicitado_rd := plimite_solicitado_rd;
        pdata.limite_solicitado_us := plimite_solicitado_us;
        pdata.fecha_solicitud := pfecha_solicitud;
        pdata.fecha_vencimiento := pfecha_vencimiento;
        pdata.codigo_oficial := pcodigo_oficial;
        pdata.cod_pais := pcod_pais;
        pdata.cod_provincia := pcod_provincia;
        pdata.cod_canton := pcod_canton;
        pdata.cod_distrito := pcod_distrito;
        pdata.cod_ciudad := pcod_ciudad;
        pdata.direccion_envio := pdireccion_envio;
        pdata.geo_coord_envio := pgeo_coord_envio;
        pdata.usuario_valida := pusuario_valida;
        pdata.fecha_validacion := pfecha_validacion;
        pdata.usuario_autoriza := pusuario_autoriza;
        pdata.fecha_autorizacion := pfecha_autorizacion;
        pdata.usuario_procesa := pusuario_procesa;
        pdata.fecha_proceso := pfecha_proceso;
        pdata.estado_solicitud := pestado_solicitud;
        vvalidar := pdata.validar(poperacion, perror);
        ia.pkg_solicitud_producto_tarj.logerror(pdata => pdata, inprogramunit => 'Validar', inerrordescription => perror, inerrortrace => dbms_utility.format_error_backtrace, outiderror => viderror);
        return vvalidar;
    end validar;

    -- PROCEDIMIENTO PARA EL JOB
    procedure cargarsolicitudesaprobadas(pfecha in date, psolicitud in number, pcodigosolicitante in number, pcodigoproducto in number, presultado in out varchar2) is
        cursor csolicitud is
            select *
            from ia.ia_solicitud_producto_tarjeta p
            where p.codigo_empresa = '1'
            and   (p.numero_solicitud = psolicitud
            or     psolicitud is null)
            and   (p.codigo_solicitante = pcodigosolicitante
            or     pcodigosolicitante is null)
            and   (p.codigo_producto = pcodigoproducto
            or     pcodigoproducto is null)
            and   (p.fecha_solicitud = pfecha
            or     pfecha is null)
            and   p.estado_solicitud in ('AX', 'AU');

        type tsoltarj is table of csolicitud%rowtype;

        vsolicitudtarjeta tsoltarj := tsoltarj();
        vsolicitudcore tc.tc_solicitud_tarjeta.no_solicitud%type;
        vcodigocliente pa.clientes_b2000.cod_cliente%type;

        pragma autonomous_transaction;
    begin
        open csolicitud;

        loop
            fetch csolicitud bulk   collect into vsolicitudtarjeta limit 5000;

            for i in 1 .. vsolicitudtarjeta.count
            loop
                dbms_output.put_line(
                    'Procesando Solicitud=' || vsolicitudtarjeta(i).numero_solicitud || ' Solicitante=' || vsolicitudtarjeta(i).codigo_solicitante || ' Producto=' || vsolicitudtarjeta(i).
                    codigo_producto);

                procesarsolicitudcore(vsolicitudtarjeta(i).codigo_empresa,
                                      vsolicitudtarjeta(i).codigo_agencia,
                                      vsolicitudtarjeta(i).codigo_subagencia,
                                      vsolicitudtarjeta(i).numero_solicitud,
                                      vsolicitudtarjeta(i).codigo_solicitante,
                                      vsolicitudtarjeta(i).codigo_producto,
                                      vcodigocliente,
                                      vsolicitudcore,
                                      presultado);

                dbms_output.put_line('RESULTADO: ' || presultado || ' Cliente=' || vcodigocliente || ' Solicitud=' || vsolicitudcore);
            --DBMS_OUTPUT.PUT_LINE('Cliente='|| vCodigoCliente||' Solicitud='|| vSolicitudCore);
            end loop;

            exit when csolicitud%notfound;
        end loop;

        close csolicitud;
    exception
        when others then
            presultado := 'Error no hay solicitudes para procesar';
            raise_application_error(-20100, presultado);
    end cargarsolicitudesaprobadas;

    procedure procesarsolicitudcore(pcodigo_empresa in    varchar2,
                                    pcodigo_agencia in    varchar2,
                                    pcodigo_subagencia in varchar2,
                                    pnumero_solicitud in  number,
                                    pcodigo_solicitante in varchar2,
                                    pcodigo_producto in   varchar2,
                                    pcodigocliente in out varchar2,
                                    psolicitudcore in out varchar2,
                                    presultado     in out varchar2) is
        cursor c_datos is
            select p.codigo_empresa,
                   p.codigo_agencia,
                   p.codigo_subagencia,
                   p.numero_solicitud,
                   p.codigo_oferta,
                   p.codigo_solicitante,
                   p.codigo_producto,
                   p.cod_tipo_cliente,
                   cc.cod_grupo cod_ciclo_fact,
                   p.numero_producto,
                   p.nombre_plastico,
                   nvl(p.limite_solicitado_rd, 0) limite_solicitado_rd,
                   nvl(p.limite_solicitado_us, 0) limite_solicitado_us,
                   p.fecha_solicitud,
                   p.fecha_vencimiento,
                   p.codigo_oficial,
                   s.cod_pais cod_pais_envio,
                   s.cod_provincia cod_provincia_envio,
                   s.cod_distrito cod_canton_envio,
                   s.cod_ciudad cod_distrito_envio,
                   s.cod_ciudad cod_ciudad_envio,
                   p.direccion_envio,
                   p.geo_coord_envio,
                   p.usuario_valida,
                   p.fecha_validacion,
                   p.usuario_autoriza,
                   p.fecha_autorizacion,
                   p.usuario_procesa,
                   p.fecha_proceso,
                   p.estado_solicitud,
                   nvl(s.tipo_identificacion, '1') tipo_identificacion,
                   s.numero_identificacion,
                   s.primer_nombre,
                   s.segundo_nombre,
                   s.primer_apellido,
                   s.segundo_apellido,
                   s.nombre_completo,
                   s.nacionalidad,
                   s.fecha_nacimiento,
                   s.sexo,
                   s.estado_civil,
                   s.cod_pais,
                   s.cod_provincia,
                   s.cod_canton,
                   s.cod_distrito,
                   s.cod_ciudad,
                   s.sector_res,
                   s.barrio_res,
                   s.calle_res,
                   s.numero_res,
                   s.detalle_res,
                   s.direccion,
                   s.geo_coord,
                   s.email,
                   nvl(s.telefono_residencia, '0000000000') telefono_residencia,
                   nvl(s.telefono_celular, '0000000000') telefono_celular,
                   nvl(s.telefono_trabajo, '0000000000') telefono_trabajo,
                   s.codigo_actividad,
                   s.intitucion_laboral,
                   s.puesto,
                   s.fecha_ingreso_puesto,
                   s.ingresos,
                   s.gastos,
                   s.xcore,
                   s.tipo_cliente,
                   s.clasificacion_sb,
                   s.codigo_cliente,
                   s.estado_solicitante,
                   s.origen_datos,
                   s.tipo_gen_divisas,
                   s.ocupacion_clasif_nac,
                   s.pep_codigo_persona,             --Solicitud 32935
                   s.pep_identificacion,             --Solicitud 32935
                   s.pep_nombre,                     --Solicitud 32935
                   s.pep_cargo,                      --Solicitud 32935
                   s.pep_fecha_ingreso,              --Solicitud 32935
                   s.pep_fecha_vencimiento,          --Solicitud 32935
                   s.pep_apodo,                      --Solicitud 32935 
                   s.pep_codigo_parentesco,          --Solicitud 32935
                   s.pep_institucion_politica,       --Solicitud 32935
                   s.pep_cod_moneda,                 --Solicitud 32935
                   s.pep_codigo_pais,                --Solicitud 32935
                   s.pep_nombre_persona_relacionada, --Solicitud 32935
                   s.autoriza_consulta_datacredito   --Solicitud 32935
            from ia.ia_solicitud_producto_tarjeta p, ia.ia_solicitante s, tc.ciclo_corte_v cc
            where p.codigo_empresa = pcodigo_empresa
            --and p.CODIGO_AGENCIA        = pCodigo_Agencia
            --and p.CODIGO_SUBAGENCIA     = pCodigo_Subagencia
            and   p.numero_solicitud = pnumero_solicitud
            and   p.codigo_solicitante = pcodigo_solicitante            
            and   p.codigo_solicitante = s.codigo_solicitante
            and   p.codigo_producto = pcodigo_producto
            and   p.cod_ciclo_fact = cc.dia_corte
            AND   p.estado_solicitud in ('AX', 'AU');

        type tsolicitante is table of c_datos%rowtype;

        vsolicitante tsolicitante;

        vnum_dependientes varchar2(10) := null;
        vprofesion varchar2(10) := null;
        vtipovivienda varchar2(10) := null;
        vexttelefono varchar2(10) := null;
        vzpostalcorresp varchar2(10) := null;

        outestado_civil varchar2(10);
        outsexo varchar2(10);
        outfecha_nacimiento varchar2(15);
        outapellido1 varchar2(60);
        outapellido2 varchar2(60);
        outprimernombre varchar2(60);
        outsegundonombre varchar2(60);
        outnum_dependientes varchar2(60);
        outprofesion varchar2(60);
        outtipovivienda varchar2(60);
        outcodpais varchar2(60);
        outcodprovincia varchar2(60);
        outcodcanton varchar2(60);
        outcoddistrito varchar2(60);
        outcodciudad varchar2(60);

        vprimernombreadic1 varchar2(10) := null;
        vsegundonombreadic1 varchar2(10) := null;
        vprimerapellidoadic1 varchar2(10) := null;
        vsegundoapellidoadic1 varchar2(10) := null;
        vnombreplasticoadic1 varchar2(10) := null;
        vfechanacimientoadic1 varchar2(10) := null;
        vsexoadic1 varchar2(10) := null;
        vestadociviladic1 varchar2(10) := null;
        vemailadic1 varchar2(10) := null;
        vtelefonoadic1 varchar2(10) := null;
        vno_solicitud_adic1 varchar2(10) := null;

        vprimernombreadic2 varchar2(10) := null;
        vsegundonombreadic2 varchar2(10) := null;
        vprimerapellidoadic2 varchar2(10) := null;
        vsegundoapellidoadic2 varchar2(10) := null;
        vnombreplasticoadic2 varchar2(10) := null;
        vfechanacimientoadic2 varchar2(10) := null;
        vsexoadic2 varchar2(10) := null;
        vestadociviladic2 varchar2(10) := null;
        vemailadic2 varchar2(10) := null;
        vtelefonoadic2 varchar2(10) := null;
        vno_solicitud_adic2 varchar2(10) := null;
        vesempleado varchar2(60) := null;
        vescliente number := 0;
        vcod_pais sectores.cod_pais%type;
        vcod_provincia sectores.cod_provincia%type;
        vcod_canton sectores.cod_canton%type;
        vcod_distrito sectores.cod_distrito%type;
        vcod_pueblo sectores.cod_pueblo%type;
        vcod_sector sectores.cod_sector%type;
        --vValor                  NUMBER;

        vidpersonas pa.id_personas_list := pa.id_personas_list();
        vidpersona pa.id_personas_obj := pa.id_personas_obj();
        vdirpersonas pa.dir_personas_list := pa.dir_personas_list();
        vdirpersona pa.dir_personas_obj := pa.dir_personas_obj();
        vtelpersonas pa.tel_personas_list := pa.tel_personas_list();
        vtelpersona pa.tel_personas_obj := pa.tel_personas_obj();
        vdirenvioxpers pa.dir_envio_x_pers_obj := pa.dir_envio_x_pers_obj();
        vinfolaboral pa.info_laboral_obj := pa.info_laboral_obj();
        vctacliotrbancos pa.ctas_clientes_otr_bancos_list := pa.ctas_clientes_otr_bancos_list();
        vrefpersonales pa.ref_personales_list := pa.ref_personales_list();
        vrefpersonal pa.ref_personales_obj := pa.ref_personales_obj();
        vrefcomerciales pa.ref_comerciales_list := pa.ref_comerciales_list();
        vrefcomercial pa.ref_comerciales_obj := pa.ref_comerciales_obj();
        vinfoprodsol pa.info_prod_sol_obj := pa.info_prod_sol_obj();
        vlistapep pa.lista_pep_list := pa.lista_pep_list();
        vpersonapep PA.LISTA_PEP_OBJ := PA.LISTA_PEP_OBJ(); --Solicitud 32935
        vpromocionpersonas pa.promocion_persona_list := pa.promocion_persona_list();
        vcanal      pa.canal_solicitud_obj := pa.canal_solicitud_obj();
        vnumtelefono varchar2(12);
        vareatelefono varchar2(12);
        vindtel pls_integer := 0;
        vindref pls_integer := 0;
        vmascara varchar2(60);
        vfecha date;
    begin
        open c_datos;

        loop
            fetch c_datos bulk   collect into vsolicitante limit 500;

            exit when c_datos%notfound;
        end loop;

        close c_datos;
        
        for i in 1 .. vsolicitante.count
        loop
            dbms_output.put_line('Iniciar Generar Cliente');

            begin
                presultado := null;

                begin
                    select mascara
                    into vmascara
                    from tipos_id
                    where cod_tipo_id = vsolicitante(i).tipo_identificacion;
                exception
                    when others then
                        vmascara := 'NNN-NNNNNNN-N';
                end;

                -- Llenar Identificacion
                vidpersonas := pa.id_personas_list();
                vidpersona := pa.id_personas_obj();
                vidpersona.cod_tipo_id := vsolicitante(i).tipo_identificacion;
                vidpersona.num_id := pa.formatear_identificacion(replace(vsolicitante(i).numero_identificacion, '-'), vmascara, 'ESPA');
                vidpersona.fec_vencimiento := to_date('31/12/2050', 'DD/MM/RRRR');
                vidpersona.cod_pais := '1';
                vidpersona.nacionalidad := vsolicitante(i).nacionalidad;
                vidpersonas.extend;
                vidpersonas(1) := vidpersona;

                -- Llenar Direcciones
                vdirpersonas := pa.dir_personas_list();
                vdirpersona := pa.dir_personas_obj();
                vdirpersona.tip_direccion := '1'; -- Direccion donde Vive
                vdirpersona.detalle := vsolicitante(i).direccion;
                vdirpersona.cod_pais := vsolicitante(i).cod_pais;
                vdirpersona.cod_provincia := vsolicitante(i).cod_provincia;
                vdirpersona.cod_canton := vsolicitante(i).cod_canton;
                vdirpersona.cod_distrito := vsolicitante(i).cod_distrito;
                vdirpersona.cod_pueblo := vsolicitante(i).cod_ciudad;
                vdirpersona.es_default := 'S';
                vdirpersonas.extend;
                vdirpersonas(1) := vdirpersona;
                /*vDirPersona.TIP_DIRECCION   := '2';                     -- Direccion de trabajo
                vDirPersona.DETALLE         := 'AV PEDRO H UREÑA NO.78';
                vDirPersona.COD_PAIS        := vSolicitante(i).COD_PAIS;
                vDirPersona.COD_PROVINCIA   := '1';
                vDirPersona.COD_CANTON      := '1';
                vDirPersona.COD_DISTRITO    := '1';
                vDirPersona.COD_PUEBLO      := '1';
                vDirPersona.ES_DEFAULT      := 'N';
                vDirPersonas.EXTEND;
                vDirPersonas(2)             := vDirPersona;*/

                -- Llenar Telefonos
                vtelpersonas := pa.tel_personas_list();
                vtelpersona := pa.tel_personas_obj();
                vindtel := 0;

                if vsolicitante(i).telefono_residencia is not null then
                    vareatelefono := substr(vsolicitante(i).telefono_residencia, 1, 3);
                    vnumtelefono := substr(vsolicitante(i).telefono_residencia, 4, 10);
                    -- Telefono Residencia
                    vtelpersona.cod_area := vareatelefono;
                    vtelpersona.num_telefono := vnumtelefono;
                    vtelpersona.tip_telefono := 'D'; -- Linea Directa
                    vtelpersona.tel_ubicacion := 'C'; -- Casa
                    vtelpersona.es_default := 'N';
                    vtelpersona.cod_pais := vsolicitante(i).cod_pais;
                    vindtel := vindtel + 1;
                    vtelpersonas.extend;
                    vtelpersonas(vindtel) := vtelpersona;
                end if;

                if vsolicitante(i).telefono_celular is not null then
                    vareatelefono := substr(vsolicitante(i).telefono_celular, 1, 3);
                    vnumtelefono := substr(vsolicitante(i).telefono_celular, 4, 10);
                    -- Telefono Celular
                    vtelpersona.cod_area := vareatelefono;
                    vtelpersona.num_telefono := vnumtelefono;
                    vtelpersona.tip_telefono := 'C'; -- Celular
                    vtelpersona.tel_ubicacion := 'C'; -- Casa
                    vtelpersona.es_default := 'S';
                    vtelpersona.cod_pais := '1';
                    vindtel := vindtel + 1;
                    vtelpersonas.extend;
                    vtelpersonas(vindtel) := vtelpersona;
                end if;

                if vsolicitante(i).telefono_trabajo is not null then
                    vareatelefono := substr(vsolicitante(i).telefono_trabajo, 1, 3);
                    vnumtelefono := substr(vsolicitante(i).telefono_trabajo, 4, 10);
                    -- Telefono Trabajo
                    vtelpersona.cod_area := vareatelefono;
                    vtelpersona.num_telefono := vnumtelefono;
                    vtelpersona.tip_telefono := 'D'; -- Celular
                    vtelpersona.tel_ubicacion := 'T'; -- Trabajo
                    vtelpersona.es_default := 'N';
                    vtelpersona.cod_pais := '1';
                    vindtel := vindtel + 1;
                    vtelpersonas.extend;
                    vtelpersonas(vindtel) := vtelpersona;
                end if;


                -- Informacion Laboral
                vinfolaboral := pa.info_laboral_obj();
                vinfolaboral.fec_ingreso := vsolicitante(i).fecha_ingreso_puesto;
                vinfolaboral.lugar_trabajo := substr(vsolicitante(i).intitucion_laboral, 1, 64);
                vinfolaboral.monto := vsolicitante(i).ingresos;
                vinfolaboral.cod_cargo := '50';
                vinfolaboral.puesto := vsolicitante(i).puesto;
                vinfolaboral.observaciones := null;
                vinfolaboral.tipo_ingreso := 'S';
                vinfolaboral.empleo_actual := 'S';
                vinfolaboral.cod_moneda := null;
                vinfolaboral.monto_origen := null;
                vinfolaboral.direccion := 'TI';
                vinfolaboral.cod_area := null;
                vinfolaboral.num_telefono := null;
                vinfolaboral.extension_tel := '0';
                vinfolaboral.antiguedad := null;

                -- Direccion de Envio
                vdirenvioxpers := pa.dir_envio_x_pers_obj();
                vdirenvioxpers.tipo_envio := 'R';
                vdirenvioxpers.cod_direccion := 1;
                vdirenvioxpers.cod_empresa := '1';
                vdirenvioxpers.cod_agencia := 50;
                vdirenvioxpers.email_usuario := vsolicitante(i).email;

                -- Cuentas de Otros Bancos
                vctacliotrbancos := pa.ctas_clientes_otr_bancos_list();

                -- Referencias Personales
                vrefpersonales := pa.ref_personales_list();
                vrefpersonal := pa.ref_personales_obj();
                vareatelefono := substr(nvl(vsolicitante(i).telefono_residencia, vsolicitante(i).telefono_celular), 1, 3);
                vnumtelefono := substr(nvl(vsolicitante(i).telefono_residencia, vsolicitante(i).telefono_celular), 4, 10);
                vrefpersonal.cod_empresa := '1';
                vrefpersonal.cod_tipo_id := vsolicitante(i).tipo_identificacion;
                vrefpersonal.nombre_ref := ' ';
                vrefpersonal.num_id := vsolicitante(i).numero_identificacion || '1';
                vrefpersonal.cod_area := vareatelefono;
                vrefpersonal.num_telefono := vnumtelefono;
                vrefpersonal.puesto := null;
                vrefpersonal.lugar_trabajo := null;
                vrefpersonal.relacion_persona := 'AMIGO';
                vrefpersonal.observaciones := null;
                vrefpersonal.extension_tel := null;
                vindref := vindref + 1;
                vrefpersonales.extend;
                vrefpersonales(vindref) := vrefpersonal;
                vrefpersonal.cod_empresa := '1';
                vrefpersonal.cod_tipo_id := vsolicitante(i).tipo_identificacion;
                vrefpersonal.nombre_ref := ' ';
                vrefpersonal.num_id := vsolicitante(i).numero_identificacion || '2';
                vrefpersonal.cod_area := vareatelefono;
                vrefpersonal.num_telefono := vnumtelefono;
                vrefpersonal.puesto := null;
                vrefpersonal.lugar_trabajo := null;
                vrefpersonal.relacion_persona := 'AMIGO';
                vrefpersonal.observaciones := null;
                vrefpersonal.extension_tel := null;
                vindref := vindref + 1;
                vrefpersonales.extend;
                vrefpersonales(vindref) := vrefpersonal;

                -- Referencias Comerciales
                vrefcomerciales := pa.ref_comerciales_list();
                vrefcomercial := pa.ref_comerciales_obj();

                vrefcomercial.cod_tip_ref := '2';
                vrefcomercial.cod_ente := '1';
                vrefcomercial.num_cuenta := null;
                vrefcomercial.credito_otorgado := null;
                vrefcomercial.saldo_credito := null;
                vrefcomercial.cuota_mensual := null;
                vrefcomercial.cod_moneda := '1';
                vrefcomercial.fec_apertura := null;
                vrefcomercial.fec_vencimiento := null;
                vrefcomercial.desc_garantia := null;
                vrefcomercial.observaciones := null;
                vrefcomercial.oficial := null;
                vrefcomercial.nombre_ente := 'BANCO ADEMI';
                vrefcomercial.num_telefono := null;
                vrefcomercial.tipo_cuenta := null;
                vrefcomerciales.extend;
                vrefcomerciales(1) := vrefcomercial;

                -- Informacion del Producto Solicitado
                vinfoprodsol := pa.info_prod_sol_obj();
                vinfoprodsol.tipo_producto := 'TARJETA DE CREDITO';
                vinfoprodsol.cod_moneda := '1';
                vinfoprodsol.proposito := 'CONSUMO PERSONAL';
                vinfoprodsol.monto_inicial := vsolicitante(i).limite_solicitado_rd;
                vinfoprodsol.instrumento_bancario := 'EFECTIVO';
                vinfoprodsol.rango_monetario_ini := null;
                vinfoprodsol.rango_monetario_fin := null;
                vinfoprodsol.prom_mes_depo_efectivo := null;
                vinfoprodsol.prom_mes_depo_cheques := null;
                vinfoprodsol.prom_mes_reti_efectivo := null;
                vinfoprodsol.prom_mes_trans_enviada := null;
                vinfoprodsol.cod_pais_destino := null;
                vinfoprodsol.prom_mes_trans_recibida := null;
                vinfoprodsol.cod_pais_origen := null;
                vinfoprodsol.compras_giros_cheques_ger := null;
                vinfoprodsol.origen_fondos := 'PROPIETARIO';
                
                -- Solicitud 32935 INICIO     
                -- Crear un objeto PA.LISTA_PEP_LIST en caso de existir un funcionario o relacionado PEP
                IF vsolicitante(i).PEP_INSTITUCION_POLITICA IS NOT NULL THEN       
                    vlistapep := pa.lista_pep_list();
                    vpersonapep := PA.LISTA_PEP_OBJ();
                    
                    vpersonapep.COD_PERSONA          := vsolicitante(i).PEP_CODIGO_PERSONA;            
                    vpersonapep.CARGO                := vsolicitante(i).PEP_CARGO;       
                    vpersonapep.FEC_INGRESO          := vsolicitante(i).PEP_FECHA_INGRESO;       
                    vpersonapep.FEC_VENCIMIENTO      := vsolicitante(i).PEP_FECHA_VENCIMIENTO;       
                    vpersonapep.APODO                := vsolicitante(i).PEP_APODO;                   
                    vpersonapep.CODIGO_PARENTESCO    := vsolicitante(i).PEP_CODIGO_PARENTESCO;       
                    vpersonapep.INSTITUCION_POLITICA := vsolicitante(i).PEP_INSTITUCION_POLITICA;           
                    vpersonapep.COD_MONEDA           := vsolicitante(i).PEP_COD_MONEDA;       
                    vpersonapep.COD_PAIS             := vsolicitante(i).PEP_CODIGO_PAIS;       
                    vpersonapep.NOMBRE_REL_PEP       := vsolicitante(i).PEP_NOMBRE_PERSONA_RELACIONADA;       
                     
                    vlistapep.EXTEND;            
                    vlistapep(vlistapep.LAST) := vpersonapep;
                END IF;    
                -- Solicitud 32935 FIN
                
                vcanal.COD_CANAL := 'OLE';
                
                DBMS_OUTPUT.PUT_LINE ( 'PKG_SOLICITUD_PRODUCTOR_TARJ => vsolicitante(i).sexo = ' || vsolicitante(i).sexo ); --prueba  

                vpromocionpersonas := pa.promocion_persona_list();
                pa.pkg_cliente.procesar_cliente_fisica(ines_fisica => 'S',
                                                       inconsultarburo => 'N',--vsolicitante(i).autoriza_consulta_datacredito,  
                                                       inconsultarpadron => 'N',--vsolicitante(i).autoriza_consulta_datacredito,
                                                       incod_promotor => vsolicitante(i).codigo_oficial,
                                                       inpaga_imp_ley288 => 'S',
                                                       inbenef_pag_ley288 => 'S',
                                                       incod_vinculacion => 'NI',
                                                       incobr_nodgii_132011 => 'S',
                                                       inprimer_apellido => vsolicitante(i).primer_apellido,
                                                       insegundo_apellido => vsolicitante(i).segundo_apellido,
                                                       inprimer_nombre => vsolicitante(i).primer_nombre,
                                                       insegundo_nombre => vsolicitante(i).segundo_nombre,
                                                       innacionalidad => vsolicitante(i).nacionalidad,
                                                       inest_civil => vsolicitante(i).estado_civil,
                                                       insexo => vsolicitante(i).sexo,
                                                       infec_nacimiento => vsolicitante(i).fecha_nacimiento,
                                                       incodsector_actividad => '1',
                                                       inemail => vsolicitante(i).email,
                                                       intipo_vivienda => '1',
                                                       innum_hijos => 3,
                                                       innum_dependientes => 7,
                                                       ines_residente => 'S',
                                                       intiempo_vivien_act => 1,
                                                       intotal_ingresos => vsolicitante(i).ingresos,
                                                       incod_pais => vsolicitante(i).cod_pais,
                                                       inactividad => substr(pa.f_obt_desc_actividad(vsolicitante(i).codigo_actividad), 1, 200),
                                                       incasada_apellido => null,
                                                       ines_funcionariopep => CASE WHEN TRIM(vsolicitante(i).PEP_CODIGO_PARENTESCO) IS NULL     THEN 'S' ELSE 'N' END, -- Solicitud 32935
                                                       ines_relacionadopep => CASE WHEN TRIM(vsolicitante(i).PEP_CODIGO_PARENTESCO) IS NOT NULL THEN 'S' ELSE 'N' END, -- Solicitud 32935
                                                       incod_actividad => vsolicitante(i).codigo_actividad,
                                                       incod_subactividad => null,
                                                       intipo_persona => pa.asigna_tipo_persona(vsolicitante(i).tipo_identificacion, vsolicitante(i).sexo),
                                                       intipo_cliente => vsolicitante(i).tipo_cliente,
                                                       incod_finalidad => '011',
                                                       intercer_nombre => null,
                                                       intipo_soc_conyugal => 'S',
                                                       ingpo_riesgo => 'B',
                                                       inindclientevip => 'N',
                                                       intipogendivisas => vsolicitante(i).tipo_gen_divisas,
                                                       inocupacionclasifnac => vsolicitante(i).ocupacion_clasif_nac,
                                                       inidentificacion => vidpersonas,
                                                       indirecciones => vdirpersonas,
                                                       intelefonos => vtelpersonas,
                                                       ininfolaboral => vinfolaboral,
                                                       indirenvioxpers => vdirenvioxpers,
                                                       inctaotrosbancos => vctacliotrbancos,
                                                       inrefpersonales => vrefpersonales,
                                                       inrefcomerciales => vrefcomerciales,
                                                       ininfoprodsol => vinfoprodsol,
                                                       inlistapep => vlistapep, -- Solicitud 32935
                                                       inpromocionpersonas => vpromocionpersonas,
                                                       incanal          => vcanal,
                                                       outcodcliente => pcodigocliente,
                                                       outerror => presultado);

                if presultado not like ' %Error%'
                   and pcodigocliente is not null
                   and pcodigocliente <> 0 then                   
                    commit;
                    vcanal.COD_PERSONA := pcodigocliente;
                else
                    begin
                        --  Cambiar estado de la solicitud a error
                        update ia.ia_solicitud_producto_tarjeta p
                           set p.ESTADO_SOLICITUD = 'E', p.motivo = presultado
                         WHERE p.codigo_empresa = pcodigo_empresa
                           and p.numero_solicitud = pnumero_solicitud
                           and p.codigo_solicitante = vsolicitante(i).codigo_solicitante  
                           and p.codigo_producto = pcodigo_producto;
                           
                        commit;
                    end;   

                end if;

                dbms_output.put_line('RESULTADO PKG_CLIENTE.Generar_Cliente:' || presultado);
            exception
                when others then
                    if presultado is null then
                        presultado := 'Error creando el cliente en el Core Solicitud=' || pnumero_solicitud || ' Solicitante=' || pcodigo_solicitante || ' Producto=' || pcodigo_producto || ' ' ||
                                      sqlerrm || ' ' || dbms_utility.format_error_backtrace;
                    end if;
                    begin
                        --  Cambiar estado de la solicitud a error
                        update ia.ia_solicitud_producto_tarjeta p
                           set p.ESTADO_SOLICITUD = 'E', p.motivo = presultado
                         WHERE p.codigo_empresa = pcodigo_empresa
                           and p.numero_solicitud = pnumero_solicitud
                           and p.codigo_solicitante = vsolicitante(i).codigo_solicitante  
                           and p.codigo_producto = pcodigo_producto;
                           
                        commit;
                    end;
                       
                    raise_application_error(-20100, presultado);
            end;

            dbms_output.put_line('Finaliza Generar Cliente ' || pcodigocliente);

            vesempleado := nvl(pa.f_es_empleado_ademi(pcodigocliente), '.');


            if pcodigocliente is not null
               and pcodigocliente <> 0
               and vesempleado <> 'X' then
                dbms_output.put_line('Actualizar Solicitante ' || pcodigo_solicitante);

                begin
                    update ia.ia_solicitante s
                    set s.codigo_cliente = pcodigocliente
                    where s.codigo_solicitante = pcodigo_solicitante;
                exception
                    when others then
                        presultado := 'Error Actualizando el solicitante';
                        raise_application_error(-20101, presultado);
                end;

                commit;

                -- Determinar el Sector
                begin
                    select cod_pais,
                           cod_provincia,
                           cod_canton,
                           cod_distrito,
                           cod_pueblo,
                           cod_sector
                    into vcod_pais,
                         vcod_provincia,
                         vcod_canton,
                         vcod_distrito,
                         vcod_pueblo,
                         vcod_sector
                    from sectores
                    where cod_pais = 1
                    and   cod_sector = vsolicitante(i).sector_res;
                exception
                    when no_data_found then
                        vcod_provincia := vsolicitante(i).cod_provincia_envio;
                        vcod_canton := vsolicitante(i).cod_distrito_envio;
                        vcod_distrito := vsolicitante(i).cod_canton_envio;
                        vcod_pueblo := vsolicitante(i).cod_ciudad_envio;
                        vcod_sector := vsolicitante(i).sector_res;
                end;

                vescliente := nvl(tc.tc_solicitud.existe_cliente(pcodigocliente), 0);

                if vescliente > 0 then
                    dbms_output.put_line('Iniciar Generar Solicitud2');

                    begin
                        --  Crear Solicitud de Tarjeta de Crédito
                        tc.tc_solicitud.generar_solicitud2(inoficinaorigen => vsolicitante(i).codigo_agencia,
                                                           intipoid => vsolicitante(i).tipo_identificacion,
                                                           innumid => vsolicitante(i).numero_identificacion,
                                                           innombreplastico => vsolicitante(i).nombre_plastico,
                                                           intipoproducto => vsolicitante(i).codigo_producto,
                                                           intipoemision => '1',
                                                           infechasolicitud => vsolicitante(i).fecha_solicitud,
                                                           intipotarjeta => case vsolicitante(i).cod_tipo_cliente when 'T' then 'P' else 'A' end, -- P = PRINCIPAL, A = ADICIONAL
                                                           inoficinaentrega => vsolicitante(i).codigo_agencia,
                                                           incodpromotor => vsolicitante(i).codigo_oficial,
                                                           incodciclofact => vsolicitante(i).cod_ciclo_fact,
                                                           intipomonedatarjeta => 'P',
                                                           inmontosolicitadord => vsolicitante(i).limite_solicitado_rd,
                                                           inmontosolicitadous => vsolicitante(i).limite_solicitado_us,
                                                           inesempleado => 'N', -- S = Continuar si es empleado
                                                           intipogarantia => null,
                                                           invalorgarantia => null,
                                                           insegregacionrd => vsolicitante(i).codigo_actividad,
                                                           outestado_civil => outestado_civil,
                                                           outsexo => outsexo,
                                                           outfecha_nacimiento => outfecha_nacimiento,
                                                           outapellido1 => outapellido1,
                                                           outapellido2 => outapellido2,
                                                           outprimernombre => outprimernombre,
                                                           outsegundonombre => outsegundonombre,
                                                           outnum_dependientes => vnum_dependientes,
                                                           outprofesion => vprofesion,
                                                           outtipovivienda => vtipovivienda,
                                                           outcodpais => vcod_pais,
                                                           outcodprovincia => vcod_provincia,
                                                           outcodcanton => vcod_canton,
                                                           outcoddistrito => vcod_distrito,
                                                           outcodciudad => vcod_pueblo,
                                                           insector_res => vcod_sector, --    '1',
                                                           inbarrio_res => vsolicitante(i).barrio_res,
                                                           incalle_res => vsolicitante(i).calle_res,
                                                           innumero_res => vsolicitante(i).numero_res,
                                                           indetalle_res => vsolicitante(i).detalle_res, --           SUBSTR(vSolicitante(i).DIRECCION_ENVIO,60),
                                                           outtelefono_corresp => vsolicitante(i).telefono_residencia,
                                                           outexttelefono => vexttelefono,
                                                           outzpostalcorresp => vzpostalcorresp,
                                                           outemail => vsolicitante(i).email,
                                                           outtelefono => vsolicitante(i).telefono_celular,
                                                           outsolicitudnumero => psolicitudcore,
                                                           intipoidadic1 => null,
                                                           inidentadic1 => null,
                                                           outprimernombreadic1 => vprimernombreadic1,
                                                           outsegundonombreadic1 => vsegundonombreadic1,
                                                           outprimerapellidoadic1 => vprimerapellidoadic1,
                                                           outsegundoapellidoadic1 => vsegundoapellidoadic1,
                                                           outnombreplasticoadic1 => vnombreplasticoadic1,
                                                           outfechanacimientoadic1 => vfechanacimientoadic1,
                                                           outsexoadic1 => vsexoadic1,
                                                           outestadociviladic1 => vestadociviladic1,
                                                           outemailadic1 => vemailadic1,
                                                           outtelefonoadic1 => vtelefonoadic1,
                                                           inparentescoadic1 => null,
                                                           inlimitesolicitadordadic1 => 0,
                                                           inlimitesolicitadousadic1 => 0,
                                                           outno_solicitud_adic1 => vno_solicitud_adic1,
                                                           intipoidadic2 => null,
                                                           inidentadic2 => null,
                                                           outprimernombreadic2 => vprimernombreadic2,
                                                           outsegundonombreadic2 => vsegundonombreadic2,
                                                           outprimerapellidoadic2 => vprimerapellidoadic2,
                                                           outsegundoapellidoadic2 => vsegundoapellidoadic2,
                                                           outnombreplasticoadic2 => vnombreplasticoadic2,
                                                           outfechanacimientoadic2 => vfechanacimientoadic2,
                                                           outsexoadic2 => vsexoadic2,
                                                           outestadociviladic2 => vestadociviladic2,
                                                           outemailadic2 => vemailadic2,
                                                           outtelefonoadic2 => vtelefonoadic2,
                                                           inparentescoadic2 => null,
                                                           inlimitesolicitadordadic2 => 0,
                                                           inlimitesolicitadousadic2 => 0,
                                                           outno_solicitud_adic2 => vno_solicitud_adic2,
                                                           outerror => presultado);
                    exception
                        when others then
                            if presultado is null then
                                presultado := 'Error creando la solicitud en el Core ' || sqlerrm;
                            end if;
                            --  Cambiar estado de la solicitud a error
                            update ia.ia_solicitud_producto_tarjeta p
                              set p.ESTADO_SOLICITUD = 'E', p.motivo = presultado
                            WHERE p.codigo_empresa = pcodigo_empresa
                              and p.numero_solicitud = pnumero_solicitud
                              and p.codigo_solicitante = vsolicitante(i).codigo_solicitante
                              and p.codigo_producto = pcodigo_producto;
                            commit;
                              
                            raise_application_error(-20102, presultado);
                    end;

                    dbms_output.put_line('Finalizar Generar Solicitud2 ' || psolicitudcore);

                    if psolicitudcore is not null
                       and psolicitudcore <> 0 then
                        dbms_output.put_line('Actualizar Solicitud Producto tarjeta');

                        begin
                            update ia.ia_solicitud_producto_tarjeta p
                            set p.solicitud_core = psolicitudcore, p.estado_solicitud = 'P'
                            where p.codigo_empresa = pcodigo_empresa
                            and   p.codigo_agencia = pcodigo_agencia
                            and   p.codigo_subagencia = pcodigo_subagencia
                            and   p.numero_solicitud = pnumero_solicitud
                            and   p.codigo_solicitante = pcodigo_solicitante
                            and   p.codigo_producto = pcodigo_producto;
                        exception
                            when others then
                                presultado := 'Error Actualizando la Solicitud del producto';
                                raise_application_error(-20103, presultado);
                        end;

                        IF vcanal.COD_CANAL IS NOT NULL THEN
                            BEGIN
                                vCanal.NUMERO_SOLICITUD := psolicitudcore;
                                vCanal.Crear();
                            EXCEPTION WHEN OTHERS THEN 
                                IF presultado IS NULL THEN
                                    presultado := SUBSTR (SQLERRM, 1, 4000);
                                END IF;
                                DBMS_OUTPUT.PUT_LINE ( 'CANAL outError = ' || presultado );
                                RAISE_APPLICATION_ERROR (-20105, 'CANAL '|| presultado);
                            END;
                        END IF;

                        dbms_output.put_line('Generar Reportes Automaticos');

                        declare
                            vurl varchar2(4000);
                            vidaplication pls_integer := 7; -- Tarjetas
                            vidtipodocumento pls_integer := '429'; -- Formulario de Conozca
                            vcodigoreferencia varchar2(100) := psolicitudcore; --pCodigoCliente||':'||pSolicitudCore;
                            vdocumento varchar2(30) := 'FCSCPF';
                        begin
                            -- Generar Conozca Su Cliente para File Flow
                            vdocumento := 'FCSCPF';
                            vidtipodocumento := '429';
                            vurl := pa.pkg_tipo_documento_pkm.urlconozcasucliente(pcodcliente => pcodigocliente, pempresa => '1');
                            pa.pkg_tipo_documento_pkm.inserturlreporte(pcodigoreferencia => vcodigoreferencia,
                                                                       pfechareporte => sysdate,
                                                                       pid_aplicacion => vidaplication,
                                                                       pidtipodocumento => vidtipodocumento,
                                                                       porigenpkm => 'Tarjeta',
                                                                       purlreporte => vurl,
                                                                       pformatodocumento => 'PDF',
                                                                       pnombrearchivo => vdocumento || '_' || psolicitudcore || '_' || pcodigocliente || '.pdf',
                                                                       prespuesta => presultado);

                            -- Formulario Solicitud de Tarjeta de Crédito
                            vdocumento := 'SolicitudTarjeta';
                            vidtipodocumento := '424';
                            vurl := pa.pkg_tipo_documento_pkm.urlsolicitudtarjeta(pnosolicitud => psolicitudcore);
                            pa.pkg_tipo_documento_pkm.inserturlreporte(pcodigoreferencia => vcodigoreferencia,
                                                                       pfechareporte => sysdate,
                                                                       pid_aplicacion => vidaplication,
                                                                       pidtipodocumento => vidtipodocumento,
                                                                       porigenpkm => 'Tarjeta',
                                                                       purlreporte => vurl,
                                                                       pformatodocumento => 'PDF',
                                                                       pnombrearchivo => vdocumento || '_' || psolicitudcore || '_' || pcodigocliente || '.pdf',
                                                                       prespuesta => presultado);


                            vidtipodocumento := '428'; -- CONSULTA BURO DE CREDITO PRIVADO
                            vdocumento := 'BURO';
                            vcodigoreferencia := vsolicitante(i).tipo_identificacion || ':' || vsolicitante(i).numero_identificacion || ':' || psolicitudcore || ': :' || vdocumento || ': ';
                            --vNombreArchivo    := vDocumento||'_'||pSolicitudCore||'_'||pCodigoCliente;
                            pa.pkg_tipo_documento_pkm.inserturlreporte(pcodigoreferencia => vcodigoreferencia,
                                                                       pfechareporte => sysdate,
                                                                       pid_aplicacion => vidaplication,
                                                                       pidtipodocumento => vidtipodocumento,
                                                                       porigenpkm => 'Tarjeta',
                                                                       purlreporte => null,
                                                                       pformatodocumento => 'PDF',
                                                                       pnombrearchivo => vdocumento || '_' || psolicitudcore || '_' || pcodigocliente || '.pdf',
                                                                       pestado => 'R',
                                                                       prespuesta => presultado);

                            vidtipodocumento := '527'; -- CONSULTA BUSCADOR DE GOOGLE
                            vdocumento := 'SIB';
                            vcodigoreferencia := vsolicitante(i).tipo_identificacion || ':' || vsolicitante(i).numero_identificacion || ':' || psolicitudcore || ': :' || vdocumento;
                            --vNombreArchivo    := vDocumento||'_'||pSolicitudCore||'_'||pCodigoCliente;
                            pa.pkg_tipo_documento_pkm.inserturlreporte(pcodigoreferencia => vcodigoreferencia,
                                                                       pfechareporte => sysdate,
                                                                       pid_aplicacion => vidaplication,
                                                                       pidtipodocumento => vidtipodocumento,
                                                                       porigenpkm => 'Tarjeta',
                                                                       purlreporte => null,
                                                                       pformatodocumento => 'PDF',
                                                                       pnombrearchivo => vdocumento || '_' || psolicitudcore || '_' || pcodigocliente || '.pdf',
                                                                       pestado => 'R',
                                                                       prespuesta => presultado);
                        exception
                            when others then
                                presultado := presultado || ' ' || dbms_utility.format_error_backtrace;
                                raise_application_error(-20104, presultado);
                        end;

                        presultado := 'Solicitud No.' || psolicitudcore || ' en el Core con el Cliente ' || pcodigocliente || ' ha sido generada';
                        commit;
                    else
                        raise_application_error(-20105, presultado);
                    end if;
                end if;
            elsif vesempleado = 'X' then
                presultado := 'Rechazado porque es un empleado';

                begin
                    update ia.ia_solicitud_producto_tarjeta p
                    set p.estado_solicitud = 'RU', p.motivo = presultado
                    where p.codigo_empresa = pcodigo_empresa
                    and   p.codigo_agencia = pcodigo_agencia
                    and   p.codigo_subagencia = pcodigo_subagencia
                    and   p.numero_solicitud = pnumero_solicitud
                    and   p.codigo_solicitante = pcodigo_solicitante
                    and   p.codigo_producto = pcodigo_producto;
                exception
                    when others then
                        presultado := 'Error Actualizando la Solicitud del producto';
                        raise_application_error(-20106, presultado);
                end;

                commit;
            elsif nvl(vescliente, 0) = 0 then
                presultado := 'Esta persona no está creado como Cliente, favor verificar...' || pcodigocliente;
                raise_application_error(-20107, presultado);
            /*
            ELSE
               pResultado := pResultado||' '||dbms_utility.format_error_backtrace;
               RAISE_APPLICATION_ERROR(-20100, pResultado);     */

            end if;

            commit;
        --DBMS_OUTPUT.PUT_LINE(vSolicitante(i).NUMERO_SOLICITUD||' '||vSolicitante(i).COD_PROVINCIA||' '||vSolicitante(i).COD_CANTON||' '||vSolicitante(i).COD_DISTRITO||' '||vSolicitante(i).COD_CIUDAD||' '||vSolicitante(i).DIRECCION);


        end loop;
    exception
        when others then
            dbms_output.put_line('Resultado: ' || presultado || ' ' || sqlerrm || ' ' || dbms_utility.format_error_backtrace);
    /*IF pResultado IS NULL THEN
        pResultado  := SQLERRM;
    END IF;
    RAISE_APPLICATION_ERROR(-20100, pResultado);     */
    end procesarsolicitudcore;

    procedure logerror(pdata in out ia.solicitud_producto_tarj_obj, inprogramunit in ia.log_error.programunit%type, inerrordescription in varchar2, inerrortrace in clob, outiderror out number) is
        ppackagename constant ia.log_error.packagename%type := 'IA.PKG_SOLICITUD_PRODUCTO_TARJ';
    begin
        ia.logger.addparamvaluev('pCodigo_Empresa', pdata.codigo_empresa);
        ia.logger.addparamvaluev('pCodigo_Agencia', pdata.codigo_agencia);
        ia.logger.addparamvaluev('pCodigo_Subagencia', pdata.codigo_subagencia);
        ia.logger.addparamvaluev('pNumero_Solicitud', pdata.numero_solicitud);
        ia.logger.addparamvaluev('pCodigo_Oferta', pdata.codigo_oferta);
        ia.logger.addparamvaluev('pCodigo_Solicitante', pdata.codigo_solicitante);
        ia.logger.addparamvaluev('pCodigo_Producto', pdata.codigo_producto);
        ia.logger.addparamvaluev('pCod_Tipo_Cliente', pdata.cod_tipo_cliente);
        ia.logger.addparamvaluev('pCod_Ciclo_Fact', pdata.cod_ciclo_fact);
        ia.logger.addparamvaluev('pNumero_Producto', pdata.numero_producto);
        ia.logger.addparamvaluev('pNombre_Plastico', pdata.nombre_plastico);
        ia.logger.addparamvaluev('pLimite_Solicitado_Rd', pdata.limite_solicitado_rd);
        ia.logger.addparamvaluev('pLimite_Solicitado_Us', pdata.limite_solicitado_us);
        ia.logger.addparamvaluev('pFecha_Solicitud', pdata.fecha_solicitud);
        ia.logger.addparamvaluev('pFecha_Vencimiento', pdata.fecha_vencimiento);
        ia.logger.addparamvaluev('pCodigo_Oficial', pdata.codigo_oficial);
        ia.logger.addparamvaluev('pCod_Pais', pdata.cod_pais);
        ia.logger.addparamvaluev('pCod_Provincia', pdata.cod_provincia);
        ia.logger.addparamvaluev('pCod_Canton', pdata.cod_canton);
        ia.logger.addparamvaluev('pCod_Distrito', pdata.cod_distrito);
        ia.logger.addparamvaluev('pCod_Ciudad', pdata.cod_ciudad);
        ia.logger.addparamvaluev('pDireccion_Envio', pdata.direccion_envio);
        ia.logger.addparamvaluev('pGeo_Coord_Envio', pdata.geo_coord_envio);
        ia.logger.addparamvaluev('pUsuario_Valida', pdata.usuario_valida);
        ia.logger.addparamvaluev('pFecha_Validacion', pdata.fecha_validacion);
        ia.logger.addparamvaluev('pUsuario_Autoriza', pdata.usuario_autoriza);
        ia.logger.addparamvaluev('pFecha_Autorizacion', pdata.fecha_autorizacion);
        ia.logger.addparamvaluev('pUsuario_Procesa', pdata.usuario_procesa);
        ia.logger.addparamvaluev('pFecha_Proceso', pdata.fecha_proceso);
        ia.logger.addparamvaluev('pEstado_Solicitud', pdata.estado_solicitud);
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
end pkg_solicitud_producto_tarj;
/