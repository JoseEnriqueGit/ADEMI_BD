CREATE OR REPLACE package PA.pkg_tipo_documento_pkm is
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
                      presultado     in out varchar2);

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
                    presultado     in out varchar2);

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
                         presultado     in out varchar2);

    procedure borrar(pid_aplicacion in number, pid_tipo_documento in varchar2, presultado in out varchar2);

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
        return pa.tipo_documento_pkm_list;

    function comparar(pdata1 in out pa.tipo_documento_pkm_obj, pdata2 in out pa.tipo_documento_pkm_obj, pmodo in varchar2, presultado in out varchar2)
        -- O = (Compare between Objects pData1 and pData2),
        -- T = (Compare pData1 and Table data "Must used pData2 like search parameter in table)
        return boolean;

    function existe(pid_aplicacion in number, pid_tipo_documento in varchar2, presultado in out varchar2)
        return boolean;

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
        return boolean;

    function urlconozcasucliente(pcodcliente in varchar2, pempresa in varchar2)
        return varchar2;

    function urlconozcasucliente2(pcodcliente in varchar2, pempresa in varchar2)
        return varchar2;

    function urlmatrizriesgo(pcodcliente in varchar2)
        return varchar2;

    function urlsolicitudtarjeta(pnosolicitud in number)
        return varchar2;

    function urlfudreprestamos(pid_tempfud in number, p_nomarchivo in varchar2)
        return varchar2;

    function urlfec(pid_tempfec in number, p_nomarchivo in varchar2)
        return varchar2;

    function urlfecfiador(pid_tempfec in number, p_nomarchivo in varchar2)
        return varchar2;

    function urlfecreprestamos(pidreprestamo in number)
        return varchar2;

    function urllexisnexis(pnombres in varchar2, papellidos in varchar2, pidentificacion in varchar2)
        return varchar2;

    procedure inserturlreporte(pcodigoreferencia in  varchar2,
                               pfechareporte  in     date,
                               pid_aplicacion in     number,
                               pidtipodocumento in   varchar2,
                               porigenpkm     in     varchar2,
                               purlreporte    in     varchar2,
                               pformatodocumento in  varchar2,
                               pnombrearchivo in     varchar2,
                               pestado        in     varchar2 default 'P',
                               prespuesta     in out varchar2);

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
                                 prespuesta     in out varchar2);

    procedure logerror(pdata in out pa.tipo_documento_pkm_obj, inprogramunit in ia.log_error.programunit%type, inerrordescription in varchar2, inerrortrace in clob, outiderror out number);
end pkg_tipo_documento_pkm;
/

