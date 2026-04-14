CREATE OR REPLACE package body CC.pkg_interfaz_cc as
    /******************************************************************************
       NAME:       pkg_interfaz_cc
       PURPOSE: crear cuentas de efectivo mediante un servicio o api

       REVISIONS:
       Ver        Date        Author           Description
       ---------  ----------  ---------------  ------------------------------------
       1.0        21/02/2024  fermin rodriguez 1. Package para el manejo de la
                                                  creacion de la cuenta efectivo Onboarding Digital.
       1.0        11/12/2024  JoseEsteban      #20241211 Change CONSULTA BUSCADOR DE GOOGLE CODE from 763 to 810
    ******************************************************************************/

    function digito_verificador(pnumero in number, ptamano in number default 11111111111111)
        return number is
        l_sum_digits pls_integer := 0;
    begin
        if (length(to_char(pnumero)) > length(to_char(ptamano))) then
            raise_application_error(-20111, 'Length of weight must be longer than ' || 'length of number');
        end if;

        for i in 1 .. (trunc(log(10, pnumero)) + 1)
        loop
            l_sum_digits := l_sum_digits + (mod(trunc(pnumero / power(10, (i - 1))), 10) * mod(trunc(ptamano / power(10, (i - 1))), 10));
        end loop;

        return (9 - mod(l_sum_digits, 9));
    end;

    --Validacion de que el numero de cuenta no exista.
    function validar_cuenta(pcuenta in number)
        return varchar2 is
        ncant number := 0;
        cretorno varchar2(1) := 'N';
    begin
        begin
            select count(*)
            into ncant
            from cuenta_efectivo
            where num_cuenta = pcuenta;
        exception
            when no_data_found then
                ncant := 0;
        end;

        if nvl(ncant, 0) = 0 then
            cretorno := 'S';
        else
            cretorno := 'N';
        end if;

        return (cretorno);
    end;

    procedure crear_cuenta_efectivo_api(psolicitudcuenta in   cc.solicitud_cuenta_list,
                                        pnumero_cuenta in out varchar2,
                                        pcodigocliente in out number,
                                        perrornum      in out number,
                                        pmensaje_error in out varchar2) is
        vcanal pa.canal_solicitud_obj := pa.canal_solicitud_obj();
        vescliente number := 0;
        vtipoid pa.id_personas.cod_tipo_id%type;
        vnumid pa.id_personas.num_id%type;
        verror varchar2(4000);
    begin
        for i in 1 .. psolicitudcuenta.count
        loop
            cc.pkg_interfaz_cc.crear_cuenta_efectivo(pcodigo_empresa => psolicitudcuenta(i).codigo_empresa,
                                                     pcodigo_cliente => psolicitudcuenta(i).codigo_cliente,
                                                     pcodigo_producto => psolicitudcuenta(i).codigo_producto,
                                                     pcodigo_moneda => psolicitudcuenta(i).codigo_moneda,
                                                     pcodigo_agencia => psolicitudcuenta(i).codigo_agencia,
                                                     pnumero_cuenta => pnumero_cuenta,
                                                     perrornum => perrornum,
                                                     pmensaje_error => pmensaje_error);

            dbms_output.put_line('pNumero_cuenta = ' || pnumero_cuenta);
            dbms_output.put_line('pMensaje_Error = ' || perrornum || '-' || pmensaje_error);

            if pnumero_cuenta is not null
               and pmensaje_error not like 'Error%' then
                pcodigocliente := psolicitudcuenta(i).codigo_cliente;

                if psolicitudcuenta(i).canal.cod_canal is not null then
                    begin
                        -- Guardar canal donde se origina la solicitud
                        vcanal := pa.canal_solicitud_obj();
                        vcanal := psolicitudcuenta(i).canal;
                        vcanal.numero_solicitud := pnumero_cuenta;
                        vcanal.crear();
                    exception
                        when others then
                            perrornum := 404;
                            pmensaje_error := 'Error determinando el canal de origen ' || dbms_utility.format_error_backtrace;
                            dbms_output.put_line('Canal pMensaje_Error = ' || pmensaje_error);
                            raise_application_error(-20104, pmensaje_error);
                    end;
                end if;


                declare
                    vurl varchar2(4000);
                    vidaplication pls_integer := 37; -- CUENTASDEAHORROS
                    vidtipodocumento pls_integer := '618'; -- Formulario de Conozca
                    vcodigoreferencia varchar2(100) := pnumero_cuenta; --pCodigoCliente||':'||vSolicitudNumero;
                    vdocumento varchar2(30) := 'FCSCPF';
                    vorigenpkm varchar2(100) := 'Cuenta';
                    pcodigo_cliente varchar2(15) := psolicitudcuenta(i).codigo_cliente;
                begin
                    -- Detarmina el Origen PKM para el BGP
                    begin
                        select x.origen_pkm
                        into vorigenpkm
                        from pa.canal_aplicacion x
                        where x.cod_sistema = vcanal.cod_sistema
                        and   x.cod_canal = vcanal.cod_canal;
                    exception
                        when no_data_found then
                            vorigenpkm := 'Onboarding';
                    end;

                    begin
                        -- Verifica si el cliente existe
                        select 1, c.codigo_tipo_identificacion, c.numero_identificacion
                        into vescliente, vtipoid, vnumid
                        from pa.clientes_b2000 c
                        where c.codigo_empresa = '1'
                        and   c.codigo_cliente = pcodigo_cliente;
                    exception
                        when no_data_found then
                            vescliente := 0;
                    end;

                    -- Generar Conozca Su Cliente para File Flow
                    vdocumento := 'FCSCPF';
                    vidtipodocumento := '618';
                    vurl := pa.pkg_tipo_documento_pkm.urlconozcasucliente2(pcodcliente => pcodigo_cliente, pempresa => '1');
                    pa.pkg_tipo_documento_pkm.inserturlreporte(pcodigoreferencia => vcodigoreferencia,
                                                               pfechareporte => sysdate,
                                                               pid_aplicacion => vidaplication,
                                                               pidtipodocumento => vidtipodocumento,
                                                               porigenpkm => vorigenpkm,
                                                               purlreporte => vurl,
                                                               pformatodocumento => 'PDF',
                                                               pnombrearchivo => vdocumento || '_' || pnumero_cuenta || '_' || pcodigo_cliente || '.pdf',
                                                               prespuesta => verror);
                    dbms_output.put_line('FCSCPF vError = ' || verror);

                    -- Generar Matriz Riesgo para File Flow
                    vdocumento := 'MRAVPF';
                    vidtipodocumento := '809';
                    vurl := pa.pkg_tipo_documento_pkm.urlmatrizriesgo(pcodcliente => pcodigo_cliente);
                    pa.pkg_tipo_documento_pkm.inserturlreporte(pcodigoreferencia => vcodigoreferencia,
                                                               pfechareporte => sysdate,
                                                               pid_aplicacion => vidaplication,
                                                               pidtipodocumento => vidtipodocumento,
                                                               porigenpkm => vorigenpkm,
                                                               purlreporte => vurl,
                                                               pformatodocumento => 'PDF',
                                                               pnombrearchivo => vdocumento || '_' || pnumero_cuenta || '_' || pcodigo_cliente || '.pdf',
                                                               prespuesta => verror);
                    dbms_output.put_line('MRAVPF vError = ' || verror);


                    /*vidtipodocumento := '762'; -- CONSULTA BURO DE CREDITO PRIVADO
                    vdocumento := 'BURO';
                    vcodigoreferencia := vtipoid || ':' || vnumid || ':' || pnumero_cuenta || ': :' || vdocumento || ': ';
                    --vNombreArchivo    := vDocumento||'_'||vSolicitudNumero||'_'||inSolicitudTarjeta.CodigoCliente;
                    pa.pkg_tipo_documento_pkm.inserturlreporte(pcodigoreferencia => vcodigoreferencia,
                                                               pfechareporte => sysdate,
                                                               pid_aplicacion => vidaplication,
                                                               pidtipodocumento => vidtipodocumento,
                                                               porigenpkm => vorigenpkm,
                                                               purlreporte => null,
                                                               pformatodocumento => 'PDF',
                                                               pnombrearchivo => vdocumento || '_' || pnumero_cuenta || '_' || pcodigo_cliente || '.pdf',
                                                               pestado => 'R',
                                                               prespuesta => verror);
                    dbms_output.put_line('BURO vError = ' || verror);

                    vidtipodocumento := '810'; -- CONSULTA BUSCADOR DE GOOGLE  (previous 763 20241211)
                    vdocumento := 'SIB';
                    vcodigoreferencia := vtipoid || ':' || vnumid || ':' || pnumero_cuenta || ': :' || vdocumento;
                    --vNombreArchivo    := vDocumento||'_'||vSolicitudNumero||'_'||inSolicitudTarjeta.CodigoCliente;
                    pa.pkg_tipo_documento_pkm.inserturlreporte(pcodigoreferencia => vcodigoreferencia,
                                                               pfechareporte => sysdate,
                                                               pid_aplicacion => vidaplication,
                                                               pidtipodocumento => vidtipodocumento,
                                                               porigenpkm => vorigenpkm,
                                                               purlreporte => null,
                                                               pformatodocumento => 'PDF',
                                                               pnombrearchivo => vdocumento || '_' || pnumero_cuenta || '_' || pcodigo_cliente || '.pdf',
                                                               pestado => 'R',
                                                               prespuesta => verror);
                    dbms_output.put_line('SIB vError = ' || verror);*/

                    -- Generar LEXISNEXIS para File Flow
                    vidtipodocumento := '621';
                    vdocumento := 'LEXISNEXIS';
                    vcodigoreferencia := vtipoid || ':' || vnumid || ':' || pnumero_cuenta || ': :' || vdocumento;
                    pa.pkg_tipo_documento_pkm.inserturlreporte(pcodigoreferencia => vcodigoreferencia,
                                                               pfechareporte => sysdate,
                                                               pid_aplicacion => vidaplication,
                                                               pidtipodocumento => vidtipodocumento,
                                                               porigenpkm => vorigenpkm,
                                                               purlreporte => null,
                                                               pformatodocumento => 'PDF',
                                                               pnombrearchivo => vdocumento || '_' || pnumero_cuenta || '_' || pcodigo_cliente || '.pdf',
                                                               pestado => 'R',
                                                               prespuesta => verror);
                    dbms_output.put_line('LEXISNEXIS vError = ' || verror);
                exception
                    when others then
                        perrornum := 404;
                        pmensaje_error := 'Error ' || verror || ' ' || dbms_utility.format_error_backtrace;
                        raise_application_error(-20104, pmensaje_error);
                end;
            else
                raise_application_error(-20104, pmensaje_error);
            end if;
        end loop;
    end;

    --Creacion de la cuenta de Efectivo
    procedure crear_cuenta_efectivo(pcodigo_empresa in    varchar2,
                                    pcodigo_cliente in    number,
                                    pcodigo_producto in   varchar2,
                                    pcodigo_moneda in     varchar2,
                                    pcodigo_agencia in    varchar2,
                                    pnumero_cuenta in out varchar2,
                                    perrornum      in out number,
                                    pmensaje_error in out varchar2) is
        vcodsistctaman varchar2(2) := param.parametro_x_empresa(pcodigo_empresa, 'PRSISTCTAMANC', 'PR');

        vcod_grupo_cierr cuenta_efectivo.cod_grupo_cierr%type := param.parametro_x_empresa(pcodigo_empresa, 'CODGRPCIE_DEFAULTCTA', 'PR');
        vtip_correspond cuenta_efectivo.tip_correspond%type := param.parametro_x_empresa(pcodigo_empresa, 'TIP_CORRESP_DEFAULT', 'PR');
        vcateg_cuenta cuenta_efectivo.categ_cuenta%type := param.parametro_x_empresa(pcodigo_empresa, 'CATEG_CUENTA_DEFAULT', 'PR');
        vclase_cuenta cuenta_efectivo.clase_cuenta%type := param.parametro_x_empresa(pcodigo_empresa, 'CLASE_CUENTA_DEFAULT', 'PR');
        vdigitover varchar2(1) := '0';
        ptipo_relacion2 cuenta_cliente_relacion.tipo_relacion%type;
        vsecuencia varchar2(15);
        vprefijocuenta varchar2(1) := '1';
        vcodoficial varchar2(10);
        vesfisica varchar2(1);
        v_sector pa.personas.cod_sec_contable%type;
        vtipo_persona clientes_b2000.tipo_de_persona%type;
        vdesc_nombre personas.nombre%type;
        vnombre_chequera cuenta_efectivo.nombre_chequera%type;
        vtitulares cuenta_efectivo.titulares%type;
        vfircltcod_cliente cuenta_cliente_relacion.codigo_cliente%type;
        vfircltcod_cliente1 cuenta_cliente_relacion.codigo_cliente%type;
        vfircltporcentaje firmas_cliente.porcentaje%type;
        vfircltnum_combinacion firmas_cuentas.num_combinacion%type;
        vfircltcod_categoria firmas_cuentas.cod_categoria%type;
        vfircltcantidad_firmas firmas_cuentas.cantidad_firmas%type;
        vfircltsigno firmas_cuentas.signo%type;
        vfircltmonto_max firmas_cuentas.monto_max%type;
        vfirclttippoder firmas_cliente.tipo_poder%type;
        vcod_ejecutivo empleados.id_empleado%type;
        vcod_agencia empleados.cod_agencia_labora%type;
        vobservacion_corta cuenta_efectivo.observacion_corta%type;
        vcod_direccion cuenta_efectivo.cod_direccion%type;
        vnum_cuenta cuenta_efectivo.num_cuenta%type;
        vfrec_calc_int cuenta_efectivo.frec_calc_int%type := 'D'; --'N';   --malmanzar
        vtip_asigna_tasa cuenta_efectivo.tip_asigna_tasa%type := 'G'; --'N'; --malmanzar
        vtip_asigna_carg cuenta_efectivo.tip_asigna_carg%type := 'G';
        vtip_car_adminis cuenta_efectivo.tip_car_adminis%type := 'N';
        vtip_capitalizac cuenta_efectivo.tip_capitalizac%type := 'M';
        vind_idioma cuenta_efectivo.ind_idioma%type := 'E';
        vind_solicitud cuenta_efectivo.ind_solicitud%type := 'N';
        vind_estado cuenta_efectivo.ind_estado%type := 1;
        vind_cta_alterna cuenta_efectivo.ind_cta_alterna%type := 'N';
        vind_trans_autom cuenta_efectivo.ind_trans_autom%type := 'N';
        vind_mancomunada cuenta_efectivo.ind_mancomunada%type := 'N';
        vind_impuesto cuenta_efectivo.ind_impuesto%type := 'S'; ---:= 'N'; --malmanzar 23-04-2018
        vind_pag_interes cuenta_efectivo.ind_pag_interes%type := 'N';
        vind_reserva_esp cuenta_efectivo.ind_reserva_esp%type := 'N';
        vcantidad_cheques cuenta_efectivo.cantidad_cheques%type := 0;
        vcant_cks_mes cuenta_efectivo.cant_cks_mes%type := 0;
        vcant_dep_mes cuenta_efectivo.cant_dep_mes%type := 0;
        vsal_total_cta cuenta_efectivo.sal_total_cta%type := 0;
        vsal_tot_dia_ant cuenta_efectivo.sal_tot_dia_ant%type := 0;
        vsal_reserva cuenta_efectivo.sal_reserva%type := 0;
        vsal_minimo cuenta_efectivo.sal_minimo%type := 0;
        vsal_consultado cuenta_efectivo.sal_consultado%type := 0;
        vsal_congelado cuenta_efectivo.sal_congelado%type := 0;
        vsal_embargado cuenta_efectivo.sal_embargado%type := 0;
        vsal_menor cuenta_efectivo.sal_menor%type := 0;
        vsal_promedio cuenta_efectivo.sal_promedio%type := 0;
        vsal_maximo cuenta_efectivo.sal_maximo%type := 0;
        vsal_al_cierre cuenta_efectivo.sal_al_cierre%type := 0;
        vsal_menor_mes cuenta_efectivo.sal_menor_mes%type := 0;
        vsal_promed_mes cuenta_efectivo.sal_promed_mes%type := 0;
        vsal_maximo_mes cuenta_efectivo.sal_maximo_mes%type := 0;
        vacumulad_imptos cuenta_efectivo.acumulad_imptos%type := 0;
        vmon_reserva_utl cuenta_efectivo.mon_reserva_utl%type := 0;
        vmon_sobgro_aut cuenta_efectivo.mon_sobgro_aut%type := 0;
        vmon_sob_no_aut cuenta_efectivo.mon_sob_no_aut%type := 0;
        vmon_sobgro_disp cuenta_efectivo.mon_sobgro_disp%type := 0;
        vmon_total_cargo cuenta_efectivo.mon_total_cargo%type := 0;
        vmonto_imptos cuenta_efectivo.monto_imptos%type := 0;
        vint_sobre_saldo cuenta_efectivo.int_sobre_saldo%type := 0;
        vint_cap_embargo cuenta_efectivo.int_cap_embargo%type := 0;
        vint_cap_congela cuenta_efectivo.int_cap_congela%type := 0;
        vint_cap_reserva cuenta_efectivo.int_cap_reserva%type := 0;
        vint_por_pagar cuenta_efectivo.int_por_pagar%type := 0;
        vint_sobgro_aut cuenta_efectivo.int_sobgro_aut%type := 0;
        vint_uso_sobgro cuenta_efectivo.int_uso_sobgro%type := 0;
        vsal_transito cuenta_efectivo.sal_transito%type := 0;
        vind_reserva_utl cuenta_efectivo.ind_reserva_utl%type := 'N';
        vint_sob_no_aut cuenta_efectivo.int_sob_no_aut%type := 0;
        vult_cke_entreg cuenta_efectivo.ult_cke_entreg%type := 0;
        vint_mes_actual cuenta_efectivo.int_mes_actual%type := 0;
        vind_sob_no_aut cuenta_efectivo.ind_sob_no_aut%type := 'S';
        vind_restringida cuenta_efectivo.ind_restringida%type := 'N';
        vcobra_cargo_inact cuenta_efectivo.cobra_cargo_inact%type := 'S';
        vcobra_cargo_sobgro cuenta_efectivo.cobra_cargo_sobgro%type := 'S';
        vcobra_cargo_chk_plaza cuenta_efectivo.cobra_cargo_chk_plaza%type := 'S';

        ---malmanzar 11-04-2018
        vind_sobgro cuenta_efectivo.ind_sobgro%type := 'N';
        vtas_interes cuenta_efectivo.tas_interes%type;
        vperiod_revisi cuenta_efectivo.period_revisi%type := 360;
        vfec_revision cuenta_efectivo.fec_revision%type := trunc(sysdate) + 360;
        vcod_tas_int cuenta_efectivo.cod_tas_int%type;
        vind_pag_int_reserva cuenta_efectivo.ind_pag_int_reserva%type := 'S';
        vind_tas_int_reserva cuenta_efectivo.ind_tas_int_reserva%type := 'P';
        vind_control_secuencia cuenta_efectivo.ind_control_secuencia%type := 'N';
        vcod_grupo cuenta_efectivo.cod_grupo%type := '1';
        vexiste varchar2(1 byte) := '';
    begin
        perrornum := null;
        pmensaje_error := null;

        begin
            select tip_tas_general, dias_base, tip_asigna_tasa
            into vcod_tas_int, vperiod_revisi, vtip_asigna_tasa
            from cc.rng_cal_interes rng
            where rng.cod_producto = pcodigo_producto;
        exception
            when no_data_found then
                perrornum := 201;
                pmensaje_error := 'Error Tasa no definida para este producto.';
                dbms_output.put_line('pMensaje_error = ' || pmensaje_error);
                raise_application_error(-20101, pmensaje_error);
        end;

        --DBMS_OUTPUT.put_line ('Clientes: ' || pcodigo_cliente);
        if perrornum is null then
            begin
                select tip_capitalizac,
                       ind_idioma,
                       ind_cta_alterna,
                       ind_impuesto,
                       ind_pag_interes,
                       ind_reserva_esp,
                       frec_calc_int
                into vtip_capitalizac,
                     vind_idioma,
                     vind_cta_alterna,
                     vind_impuesto,
                     vind_pag_interes,
                     vind_reserva_esp,
                     vfrec_calc_int
                from cc.cara_x_producto pro
                where pro.cod_producto = pcodigo_producto;
            exception
                when no_data_found then
                    vtip_capitalizac := 'M';
                    vind_idioma := 'E';
                    vind_cta_alterna := 'N';
                    vind_impuesto := 'N';
                    vind_reserva_esp := 'N';
                    vfrec_calc_int := 'D';
                    perrornum := 202;
                    pmensaje_error := 'Error Producto no parametrizado en cara_x_producto.';
                    dbms_output.put_line('pmensaje_error = ' || pmensaje_error);
                    raise_application_error(-20102, pmensaje_error);
            end;
        end if;

        if instr(pcodigo_cliente, ',', 1) > 0 then
            vfircltcod_cliente := substr(pcodigo_cliente, 1, instr(pcodigo_cliente, ',', 1) - 1);
        else
            vfircltcod_cliente := pcodigo_cliente;
        end if;

        vfircltcod_cliente := pcodigo_cliente;
        dbms_output.put_line('Principal Cliente: ' || vfircltcod_cliente);
        dbms_output.put_line('pErrornum = ' || perrornum);

        if perrornum is null then
            begin
                select b.nombre,
                       b.es_fisica,
                       nvl((select nvl(a.cod_oficial, gerente)
                            from pa.agencia
                            where cod_agencia = a.cod_agencia),
                           a.cod_oficial) cod_oficial,
                       c.tipo_de_persona,
                       cod_sec_contable
                into vdesc_nombre, vesfisica, vcodoficial, vtipo_persona, v_sector
                from clientes_b2000 c, cliente a, personas b
                where (a.cod_empresa = pcodigo_empresa)
                and   (a.cod_cliente = pcodigo_cliente)
                and   (a.esta_activo = 'S')
                and   (b.cod_persona = a.cod_cliente)
                and   c.cod_cliente = a.cod_cliente
                and   c.codigo_empresa = pcodigo_empresa;
            exception
                when no_data_found then
                    dbms_output.put_line('-20001,[CREA_CUENTA_EFECTIVO_AT]');
                    perrornum := 203;
                    pmensaje_error := 'Error buscando cliente [' || pcodigo_cliente || '] en la DB, favor verificar codigo de cliente';
                    raise_application_error(-20103, pmensaje_error);
            end;
        end if;

        vnombre_chequera := substr(vdesc_nombre, 1, 200);
        --:bkctaefe.NOM_CLIENTE;
        vtitulares := vnombre_chequera; --:bkctaefe.NOM_CLIENTE;
        vobservacion_corta := 'Cuenta Onboarding Digital';

        if (vesfisica = 'S') then
            --vfircltcod_cliente := pCodigo_cliente;   --:bkctaefe.cod_cliente;
            vfircltporcentaje := 100;
            vfircltnum_combinacion := 1;
            vfircltcod_categoria := 'A';
            vfircltcantidad_firmas := 1;
            vfircltsigno := '>';
            vfircltmonto_max := 0.00;
            vfirclttippoder := param.parametro_x_empresa(pcodigo_empresa, 'TIPPODER_DEFAULTCTAN', 'PR');
        end if;

        dbms_output.put_line('vcodoficial: ' || vcodoficial);

        if (vcodoficial is not null) then
            begin
                select a.id_empleado --, b.nombre
                into vcod_ejecutivo --, :bkctaefe.nom_ejecutivo
                from empleados a, personas b
                where (a.cod_empresa = pcodigo_empresa)
                and   (a.id_empleado = vcodoficial)
                and   (b.cod_persona = a.cod_per_fisica);
            exception
                when no_data_found then
                    dbms_output.put_line('-20002,[CREA_CUENTA_EFECTIVO_AT] Cliente no tiene ejeciutivo asignado');
                    perrornum := 204;
                    pmensaje_error := 'Error buscando Ejecutivo del Cliente en la DB (' || vcodoficial || '), favor verificar codigo de cliente';
                    raise_application_error(-20104, pmensaje_error);
            end;

            -- HJORGE 19/02/2008 -- Agencia del Oficial
            begin
                select a.cod_agencia_labora --,b.descripcion
                into vcod_agencia --,vdes_agencia
                from empleados a, agencia b
                where a.id_empleado = vcodoficial
                and   a.cod_agencia_labora = b.cod_agencia;
            exception
                when no_data_found then
                    dbms_output.put_line('-20002,[CREA_CUENTA_EFECTIVO_AT] Buscando agencia ejecutivo');
                    perrornum := 205;
                    pmensaje_error := 'Error buscando codigo de empleado del Ejecutivo de Cuenta (' || vcodoficial || '), favor verificar codigo de cliente';
                    raise_application_error(-20105, pmensaje_error);
            end;
        end if;

        --
        begin
            select cod_direccion --, detalle
            into vcod_direccion --, :bkctaefe.des_direccion
            from dir_personas
            where (cod_persona = pcodigo_cliente) --:bkctaefe.cod_cliente )
            and   (rownum = 1);
        exception
            when no_data_found then
                dbms_output.put_line('-20002,[CREA_CUENTA_EFECTIVO_AT] Buscando direccion');
                perrornum := 206;
                pmensaje_error := 'Error buscando direccion del cliente en la DB, favor verificar codigo de cliente';
                raise_application_error(-20106, pmensaje_error);
        end;

        begin
            select prefijo_num_cuenta,
                   -- LMVR 20/03/2017 Modificacion para considerar el indicador del pago de immpuesto por producto
                   nvl(ind_impuesto, 'N'),
                   nvl(ind_cta_alterna, 'N'),
                   nvl(ind_idioma, 'E'),
                   nvl(ind_pag_interes, 'N'),
                   nvl(ind_reserva_esp, 'N'),
                   nvl(ind_solicitud, 'N'),
                   nvl(ind_trans_autom, 'N')
            -- LMVR 20/03/2017 Modificacion para considerar el indicador del pago de immpuesto por producto
            into vprefijocuenta,
                 -- LMVR 20/03/2017 Modificacion para considerar el indicador del pago de immpuesto por producto
                 vind_impuesto,
                 vind_cta_alterna,
                 vind_idioma,
                 vind_pag_interes,
                 vind_reserva_esp,
                 vind_solicitud,
                 vind_trans_autom
            -- LMVR 20/03/2017 Modificacion para considerar el indicador del pago de immpuesto por producto
            from cara_x_producto
            where cod_empresa = pcodigo_empresa
            and   cod_producto = pcodigo_producto;
        exception
            when others then
                vprefijocuenta := '1';
        end;

        loop
            vsecuencia := pcodigo_producto || vprefijocuenta || lpad(pcodigo_cliente, 7, '0') || lpad(trunc(dbms_random.value(0, 99)), 2, '0');
            dbms_output.put_line('vsecuencia: ' || vsecuencia);
            vdigitover := digito_verificador(vsecuencia);
            dbms_output.put_line('vdigitover: ' || vdigitover);
            vnum_cuenta := to_number(vsecuencia || vdigitover);
            dbms_output.put_line('Cuenta: ' || vnum_cuenta);
            exit when validar_cuenta(vnum_cuenta) = 'S';
        -- AND LENGTH(vnum_cuenta) = 14;
        end loop;

        pnumero_cuenta := vnum_cuenta;

        begin
            select valor_actual
            into vtas_interes
            from tasas_interes
            where cod_empresa = 1
            and   cod_tasa = vcod_tas_int;
        exception
            when others then
                vtas_interes := 0;
        end;


        begin
            insert into cuenta_efectivo(cod_empresa,
                                        num_cuenta,
                                        cod_producto,
                                        cod_agencia,
                                        cod_cliente,
                                        cod_direccion,
                                        cod_grupo_cierr,
                                        cod_ejecutivo,
                                        clase_cuenta,
                                        categ_cuenta,
                                        frec_calc_int,
                                        tip_asigna_tasa,
                                        tip_asigna_carg,
                                        tip_car_adminis,
                                        tip_capitalizac,
                                        tip_correspond,
                                        ind_idioma,
                                        ind_solicitud,
                                        ind_estado,
                                        ind_cta_alterna,
                                        ind_trans_autom,
                                        ind_mancomunada,
                                        ind_impuesto,
                                        ind_pag_interes,
                                        ind_reserva_esp,
                                        cantidad_cheques,
                                        cant_cks_mes,
                                        cant_dep_mes,
                                        sal_total_cta,
                                        sal_tot_dia_ant,
                                        sal_reserva,
                                        sal_minimo,
                                        sal_consultado,
                                        sal_congelado,
                                        sal_embargado,
                                        sal_menor,
                                        sal_promedio,
                                        sal_maximo,
                                        sal_al_cierre,
                                        sal_menor_mes,
                                        sal_promed_mes,
                                        sal_maximo_mes,
                                        acumulad_imptos,
                                        mon_reserva_utl,
                                        mon_sobgro_aut,
                                        mon_sob_no_aut,
                                        mon_sobgro_disp,
                                        mon_total_cargo,
                                        monto_imptos,
                                        int_sobre_saldo,
                                        int_cap_embargo,
                                        int_cap_congela,
                                        int_cap_reserva,
                                        int_por_pagar,
                                        int_sobgro_aut,
                                        int_uso_sobgro,
                                        sal_transito,
                                        ind_reserva_utl,
                                        int_sob_no_aut,
                                        ult_cke_entreg,
                                        int_mes_actual,
                                        ind_sob_no_aut,
                                        ind_restringida,
                                        cobra_cargo_inact,
                                        cobra_cargo_sobgro,
                                        cobra_cargo_chk_plaza,
                                        observacion_corta,
                                        titulares,
                                        nombre_chequera,
                                        fec_apertura,
                                        ind_sobgro,
                                        tas_interes,
                                        period_revisi,
                                        fec_revision,
                                        cod_tas_int,
                                        ind_pag_int_reserva,
                                        ind_tas_int_reserva,
                                        ind_control_secuencia,
                                        cod_grupo)
            values (pcodigo_empresa,
                    vnum_cuenta,
                    pcodigo_producto,
                    vcod_agencia,
                    pcodigo_cliente,
                    vcod_direccion,
                    vcod_grupo_cierr,
                    vcod_ejecutivo,
                    vclase_cuenta,
                    vcateg_cuenta,
                    vfrec_calc_int,
                    vtip_asigna_tasa,
                    vtip_asigna_carg,
                    vtip_car_adminis,
                    vtip_capitalizac,
                    vtip_correspond,
                    vind_idioma,
                    vind_solicitud,
                    vind_estado,
                    vind_cta_alterna,
                    vind_trans_autom,
                    vind_mancomunada,
                    vind_impuesto,
                    vind_pag_interes,
                    vind_reserva_esp,
                    vcantidad_cheques,
                    vcant_cks_mes,
                    vcant_dep_mes,
                    vsal_total_cta,
                    vsal_tot_dia_ant,
                    vsal_reserva,
                    vsal_minimo,
                    vsal_consultado,
                    vsal_congelado,
                    vsal_embargado,
                    vsal_menor,
                    vsal_promedio,
                    vsal_maximo,
                    vsal_al_cierre,
                    vsal_menor_mes,
                    vsal_promed_mes,
                    vsal_maximo_mes,
                    vacumulad_imptos,
                    vmon_reserva_utl,
                    vmon_sobgro_aut,
                    vmon_sob_no_aut,
                    vmon_sobgro_disp,
                    vmon_total_cargo,
                    vmonto_imptos,
                    vint_sobre_saldo,
                    vint_cap_embargo,
                    vint_cap_congela,
                    vint_cap_reserva,
                    vint_por_pagar,
                    vint_sobgro_aut,
                    vint_uso_sobgro,
                    vsal_transito,
                    vind_reserva_utl,
                    vint_sob_no_aut,
                    vult_cke_entreg,
                    vint_mes_actual,
                    vind_sob_no_aut,
                    vind_restringida,
                    vcobra_cargo_inact,
                    vcobra_cargo_sobgro,
                    vcobra_cargo_chk_plaza,
                    vobservacion_corta,
                    vtitulares,
                    vnombre_chequera,
                    trunc(sysdate),
                    vind_sobgro,
                    vtas_interes,
                    vperiod_revisi,
                    vfec_revision,
                    vcod_tas_int,
                    vind_pag_int_reserva,
                    vind_tas_int_reserva,
                    vind_control_secuencia,
                    vcod_grupo);
        exception
            when others then
                dbms_output.put_line('error: ' || sqlerrm);
                perrornum := 207;
                pmensaje_error := 'Error creando Cuenta del cliente, favor verificar codigo de cliente ' || sqlerrm;
                raise_application_error(-20107, pmensaje_error);
        end;

        if vnum_cuenta is not null
           and pmensaje_error is null then
            --update consec_agencia_prod set secuencia_cta = vnumero+1
            --where cod_agencia=vcodagencia2 and cod_producto=vcod_productof;
            pnumero_cuenta := vnum_cuenta;

            begin
                insert into cuenta_cliente_relacion(num_cuenta,
                                                    codigo_cliente,
                                                    tipo_relacion,
                                                    principal,
                                                    cod_sistema,
                                                    estado,
                                                    numero_linea)
                values (vnum_cuenta,
                        vfircltcod_cliente,
                        null,
                        'S',
                        vcodsistctaman,
                        'A',
                        '1');
            end;

            begin
                select 'S'
                into vexiste
                from cc.cuenta_efectivo cta
                where num_cuenta = vnum_cuenta;
            exception
                when no_data_found then
                    perrornum := 210;
                    pmensaje_error := 'Error No se pudo crear  la cuenta, favor verificar par¿metros.';
                    vexiste := 'N';
            end;

            if vexiste = 'S' then
                crear_matriz_riesgos(pcodigo_empresa, pcodigo_cliente, pmensaje_error);
                BEGIN
                update PA.INFO_PROD_SOL
                set cod_moneda=pcodigo_moneda
                where cod_persona=pcodigo_cliente
                and tipo_producto='CUENTA EFECTIVO';
                IF sql%notfouNd THEN
                BEGIN
                INSERT INTO PA.INFO_PROD_SOL(cod_persona,tipo_producto,cod_moneda,proposito,monto_inicial,instrumento_bancario,origen_fondos,incluido_por,fec_inclusion)
                VALUES (pcodigo_cliente,'CUENTA EFECTIVO',pcodigo_moneda,'AHORRAR',500,'EFECTIVO','AHORROS',USER,SYSDATE);
                END;

                end if;
                end;
                commit;
                perrornum := 200;
                pmensaje_error := 'Cuenta creada satisfactoriamente.';
            else
                perrornum := 210;
                pmensaje_error := 'Error No se pudo crear  la cuenta, favor verificar par¿metros.';
                rollback;
            end if;
        --vcod_productof;--vnumero, vcodagencia2
        end if;

        commit;
    --vnumcuentacreado := vnum_cuenta;
    exception
        /*    WHEN NO_DATA_FOUND THEN
                pMumero_cuenta := NULL;
                pErrornum:=208;
                pMensaje_Error := '1-Error creando cuenta, favor verificar codigo';*/
        when others then
            pnumero_cuenta := null;
    /*pErrornum:=209;
    pMensaje_Error := '2-Error creando cuenta, favor verificar codigo';*/
    end;

    procedure crear_matriz_riesgos(pcodigo_empresa in varchar2, 
                                    pcodigo_cliente in number, 
                                    pmensaje_error out varchar2) is
    vcodagencia pa.agencia.cod_agencia%type:=null;
    vcodrespuesta pa.evaluacion_persona.cod_respuesta%type:=null;
    vcodzona pa.agencia.cod_zona%type:=null;
   nValorRespuesta PA.RESPUESTA_PREGUNTA_EVALUACION.valor%type;
    BEGIN
        Begin
            select t1.cod_agencia,t2.cod_zona
            into vcodagencia, vcodzona
            from pa.cliente T1, pa.agencia t2
            where T1.cod_cliente=pcodigo_cliente
            and t1.cod_agencia=t2.cod_agencia;
            exception
            when no_data_found then
            vcodagencia:='';
            vcodzona:='';
            vcodrespuesta:='278';
        End;
        if vcodrespuesta is null and vcodzona is not null then
            begin
                select cod_respuesta 
                into vcodrespuesta 
                from pa.zona_oper_onboarding
                where cod_pregunta='9' and cod_zona=vcodzona;
                exception
                when no_data_found then
                    vcodrespuesta:='278';
            end;
        end if;
        begin
        select valor
        into nValorRespuesta
        from PA.RESPUESTA_PREGUNTA_EVALUACION
        where cod_pregunta='9' and cod_respuesta=vcodrespuesta;
        exception
        when no_data_found then
        nValorRespuesta:=0;
        end;
    BEGIN
        insert into pa.evaluacion_persona(cod_persona,
                                          cod_pregunta,
                                          cod_respuesta,
                                          scoring,
                                          fecha_evaluacion,
                                          incluido_por,
                                          fec_inclusion)
            select pcodigo_cliente,
                   t1.cod_pregunta,
                   case when t1.cod_pregunta ='9' and vcodrespuesta is not null 
                   then 
                        vcodrespuesta else t1.cod_respuesta 
                   end cod_respuesta,
                   case when t1.cod_pregunta ='9' and vcodrespuesta is not null then nValorRespuesta else res.valor end valor,
                   trunc(sysdate),
                   user,
                   sysdate
            from pa.matriz_riesgo_onboarding t1, pa.respuesta_pregunta_evaluacion res
            where t1.cod_pregunta = res.cod_pregunta
            and   t1.cod_respuesta = res.cod_respuesta
            and   not exists
                      (select 1
                       from pa.evaluacion_persona mat
                       where mat.cod_persona = pcodigo_cliente
                       and   cod_pregunta = mat.cod_pregunta
                       and   cod_respuesta = mat.cod_respuesta);
    exception
        when others then
            pmensaje_error := ('Ha ocurrido un eror inesperado' || sqlerrm);
    end;
   END;
end pkg_interfaz_cc;

/

