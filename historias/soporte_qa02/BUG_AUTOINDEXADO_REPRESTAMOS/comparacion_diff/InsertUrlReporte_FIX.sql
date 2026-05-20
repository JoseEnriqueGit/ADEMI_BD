procedure inserturlreporte(pcodigoreferencia in  varchar2,
                             pfechareporte  in     date,
                             pid_aplicacion in     number,
                             pidtipodocumento in   varchar2,
                             porigenpkm     in     varchar2,
                             purlreporte    in     varchar2,
                             pformatodocumento in  varchar2,
                             pnombrearchivo in     varchar2,
                             pestado        in     varchar2 default 'P',
                             prespuesta     in out varchar2) IS
      vDirectorio   VARCHAR2(256) := NVL(PA.PARAM.PARAMETRO_X_EMPRESA('1', 'DIR_REPORTES', 'IA'), 'RPT_REGULATORIOS');
      vEnviarAPI    VARCHAR2(2);
      v_codigo_reporte  NUMBER;
      v_tipo_identificacion VARCHAR2(5);
      v_identificacion  VARCHAR2(30);
      v_num_prestamo  VARCHAR2(40);
      v_prest_anterior VARCHAR2(40);
      v_Id_tempfud    VARCHAR2(30);
      v_tipo_archivo VARCHAR2(40);
      v_nombre_archivo VARCHAR2(60);
      v_codigo_agencia	 VARCHAR2(60);
      v_nombre_agencia	 VARCHAR2(60);
      v_primer_nombre	     VARCHAR2(60);
      v_segundo_nombre	 VARCHAR2(60);
      v_primer_apellido	 VARCHAR2(60);
      v_segundo_apellido	 VARCHAR2(60);
      v_nacionalidad       VARCHAR2(60);
 BEGIN

      BEGIN
          SELECT T.ENVIAR_API
            INTO vEnviarAPI
            FROM PA.PA_TIPO_DOCUMENTO_PKM t
           WHERE T.ID_APLICACION = pId_Aplicacion
             AND T.ID_TIPO_DOCUMENTO = pIdTipoDocumento;
      EXCEPTION WHEN NO_DATA_FOUND THEN
          vEnviarAPI := 'S';
      END;

      BEGIN
          INSERT INTO PA.PA_REPORTES_AUTOMATICOS
          ( CODIGO_REFERENCIA, FECHA_REPORTE, ID_APLICACION, ID_TIPO_DOCUMENTO, ORIGEN_PKM, URL_REPORTE, FORMATO_DOCUMENTO, DIRECTORIO_DESTINO, NOMBRE_ARCHIVO, ENVIAR_API, ESTADO_REPORTE, FECHA_PROCESO )
          VALUES ( pCodigoReferencia, pFechaReporte, pId_Aplicacion, pIdTipoDocumento, pOrigenPkm, pUrlReporte, pFormatoDocumento, vDirectorio, pNombreArchivo, NVL(vEnviarAPI,'S'), NVL(pEstado,'P'), SYSDATE );
      EXCEPTION WHEN OTHERS THEN
          pRespuesta := 'Error: '||SQLERRM;
          RAISE_APPLICATION_ERROR(-20100, pRespuesta);
      END;

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
                                  ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':',
                                      case when ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 3) is not null then 3 else 1 end)
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
                                      and cr.no_credito = ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':',
                                          case when ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 3) is not null then 3 else 1 end)
                                  )
                              WHEN R.ORIGEN_PKM IN ('Onboarding', 'TarjetaPC', 'Tarjeta') THEN
                                  (SELECT to_number(st.oficina)
                                     FROM TC.TC_SOLICITUD_TARJETA st
                                    WHERE st.no_solicitud =  ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', CASE WHEN r.url_reporte is not null THEN 1 ELSE 3 END)
                                  )
                         END  as codigo_agencia
                       from PA.PA_REPORTES_AUTOMATICOS r
                      WHERE r.codigo_reporte = (select max(x.codigo_reporte)
                                                  from pa.pa_reportes_automaticos x where x.origen_pkm = r.origen_pkm)
                        and r.ORIGEN_PKM = porigenpkm) r;

      InsertAutoIndexado
      (
        v_codigo_reporte,
        pId_Aplicacion,
        pIdTipoDocumento,
        v_tipo_identificacion,
        v_identificacion	 ,
        v_num_prestamo       ,
        v_prest_anterior     ,
        v_tipo_archivo         ,
        v_Id_tempfud           ,
        pOrigenPkm             ,
        pUrlReporte          ,
        v_nombre_archivo       ,
        pCodigoReferencia    ,
        NVL(vEnviarAPI,'S')     ,
        v_codigo_agencia       ,
        v_nombre_agencia       ,
        NVL(pEstado,'P')       ,
        v_primer_nombre        ,
        v_segundo_nombre       ,
        v_primer_apellido      ,
        v_segundo_apellido     ,
        v_nacionalidad         ,
        NULL ,
        pRespuesta
      );

 END InsertUrlReporte;
