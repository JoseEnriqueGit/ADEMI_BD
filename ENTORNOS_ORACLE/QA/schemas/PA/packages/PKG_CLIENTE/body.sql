CREATE OR REPLACE package body PA.pkg_cliente is
    function convertir_cliente_api(p_json in blob, p_error in out varchar2)
        return pa.clientes_persona_fisica_obj is
        j apex_json.t_values;
        l_clob clob;
        l_dest_offset pls_integer := 1;
        l_src_offset pls_integer := 1;
        l_lang_context pls_integer := dbms_lob.default_lang_ctx;
        l_warning pls_integer;
        vfecha varchar2(30);
        vprimer_nombre pa.personas_fisicas.primer_nombre%type;
        vsegundo_nombre pa.personas_fisicas.segundo_nombre%type;
        vprimer_apellido pa.personas_fisicas.primer_apellido%type;
        vsegundo_apellido pa.personas_fisicas.segundo_apellido%type;
        vnombrefull pa.personas.nombre%type;
        vtotalingresos number := 0;
        vtotalidpersonas pls_integer := 0;
        vtotaldirpersonas pls_integer := 0;
        vtotaltelpersonas pls_integer := 0;
        vtotalotrobancos pls_integer := 0;
        vtotalrefpers pls_integer := 0;
        vtotalrefcomerc pls_integer := 0;
        vtotallistapep pls_integer := 0;
        vtotalprom pls_integer := 0;
        vindi pls_integer := 0;
        vindd pls_integer := 0;
        vindt pls_integer := 0;
        vindc pls_integer := 0;
        vindrp pls_integer := 0;
        vindrc pls_integer := 0;
        vindp pls_integer := 0;
        vindpp pls_integer := 0;
        vnacionalidad pa.pais.nacionalidad%type;
        vtipoid pa.id_personas.cod_tipo_id%type;
        vmascara pa.tipos_id.mascara%type;
        vtelefono varchar2(30);
        vcodarea pa.tel_personas.cod_area%type;
        vnumtel pa.tel_personas.num_telefono%type;
        vpaisiso3 varchar2(100);
        vcodigopais pa.pais.cod_pais%type;
        vdirsector varchar2(100);
        vdirbarrio varchar2(100);
        vdircalle varchar2(100);
        vdirnumero varchar2(100);
        vcodagencia varchar2(15);
        vcodactividad pa.personas_fisicas.cod_actividad%type;
        vlugartrabajo pa.info_laboral.lugar_trabajo%type;
        vclientepersonafisica pa.clientes_persona_fisica_obj := pa.clientes_persona_fisica_obj();
        vpersona pa.personas_obj := pa.personas_obj();
        vpersonafisica pa.personas_fisicas_obj := pa.personas_fisicas_obj();
        vidpersonas pa.id_personas_list := pa.id_personas_list();
        vidpersona pa.id_personas_obj := pa.id_personas_obj();
        vdirpersonas pa.dir_personas_list := pa.dir_personas_list();
        vdirpersona pa.dir_personas_obj := pa.dir_personas_obj();
        vtelpersonas pa.tel_personas_list := pa.tel_personas_list();
        vtelpersona pa.tel_personas_obj := pa.tel_personas_obj();
        vdirenvioxpers pa.dir_envio_x_pers_obj := pa.dir_envio_x_pers_obj();
        vinfolaboral pa.info_laboral_obj := pa.info_laboral_obj();
        vctacliotrbancos pa.ctas_clientes_otr_bancos_list := pa.ctas_clientes_otr_bancos_list();
        vctacliotrbanco pa.ctas_clientes_otr_bancos_obj := pa.ctas_clientes_otr_bancos_obj();
        vrefpersonales pa.ref_personales_list := pa.ref_personales_list();
        vrefpersonal pa.ref_personales_obj := pa.ref_personales_obj();
        vrefcomerciales pa.ref_comerciales_list := pa.ref_comerciales_list();
        vrefcomercial pa.ref_comerciales_obj := pa.ref_comerciales_obj();
        vinfoprodsol pa.info_prod_sol_obj := pa.info_prod_sol_obj();
        vinfoburo pa.info_buro_obj := pa.info_buro_obj();
        vinfodocfisnac pa.info_doc_fisica_nacional_obj := pa.info_doc_fisica_nacional_obj();
        vinfodocfisextranj pa.info_doc_fisica_extranj_obj := pa.info_doc_fisica_extranj_obj();
        vinfoverifdocfisnac pa.info_verif_doc_fis_nac_obj := pa.info_verif_doc_fis_nac_obj();
        vinfoverifdocfisext pa.info_verif_doc_fis_extran_obj := pa.info_verif_doc_fis_extran_obj();
        vinfoworldcheck pa.info_world_check_obj := pa.info_world_check_obj();
        vlistapep pa.lista_pep_list := pa.lista_pep_list();
        vpep pa.lista_pep_obj := pa.lista_pep_obj();
        vpromocionpersonas pa.promocion_persona_list := pa.promocion_persona_list();
        vpromocionpersona pa.promocion_persona_obj := pa.promocion_persona_obj();
        vcanal pa.canal_solicitud_obj := pa.canal_solicitud_obj();
        vpuestodesc  PA.INFO_LABORAL.PUESTO%TYPE;
    begin
        if p_json is not null then
            -- Convert the BLOB to a CLOB.
            dbms_lob.createtemporary(lob_loc => l_clob, cache => false, dur => dbms_lob.call);

            dbms_lob.converttoclob(dest_lob => l_clob,
                                   src_blob => p_json,
                                   amount => dbms_lob.lobmaxsize,
                                   dest_offset => l_dest_offset,
                                   src_offset => l_src_offset,
                                   blob_csid => dbms_lob.default_csid,
                                   lang_context => l_lang_context,
                                   warning => l_warning);

            apex_json.parse(j, l_clob);

            vclientepersonafisica := pa.clientes_persona_fisica_obj();

            vcanal := pa.canal_solicitud_obj();
            vcanal.cod_canal := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.Canal.idCanal');
            vcanal.cod_sistema := case when vcanal.cod_canal = 'ONB' then 'CC' else 'TC' end;

            vcodagencia := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.CodAgencia');
            vclientepersonafisica.esfisica := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.EsFisica');
            vclientepersonafisica.consultarburo :=
                nvl(apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.ConsultarBuro'), apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.ConsultaBuro'));
            vclientepersonafisica.consultarpadron :=
                nvl(apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.ConsultarPadron'), apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.ConsultarPadron'));
            vclientepersonafisica.cod_promotor := to_number(apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.CodPromotor'));

            if (vcodagencia is not null) then
                select nvl(a.gerente, vclientepersonafisica.cod_promotor)
                into vclientepersonafisica.cod_promotor
                from pa.agencia a
                where a.cod_agencia = vcodagencia;
            end if;

            vprimer_nombre := upper(apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.PrimerNombre'));
            vsegundo_nombre := upper(apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.SegundoNombre'));
            vprimer_apellido := upper(apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.PrimerApellido'));
            vsegundo_apellido := upper(apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.SegundoApellido'));
            vnombrefull := vprimer_nombre || ' ' || vsegundo_nombre || ' ' || vprimer_apellido || ' ' || vsegundo_apellido;
            dbms_output.put_line('ANTES vPrimer_Nombre = [' || vprimer_nombre || ']');
            dbms_output.put_line('ANTES vSegundo_Nombre = ' || vsegundo_nombre);
            dbms_output.put_line('ANTES vPrimer_Apellido = ' || vprimer_apellido);
            dbms_output.put_line('ANTES vSegundo_Apellido = ' || vsegundo_apellido);

            dbms_output.put_line('vNombreFull = ' || vnombrefull || ' longitud=' || length(vnombrefull));

            -- Personas
            vpersona := pa.personas_obj();
            vpersona.es_fisica := vclientepersonafisica.esfisica;
            vpersona.nombre := vnombrefull;
            vpersona.ind_clte_i2000 := 'N';
            vpersona.paga_imp_ley288 := 'S';
            vpersona.benef_pag_ley288 := 'S';
            vpersona.cod_vinculacion := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.CodigoVinculacion');
            vpersona.cod_sec_contable := '030202';
            vpersona.codigo_sustituto := null;
            vpersona.estado_persona := 'A';
            vpersona.cobr_nodgii_132011 := 'S';
            vpersona.lleno_fatca := 'N';
            vpersona.imprimio_fatca := 'N';
            vpersona.es_fatca := 'N';
            vpersona.tel_verificado := 'N';

            vpersonafisica := pa.personas_fisicas_obj();
            vpersonafisica.est_civil := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.EstadoCivil');
            vpersonafisica.sexo := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.Sexo');
            vfecha := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.FechaNacimiento');
            vpersonafisica.fec_nacimiento := to_date(vfecha, 'DD/MM/RRRR');
            vpersonafisica.primer_apellido := vprimer_apellido;
            vpersonafisica.segundo_apellido := vsegundo_apellido;
            vpersonafisica.primer_nombre := vprimer_nombre;
            vpersonafisica.segundo_nombre := vsegundo_nombre;
            vpersonafisica.idioma_correo := 'ESPA';
            vpersonafisica.es_mal_deudor := 'N';
            vpersonafisica.nacionalidad := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.Nacionalidad');
            vpersonafisica.cod_sector := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.SectorActividad');
            vpersonafisica.estatal := 'N';
            vpersonafisica.email_usuario := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.Email');
            vpersonafisica.email_servidor := null;
            vpersonafisica.nivel_estudios := null;
            vpersonafisica.tipo_vivienda := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.TipoVivienda');
            vpersonafisica.num_hijos := nvl(apex_json.get_number(p_values => j, p_path => 'ClientePersonaFisica.NumeroHijos'), 0);
            vpersonafisica.num_dependientes := nvl(apex_json.get_number(p_values => j, p_path => 'ClientePersonaFisica.NumeroDependientes'), 0);
            vpersonafisica.es_residente := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.EsResidente');
            vpersonafisica.tiempo_vivien_act := nvl(apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.TiempoViviendaActual'), 0);
            vpersonafisica.eval_ref_bancaria := 'V';
            vpersonafisica.eval_ref_tarjetas := 'V';
            vpersonafisica.eval_ref_laboral := 'C';
            vpersonafisica.tipo_gen_divisas := nvl(apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.TipoGeneradorDivisa'), pa.obt_parametros('1', 'PA', 'TIPO_GEN_DIVISAS'));
            vpersonafisica.ocupacion_clasif_nac := nvl(apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.InformacionLaboral.Ocupacion'), '10014');
            vtotalingresos := nvl(apex_json.get_number(p_values => j, p_path => 'ClientePersonaFisica.TotalIngresos'), 0);
            vpersonafisica.total_ingresos := vtotalingresos;
            vpaisiso3 := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.PaisIso3');

            begin
                select cod_pais
                into vcodigopais
                from pa.pais
                where pa.pais.cod_pais_iso = vpaisiso3;
            exception
                when no_data_found then
                    vcodigopais := pa.obt_parametros('1', 'PA', 'CODIGO_PAIS_LOCAL');
            end;

            vpersonafisica.cod_pais := nvl(vcodigopais, pa.obt_parametros('1', 'PA', 'CODIGO_PAIS_LOCAL'));
            vpersonafisica.scoring := 0;
            vpersonafisica.actividad := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.ActividadQueRealiza');
            vpersonafisica.rango_ingresos := nvl(pa.obt_rango_ingresos(nvl(vtotalingresos, 0)), 1);
            vpersonafisica.casada_apellido := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.ApellidoCasada');
            vpersonafisica.es_funcionario := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.EsFuncionarioPep');
            vpersonafisica.es_peps := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.EsRelacionadoPep');

            vcodactividad := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.CodigoActividad');

            if vcanal.cod_canal = 'ONB'
               and vcodactividad is null then
                vcodactividad := '930992';
            end if;

            vpersonafisica.cod_actividad := vcodactividad;


            vpersonafisica.cod_subactividad := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.CodigoSubactividad');

            vpersonafisica.tipo_cliente := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.TipoCliente');
            vpersonafisica.cod_finalidad := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.CodigoFinalidad');
            vpersonafisica.apellido_casada := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.ApellidoCasada');
            vpersonafisica.tercer_nombre := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.TercerNombre');
            vpersonafisica.tipo_soc_conyugal := 'S';
            vpersonafisica.gpo_riesgo := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.GrupoRiesgo');
            vpersonafisica.ind_clte_vip := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.ClienteVIP');

            vtotalidpersonas := apex_json.get_count(p_values => j, p_path => 'ClientePersonaFisica.Identificaciones');
            vidpersonas := pa.id_personas_list();

            if vtotalidpersonas > 0 then
                for i in 1 .. vtotalidpersonas
                loop
                    vidpersona := pa.id_personas_obj();
                    vtipoid := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.Identificaciones[%d].TipoIdentificacion', p0 => i);

                    begin
                        select mascara
                        into vmascara
                        from tipos_id
                        where cod_tipo_id = vtipoid;
                    exception
                        when others then
                            vmascara := 'NNN-NNNNNNN-N';
                    end;

                    vidpersona.cod_tipo_id := vtipoid;
                    vidpersona.num_id :=
                        pa.formatear_identificacion(apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.Identificaciones[%d].NumeroIdentificacion', p0 => i), vmascara, 'ESPA');
                    vidpersona.fec_vencimiento := to_date('31/12/2050', 'DD/MM/RRRR');
                    vpaisiso3 := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.Identificaciones[%d].PaisIso3Identificacion', p0 => i);

                    begin
                        select cod_pais
                        into vcodigopais
                        from pa.pais
                        where pa.pais.cod_pais_iso = vpaisiso3;
                    exception
                        when no_data_found then
                            vcodigopais := pa.obt_parametros('1', 'PA', 'CODIGO_PAIS_LOCAL');
                    end;

                    vidpersona.cod_pais := vcodigopais;

                    begin
                        select distinct nacionalidad
                        into vnacionalidad
                        from pa.pais
                        where cod_pais = vidpersona.cod_pais;
                    exception
                        when no_data_found then
                            vnacionalidad := null;
                    end;

                    vidpersona.nacionalidad := nvl(vnacionalidad, 'Dominicana');
                    vidpersonas.extend;
                    vindi := vindi + 1;
                    vidpersonas(vindi) := vidpersona;
                end loop;
            end if;

            vpersonafisica.tipo_persona := nvl(apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.TipoPersona'), pa.asigna_tipo_persona(vtipoid, vpersonafisica.sexo));
            vdirpersonas := pa.dir_personas_list();
            vtotaldirpersonas := apex_json.get_count(p_values => j, p_path => 'ClientePersonaFisica.Direcciones');

            if vtotaldirpersonas > 0 then
                for d in 1 .. vtotaldirpersonas
                loop
                    vdirpersona := pa.dir_personas_obj();
                    vdirpersona.tip_direccion := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.Direcciones[%d].TipoDireccion', p0 => d); -- Direccion donde Vive
                    vpaisiso3 := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.Direcciones[%d].PaisIso3', p0 => d);

                    begin
                        select cod_pais
                        into vcodigopais
                        from pa.pais
                        where pa.pais.cod_pais_iso = vpaisiso3;
                    exception
                        when no_data_found then
                            vcodigopais := pa.obt_parametros('1', 'PA', 'CODIGO_PAIS_LOCAL');
                    end;

                    vdirpersona.cod_pais := vcodigopais;
                    vdirpersona.cod_provincia := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.Direcciones[%d].CodigoRegion', p0 => d);

                    vdirpersona.cod_canton := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.Direcciones[%d].CodigoProvincia', p0 => d);

                    if vdirpersona.cod_provincia is null
                       and vdirpersona.cod_canton is not null then
                        begin
                            select distinct c.cod_provincia
                            into vdirpersona.cod_provincia
                            from pa.cantones c
                            where c.cod_pais = 1
                            and   c.cod_canton = vdirpersona.cod_canton;
                        exception
                            when others then
                                vdirpersona.cod_provincia := '1';
                        end;
                    end if;

                    vdirpersona.cod_distrito := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.Direcciones[%d].CodigoMunicipio', p0 => d);
                    vdirpersona.cod_pueblo := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.Direcciones[%d].CodigoPueblo', p0 => d);
                    vdirpersona.es_default := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.Direcciones[%d].PorDefecto', p0 => d);
                    vdirsector := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.Direcciones[%d].Sector', p0 => d);
                    vdirbarrio := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.Direcciones[%d].Barrio', p0 => d);
                    vdircalle := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.Direcciones[%d].Calle', p0 => d);
                    vdirnumero := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.Direcciones[%d].NumeroCasaApto', p0 => d);
                    vdirpersona.detalle := vdircalle || ' NO.' || vdirnumero || ', ' || vdirbarrio || ', ' || vdirsector;
                    vdirpersonas.extend;
                    vindd := vindd + 1;
                    vdirpersonas(vindd) := vdirpersona;
                end loop;
            end if;

            vtelpersonas := pa.tel_personas_list();
            vtotaltelpersonas := apex_json.get_count(p_values => j, p_path => 'ClientePersonaFisica.Telefonos');

            if vtotaltelpersonas > 0 then
                for t in 1 .. vtotaltelpersonas
                loop
                    vtelpersona := pa.tel_personas_obj();
                    vtelefono := pa.extraer_numeros(apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.Telefonos[%d].NumeroTelefono', p0 => t));
                    vcodarea := substr(vtelefono, 1, 3);
                    vnumtel := substr(vtelefono, 4);
                    vtelpersona.cod_area := vcodarea;
                    vtelpersona.num_telefono := vnumtel;
                    vtelpersona.tip_telefono := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.Telefonos[%d].TipoTelefono', p0 => t); -- Linea Directa
                    vtelpersona.tel_ubicacion := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.Telefonos[%d].UbicacionTelefono', p0 => t); -- Casa
                    vtelpersona.es_default := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.Telefonos[%d].PorDefecto', p0 => t);
                    vpaisiso3 := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.Telefonos[%d].PaisIso3Telefono', p0 => t);

                    begin
                        select cod_pais
                        into vcodigopais
                        from pa.pais
                        where pa.pais.cod_pais_iso = vpaisiso3;
                    exception
                        when no_data_found then
                            vcodigopais := pa.obt_parametros('1', 'PA', 'CODIGO_PAIS_LOCAL');
                    end;

                    vtelpersona.cod_pais := vcodigopais;
                    vtelpersonas.extend;
                    vindt := vindt + 1;
                    vtelpersonas(vindt) := vtelpersona;
                end loop;
            end if;

            vdirenvioxpers := pa.dir_envio_x_pers_obj();
            vdirenvioxpers.tipo_envio := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.DireccionEnvio.TipoEnvio');
            /*vCodPais                       := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.DireccionEnvio.CodigoPais');
            vCodRegion                     := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.DireccionEnvio.CodigoRegion');
            vCodProvincia                  := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.DireccionEnvio.CodigoProvincia');
            vCodMunicipio                  := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.DireccionEnvio.CodigoMunicipio');
            vCodPueblo                     := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.DireccionEnvio.CodigoPueblo');
            vDetalleDireccion              := APEX_JSON.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.DireccionEnvio.Detalle');*/
            vdirenvioxpers.cod_direccion := 4;
            vdirenvioxpers.cod_empresa := '1';
            vdirenvioxpers.cod_agencia := nvl(vcodagencia, 50);
            vdirenvioxpers.email_usuario := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.DireccionEnvio.EmailEnvio');



            vinfolaboral := pa.info_laboral_obj();
            vfecha := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.InformacionLaboral.FechaIngreso');
            vlugartrabajo := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.InformacionLaboral.LugarTrabajo');
           vpuestodesc := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.InformacionLaboral.Puesto');
            if vcanal.cod_canal = 'ONB'
               and vlugartrabajo is null then
                vlugartrabajo := 'Independiente';
            end if;

            if vcanal.cod_canal = 'ONB'
               and vpuestodesc is null then
                vpuestodesc:='Trabajo independiente';
            end if;

            if vfecha is not null
               and vlugartrabajo is not null then
                vinfolaboral.fec_ingreso := to_date(vfecha, 'DD/MM/RRRR');
                vinfolaboral.lugar_trabajo := vlugartrabajo;
                vinfolaboral.monto := apex_json.get_number(p_values => j, p_path => 'ClientePersonaFisica.InformacionLaboral.MontoIngreso');
                vinfolaboral.cod_cargo := '50';
                vinfolaboral.puesto := vpuestodesc;--apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.InformacionLaboral.Puesto');
                vinfolaboral.observaciones := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.InformacionLaboral.Observaciones');
                vinfolaboral.tipo_ingreso := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.InformacionLaboral.TipoIngresos');
                vinfolaboral.empleo_actual := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.InformacionLaboral.EsEmpleoActual');
                vinfolaboral.cod_moneda := null;
                vinfolaboral.monto_origen := null;
                vinfolaboral.direccion := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.InformacionLaboral.DireccionLaboral');
                vtelefono := pa.extraer_numeros(apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.InformacionLaboral.Telefono'));
                vcodarea := substr(vtelefono, 1, 3);
                vnumtel := substr(vtelefono, 4);
                vinfolaboral.cod_area := vcodarea;
                vinfolaboral.num_telefono := vnumtel;
                vinfolaboral.extension_tel := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.InformacionLaboral.ExtensionTelefonica');
                vinfolaboral.antiguedad := null;
            end if;

            vctacliotrbancos := pa.ctas_clientes_otr_bancos_list();
            vtotalotrobancos := apex_json.get_count(p_values => j, p_path => 'ClientePersonaFisica.CuentaOtrosBancos');

            if vtotalotrobancos > 0 then
                for c in 1 .. vtotalotrobancos
                loop
                    vctacliotrbanco := pa.ctas_clientes_otr_bancos_obj();
                    vctacliotrbanco.cod_emisor := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.CuentaOtrosBancos[%d].EntidadBancaria', p0 => c);
                    vctacliotrbanco.num_cuenta := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.CuentaOtrosBancos[%d].NumeroCuenta', p0 => c);
                    vctacliotrbanco.nom_cuenta := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.CuentaOtrosBancos[%d].NombreCuenta', p0 => c);
                    vctacliotrbanco.tipo_cuenta := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.CuentaOtrosBancos[%d].TipoCuenta', p0 => c);
                    vctacliotrbanco.cod_moneda := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.CuentaOtrosBancos[%d].MonedaCuenta', p0 => c);
                    vpaisiso3 := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.CuentaOtrosBancos[%d].PaisIso3Cuenta', p0 => c);

                    begin
                        select cod_pais
                        into vcodigopais
                        from pa.pais
                        where pa.pais.cod_pais_iso = vpaisiso3;
                    exception
                        when no_data_found then
                            vcodigopais := pa.obt_parametros('1', 'PA', 'CODIGO_PAIS_LOCAL');
                    end;

                    vctacliotrbanco.cod_pais := vcodigopais;
                    vctacliotrbanco.oficial_responsable := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.CuentaOtrosBancos[%d].Oficial', p0 => c);
                    vctacliotrbanco.tiempo_apertura := apex_json.get_number(p_values => j, p_path => 'ClientePersonaFisica.CuentaOtrosBancos[%d].TiempoAperturaCuenta', p0 => c);
                    vctacliotrbancos.extend;
                    vindc := vindc + 1;
                    vctacliotrbancos(vindc) := vctacliotrbanco;
                end loop;
            end if;

            vrefpersonales := pa.ref_personales_list();
            vtotalrefpers := apex_json.get_count(p_values => j, p_path => 'ClientePersonaFisica.ReferenciasPersonales');

            if vtotalrefpers > 0 then
                for p in 1 .. vtotalrefpers
                loop
                    vrefpersonal := pa.ref_personales_obj();
                    vtelefono := null;
                    vrefpersonal.cod_empresa := '1';
                    vrefpersonal.cod_tipo_id := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.ReferenciasPersonales[%d].TipoIdentificacion', p0 => p);
                    vrefpersonal.nombre_ref := UPPER(apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.ReferenciasPersonales[%d].Nombres', p0 => p));
                    vrefpersonal.num_id := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.ReferenciasPersonales[%d].NumeroIdentificacion', p0 => p);
                    vtelefono := pa.extraer_numeros(apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.ReferenciasPersonales[%d].Telefono', p0 => p));
                    vcodarea := substr(vtelefono, 1, 3);
                    vnumtel := substr(vtelefono, 4);
                    vrefpersonal.cod_area := vcodarea;
                    vrefpersonal.num_telefono := vnumtel;
                    vrefpersonal.puesto := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.ReferenciasPersonales[%d].Puesto', p0 => p);
                    vrefpersonal.lugar_trabajo := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.ReferenciasPersonales[%d].LugarTrabajo', p0 => p);
                    vrefpersonal.relacion_persona := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.ReferenciasPersonales[%d].RelacionConCliente', p0 => p);
                    vrefpersonales.extend;
                    vindrp := vindrp + 1;
                    vrefpersonales(vindrp) := vrefpersonal;
                end loop;
            else
                if vcanal.cod_canal = 'ONB' THEN
                    --HAGUTIERREZ | ELSE Agregado para Onboarding
                    --Se insertan referencias personasles dummy para saltar validacion del mismo
                    for p in 1 .. 2
                    loop
                        vrefpersonal := pa.ref_personales_obj();
                        vrefpersonal.cod_empresa := '1';
                        vrefpersonal.cod_tipo_id := '1';
                        vrefpersonal.nombre_ref := 'REF ONBOARDING';
                        vrefpersonal.num_id := '1';
                        /*vTelefono                       := null;
                        vCodArea                        := SUBSTR(vTelefono,1,3);
                        vNumTel                         := SUBSTR(vTelefono, 4);*/
                        /*vRefPersonal.COD_AREA           := vCodArea;
                        vRefPersonal.NUM_TELEFONO       := vNumTel;*/
                        /* vRefPersonal.PUESTO             := '';
                         vRefPersonal.LUGAR_TRABAJO      := '';*/
                        vrefpersonal.relacion_persona := 'FAMILIAR';
                        vrefpersonales.extend;
                        vindrp := vindrp + 1;
                        vrefpersonales(vindrp) := vrefpersonal;
                    end loop;
                end if;
            end if;

            vtotalrefcomerc := apex_json.get_count(p_values => j, p_path => 'ClientePersonaFisica.RefenciasComerciales');

            if vtotalrefcomerc > 0 then
                for c in 1 .. vtotalrefcomerc
                loop
                    vrefcomercial.cod_tip_ref := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.RefenciasComerciales[%d].TipoReferencia', p0 => c);
                    vrefcomercial.cod_ente := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.RefenciasComerciales[%d].EntidadComercial', p0 => c);
                    vrefcomercial.num_cuenta := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.RefenciasComerciales[%d].NumeroCuenta', p0 => c);
                    vrefcomercial.credito_otorgado := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.RefenciasComerciales[%d].CreditoOtorgado', p0 => c);
                    vrefcomercial.saldo_credito := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.RefenciasComerciales[%d].CreditoSaldado', p0 => c);
                    vrefcomercial.cuota_mensual := apex_json.get_number(p_values => j, p_path => 'ClientePersonaFisica.RefenciasComerciales[%d].CuotaMensual', p0 => c);
                    vrefcomercial.cod_moneda := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.RefenciasComerciales[%d].Moneda', p0 => c);
                    vfecha := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.RefenciasComerciales[%d].FechaApertura', p0 => c);
                    vrefcomercial.fec_apertura := to_date(vfecha, 'DD/MM/RRRR');
                    vfecha := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.RefenciasComerciales[%d].FechaVencimiento', p0 => c);
                    vrefcomercial.fec_vencimiento := to_date(vfecha, 'DD/MM/RRRR');
                    vrefcomercial.desc_garantia := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.RefenciasComerciales[%d].DescripionGarantia', p0 => c);
                    vrefcomercial.observaciones := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.RefenciasComerciales[%d].Observaciones', p0 => c);
                    vrefcomercial.oficial := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.RefenciasComerciales[%d].Oficial', p0 => c);
                    vrefcomercial.nombre_ente := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.RefenciasComerciales[%d].NombreEntidad', p0 => c);
                    vrefcomercial.num_telefono := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.RefenciasComerciales[%d].Telefono', p0 => c);
                    vrefcomercial.tipo_cuenta := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.RefenciasComerciales[%d].TipoCuenta', p0 => c);
                    vrefcomerciales.extend;
                    vindrc := vindrc + 1;
                    vrefcomerciales(vindrc) := vrefcomercial;
                end loop;
            end if;

            vinfoprodsol.tipo_producto := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.InformacionProductoSolicitado.TipoProducto');
            vinfoprodsol.cod_moneda := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.InformacionProductoSolicitado.Moneda');
            vinfoprodsol.proposito := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.InformacionProductoSolicitado.PropositoDelProducto');
            vinfoprodsol.monto_inicial := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.InformacionProductoSolicitado.MontoProducto');
            vinfoprodsol.instrumento_bancario := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.InformacionProductoSolicitado.InstrumentoBancario');
            vinfoprodsol.rango_monetario_ini := null;
            vinfoprodsol.rango_monetario_fin := null;
            vinfoprodsol.prom_mes_depo_efectivo := null;
            vinfoprodsol.prom_mes_depo_cheques := null;
            vinfoprodsol.prom_mes_reti_efectivo := null;
            vinfoprodsol.prom_mes_trans_enviada := null;
            vpaisiso3 := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.InformacionProductoSolicitado.PaisIso3OrigenFondos');

            begin
                select cod_pais
                into vcodigopais
                from pa.pais
                where pa.pais.cod_pais_iso = vpaisiso3;
            exception
                when no_data_found then
                    vcodigopais := pa.obt_parametros('1', 'PA', 'CODIGO_PAIS_LOCAL');
            end;

            vinfoprodsol.cod_pais_destino := vcodigopais;
            vinfoprodsol.prom_mes_trans_recibida := null;
            vinfoprodsol.cod_pais_origen := null;
            vinfoprodsol.compras_giros_cheques_ger := null;
            vinfoprodsol.origen_fondos := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.InformacionProductoSolicitado.OrigenFondos');

            vinfoburo := pa.info_buro_obj();

            if vclientepersonafisica.consultarburo = 'S' then
                vinfoburo.reporte := vclientepersonafisica.consultarburo;
                vinfoburo.fecha := sysdate;
                vinfoburo.comentarios := null;
            end if;

            vinfodocfisnac := pa.info_doc_fisica_nacional_obj();
            vinfoverifdocfisnac := pa.info_verif_doc_fis_nac_obj();

            if vpersonafisica.cod_pais = '1' then
                vinfodocfisnac.pind_cedula := 'S';
                vinfodocfisnac.pind_licencia_conducir := 'N';
                vinfodocfisnac.pind_residencia := 'N';
                vinfodocfisnac.pind_id_otro := 'N';
                vinfodocfisnac.id_otro_desc := null;
                vinfodocfisnac.pind_certificado_nacimiento := 'N';
                vinfodocfisnac.pind_pensionado_jubilado := 'N';
                vinfodocfisnac.pind_lab_tiempo := 'N';
                vinfodocfisnac.pind_lab_ingreso_anual := 'N';
                vinfodocfisnac.pind_lab_puesto_desempena := 'N';
                vinfodocfisnac.pind_trabaja_independiente := 'N';
                vinfodocfisnac.pind_independiente_actividad := 'N';
                vinfodocfisnac.pind_independiente_justifica_a := 'N';
                vinfodocfisnac.comentarios_adicionales := null;
            end if;

            vinfodocfisextranj := pa.info_doc_fisica_extranj_obj();
            vinfoverifdocfisext := pa.info_verif_doc_fis_extran_obj();

            if vpersonafisica.cod_pais <> '1' then
                vinfodocfisextranj.pind_pasaporte := 'N';
                vinfodocfisextranj.pind_permiso := 'N';
                vinfodocfisextranj.pind_carta_trabajo := 'N';
                vinfodocfisextranj.pind_decla_renta := 'N';
                vinfodocfisextranj.pind_naturaleza_actividad := 'N';
                vinfodocfisextranj.pind_licencia_actividad := 'N';
            end if;

            vinfoworldcheck := pa.info_world_check_obj();

            -- Pep
            vlistapep := pa.lista_pep_list();

            if vclientepersonafisica.personafisica.es_funcionario = 'S'
               or vclientepersonafisica.personafisica.es_peps = 'S' then
                vtotallistapep := apex_json.get_count(p_values => j, p_path => 'ClientePersonaFisica.ListaPep');

                if vtotallistapep > 0 then
                    for l in 1 .. vtotallistapep
                    loop
                        vpep := pa.lista_pep_obj();
                        vpep.cargo := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.ListaPep[%d].CargoPol¿tico', p0 => l);
                        vfecha := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.ListaPep[%d].FechaIngresoAlCargo', p0 => l);
                        vpep.fec_ingreso := to_date(vfecha, 'DD/MM/RRRR');
                        vfecha := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.ListaPep[%d].FechaSalidaDelCargo', p0 => l);
                        vpep.fec_vencimiento := to_date(vfecha, 'DD/MM/RRRR');
                        vpep.apodo := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.ListaPep[%d].Apodo', p0 => l);
                        vpep.codigo_parentesco := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.ListaPep[%d].Parentesco', p0 => l);
                        vpep.institucion_politica := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.ListaPep[%d].InstitucionPolitica', p0 => l);
                        vpep.cod_moneda := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.ListaPep[%d].Moneda', p0 => l);
                        vpaisiso3 := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.ListaPep[%d].PaisIso3', p0 => l);

                        begin
                            select cod_pais
                            into vcodigopais
                            from pa.pais
                            where pa.pais.cod_pais_iso = vpaisiso3;
                        exception
                            when no_data_found then
                                vcodigopais := pa.obt_parametros('1', 'PA', 'CODIGO_PAIS_LOCAL');
                        end;

                        vpep.cod_pais := vcodigopais;
                        vpep.nombre_rel_pep := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.ListaPep[%d].NombreRelacionadoPep', p0 => l);
                        vlistapep.extend;
                        vindp := vindp + 1;
                        vlistapep(vindp) := vpep;
                    end loop;
                end if;
            end if;

            -- Promociones
            vpromocionpersonas := pa.promocion_persona_list();
            vtotalprom := apex_json.get_count(p_values => j, p_path => 'ClientePersonaFisica.PromocionPersonas');

            if vtotalprom > 0 then
                for p in 1 .. vtotalprom
                loop
                    vpromocionpersona := pa.promocion_persona_obj();
                    vpromocionpersona.cod_canal := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.PromocionPersonas[%d].CodigoCanal', p0 => p);
                    vpromocionpersona.fecha_autorizacion := sysdate;
                    vpromocionpersona.autorizado := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.PromocionPersonas[%d].AutorizaPromocionesPorCanal', p0 => p);
                    vpromocionpersona.cod_origen := apex_json.get_varchar2(p_values => j, p_path => 'ClientePersonaFisica.PromocionPersonas[%d].FuenteOrigenPromocion', p0 => p);
                    vpromocionpersonas.extend;
                    vindpp := vindpp + 1;
                    vpromocionpersonas(vindpp) := vpromocionpersona;
                end loop;
            end if;

            dbms_output.put_line('Asignacion de objetos al master vClientePersonaFisica');
            dbms_output.put_line('vClientePersonaFisica.Persona=' || vpersona.nombre);
            vclientepersonafisica.persona := vpersona;
            vclientepersonafisica.personafisica := vpersonafisica;
            vclientepersonafisica.idpersonas := vidpersonas;
            vclientepersonafisica.dirpersonas := vdirpersonas;
            vclientepersonafisica.telpersonas := vtelpersonas;
            vclientepersonafisica.direnvioxpers := vdirenvioxpers;
            vclientepersonafisica.infolaboral := vinfolaboral;
            vclientepersonafisica.ctacliotrbancos := vctacliotrbancos;
            vclientepersonafisica.refpersonales := vrefpersonales;
            vclientepersonafisica.refcomerciales := vrefcomerciales;
            vclientepersonafisica.infoprodsol := vinfoprodsol;
            vclientepersonafisica.infoburo := vinfoburo;
            vclientepersonafisica.infodocfisnac := vinfodocfisnac;
            vclientepersonafisica.infodocfisextranj := vinfodocfisextranj;
            vclientepersonafisica.infoverifdocfisnac := vinfoverifdocfisnac;
            vclientepersonafisica.infoverifdocfisext := vinfoverifdocfisext;
            vclientepersonafisica.infoworldcheck := vinfoworldcheck;
            vclientepersonafisica.listapep := vlistapep;
            vclientepersonafisica.promocionpersonas := vpromocionpersonas;
            vclientepersonafisica.canal := vcanal;
        else
            p_error := p_error || ' Error - El JSON est¿ vacio.';
            raise_application_error(-20100, p_error);
        end if;

        dbms_lob.freetemporary(l_clob);
        return vclientepersonafisica;
    exception
        when others then
            p_error := sqlerrm || ' ' || dbms_utility.format_error_backtrace;
            dbms_output.put_line('p_error = ' || p_error);
            return vclientepersonafisica;
    end;

    procedure procesar_cliente_fisica(ines_fisica    in     varchar2 default 'S',
                                      inconsultarburo in    varchar2 default 'N', -- Consultar en el Buro
                                      inconsultarpadron in  varchar2 default 'N', -- Consulta en Padron
                                      incod_promotor in     varchar2,
                                      inpaga_imp_ley288 in  varchar2 default 'S',
                                      inbenef_pag_ley288 in varchar2 default 'S',
                                      incod_vinculacion in  varchar2,
                                      incobr_nodgii_132011 in varchar2 default 'S',
                                      inprimer_apellido in  varchar2,
                                      insegundo_apellido in varchar2,
                                      inprimer_nombre in    varchar2,
                                      insegundo_nombre in   varchar2,
                                      innacionalidad in     varchar2,
                                      inest_civil    in     varchar2,
                                      insexo         in     varchar2,
                                      infec_nacimiento in   date,
                                      incodsector_actividad in varchar2,
                                      inemail        in     varchar2,
                                      intipo_vivienda in    varchar2 default null,
                                      innum_hijos    in     pls_integer,
                                      innum_dependientes in pls_integer,
                                      ines_residente in     varchar2 default 'S',
                                      intiempo_vivien_act in pls_integer,
                                      intotal_ingresos in   number,
                                      incod_pais     in     varchar2,
                                      inactividad    in     varchar2,
                                      incasada_apellido in  varchar2 default null,
                                      ines_funcionariopep in varchar2 default 'N',
                                      ines_relacionadopep in varchar2 default 'N',
                                      incod_actividad in    varchar2,
                                      incod_subactividad in varchar2,
                                      intipo_persona in     varchar2,
                                      intipo_cliente in     varchar2,
                                      incod_finalidad in    varchar2,
                                      intercer_nombre in    varchar2 default null,
                                      intipo_soc_conyugal in varchar2 default 'S',
                                      ingpo_riesgo   in     varchar2 default 'B',
                                      inindclientevip in    varchar2 default 'N',
                                      intipogendivisas in   varchar2 default null,
                                      inocupacionclasifnac in varchar2 default null,
                                      -- Identificaciones
                                      inidentificacion in   pa.id_personas_list,
                                      -- Direcciones
                                      indirecciones  in     pa.dir_personas_list,
                                      -- Telefonos
                                      intelefonos    in     pa.tel_personas_list,
                                      -- Informacion Laboral
                                      ininfolaboral  in     pa.info_laboral_obj,
                                      -- Direccion de Envio
                                      indirenvioxpers in    pa.dir_envio_x_pers_obj,
                                      -- Cuenta de Otros Bancos
                                      inctaotrosbancos in   pa.ctas_clientes_otr_bancos_list,
                                      -- Referencias Personales
                                      inrefpersonales in    pa.ref_personales_list,
                                      -- Referencias Comerciales
                                      inrefcomerciales in   pa.ref_comerciales_list,
                                      -- Informacion Producto Solicitado
                                      ininfoprodsol  in     pa.info_prod_sol_obj,
                                      -- Lista PEP
                                      inlistapep     in     pa.lista_pep_list,
                                      -- Promociones Personas
                                      inpromocionpersonas in pa.promocion_persona_list,
                                      incanal        in     pa.canal_solicitud_obj default null,
                                      outcodcliente  in out varchar2,
                                      outerror       in out varchar2) is
        vcedula pa.id_personas.num_id%type := null;
        vtipoid pa.id_personas.cod_tipo_id%type;
        vcodpersona pa.personas.cod_per_fisica%type;
        vcodigopais pa.pais.cod_pais%type;
        verror varchar2(4000);
        vcliente pa.clientes_persona_fisica_obj;
        vpersona pa.personas_obj := pa.personas_obj();
        vpersonafisica pa.personas_fisicas_obj := pa.personas_fisicas_obj();
        vinfoburo pa.info_buro_obj := pa.info_buro_obj();
        vinfodocfisnac pa.info_doc_fisica_nacional_obj := pa.info_doc_fisica_nacional_obj();
        vinfodocfisextranj pa.info_doc_fisica_extranj_obj := pa.info_doc_fisica_extranj_obj();
        vinfoverifdocfisnac pa.info_verif_doc_fis_nac_obj := pa.info_verif_doc_fis_nac_obj();
        vinfoverifdocfisext pa.info_verif_doc_fis_extran_obj := pa.info_verif_doc_fis_extran_obj();
        vinfoworldcheck pa.info_world_check_obj := pa.info_world_check_obj();
    begin
        vcliente := pa.clientes_persona_fisica_obj();

        for i in 1 .. inidentificacion.count
        loop
            vtipoid := inidentificacion(i).cod_tipo_id;

            if vtipoid = '1' then
                exit;
            end if;
        end loop;

        -- Determina y asigna el C¿digo de la Persona por la identificaci¿n
        for i in 1 .. inidentificacion.count
        loop
            vcedula := pa.formato_cedula(replace(inidentificacion(i).num_id, '-'), inidentificacion(i).cod_tipo_id, verror);
            vcodpersona := pa.obt_codpersona_con_id(inidentificacion(i).cod_tipo_id, vcedula);

            if vcodpersona is not null then
                exit;
            end if;
        end loop;

        -- Asigna el Codigo de Persona
        if vcodpersona is null then
            vcodpersona := pa.nuevo_codpersona('1', '0');
        end if;

        vcliente.consultarburo := inconsultarburo;
        vcliente.consultarpadron := inconsultarpadron;
        vcliente.cod_promotor := to_number(incod_promotor);
        vcliente.esfisica := ines_fisica;

        vpersona := pa.personas_obj();

        if inprimer_nombre is not null then
            vpersona.nombre := inprimer_nombre || ' ' || insegundo_nombre || ' ' || inprimer_apellido || ' ' || insegundo_apellido;
        end if;

        dbms_output.put_line('PROCESAR CLIENTE FISICA nombres = ' || inprimer_nombre || ' ' || insegundo_nombre || ' ' || inprimer_apellido || ' ' || insegundo_apellido);
        dbms_output.put_line('PROCESAR CLIENTE FISICA vPersona.Nombre = ' || vpersona.nombre);
        vpersona.cod_persona := vcodpersona;
        vpersona.es_fisica := ines_fisica;
        vpersona.ind_clte_i2000 := 'N';
        vpersona.paga_imp_ley288 := inpaga_imp_ley288;
        vpersona.benef_pag_ley288 := inbenef_pag_ley288;
        vpersona.cod_vinculacion := incod_vinculacion;
        vpersona.cod_sec_contable := '030202';
        vpersona.estado_persona := 'A';
        vpersona.cobr_nodgii_132011 := incobr_nodgii_132011;
        vpersona.lleno_fatca := 'N';
        vpersona.imprimio_fatca := 'N';
        vpersona.es_fatca := 'N';
        vpersona.tel_verificado := 'N';
        vcliente.persona := vpersona;

        dbms_output.put_line('PKG_CLIENTE => inSexo = ' || insexo); --prueba

        vpersonafisica := pa.personas_fisicas_obj();
        vpersonafisica.cod_per_fisica := vcodpersona;
        vpersonafisica.est_civil := inest_civil;
        vpersonafisica.sexo := insexo;
        dbms_output.put_line('PKG_CLIENTE => vPersonaFisica.SEXO = ' || vpersonafisica.sexo); --prueba
        vpersonafisica.fec_nacimiento := infec_nacimiento;
        vpersonafisica.primer_apellido := inprimer_apellido;
        vpersonafisica.segundo_apellido := insegundo_apellido;
        vpersonafisica.primer_nombre := inprimer_nombre;
        vpersonafisica.segundo_nombre := insegundo_nombre;
        vpersonafisica.idioma_correo := 'ESPA';
        vpersonafisica.es_mal_deudor := 'N';
        vpersonafisica.nacionalidad := innacionalidad;
        vpersonafisica.cod_sector := incodsector_actividad;
        vpersonafisica.estatal := 'N';
        vpersonafisica.email_usuario := inemail;
        vpersonafisica.email_servidor := null;
        vpersonafisica.nivel_estudios := null;
        vpersonafisica.tipo_vivienda := intipo_vivienda;
        vpersonafisica.num_hijos := nvl(innum_hijos, 0);
        vpersonafisica.num_dependientes := nvl(innum_dependientes, 0);
        vpersonafisica.es_residente := ines_residente;
        vpersonafisica.tiempo_vivien_act := nvl(intiempo_vivien_act, 0);
        vpersonafisica.eval_ref_bancaria := 'V';
        vpersonafisica.eval_ref_tarjetas := 'V';
        vpersonafisica.eval_ref_laboral := 'C';
        vpersonafisica.total_ingresos := nvl(intotal_ingresos, 0);
        vpersonafisica.cod_pais := incod_pais;
        vpersonafisica.scoring := 0;
        vpersonafisica.actividad := inactividad;
        vpersonafisica.rango_ingresos := nvl(pa.obt_rango_ingresos(nvl(intotal_ingresos, 0)), 1);
        vpersonafisica.casada_apellido := incasada_apellido;
        vpersonafisica.es_funcionario := ines_funcionariopep;
        vpersonafisica.es_peps := ines_relacionadopep;
        vpersonafisica.cod_actividad := incod_actividad;
        vpersonafisica.cod_subactividad := incod_subactividad;
        vpersonafisica.tipo_persona := nvl(intipo_persona, pa.asigna_tipo_persona(vtipoid, insexo));
        vpersonafisica.tipo_cliente := intipo_cliente;
        vpersonafisica.cod_finalidad := incod_finalidad;
        vpersonafisica.apellido_casada := incasada_apellido;
        vpersonafisica.tercer_nombre := intercer_nombre;
        vpersonafisica.tipo_soc_conyugal := nvl(intipo_soc_conyugal, 'S');
        vpersonafisica.gpo_riesgo := ingpo_riesgo;
        vpersonafisica.ind_clte_vip := inindclientevip;
        vpersonafisica.tipo_gen_divisas := intipogendivisas;
        vpersonafisica.ocupacion_clasif_nac := inocupacionclasifnac;

        vcliente.personafisica := vpersonafisica;

        dbms_output.put_line('vCliente.PersonaFisica.sexo = ' || vcliente.personafisica.sexo); --prueba
        vcliente.idpersonas := inidentificacion;
        vcliente.dirpersonas := indirecciones;
        vcliente.telpersonas := intelefonos;
        vcliente.direnvioxpers := indirenvioxpers;
        vcliente.infolaboral := ininfolaboral;
        vcliente.ctacliotrbancos := inctaotrosbancos;
        vcliente.refpersonales := inrefpersonales;
        vcliente.refcomerciales := inrefcomerciales;
        vcliente.infoprodsol := ininfoprodsol;

        vinfoburo := pa.info_buro_obj();

        if inconsultarburo = 'S' then
            vinfoburo.reporte := inconsultarburo;
            vinfoburo.fecha := sysdate;
            vinfoburo.comentarios := null;
        end if;

        vcliente.infoburo := vinfoburo;

        vinfodocfisnac := pa.info_doc_fisica_nacional_obj();
        vinfoverifdocfisnac := pa.info_verif_doc_fis_nac_obj();

        if incod_pais = '1' then
            vinfodocfisnac.pind_cedula := 'S';
            vinfodocfisnac.pind_licencia_conducir := 'N';
            vinfodocfisnac.pind_residencia := 'N';
            vinfodocfisnac.pind_id_otro := 'N';
            vinfodocfisnac.id_otro_desc := null;
            vinfodocfisnac.pind_certificado_nacimiento := 'N';
            vinfodocfisnac.pind_pensionado_jubilado := 'N';
            vinfodocfisnac.pind_lab_tiempo := 'N';
            vinfodocfisnac.pind_lab_ingreso_anual := 'N';
            vinfodocfisnac.pind_lab_puesto_desempena := 'N';
            vinfodocfisnac.pind_trabaja_independiente := 'N';
            vinfodocfisnac.pind_independiente_actividad := 'N';
            vinfodocfisnac.pind_independiente_justifica_a := 'N';
            vinfodocfisnac.comentarios_adicionales := null;
        end if;

        vcliente.infoverifdocfisnac := vinfoverifdocfisnac;
        vcliente.infodocfisnac := vinfodocfisnac;

        vinfodocfisextranj := pa.info_doc_fisica_extranj_obj();
        vinfoverifdocfisext := pa.info_verif_doc_fis_extran_obj();

        if incod_pais <> '1' then
            vinfodocfisextranj.pind_pasaporte := 'N';
            vinfodocfisextranj.pind_permiso := 'N';
            vinfodocfisextranj.pind_carta_trabajo := 'N';
            vinfodocfisextranj.pind_decla_renta := 'N';
            vinfodocfisextranj.pind_naturaleza_actividad := 'N';
            vinfodocfisextranj.pind_licencia_actividad := 'N';
        end if;

        vcliente.infodocfisextranj := vinfodocfisextranj;
        vcliente.infoverifdocfisext := vinfoverifdocfisext;
        vinfoworldcheck := pa.info_world_check_obj();
        vcliente.infoworldcheck := vinfoworldcheck;
        vcliente.listapep := inlistapep;
        vcliente.promocionpersonas := inpromocionpersonas;
        vcliente.canal := incanal;

        for i in 1 .. vcliente.idpersonas.count
        loop
            vcliente.idpersonas(i).cod_persona := vcodpersona;
        end loop;

        for d in 1 .. vcliente.dirpersonas.count
        loop
            vcliente.dirpersonas(d).cod_persona := vcodpersona;
        end loop;

        for t in 1 .. vcliente.telpersonas.count
        loop
            vcliente.telpersonas(t).cod_persona := vcodpersona;
        end loop;

        vcliente.direnvioxpers.cod_persona := vcodpersona;
        vcliente.infolaboral.cod_per_fisica := vcodpersona;

        for c in 1 .. vcliente.ctacliotrbancos.count
        loop
            vcliente.ctacliotrbancos(c).cod_cliente := vcodpersona;
        end loop;

        for r in 1 .. vcliente.refpersonales.count
        loop
            vcliente.refpersonales(r).cod_persona := vcodpersona;
        end loop;

        for r in 1 .. vcliente.refcomerciales.count
        loop
            vcliente.refcomerciales(r).cod_persona := vcodpersona;
        end loop;

        vcliente.infoprodsol.cod_persona := vcodpersona;
        vcliente.infoburo.cod_persona := vcodpersona;
        vcliente.infodocfisnac.cod_persona := vcodpersona;
        vcliente.infodocfisextranj.cod_persona := vcodpersona;
        vcliente.infoverifdocfisnac.cod_persona := vcodpersona;
        vcliente.infoverifdocfisext.cod_persona := vcodpersona;
        vcliente.infoworldcheck.cod_persona := vcodpersona;

        if ines_funcionariopep = 'S'
           or ines_relacionadopep = 'S' then
            for p in 1 .. vcliente.listapep.count
            loop
                vcliente.listapep(p).cod_persona := vcodpersona;
            end loop;
        end if;

        for p in 1 .. vcliente.promocionpersonas.count
        loop
            vcliente.promocionpersonas(p).cod_persona := vcodpersona;
        end loop;

        if vcliente.canal.cod_canal is not null then
            vcliente.canal.cod_persona := vcodpersona;
            vcliente.canal.cod_sistema := case when vcliente.canal.cod_canal = 'ONB' then 'CC' else 'TC' end;
        end if;

        begin
            /*
         DBMS_OUTPUT.PUT_LINE ( 'generar PKG_CLIENTE => inSexo = ' || inSexo ); --prueba
DBMS_OUTPUT.PUT_LINE ( 'generar PKG_CLIENTE => vPersonaFisica.SEXO = ' || vPersonaFisica.SEXO ); --prueba
DBMS_OUTPUT.PUT_LINE ( 'generar vCliente.PersonaFisica.sexo = ' || vCliente.PersonaFisica.sexo ); --prueba
*/
            vcliente.generar();
        exception
            when others then
                if verror is null then
                    verror := substr(sqlerrm || ' ' || dbms_utility.format_error_backtrace, 1, 4000);
                else
                    verror := substr(verror || ' ' || sqlerrm || ' ' || dbms_utility.format_error_backtrace, 1, 4000);
                end if;

                dbms_output.put_line('PROCESAR CLIENTE FISICA vCliente.Generar vError = ' || verror);
                outerror := verror;
                vcodpersona := null;
                rollback;
                raise_application_error(-20100, verror);
        end;

        outcodcliente := vcodpersona;
    /*EXCEPTION WHEN OTHERS THEN
        outCodCliente := '0';
        IF vError IS NULL THEN
            vError:= SUBSTR(SQLERRM||' '||dbms_utility.format_error_backtrace,1,4000);
        ELSE
            vError:= SUBSTR(vError||' '||SQLERRM||' '||dbms_utility.format_error_backtrace,1,4000);
        END IF;
        outError := vError;
        DBMS_OUTPUT.PUT_LINE( vError );
        ROLLBACK; */
    end procesar_cliente_fisica;

    procedure generar_cliente(ines_fisica    in     varchar2 default 'S',
                              inindconsultarburo in varchar2 default 'N', -- Consultar en el Buro
                              inindconsultarpadron in varchar2 default 'N', -- Consulta en Padron
                              intipoident    in     varchar2,
                              inidentificacion in   varchar2,
                              inpaga_imp_ley288 in  varchar2 default 'S',
                              inbenef_pag_ley288 in varchar2 default 'S',
                              incod_vinculacion in  varchar2,
                              incobr_nodgii_132011 in varchar2 default 'S',
                              inest_civil    in     varchar2,
                              insexo         in     varchar2,
                              infec_nacimiento in   varchar2,
                              inprimer_apellido in  varchar2,
                              insegundo_apellido in varchar2,
                              inprimer_nombre in    varchar2,
                              insegundo_nombre in   varchar2,
                              innacionalidad in     varchar2,
                              incod_sector   in     varchar2,
                              inemail        in     varchar2,
                              intipo_vivienda in    varchar2 default null,
                              innum_hijos    in     varchar2,
                              innum_dependientes in varchar2,
                              ines_residente in     varchar2 default 'S',
                              intiempo_vivien_act in varchar2,
                              intotal_ingresos in   varchar2,
                              incod_pais     in     varchar2,
                              inactividad    in     varchar2,
                              inrango_ingresos in   varchar2,
                              incasada_apellido in  varchar2 default null,
                              ines_funcionario in   varchar2 default 'N',
                              ines_peps      in     varchar2 default 'N',
                              incod_actividad in    varchar2,
                              incod_subactividad in varchar2,
                              intipo_persona in     varchar2,
                              intipo_cliente in     varchar2,
                              incod_finalidad in    varchar2,
                              intercer_nombre in    varchar2 default null,
                              intipo_soc_conyugal in varchar2 default 'S',
                              ingpo_riesgo   in     varchar2 default 'B',
                              incod_promotor in     varchar2,
                              -- Direccion Personal
                              incod_provincia in    varchar2,
                              incod_canton   in     varchar2,
                              incod_distrito in     varchar2,
                              incod_pueblo   in     varchar2,
                              indirdetalle   in     varchar2,
                              -- Direccion Trabajo
                              incod_pais_trabajo in varchar2,
                              incod_provincia_trabajo in varchar2,
                              incod_canton_trabajo in varchar2,
                              incod_distrito_trabajo in varchar2,
                              incod_pueblo_trabajo in varchar2,
                              indirdetalle_trabajo in varchar2,
                              -- Telefonos
                              intelefonocasa in     varchar2,
                              intelefonocelular in  varchar2,
                              intelefonotrabajo in  varchar2,
                              intelefonoexttrabajo in varchar2,
                              -- Informacion Laboral
                              pcod_agencia_direnv in varchar2,
                              infec_ingreso  in     varchar2,
                              inlugar_trabajo in    varchar2,
                              insueldo       in     varchar2,
                              inpuesto       in     varchar2,
                              intipo_ingreso in     varchar2,
                              inempleo_actual in    varchar2,
                              inprofesion    in     varchar2,
                              -- Cuentas de Otros Bancos
                              incod_emisor_cta in   varchar2,
                              innum_cuenta   in     varchar2,
                              innom_cuenta   in     varchar2,
                              intipo_cuenta  in     varchar2,
                              incod_moneda_cta in   varchar2,
                              incod_pais_cta in     varchar2,
                              inoficial_responsable in varchar2,
                              intiempo_apertura_cta in varchar2,
                              -- Referencias Personales
                              intipo_id_refpers1 in varchar2,
                              innombre_refpers1 in  varchar2,
                              inident_refpers1 in   varchar2,
                              intelefono_refpers1 in varchar2,
                              inrelacion_persona1 in varchar2,
                              intipo_id_refpers2 in varchar2,
                              innombre_refpers2 in  varchar2,
                              inident_refpers2 in   varchar2,
                              intelefono_refpers2 in varchar2,
                              inrelacion_persona2 in varchar2,
                              -- Referencias Comerciales
                              incod_tip_refcomerc in varchar2,
                              incod_entecomerc in   varchar2,
                              inoficial_comerc in   varchar2,
                              innombre_entecomerc in varchar2,
                              --  Informacion Producto Soliictado
                              intipo_producto in    varchar2,
                              incod_moneda_prodsol in varchar2,
                              inproposito_prodsol in varchar2,
                              inmonto_ini_prodsol in varchar2,
                              ininstrumento_bancario in varchar2,
                              inorigen_fondos in    varchar2,
                              outcodpersona  in out varchar2,
                              outerror       in out varchar2) is
        vcliente pa.clientes_obj;
        vpersona pa.personas_obj;
        vpersonafisica pa.personas_fisicas_obj;
        vidpersona pa.id_personas_obj;
        vidpersonas pa.id_personas_list := pa.id_personas_list();
        vdirpersona pa.dir_personas_obj;
        vdirpersonas pa.dir_personas_list := pa.dir_personas_list();
        vtelpersona pa.tel_personas_obj;
        vtelpersonas pa.tel_personas_list := pa.tel_personas_list();
        vdirenvioxpers pa.dir_envio_x_pers_obj;
        vinfolaboral pa.info_laboral_obj;
        vctacliotrbanco pa.ctas_clientes_otr_bancos_obj;
        vctacliotrbancos pa.ctas_clientes_otr_bancos_list := pa.ctas_clientes_otr_bancos_list();
        vrefpersonal pa.ref_personales_obj;
        vrefpersonales pa.ref_personales_list := pa.ref_personales_list();
        vrefcomercial pa.ref_comerciales_obj;
        vrefcomerciales pa.ref_comerciales_list := pa.ref_comerciales_list();
        vinfoprodsol pa.info_prod_sol_obj;
        vinfoburo pa.info_buro_obj;
        vinfodocfisnac pa.info_doc_fisica_nacional_obj;
        vinfodocfisextranj pa.info_doc_fisica_extranj_obj;
        vinfoverifdocfisnac pa.info_verif_doc_fis_nac_obj;
        vinfoverifdocfisext pa.info_verif_doc_fis_extran_obj;
        vinfoworldcheck pa.info_world_check_obj;
        vpromocionpersona pa.promocion_persona_obj;
        vlistapep pa.lista_pep_list := pa.lista_pep_list();
        presultado resultado;
        nindextel number := 0;
        vcodarea varchar2(3);
        vnumtel varchar2(10);
        nindexdir number := 0;
        nindexrefpers number := 0;

        vcodpais pa.pais.cod_pais%type;
        vcodprovincia pa.provincias.cod_provincia%type;
        vcodcanton pa.cantones.cod_canton%type;
        vcoddistrito pa.distritos.cod_distrito%type;
        vcodpueblo pa.sectores.cod_sector%type;

        vtelefonocasa varchar2(30);
        vtelefonocelular varchar2(30);
        vtelefonotrabajo varchar2(30);
        vtelefono_refpers1 varchar2(30);
        vtelefono_refpers2 varchar2(30);

        vcod_sector varchar2(10);
        vprofesion pa.personas_fisicas.profesion%type;

        vrangoingresos pa.rango_ingreso_nicho.codigo%type;

        vcodpersona pa.personas_fisicas.cod_per_fisica%type;
        vcedula pa.id_personas.num_id%type;
    --     vParametros CLOB;

    begin
        -- Llenar datos para crear Cliente

        -- Formato de la Identificacion.

        begin
            vcedula := pa.formato_cedula(inidentificacion, intipoident, outerror);
            vtelefonocasa := pa.extraer_numeros(intelefonocasa);
            vtelefonocelular := pa.extraer_numeros(intelefonocelular);
            vtelefonotrabajo := pa.extraer_numeros(intelefonotrabajo);
            vtelefono_refpers1 := pa.extraer_numeros(intelefono_refpers1);
            vtelefono_refpers2 := pa.extraer_numeros(intelefono_refpers2);
            vcod_sector := pa.extraer_numeros(incod_sector);
        exception
            when others then
                outcodpersona := '0';
                outerror := 'Error - Formateando los telefonos/identificaci¿n.  ' || inidentificacion || ' ' || intelefonocasa || ' ' || intelefonocelular || ' ' || intelefonotrabajo || ' ' ||
                            intelefono_refpers1 || ' ' || intelefono_refpers2;
                return;
        end;

        --DBMS_OUTPUT.PUT_LINE('vTelefonoCasa='||vTelefonoCasa||' vTelefonoCelular='|| vTelefonoCelular ||' vTelefonoTrabajo='||vTelefonoTrabajo||
        --                     ' vTelefono_RefPers1='||vTelefono_RefPers1||' vTelefono_RefPers2='|| vTelefono_RefPers2||' vCod_Sector='||vCod_Sector);
        begin
            select p.cod_pais
            into vcodpais
            from pa.pais p
            where p.cod_pais = to_number(incod_pais);
        exception
            when no_data_found then
                vcodpais := 1;
        end;

        --DBMS_OUTPUT.PUT_LINE('vCodPais='||vCodPais);
        --  Determinar si el cliente existe
        begin
            select i.cod_persona
            into vcodpersona
            from pa.id_personas i
            where i.cod_tipo_id = intipoident
            and   replace(i.num_id, '-', '') = replace(vcedula, '-', '');
        exception
            when no_data_found then
                -- vCodPersona := PA.NUEVO_CODPERSONA ( '1', '0');
                null; --Omariot / malmanzar 15-03-2023
        end;

        --DBMS_OUTPUT.PUT_LINE('vCodPersona='||vCodPersona);
        -- Determina el Rango de Ingresos
        if intotal_ingresos is not null then
            begin
                select to_char(codigo) codigo
                into vrangoingresos
                from rango_ingreso_nicho
                where to_number(intotal_ingresos) >= rango_inicio
                and   to_number(intotal_ingresos) <= rango_fin;
            exception
                when no_data_found then
                    vrangoingresos := '2'; --inRango_Ingresos;
            end;
        end if;

        --DBMS_OUTPUT.PUT_LINE('vRangoIngresos='||vCodPersona);
        --  Empleado
        if inprofesion = '01' then
            vprofesion := '58';
        -- Jubilado
        elsif inprofesion = '04' then
            vprofesion := '53';
        -- Porfesional Independiente
        elsif inprofesion = '05' then
            vprofesion := '677';
        --  Otros
        else
            vprofesion := '999';
        end if;

        --DBMS_OUTPUT.PUT_LINE('vProfesion='||vProfesion);
        -- Personas Fisicas
        vpersonafisica := pa.personas_fisicas_obj();
        vpersonafisica.cod_per_fisica := vcodpersona;
        vpersonafisica.est_civil := nvl(inest_civil, 'S');
        vpersonafisica.sexo := nvl(insexo, 'M');
        vpersonafisica.fec_nacimiento := to_date(infec_nacimiento, 'DD/MM/YYYY');
        vpersonafisica.primer_apellido := upper(inprimer_apellido);
        vpersonafisica.segundo_apellido := upper(insegundo_apellido);
        vpersonafisica.primer_nombre := upper(inprimer_nombre);
        vpersonafisica.segundo_nombre := upper(insegundo_nombre);
        vpersonafisica.profesion := vprofesion;
        vpersonafisica.es_mal_deudor := null;
        vpersonafisica.conyugue := null;
        vpersonafisica.nacionalidad := innacionalidad;
        vpersonafisica.cod_sector := to_number(vcod_sector);
        vpersonafisica.estatal := null;
        --vPersonaFisica.Email_Usuario        := SUBSTR(inEmail, 1, INSTR(inEmail,'@',1)-1);
        vpersonafisica.email_usuario := inemail;
        vpersonafisica.email_servidor := null;
        --vPersonaFisica.Email_Servidor       := SUBSTR(inEmail, INSTR(inEmail,'@',1));
        vpersonafisica.nivel_estudios := null;
        vpersonafisica.tipo_vivienda := intipo_vivienda;
        vpersonafisica.num_hijos := to_number(innum_hijos);
        vpersonafisica.num_dependientes := to_number(innum_dependientes);
        vpersonafisica.es_residente := ines_residente;

        begin
            vpersonafisica.tiempo_vivien_act := to_number(intiempo_vivien_act / 365);
        exception
            when others then
                outcodpersona := '0';
                outerror := 'Error - Convirtiendo el tiempo de vivienda actual. ' || intiempo_vivien_act || ' ' || sqlerrm;
                raise_application_error(-20105, outerror);
        end;

        vpersonafisica.eval_ref_bancaria := 'V';
        vpersonafisica.eval_ref_tarjetas := 'V';
        vpersonafisica.eval_ref_laboral := 'C';
        vpersonafisica.total_ingresos := to_number(intotal_ingresos);
        vpersonafisica.cod_pais := to_number(vcodpais);
        vpersonafisica.actividad := inactividad;
        vpersonafisica.rango_ingresos := to_number(vrangoingresos);
        vpersonafisica.casada_apellido := null;
        vpersonafisica.es_funcionario := ines_funcionario;
        vpersonafisica.es_peps := ines_peps;
        vpersonafisica.cod_actividad := incod_actividad;
        vpersonafisica.cod_subactividad := null;
        vpersonafisica.tipo_persona := intipo_persona;
        vpersonafisica.tipo_cliente := to_number(intipo_cliente);
        vpersonafisica.cod_pais_padre := null;
        vpersonafisica.cod_pais_madre := null;
        vpersonafisica.cod_pais_conyugue := null;
        vpersonafisica.mas_180_dias_eeuu := null;
        vpersonafisica.cod_finalidad := incod_finalidad;
        vpersonafisica.peso := null;
        vpersonafisica.estatura := null;
        vpersonafisica.actividad_polizah := null;
        vpersonafisica.deporte_polizah := null;
        vpersonafisica.peso_polizah := null;
        vpersonafisica.estatura_polizah := null;
        vpersonafisica.apellido_casada := null;
        vpersonafisica.tercer_nombre := null;
        vpersonafisica.tipo_soc_conyugal := intipo_soc_conyugal;
        vpersonafisica.ind_fallecimiento := 'N';
        vpersonafisica.fec_fallecimiento := null;
        vpersonafisica.gpo_riesgo := ingpo_riesgo;
        vpersonafisica.num_empleados := null;
        vpersonafisica.ventas_ingresos := null;
        vpersonafisica.cp_total_activo := null;
        vpersonafisica.ind_clte_vip := null;

        -- Persona
        vpersona := pa.personas_obj();
        vpersona.cod_persona := vpersonafisica.cod_per_fisica;
        vpersona.cod_per_fisica := vpersonafisica.cod_per_fisica;
        vpersona.es_fisica := ines_fisica;
        vpersona.nombre := upper(inprimer_nombre || ' ' || insegundo_nombre || ' ' || inprimer_apellido || ' ' || insegundo_apellido);
        vpersona.paga_imp_ley288 := inpaga_imp_ley288;
        vpersona.benef_pag_ley288 := inbenef_pag_ley288;
        vpersona.cod_vinculacion := incod_vinculacion;
        vpersona.codigo_sustituto := null;
        vpersona.cobr_nodgii_132011 := incobr_nodgii_132011;

        -- Id Personas
        vidpersona := pa.id_personas_obj();
        vidpersona.cod_persona := vpersonafisica.cod_per_fisica;
        vidpersona.cod_tipo_id := to_number(intipoident);
        vidpersona.num_id := vcedula;
        vidpersona.fec_vencimiento := to_date('31/12/2050', 'DD/MM/YYYY');
        vidpersona.cod_pais := to_number(vcodpais);

        --dbms_output.put_line('Dentro de pkg_cliente TipoId='||TO_NUMBER(inTipoIdent)||' vIdPersona.Cod_Tipo_Id='||vIdPersona.Cod_Tipo_Id);
        begin
            select nacionalidad
            into vidpersona.nacionalidad
            from pa.pais
            where cod_pais = to_number(vcodpais);
        exception
            when others then
                vidpersona.nacionalidad := null;
        end;

        vpersonafisica.nacionalidad := nvl(vidpersona.nacionalidad, innacionalidad);

        if vidpersona.nacionalidad is null then
            vidpersona.nacionalidad := innacionalidad;
        end if;

        vidpersonas.extend;
        vidpersonas(1) := vidpersona;

        -- Dir Personas
        vdirpersona := pa.dir_personas_obj();

        if indirdetalle is not null then
            begin
                select cod_provincia, cod_canton, cod_distrito
                into vcodprovincia, vcodcanton, vcoddistrito
                from pa.distritos c
                where c.cod_pais = vcodpais
                and   c.cod_provincia = incod_provincia
                and   c.cod_canton = incod_canton
                and   c.cod_distrito = incod_distrito;
            exception
                when no_data_found then
                    vcodprovincia := incod_provincia;
                    vcodcanton := incod_canton;
                    vcoddistrito := incod_distrito;
            end;

            --DBMS_OUTPUT.PUT_LINE('vCodPais='||vCodPais||' vCodProvincia=['||vCodProvincia||'-'||inCod_Provincia||'] vCodCanton=['||vCodCanton||'-'||inCod_Canton||'] vCodDistrito='||vCodDistrito||' vCodPueblo='||inCod_Pueblo||' '||inDirDetalle);
            vdirpersona.tip_direccion := 1;
            vdirpersona.detalle := upper(indirdetalle);
            vdirpersona.cod_pais := to_number(vcodpais);
            vdirpersona.cod_provincia := to_number(vcodprovincia);
            vdirpersona.cod_canton := to_number(vcodcanton);
            vdirpersona.cod_distrito := to_number(vcoddistrito);
            vdirpersona.cod_pueblo := to_number(nvl(incod_pueblo, nvl(vcodpueblo, 1)));
            vdirpersona.es_default := 'S';
            vdirpersonas.extend;
            nindexdir := nindexdir + 1;
            vdirpersonas(nindexdir) := vdirpersona;
        end if;

        if indirdetalle_trabajo is not null then
            begin
                select cod_provincia, cod_canton, cod_distrito
                into vcodprovincia, vcodcanton, vcoddistrito
                from pa.distritos c
                where c.cod_pais = vcodpais
                and   c.cod_canton = incod_provincia_trabajo
                and   c.cod_distrito = incod_canton_trabajo;
            exception
                when no_data_found then
                    vcodprovincia := null;
            end;

            --DBMS_OUTPUT.PUT_LINE('vCodProvincia=' || vCodProvincia || ' vCodCanton=' || vCodCanton || ' vCodDistrito=' || vCodDistrito || ' vCodPueblo='|| inCod_Pueblo);

            vdirpersona.tip_direccion := 2;
            vdirpersona.detalle := upper(indirdetalle_trabajo);
            vdirpersona.cod_pais := to_number(incod_pais_trabajo);
            vdirpersona.cod_provincia := to_number(vcodprovincia);
            vdirpersona.cod_canton := to_number(vcodcanton);
            vdirpersona.cod_distrito := to_number(vcoddistrito);
            vdirpersona.cod_pueblo := to_number(nvl(incod_pueblo, nvl(vcodpueblo, 1)));
            vdirpersona.es_default := 'N';
            vdirpersonas.extend;
            nindexdir := nindexdir + 1;
            vdirpersonas(nindexdir) := vdirpersona;
        end if;

        -- Tel Personas
        vtelpersona := pa.tel_personas_obj();
        vtelpersona.extension := null;
        vtelpersona.nota := null;
        vtelpersona.posicion := null;
        vtelpersona.cod_direccion := null;
        vtelpersona.cod_pais := null;

        -- Casa
        if vtelefonocasa is not null
           and length(vtelefonocasa) >= 10 then
            vcodarea := substr(vtelefonocasa, 1, 3);
            vnumtel := substr(vtelefonocasa, 4);
            vtelpersona.cod_area := vcodarea;
            vtelpersona.num_telefono := vnumtel;
            vtelpersona.tip_telefono := 'D';
            vtelpersona.tel_ubicacion := 'C';
            vtelpersona.es_default := 'S';
            nindextel := nindextel + 1;
            vtelpersonas.extend;
            vtelpersonas(nindextel) := vtelpersona;
        else
            outcodpersona := '0';
            outerror := 'Error - El Tel¿fono de la casa est¿ incompleto.   Ejemplo: 8099999999';
            raise_application_error(-20105, outerror);
        end if;

        --DBMS_OUTPUT.PUT_LINE('vTelefonoCasa=' || vTelefonoCasa);

        if vtelefonocelular is not null
           and length(vtelefonocelular) >= 10 then
            vcodarea := substr(vtelefonocelular, 1, 3);
            vnumtel := substr(vtelefonocelular, 4);
            vtelpersona.cod_area := vcodarea;
            vtelpersona.num_telefono := vnumtel;
            vtelpersona.tip_telefono := 'C';
            vtelpersona.tel_ubicacion := 'C';

            if vtelefonocasa is null then
                vtelpersona.es_default := 'S';
            else
                vtelpersona.es_default := 'N';
            end if;

            nindextel := nindextel + 1;
            vtelpersonas.extend;
            vtelpersonas(nindextel) := vtelpersona;
        else
            outcodpersona := '0';
            outerror := 'Error - El Tel¿fono celular est¿ incompleto.   Ejemplo: 8099999999';
            raise_application_error(-20105, outerror);
        end if;

        --DBMS_OUTPUT.PUT_LINE('vTelefonoCelular=' || vTelefonoCelular);

        if vtelefonotrabajo is not null
           and length(vtelefonotrabajo) >= 10 then
            vcodarea := substr(vtelefonotrabajo, 1, 3);
            vnumtel := substr(vtelefonotrabajo, 4);
            vtelpersona.cod_area := vcodarea;
            vtelpersona.num_telefono := vnumtel;
            vtelpersona.tip_telefono := 'D';
            vtelpersona.tel_ubicacion := 'T';
            vtelpersona.extension := intelefonoexttrabajo;

            if vtelefonocasa is null
               and vtelefonocelular is null then
                vtelpersona.es_default := 'S';
            else
                vtelpersona.es_default := 'N';
            end if;

            nindextel := nindextel + 1;
            vtelpersonas.extend;
            vtelpersonas(nindextel) := vtelpersona;
        else
            outcodpersona := '0';
            outerror := 'Error - El Tel¿fono del trabajo est¿ incompleto.   Ejemplo: 8099999999';
            raise_application_error(-20105, outerror);
        end if;

        --DBMS_OUTPUT.PUT_LINE('vTelefonoTrabajo=' || vTelefonoTrabajo);

        -- Dir Envio x Persona
        vdirenvioxpers := pa.dir_envio_x_pers_obj();
        vdirenvioxpers.tipo_envio := 'R';
        vdirenvioxpers.apdo_postal := null;
        vdirenvioxpers.codigo_postal := null;
        vdirenvioxpers.cod_direccion := null;
        vdirenvioxpers.cod_area := null;
        vdirenvioxpers.num_telefono := null;
        vdirenvioxpers.num_casilla := null;
        vdirenvioxpers.cod_empresa := '1';
        vdirenvioxpers.cod_agencia := pcod_agencia_direnv;
        vdirenvioxpers.email_usuario := null;
        vdirenvioxpers.email_servidor := null;
        --DBMS_OUTPUT.PUT_LINE('pCod_Agencia_DirEnv=' || pCod_Agencia_DirEnv);

        -- Info Laboral
        vinfolaboral := pa.info_laboral_obj();
        vinfolaboral.fec_ingreso := to_date(infec_ingreso, 'DD/MM/YYYY');
        vinfolaboral.fec_salida := null;
        vinfolaboral.lugar_trabajo := upper(inlugar_trabajo);
        vinfolaboral.monto := to_number(insueldo);
        vinfolaboral.cod_cargo := null;
        vinfolaboral.puesto := inpuesto;
        vinfolaboral.observaciones := null;
        vinfolaboral.tipo_ingreso := nvl(intipo_ingreso, 'S');
        vinfolaboral.empleo_actual := inempleo_actual;
        vinfolaboral.cod_moneda := null;
        vinfolaboral.monto_origen := null;

        --DBMS_OUTPUT.PUT_LINE('inLugar_Trabajo=' || inLugar_Trabajo||' inPuesto='||inPuesto||' inSueldo='||inSueldo);

        if indirdetalle_trabajo is not null then
            vinfolaboral.direccion := upper(indirdetalle_trabajo);
        end if;

        if vtelefonotrabajo is not null
           and length(vtelefonotrabajo) >= 10 then
            vcodarea := substr(vtelefonotrabajo, 1, 3);
            vnumtel := substr(vtelefonotrabajo, 4);
            vinfolaboral.cod_area := vcodarea;
            vinfolaboral.num_telefono := vnumtel;
        end if;

        vinfolaboral.ind_verificado := 'S';


        -- Cuenta Cliente Otros Bancos
        vctacliotrbanco := pa.ctas_clientes_otr_bancos_obj();

        if incod_emisor_cta is not null then
            vctacliotrbanco.cod_emisor := to_number(incod_emisor_cta);
            vctacliotrbanco.num_cuenta := innum_cuenta;
            vctacliotrbanco.nom_cuenta := upper(innom_cuenta);
            vctacliotrbanco.tipo_cuenta := intipo_cuenta;
            vctacliotrbanco.cod_moneda := to_number(incod_moneda_cta);
            vctacliotrbanco.cod_pais := to_number(incod_pais_cta);
            vctacliotrbanco.oficial_responsable := inoficial_responsable;
            vctacliotrbanco.tiempo_apertura := to_number(intiempo_apertura_cta);
        end if;

        vctacliotrbancos.extend;
        vctacliotrbancos(1) := vctacliotrbanco;


        -- Ref Personales
        vrefpersonal := pa.ref_personales_obj();
        vrefpersonal.cod_empresa := '1';
        vrefpersonal.extension_tel := null;
        vrefpersonal.cod_tipo_id := to_number(intipo_id_refpers1);
        vrefpersonal.nombre_ref := upper(innombre_refpers1);
        vrefpersonal.num_id := inident_refpers1;

        if vtelefono_refpers1 is not null then
            vcodarea := substr(vtelefono_refpers1, 1, 3);
            vnumtel := substr(vtelefono_refpers1, 4);
            vrefpersonal.cod_area := vcodarea;
            vrefpersonal.num_telefono := vnumtel;
        end if;

        vrefpersonal.relacion_persona := inrelacion_persona1;

        vrefpersonales.extend;
        nindexrefpers := nindexrefpers + 1;
        vrefpersonales(nindexrefpers) := vrefpersonal;

        vrefpersonal.cod_tipo_id := to_number(intipo_id_refpers2);
        vrefpersonal.nombre_ref := upper(innombre_refpers2);
        vrefpersonal.num_id := inident_refpers2;

        if vtelefono_refpers2 is not null then
            vcodarea := substr(vtelefono_refpers2, 1, 3);
            vnumtel := substr(vtelefono_refpers2, 4);
            vrefpersonal.cod_area := vcodarea;
            vrefpersonal.num_telefono := vnumtel;
        end if;

        vrefpersonal.relacion_persona := upper(inrelacion_persona2);
        vrefpersonales.extend;
        nindexrefpers := nindexrefpers + 1;
        vrefpersonales(nindexrefpers) := vrefpersonal;

        -- Ref Comerciales
        vrefcomercial := pa.ref_comerciales_obj();

        if innombre_entecomerc is not null then
            vrefcomercial.cod_tip_ref := to_number(incod_tip_refcomerc);
            vrefcomercial.cod_ente := to_number(incod_entecomerc);
            vrefcomercial.num_cuenta := null;
            vrefcomercial.cod_moneda := 1;
            vrefcomercial.oficial := inoficial_comerc;
            vrefcomercial.nombre_ente := upper(innombre_entecomerc);
        end if;

        vrefcomerciales.extend;
        vrefcomerciales(1) := vrefcomercial;

        -- Info Producto Solicitado
        vinfoprodsol := pa.info_prod_sol_obj();
        vinfoprodsol.tipo_producto := intipo_producto;
        vinfoprodsol.cod_moneda := to_number(incod_moneda_prodsol);
        vinfoprodsol.proposito := inproposito_prodsol;
        vinfoprodsol.monto_inicial := to_number(inmonto_ini_prodsol);
        vinfoprodsol.instrumento_bancario := upper(ininstrumento_bancario);
        vinfoprodsol.origen_fondos := inorigen_fondos;

        -- Info Buro
        if inindconsultarburo = 'S' then
            vinfoburo := pa.info_buro_obj();
            vinfoburo.reporte := inindconsultarburo;
        end if;

        -- Info Doc Fisica Nacional
        vinfodocfisnac := pa.info_doc_fisica_nacional_obj();
        vinfodocfisnac.pind_cedula := 'S';
        vinfodocfisnac.pind_licencia_conducir := 'N';
        vinfodocfisnac.pind_residencia := 'N';
        vinfodocfisnac.pind_id_otro := 'N';
        vinfodocfisnac.id_otro_desc := 'N';
        vinfodocfisnac.pind_certificado_nacimiento := 'N';
        vinfodocfisnac.pind_pensionado_jubilado := 'N';
        vinfodocfisnac.pind_lab_tiempo := 'N';
        vinfodocfisnac.pind_lab_ingreso_anual := 'N';
        vinfodocfisnac.pind_lab_puesto_desempena := 'N';
        vinfodocfisnac.pind_trabaja_independiente := 'N';
        vinfodocfisnac.pind_independiente_actividad := 'N';
        vinfodocfisnac.pind_independiente_justifica_a := 'N';
        vinfodocfisnac.comentarios_adicionales := 'N';

        -- Info Doc
        vinfodocfisextranj := pa.info_doc_fisica_extranj_obj();
        vinfoverifdocfisnac := pa.info_verif_doc_fis_nac_obj();
        vinfoverifdocfisext := pa.info_verif_doc_fis_extran_obj();
        vinfoworldcheck := pa.info_world_check_obj();
        vlistapep := pa.lista_pep_list();

        -- Cliente
        vcliente := pa.clientes_obj();
        vcliente.indconsultarburo := inindconsultarburo;
        vcliente.indconsultarpadron := inindconsultarpadron;
        vcliente.incod_promotor := incod_promotor;
        vcliente.persona := vpersona;
        vcliente.personafisica := vpersonafisica;
        vcliente.idpersonas := vidpersonas;
        vcliente.dirpersonas := vdirpersonas;
        vcliente.telpersonas := vtelpersonas;
        vcliente.direnvioxpers := vdirenvioxpers;
        vcliente.infolaboral := vinfolaboral;
        vcliente.ctacliotrbancos := vctacliotrbancos;
        vcliente.refpersonales := vrefpersonales;
        vcliente.refcomerciales := vrefcomerciales;
        vcliente.infoprodsol := vinfoprodsol;
        vcliente.infoburo := vinfoburo;
        vcliente.infodocfisnac := vinfodocfisnac;
        vcliente.infodocfisextranj := vinfodocfisextranj;
        vcliente.infoverifdocfisnac := vinfoverifdocfisnac;
        vcliente.infoverifdocfisext := vinfoverifdocfisext;
        vcliente.infoworldcheck := vinfoworldcheck;
        vcliente.listapep := vlistapep;

        --DBMS_OUTPUT.PUT_LINE('Antes de Generar_Persona_Fisica');
        begin
            generar_persona_fisica(vcliente, presultado);

            if presultado.codigo is not null then
                outcodpersona := '0';
                outerror := presultado.descripcion;
                return;
            else
                outcodpersona := pa.obt_codpersona_con_id(p_tipoid => intipoident, p_numid => vcedula); --vCliente.PersonaFisica.Cod_per_fisica;  --malmanzar 15-03-2023
                outerror := presultado.descripcion;
            end if;
        exception
            when others then
                if presultado.codigo is not null then
                    outerror := presultado.descripcion;
                else
                    outerror := substr(sqlerrm || ' ' || dbms_utility.format_error_backtrace, 1, 4000);
                end if;

                outcodpersona := '0';
                return;
        end;

        --DBMS_OUTPUT.PUT_LINE('Despu¿s de Generar_Persona_Fisica '||outError);
        begin
            --
            -- Activar las promociones por todos los canales
            pa.pkg_promocion_persona.asignarcanales(pcod_persona => outcodpersona, --vCodPersona,--vCliente.PersonaFisica.Cod_per_fisica, --malmanzar 15-03-2023
                                                    pfecha_autorizacion => sysdate,
                                                    pautorizado => 'S',
                                                    pcod_origen => 'APP',
                                                    pobservaciones => 'Contactado al Cliente directamente por el APP Portacredit',
                                                    presultado => outerror);
        exception
            when others then
                dbms_output.put_line('Error Asignando Canales de Promociones ' || dbms_utility.format_error_backtrace);

                if presultado.codigo is not null then
                    outerror := presultado.descripcion;
                else
                    outerror := substr(sqlerrm || ' ' || dbms_utility.format_error_backtrace, 1, 4000);
                end if;
        end;

        if outerror = 'Exitoso.' then
            outerror := null;
        end if;
    --DBMS_OUTPUT.PUT_LINE('Despu¿s de AsignarCanales '||outError);
    --DBMS_OUTPUT.PUT_LINE('Antes de Convertir a Cliente');
    /****  ---Omariot / malmanzar 15-03-2023
            BEGIN
                vCliente.Convertir();
            EXCEPTION WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Error convirtiendo a Cliente '||SQLERRM);
                IF pResultado.Codigo IS NOT NULL THEN
                    outError := pResultado.Descripcion;
                ELSE
                    outError:= SUBSTR(SQLERRM||' '||dbms_utility.format_error_backtrace,1,4000);
                END IF;
                DBMS_OUTPUT.PUT_LINE( outError );
            END;
            ****/
    --DBMS_OUTPUT.PUT_LINE('Despu¿s de Convertir a Cliente');
    exception
        when others then
            outcodpersona := '0';

            if outerror is null then
                outerror := substr(sqlerrm || ' ' || dbms_utility.format_error_backtrace, 1, 4000);
            end if;

            dbms_output.put_line(outerror);
            rollback;
    -- INSERT INTO tc.datatemptc (CAMPO, FECHA, VALOR) VALUES ('PKG_CLIENTE ERROR 2', SYSDATE, outError); commit;   */
    end;

    procedure generar_persona_fisica(pcliente in out pa.clientes_obj, presultado in out resultado) is
        vcodpersona pa.personas.cod_persona%type := null;
        vexiste boolean := false;
        vigual boolean := false;
        vcliente pa.clientes_obj;
        vclienteregistrado pa.clientes_obj;
    begin
        vcodpersona := null;
        vcliente := pcliente;

        for i in 1 .. vcliente.idpersonas.count
        loop
            begin
                select i.cod_persona
                into vcodpersona
                from pa.id_personas i
                where i.cod_tipo_id = vcliente.idpersonas(i).cod_tipo_id
                and   replace(i.num_id, '-', '') = replace(vcliente.idpersonas(i).num_id, '-', '')
                and   rownum = 1;

                vcliente.persona.cod_persona := vcodpersona;
                exit;
            exception
                when no_data_found then
                    null;
            end;
        end loop;

        vexiste := vcliente.persona.existe();

        -- Si No Existe la Persona entonces Crea
        if vexiste = false then
            begin
                vcliente.crear();
                presultado.codigo := null;
                presultado.descripcion := 'Cliente ' || vcliente.personafisica.cod_per_fisica || ' creado satisfactoriamente.';
                commit;
            exception
                when others then
                    dbms_output.put_line('Error en Crear Cliente ' || substr(sqlerrm || ' ' || dbms_utility.format_error_backtrace, 1, 4000));
                    vcliente.persona.cod_persona := null;
                    presultado.codigo := sqlcode;
                    presultado.descripcion := 'Error en Crear Cliente ' || substr(sqlerrm, 1, 4000);
                    rollback;
            end;
        else
            begin
                vcliente.actualizar();
                presultado.codigo := null;
                presultado.descripcion := 'Cliente ' || vcliente.personafisica.cod_per_fisica || ' actualizado satisfactoriamente.';
                commit;
            exception
                when others then
                    dbms_output.put_line('Error en Actualizar Cliente ' || substr(sqlerrm || ' ' || dbms_utility.format_error_backtrace, 1, 4000));
                    vcliente.persona.cod_persona := null;
                    presultado.codigo := sqlcode;
                    presultado.descripcion := substr(sqlerrm, 1, 4000);
                    rollback;
            end;
        end if;
    end;

    function consultar_persona_fisica(pcodpersona in varchar2, ptipoid in number, pnumid in varchar2)
        return pa.clientes_obj is
        vpersona pa.personas_obj;
        vpersonafisica pa.personas_fisicas_obj;
        vidpersonas pa.id_personas_list;
        vdirpersonas pa.dir_personas_list;
        vtelpersonas pa.tel_personas_list;
        vdirenvioxpers pa.dir_envio_x_pers_obj;
        vinfolaboral pa.info_laboral_obj;
        vctacliotrbancos pa.ctas_clientes_otr_bancos_list;
        vrefpersonales pa.ref_personales_list;
        vrefcomerciales pa.ref_comerciales_list;
        vinfoprodsol pa.info_prod_sol_obj;
        vinfoburo pa.info_buro_obj;
        vinfodocfisnac pa.info_doc_fisica_nacional_obj;
        vinfodocfisextranj pa.info_doc_fisica_extranj_obj;
        vinfoverifdocfisnac pa.info_verif_doc_fis_nac_obj;
        vinfoverifdocfisext pa.info_verif_doc_fis_extran_obj;
        vinfoworldcheck pa.info_world_check_obj;
        vlistapep pa.lista_pep_list;

        vcliente pa.clientes_obj;
    begin
        vcliente := pa.clientes_obj();
        vpersona := pa.personas_obj();
        vpersonafisica := pa.personas_fisicas_obj();
        vidpersonas := pa.id_personas_list();
        vdirpersonas := pa.dir_personas_list();
        vtelpersonas := pa.tel_personas_list();
        vdirenvioxpers := pa.dir_envio_x_pers_obj();
        vinfolaboral := pa.info_laboral_obj();
        vctacliotrbancos := pa.ctas_clientes_otr_bancos_list();
        vrefpersonales := pa.ref_personales_list();
        vrefcomerciales := pa.ref_comerciales_list();
        vinfoprodsol := pa.info_prod_sol_obj();
        vinfoburo := pa.info_buro_obj();
        vinfodocfisnac := pa.info_doc_fisica_nacional_obj();
        vinfodocfisextranj := pa.info_doc_fisica_extranj_obj();
        vinfoverifdocfisnac := pa.info_verif_doc_fis_nac_obj();
        vinfoverifdocfisext := pa.info_verif_doc_fis_extran_obj();
        vinfoworldcheck := pa.info_world_check_obj();
        vlistapep := pa.lista_pep_list();

        -- Datos de Persona
        if pcodpersona is not null
           or(ptipoid is not null
              and pnumid is not null) then
            -- Datos Personas Fisicas
            declare
                vpersonasfisicas pa.personas_fisicas_list := pa.personas_fisicas_list();
            begin
                vpersonasfisicas.delete;
                vpersonasfisicas := pa.pkg_personas_fisicas.consultar(pcod_per_fisica => pcodpersona,
                                                                      pest_civil => null,
                                                                      psexo => null,
                                                                      pfec_nacimiento => null,
                                                                      pprimer_apellido => null,
                                                                      psegundo_apellido => null,
                                                                      pprimer_nombre => null,
                                                                      psegundo_nombre => null,
                                                                      pprofesion => null,
                                                                      pidioma_correo => null,
                                                                      pes_mal_deudor => null,
                                                                      pconyugue => null,
                                                                      pnacionalidad => null,
                                                                      pcod_sector => null,
                                                                      pestatal => null,
                                                                      pemail_usuario => null,
                                                                      pemail_servidor => null,
                                                                      pnivel_estudios => null,
                                                                      ptipo_vivienda => null,
                                                                      pnum_hijos => null,
                                                                      pnum_dependientes => null,
                                                                      pes_residente => null,
                                                                      ptiempo_vivien_act => null,
                                                                      peval_ref_bancaria => null,
                                                                      peval_ref_tarjetas => null,
                                                                      peval_ref_laboral => null,
                                                                      ptotal_ingresos => null,
                                                                      pcod_pais => null,
                                                                      pincluido_por => null,
                                                                      pfec_inclusion => null,
                                                                      pmodificado_por => null,
                                                                      pfec_modificacion => null,
                                                                      pscoring => null,
                                                                      pactividad => null,
                                                                      prango_ingresos => null,
                                                                      pcasada_apellido => null,
                                                                      pes_funcionario => null,
                                                                      pes_peps => null,
                                                                      pcod_actividad => null,
                                                                      pcod_subactividad => null,
                                                                      ptipo_persona => null,
                                                                      ptipo_cliente => null,
                                                                      pcod_pais_padre => null,
                                                                      pcod_pais_madre => null,
                                                                      pcod_pais_conyugue => null,
                                                                      pmas_180_dias_eeuu => null,
                                                                      pcod_finalidad => null,
                                                                      ppeso => null,
                                                                      pestatura => null,
                                                                      pactividad_polizah => null,
                                                                      pdeporte_polizah => null,
                                                                      ppeso_polizah => null,
                                                                      pestatura_polizah => null,
                                                                      papellido_casada => null,
                                                                      ptercer_nombre => null,
                                                                      ptipo_soc_conyugal => null,
                                                                      pind_fallecimiento => null,
                                                                      pfec_fallecimiento => null,
                                                                      pgpo_riesgo => null,
                                                                      pnum_empleados => null,
                                                                      pventas_ingresos => null,
                                                                      pcp_total_activo => null,
                                                                      pind_clte_vip => null,
                                                                      ptipo_gen_divisas => null,
                                                                      pocupacion_clasif_nac => null);

                if vpersonasfisicas.count >= 1 then
                    vpersonafisica := vpersonasfisicas(1);
                end if;
            exception
                when no_data_found then
                    raise_application_error(-20404, 'Datos de Persona F¿sica no encontrados');
            end;

            if vpersonafisica.cod_per_fisica is not null then
                declare
                    vpersonaslist pa.personas_list := pa.personas_list();
                begin
                    vpersonaslist.delete;
                    vpersonaslist := pa.pkg_personas.consultar(pcod_persona => vpersonafisica.cod_per_fisica,
                                                               pcod_per_fisica => vpersonafisica.cod_per_fisica,
                                                               pcod_per_juridica => null,
                                                               pes_fisica => null,
                                                               pnombre => null,
                                                               pind_clte_i2000 => null,
                                                               ppaga_imp_ley288 => null,
                                                               pbenef_pag_ley288 => null,
                                                               pcod_vinculacion => null,
                                                               pcod_sec_contable => null,
                                                               padicionado_por => null,
                                                               pfecha_adicion => null,
                                                               pmodificado_por => null,
                                                               pfecha_modificacion => null,
                                                               pcodigo_sustituto => null,
                                                               pestado_persona => null,
                                                               pcobr_nodgii_132011 => null,
                                                               plleno_fatca => null,
                                                               pimprimio_fatca => null,
                                                               pes_fatca => null,
                                                               pfec_actualizacion => null,
                                                               ptel_verificado => null);

                    if vpersonaslist.count >= 1 then
                        vpersona := vpersonaslist(1);
                    end if;
                exception
                    when no_data_found then
                        raise_application_error(-20404, 'Datos de Persona no encontrados');
                end;

                if vpersona.cod_persona is not null then
                    -- Id Personas
                    begin
                        vidpersonas.delete;
                        vidpersonas := pa.pkg_id_personas.consultar(pcod_persona => vpersona.cod_persona,
                                                                    pcod_tipo_id => null,
                                                                    pnum_id => null,
                                                                    pfec_vencimiento => null,
                                                                    pcod_pais => null,
                                                                    pnacionalidad => null);
                    exception
                        when no_data_found then
                            raise_application_error(-20404, 'Datos de Id Personas no encontrados');
                    end;

                    -- Dir Personas
                    begin
                        vdirpersonas.delete;
                        vdirpersonas := pa.pkg_dir_personas.consultar(pcod_persona => vpersona.cod_persona,
                                                                      pcod_direccion => null,
                                                                      ptip_direccion => null,
                                                                      papartado_postal => null,
                                                                      pcod_postal => null,
                                                                      pdetalle => null,
                                                                      pcod_pais => null,
                                                                      pcod_provincia => null,
                                                                      pcod_canton => null,
                                                                      pcod_distrito => null,
                                                                      pcod_pueblo => null,
                                                                      pes_default => null,
                                                                      pcolonia => null,
                                                                      pzona => null,
                                                                      pind_estado => null,
                                                                      pincluido_por => null,
                                                                      pfec_inclusion => null,
                                                                      pmodificado_por => null,
                                                                      pfecha_modificacion => null);
                    exception
                        when no_data_found then
                            raise_application_error(-20404, 'Datos de Direcciones de Personas no encontrados');
                    end;

                    -- Tel Personas
                    begin
                        vtelpersonas.delete;
                        vtelpersonas := pa.pkg_tel_personas.consultar(pcod_persona => vpersona.cod_persona,
                                                                      pcod_area => null,
                                                                      pnum_telefono => null,
                                                                      ptip_telefono => null,
                                                                      ptel_ubicacion => null,
                                                                      pextension => null,
                                                                      pnota => null,
                                                                      pes_default => null,
                                                                      pposicion => null,
                                                                      pcod_direccion => null,
                                                                      pcod_pais => null,
                                                                      pmodificado_por => null,
                                                                      pfecha_modificacion => null,
                                                                      pincluido_por => null,
                                                                      pfec_inclusion => null,
                                                                      pnotif_digital => null,
                                                                      pfecha_notif_digital => null,
                                                                      pusuaario_notif_digital => null);
                    exception
                        when no_data_found then
                            raise_application_error(-20404, 'Datos de Telefonos de Personas no encontrados');
                    end;

                    -- Dir Envio x Personas
                    declare
                        vdirenvioxperslist pa.dir_envio_x_pers_list := pa.dir_envio_x_pers_list();
                    begin
                        vdirenvioxperslist := pa.pkg_dir_envio_x_pers.consultar(pcod_persona => vpersona.cod_persona,
                                                                                ptipo_envio => null,
                                                                                papdo_postal => null,
                                                                                pcodigo_postal => null,
                                                                                pcod_direccion => null,
                                                                                pcod_area => null,
                                                                                pnum_telefono => null,
                                                                                pnum_casilla => null,
                                                                                pcod_empresa => null,
                                                                                pcod_agencia => null,
                                                                                pemail_usuario => null,
                                                                                pemail_servidor => null);

                        if vdirenvioxperslist.count >= 1 then
                            vdirenvioxpers := vdirenvioxperslist(1);
                        end if;
                    exception
                        when no_data_found then
                            raise_application_error(-20404, 'Datos de Direccion de Envio por Personas no encontrados');
                    end;

                    -- Info Laboral
                    declare
                        vinfolaborallist pa.info_laboral_list := pa.info_laboral_list();
                    begin
                        vinfolaborallist := pa.pkg_info_laboral.consultar(pcod_per_fisica => vpersona.cod_persona,
                                                                          pcod_laboral => null,
                                                                          pfec_ingreso => null,
                                                                          pfec_salida => null,
                                                                          plugar_trabajo => null,
                                                                          pmonto => null,
                                                                          pcod_cargo => null,
                                                                          ppuesto => null,
                                                                          pobservaciones => null,
                                                                          ptipo_ingreso => null,
                                                                          pempleo_actual => null,
                                                                          pcod_moneda => null,
                                                                          pmonto_origen => null,
                                                                          pdireccion => null,
                                                                          pcod_area => null,
                                                                          pnum_telefono => null,
                                                                          pextension_tel => null,
                                                                          pind_verificado => null,
                                                                          pantiguedad => null);

                        if vinfolaborallist.count >= 1 then
                            vinfolaboral := vinfolaborallist(1);
                        end if;
                    exception
                        when no_data_found then
                            raise_application_error(-20404, 'Datos de la Informaci¿n Laboral no encontrados');
                    end;

                    -- Cuentas Clientes de Otros Bancos
                    begin
                        vctacliotrbancos.delete;
                        vctacliotrbancos := pa.pkg_ctas_clientes_otr_bancos.consultar(pcod_cliente => vpersona.cod_persona,
                                                                                      pcod_emisor => null,
                                                                                      pnum_cuenta => null,
                                                                                      pnom_cuenta => null,
                                                                                      ptipo_cuenta => null,
                                                                                      pcod_moneda => null,
                                                                                      padicionado_por => null,
                                                                                      pfecha_adicion => null,
                                                                                      pmodificado_por => null,
                                                                                      pfecha_modificacion => null,
                                                                                      pcod_pais => null,
                                                                                      poficial_responsable => null,
                                                                                      ptiempo_apertura => null);
                    exception
                        when no_data_found then
                            raise_application_error(-20404, 'Datos de las Cuentas de Cliente de Otros Bancos no encontrados');
                    end;

                    -- Referencias Personales
                    declare
                    begin
                        vrefpersonales.delete;
                        vrefpersonales := pa.pkg_ref_personales.consultar(pcod_ref_per => null,
                                                                          pcod_persona => vpersona.cod_persona,
                                                                          pcod_empresa => null,
                                                                          pcod_tipo_id => null,
                                                                          pnombre_ref => null,
                                                                          pnum_id => null,
                                                                          pcod_area => null,
                                                                          pnum_telefono => null,
                                                                          ppuesto => null,
                                                                          plugar_trabajo => null,
                                                                          prelacion_persona => null,
                                                                          pobservaciones => null,
                                                                          pextension_tel => null);
                    exception
                        when no_data_found then
                            raise_application_error(-20404, 'Datos de las Referencias Personales no encontrados');
                    end;

                    -- Referencias Comerciales
                    begin
                        vrefcomerciales.delete;
                        vrefcomerciales := pa.pkg_ref_comerciales.consultar(pcod_ref_com => null,
                                                                            pcod_tip_ref => null,
                                                                            pcod_persona => vpersona.cod_persona,
                                                                            pcod_ente => null,
                                                                            pnum_cuenta => null,
                                                                            pcredito_otorgado => null,
                                                                            psaldo_credito => null,
                                                                            pcuota_mensual => null,
                                                                            pcod_moneda => null,
                                                                            pfec_apertura => null,
                                                                            pfec_vencimiento => null,
                                                                            pdesc_garantia => null,
                                                                            pobservaciones => null,
                                                                            poficial => null,
                                                                            pnombre_ente => null);
                    exception
                        when no_data_found then
                            raise_application_error(-20404, 'Datos de las Referencias Comerciales no encontrados');
                    end;

                    -- Info Prod Sol
                    declare
                        vinfoprodsollist pa.info_prod_sol_list := pa.info_prod_sol_list();
                    begin
                        vinfoprodsollist.delete;
                        vinfoprodsollist := pa.pkg_info_prod_sol.consultar(pcod_persona => vpersona.cod_persona,
                                                                           ptipo_producto => null,
                                                                           pcod_moneda => null,
                                                                           pproposito => null,
                                                                           pmonto_inicial => null,
                                                                           pinstrumento_bancario => null,
                                                                           prango_monetario_ini => null,
                                                                           prango_monetario_fin => null,
                                                                           pprom_mes_depo_efectivo => null,
                                                                           pprom_mes_depo_cheques => null,
                                                                           pprom_mes_reti_efectivo => null,
                                                                           pprom_mes_trans_enviada => null,
                                                                           pcod_pais_destino => null,
                                                                           pprom_mes_trans_recibida => null,
                                                                           pcod_pais_origen => null,
                                                                           pcompras_giros_cheques_ger => null,
                                                                           porigen_fondos => null);

                        if vinfoprodsollist.count >= 1 then
                            vinfoprodsol := vinfoprodsollist(1);
                        end if;
                    exception
                        when no_data_found then
                            --RAISE_APPLICATION_ERROR(-20404, 'Datos de la Informaci¿n del Producto Solicitado no encontrados');
                            vinfoprodsol := pa.info_prod_sol_obj();
                    end;

                    -- Info Buro
                    declare
                        vinfoburolist pa.info_buro_list := pa.info_buro_list();
                    begin
                        vinfoburolist.delete;
                        vinfoburolist := pa.pkg_info_buro.consultar(pcod_persona => vpersona.cod_persona, preporte => null, pfecha => null, pcomentarios => null, parchivo => null);

                        if vinfoburolist.count >= 1 then
                            vinfoburo := vinfoburolist(1);
                        end if;
                    exception
                        when no_data_found then
                            vinfoburo := pa.info_buro_obj();
                    end;

                    -- Info Doc Fisica Nacional
                    declare
                        vinfodocfisnaclist pa.info_doc_fisica_nacional_list := pa.info_doc_fisica_nacional_list();
                    begin
                        vinfodocfisnaclist.delete;
                        vinfodocfisnaclist := pa.pkg_info_doc_fisica_nacional.consultar(pcod_persona => vpersona.cod_persona,
                                                                                        ppind_cedula => null,
                                                                                        ppind_licencia_conducir => null,
                                                                                        ppind_residencia => null,
                                                                                        ppind_id_otro => null,
                                                                                        pid_otro_desc => null,
                                                                                        ppind_certificado_nacimiento => null,
                                                                                        ppind_pensionado_jubilado => null,
                                                                                        ppind_lab_tiempo => null,
                                                                                        ppind_lab_ingreso_anual => null,
                                                                                        ppind_lab_puesto_desempena => null,
                                                                                        ppind_trabaja_independiente => null,
                                                                                        ppind_independiente_actividad => null,
                                                                                        ppindindependientejustificaa => null,
                                                                                        pcomentarios_adicionales => null);

                        if vinfodocfisnaclist.count >= 1 then
                            vinfodocfisnac := vinfodocfisnaclist(1);
                        end if;
                    exception
                        when no_data_found then
                            vinfodocfisnac := pa.info_doc_fisica_nacional_obj();
                    end;

                    -- Info Doc Fisica Extranjero
                    declare
                        vinfodocfisextralist pa.info_doc_fisica_extranj_list := pa.info_doc_fisica_extranj_list();
                    begin
                        vinfodocfisextralist.delete;
                        vinfodocfisextralist := pa.pkg_info_doc_fisica_extranjero.consultar(pcod_persona => vpersona.cod_persona,
                                                                                            ppind_pasaporte => null,
                                                                                            ppind_permiso => null,
                                                                                            ppind_carta_trabajo => null,
                                                                                            ppind_decla_renta => null,
                                                                                            ppind_naturaleza_actividad => null,
                                                                                            ppind_licencia_actividad => null);

                        if vinfodocfisextralist.count >= 1 then
                            vinfodocfisextranj := vinfodocfisextralist(1);
                        end if;
                    exception
                        when no_data_found then
                            vinfodocfisextranj := pa.info_doc_fisica_extranj_obj();
                    end;

                    -- Info Verifica Doc Fisica Nacional
                    declare
                        vdata pa.info_verif_doc_fis_nac_list := pa.info_verif_doc_fis_nac_list();
                    begin
                        vdata.delete;
                        vdata := pa.pkg_info_verif_doc_fis_nac.consultar(pcod_persona => vpersona.cod_persona,
                                                                         ppind_telefono => null,
                                                                         ptelefono_fecha => null,
                                                                         ptelefono_icp => null,
                                                                         ppind_domicilio => null,
                                                                         pdomicilio_fecha => null,
                                                                         pdomicilio_icp => null,
                                                                         ppind_trabajo => null,
                                                                         ptrabajo_fecha => null,
                                                                         ptrabajo_icp => null,
                                                                         ppind_ref_personal => null,
                                                                         pref_personal_fecha => null,
                                                                         pref_personal_icp => null,
                                                                         ppind_ref_crediticias => null,
                                                                         pref_crediticias_fecha => null,
                                                                         pref_crediticias_icp => null,
                                                                         pcomentarios_adicionales => null,
                                                                         popinion_oficial => null,
                                                                         ppind_email => null,
                                                                         pemail_fecha => null,
                                                                         pemail_icp => null,
                                                                         ppind_direnvio => null,
                                                                         pdirenvio_fecha => null,
                                                                         pdirenvio_icp => null);

                        if vdata.count >= 1 then
                            vinfoverifdocfisnac := vdata(1);
                        end if;
                    exception
                        when no_data_found then
                            vinfoverifdocfisnac := pa.info_verif_doc_fis_nac_obj();
                    end;

                    -- Info Verifica Doc Fisica Extranjero
                    declare
                        vdata pa.info_verif_doc_fis_extran_list := pa.info_verif_doc_fis_extran_list();
                    begin
                        vdata.delete;
                        vdata := pa.pkg_info_verif_doc_fis_extran.consultar(pcod_persona => vpersona.cod_persona,
                                                                            ppind_telefono => null,
                                                                            ptelefono_fecha => null,
                                                                            ptelefono_icp => null,
                                                                            ppind_domicilio => null,
                                                                            pdomicilio_fecha => null,
                                                                            pdomicilio_icp => null,
                                                                            ppind_trabajo => null,
                                                                            ptrabajo_fecha => null,
                                                                            ptrabajo_icp => null,
                                                                            ppind_ref_personal => null,
                                                                            pref_personal_fecha => null,
                                                                            pref_personal_icp => null,
                                                                            ppind_ref_crediticias => null,
                                                                            pref_crediticias_fecha => null,
                                                                            pref_crediticias_icp => null,
                                                                            ppind_datos_personales => null,
                                                                            ppind_domicilio_local => null,
                                                                            ppind_domicilio_facturas => null,
                                                                            ppind_domicilio_llamando => null,
                                                                            ppind_condicion_migratoria => null,
                                                                            ppind_licencia_com_industrial => null,
                                                                            pcomentarios_adicionales => null,
                                                                            ppind_ref_personales => null,
                                                                            pref_personales_icp => null,
                                                                            ppind_ref_banacarias_local => null,
                                                                            pref_banacarias_local_icp => null,
                                                                            ppind_ref_bancarias_ext => null,
                                                                            pref_bancarias_ext_icp => null,
                                                                            ppind_ref_credito => null,
                                                                            pref_credito_icp => null,
                                                                            ppind_ref_cond_legal => null,
                                                                            pref_cond_legal_icp => null,
                                                                            popinion_oficial => null,
                                                                            ppind_email => null,
                                                                            pemail_fecha => null,
                                                                            pemail_icp => null,
                                                                            ppind_direnvio => null,
                                                                            pdirenvio_fecha => null,
                                                                            pdirenvio_icp => null);

                        if vdata.count >= 1 then
                            vinfoverifdocfisext := vdata(1);
                        end if;
                    exception
                        when no_data_found then
                            vinfoverifdocfisext := pa.info_verif_doc_fis_extran_obj();
                    end;

                    -- Info World Check
                    declare
                        vdata pa.info_world_check_list := pa.info_world_check_list();
                    begin
                        vdata.delete;
                        vdata := pa.pkg_info_world_check.consultar(pcod_persona => vpersona.cod_persona, preporte => null, pfecha => null, pcomentarios => null);

                        if vdata.count >= 1 then
                            vinfoworldcheck := vdata(1);
                        end if;
                    exception
                        when no_data_found then
                            vinfoworldcheck := pa.info_world_check_obj();
                    end;

                    -- Lista PEP
                    begin
                        vlistapep.delete;
                        vlistapep := pa.pkg_lista_pep.consultar(pcod_persona => vpersona.cod_persona,
                                                                pconsecutivo => null,
                                                                pcargo => null,
                                                                pfec_ingreso => null,
                                                                pfec_vencimiento => null,
                                                                papodo => null,
                                                                padicionado_por => null,
                                                                pfecha_adicion => null,
                                                                pmodificado_por => null,
                                                                pfecha_modificacion => null,
                                                                pcodigo_parentesco => null,
                                                                pinstitucion_politica => null,
                                                                pcodigo_operacion => null,
                                                                pcod_moneda => null,
                                                                pcod_pais => null,
                                                                pnombre_rel_pep => null);
                    exception
                        when no_data_found then
                            vlistapep := pa.lista_pep_list();
                    end;
                end if;
            end if;
        --IA.LOGGER.OUTPUTOFF;
        end if;

        vcliente.persona := vpersona;
        vcliente.personafisica := vpersonafisica;
        vcliente.idpersonas := vidpersonas;
        vcliente.dirpersonas := vdirpersonas;
        vcliente.telpersonas := vtelpersonas;
        vcliente.direnvioxpers := vdirenvioxpers;
        vcliente.infolaboral := vinfolaboral;
        vcliente.ctacliotrbancos := vctacliotrbancos;
        vcliente.refpersonales := vrefpersonales;
        vcliente.refcomerciales := vrefcomerciales;
        vcliente.infoprodsol := vinfoprodsol;
        vcliente.infoburo := vinfoburo;
        vcliente.infodocfisnac := vinfodocfisnac;
        vcliente.infodocfisextranj := vinfodocfisextranj;
        vcliente.infoverifdocfisnac := vinfoverifdocfisnac;
        vcliente.infoverifdocfisext := vinfoverifdocfisext;
        vcliente.infoworldcheck := vinfoworldcheck;
        vcliente.listapep := vlistapep;

        return vcliente;
    exception
        when others then
            raise_application_error(-20104, 'Error - ' || sqlerrm || '-' || dbms_utility.format_error_backtrace || '-' || dbms_utility.format_error_stack);
    end;

    function compararclientes(pcliente1 in pa.clientes_obj, pcliente2 in pa.clientes_obj)
        return boolean is
        -- Cliente 1
        vpersona1 pa.personas_obj;
        vpersonafisica1 pa.personas_fisicas_obj;
        vidpersonas1 pa.id_personas_list;
        vdirpersonas1 pa.dir_personas_list;
        vtelpersonas1 pa.tel_personas_list;
        vdirenvioxpers1 pa.dir_envio_x_pers_obj;
        vinfolaboral1 pa.info_laboral_obj;
        vctacliotrbancos1 pa.ctas_clientes_otr_bancos_list;
        vrefpersonales1 pa.ref_personales_list;
        vrefcomerciales1 pa.ref_comerciales_list;
        vinfoprodsol1 pa.info_prod_sol_obj;

        -- Cliente 2
        vpersona2 pa.personas_obj;
        vpersonafisica2 pa.personas_fisicas_obj;
        vidpersonas2 pa.id_personas_list;
        vdirpersonas2 pa.dir_personas_list;
        vtelpersonas2 pa.tel_personas_list;
        vdirenvioxpers2 pa.dir_envio_x_pers_obj;
        vinfolaboral2 pa.info_laboral_obj;
        vctacliotrbancos2 pa.ctas_clientes_otr_bancos_list;
        vrefpersonales2 pa.ref_personales_list;
        vrefcomerciales2 pa.ref_comerciales_list;
        vinfoprodsol2 pa.info_prod_sol_obj;


        vretorno boolean := false;
    begin
        vpersona1 := pcliente1.persona;
        vpersonafisica1 := pcliente1.personafisica;
        vidpersonas1 := pcliente1.idpersonas;
        vdirpersonas1 := pcliente1.dirpersonas;
        vtelpersonas1 := pcliente1.telpersonas;
        vdirenvioxpers1 := pcliente1.direnvioxpers;
        vinfolaboral1 := pcliente1.infolaboral;
        vctacliotrbancos1 := pcliente1.ctacliotrbancos;
        vrefpersonales1 := pcliente1.refpersonales;
        vrefcomerciales1 := pcliente1.refcomerciales;
        vinfoprodsol1 := pcliente1.infoprodsol;

        vpersona2 := pcliente2.persona;
        vpersonafisica2 := pcliente2.personafisica;
        vidpersonas2 := pcliente2.idpersonas;
        vdirpersonas2 := pcliente2.dirpersonas;
        vtelpersonas2 := pcliente2.telpersonas;
        vdirenvioxpers2 := pcliente2.direnvioxpers;
        vinfolaboral2 := pcliente2.infolaboral;
        vctacliotrbancos2 := pcliente2.ctacliotrbancos;
        vrefpersonales2 := pcliente2.refpersonales;
        vrefcomerciales2 := pcliente2.refcomerciales;
        vinfoprodsol2 := pcliente2.infoprodsol;

        -- Comparar
        vretorno := vpersona1.comparar(vpersona2);

        if vretorno = false then
            return vretorno;
        end if;

        vretorno := vpersonafisica1.comparar(vpersonafisica2);

        if vretorno = false then
            return vretorno;
        end if;

        /*
        FOR i IN 1 .. vIdPersonas1.COUNT LOOP
            vRetorno := vIdPersonas1(i).Comparar(vIdPersonas2(i));
            IF vRetorno = FALSE THEN
              RETURN vRetorno;
            END IF;
        END LOOP;

        FOR i IN 1 .. vDirPersonas1.COUNT LOOP
            vRetorno := vDirPersonas1(i).Comparar(vDirPersonas2(i));
            IF vRetorno = FALSE THEN
              RETURN vRetorno;
            END IF;
        END LOOP;

        FOR i IN 1 .. vTelPersonas1.COUNT LOOP
            vRetorno := vTelPersonas1(i).Comparar(vTelPersonas2(i));
            IF vRetorno = FALSE THEN
              RETURN vRetorno;
            END IF;
        END LOOP;


        vRetorno := vPersona1.Comparar(vPersona2);
        IF vRetorno = FALSE THEN
          RETURN vRetorno;
        END IF;
        vRetorno := vPersona1.Comparar(vPersona2);
        IF vRetorno = FALSE THEN
          RETURN vRetorno;
        END IF;
        vRetorno := vPersona1.Comparar(vPersona2);
        IF vRetorno = FALSE THEN
          RETURN vRetorno;
        END IF;
        vRetorno := vPersona1.Comparar(vPersona2);
        IF vRetorno = FALSE THEN
          RETURN vRetorno;
        END IF;
        vRetorno := vPersona1.Comparar(vPersona2);
        IF vRetorno = FALSE THEN
          RETURN vRetorno;
        END IF;
        vRetorno := vPersona1.Comparar(vPersona2);
        IF vRetorno = FALSE THEN
          RETURN vRetorno;
        END IF;
        */
        return vretorno;
    end;


    procedure doc_fisica_nacional(pcod_persona   in     varchar2,
                                  ppind_cedula   in     varchar2,
                                  ppind_licencia_conducir in varchar2,
                                  ppind_residencia in   varchar2,
                                  ppind_id_otro  in     varchar2,
                                  pid_otro_desc  in     varchar2,
                                  ppind_certificado_nacimiento in varchar2,
                                  ppind_pensionado_jubilado in varchar2,
                                  ppind_lab_tiempo in   varchar2,
                                  ppind_lab_ingreso_anual in varchar2,
                                  ppind_lab_puesto_desempena in varchar2,
                                  ppind_trabaja_independiente in varchar2,
                                  ppind_independiente_actividad in varchar2,
                                  ppindindependientejustificaa in varchar2,
                                  pcomentarios_adicionales in varchar2,
                                  perror         in out varchar) is
        verror pa.pkg_info_doc_fisica_nacional.resultado;
    begin
        pa.pkg_info_doc_fisica_nacional.generar(pcod_persona,
                                                ppind_cedula,
                                                ppind_licencia_conducir,
                                                ppind_residencia,
                                                ppind_id_otro,
                                                pid_otro_desc,
                                                ppind_certificado_nacimiento,
                                                ppind_pensionado_jubilado,
                                                ppind_lab_tiempo,
                                                ppind_lab_ingreso_anual,
                                                ppind_lab_puesto_desempena,
                                                ppind_trabaja_independiente,
                                                ppind_independiente_actividad,
                                                ppindindependientejustificaa,
                                                pcomentarios_adicionales,
                                                verror);

        perror := verror.descripcion;
    end;

    function remover_caracteres_especiales(pdata in varchar2)
        return varchar2 is
        vresult varchar2(4000);
        vexclusion varchar2(1000)
            := chr(2) || chr(3) || chr(4) || chr(5) || chr(7) || chr(8) || chr(14) || chr(15) || chr(16) || chr(17) || chr(18) || chr(19) || chr(20) || chr(21) || chr(22) || chr(23) || chr(24) ||
               chr                                                                                                                                                                                  (25
               ) || chr(26) || chr(27) || chr(33) || chr(36) || chr(37) || chr(42) || chr(43) || chr(60) || chr(61) || chr(62) || chr(63) || chr(94) || chr(95) || chr(123) || chr(124) || chr(125) ||
               chr
               (126) || chr(127) || chr(63) || chr(161) || chr(162) || chr(163) || chr(164) || chr(165) || chr(166) || chr(167) || chr(168) || chr(169) || chr(170) || chr(171) || chr(172) || chr(174)
               || chr(175) || chr(176) || chr(177) || chr(178) || chr(179) || chr(180) || chr(181) || chr(182) || chr(183) || chr(184) || chr(185) || chr(186) || chr(187) || chr(188) || chr(189) ||
               chr
               (191) || chr(192) || chr(194) || chr(195) || chr(197) || chr(198) || chr(199) || chr(200) || chr(202) || chr(204) || chr(206) || chr(208) || chr(210) || chr(212) || chr(213) || chr(215
               ) || chr(216) || chr(217) || chr(219) || chr(222) || chr(223) || chr(224) || chr(226) || chr(227) || chr(229) || chr(230) || chr(231) || chr(232) || chr(234) || chr(236) || chr(238) ||
               chr
               (240) || chr(242) || chr(244) || chr(245) || chr(247) || chr(248) || chr(249) || chr(251) || chr(253) || chr(254);
        --'!$%*+<=>?^_{|}~?¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿';
        vchar varchar2(1);
        nlength number := 0;
    begin
        select length(pdata) into nlength from dual;

        vresult := pdata;

        if pdata is not null then
            for i in 1 .. nlength
            loop
                vchar := substr(pdata, i, 1);

                begin
                    select replace(vresult, vchar, '')
                    into vresult
                    from dual
                    where vexclusion like '%' || vchar || '%';
                exception
                    when no_data_found then
                        null;
                end;
            end loop;
        end if;

        return rtrim(ltrim(vresult));
    end;

    procedure mapear_direccion(inidpais       in     varchar2,
                               inidcanton     in     varchar2,
                               outcod_provincia in out varchar2,
                               outcod_canton  in out varchar2,
                               outcod_distrito in out varchar2,
                               outerror       in out varchar2) is
        vidpais varchar2(10);
    begin
        outerror := null;

        if inidpais = 'DO' then
            vidpais := 1;
        else
            vidpais := remover_caracteres_especiales(inidpais);
        end if;

        begin
            select cod_provincia, cod_canton, cod_distrito
            into outcod_provincia, outcod_canton, outcod_distrito
            from pa.distritos
            where cod_pais = vidpais
            and   cod_canton = to_number(substr(remover_caracteres_especiales(inidcanton), 1, 2))
            and   cod_distrito = to_number(substr(remover_caracteres_especiales(inidcanton), 3, 2));
        exception
            when no_data_found then
                outcod_provincia := null;
                outcod_canton := null;
                outcod_distrito := null;
                outerror := 'Error Mapeando los c¿digos de la direcci¿n (' || inidcanton || ').';
                raise_application_error(-20100, outerror);
        end;
    end;
end pkg_cliente;
/