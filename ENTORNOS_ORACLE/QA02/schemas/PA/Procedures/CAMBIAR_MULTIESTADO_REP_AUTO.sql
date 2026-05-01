-- =============================================================================
-- Entorno: QA02
-- Schema: PA
-- Objeto: PA.CAMBIAR_MULTIESTADO_REP_AUTO (PROCEDURE)
-- Fecha incorporacion: 2026-04-30
-- Origen: Toad / ALL_SOURCE en QADEMI02_19C
-- Motivo: Investigacion registros faltantes en Reportes Onboarding
-- Observacion: Objeto incorporado como referencia, sin alterar logica.
-- =============================================================================

CREATE OR REPLACE procedure PA.cambiar_multiestado_rep_auto(pestado_update in varchar2,
                                                            pestado_query  in varchar2,
                                                            pmensaje       in varchar2,
                                                            pidproceso     in varchar2,
                                                            prownum        in number,
                                                            plistatipodoc  in varchar2,
                                                            porigenpkm     in varchar2) is
    cursor cpendientes(p_estado in varchar2, p_origen in varchar2, p_rownum in number) is
        select *
        from v_reportes_automatico_robot r
        where r.estado_reporte = p_estado
        and   r.f_document_type in ((select regexp_substr(trim(plistatipodoc), '[^,]+', 1, level) dato
                                     from dual
                                     connect by regexp_substr(trim(plistatipodoc), '[^,]+', 1, level) is not null))
        and   r.f_origen = p_origen
        and   rownum <= p_rownum
        -- OMARIOT 01/04/2024 Para evitar cambiar registros que ya estaban en estado S
        and   not exists
                  (select 1
                   from pa.bitacora_rep_automaticos b
                   where b.codigo_reporte = r.codigo_reporte
                   and   b.estado_reporte = 'S');

    type tpendiente is table of cpendientes%rowtype;

    vpendiente tpendiente;

    cursor cpendienteenvio(p_estado in varchar2, p_origen in varchar2, p_rownum in number) is
        select *
        from v_reportes_autom_pkm r
        where r.estado_reporte = p_estado
        and   r.f_document_type in ((select regexp_substr(trim(plistatipodoc), '[^,]+', 1, level) dato
                                     from dual
                                     connect by regexp_substr(trim(plistatipodoc), '[^,]+', 1, level) is not null))
        and   r.f_origen = p_origen
        and   rownum <= p_rownum
        -- OMARIOT 01/04/2024 Para evitar cambiar registros que ya estaban en estado S
        and   not exists
                  (select 1
                   from pa.bitacora_rep_automaticos b
                   where b.codigo_reporte = r.codigo_reporte
                   and   b.estado_reporte = 'S');

    type tpendienteenvio is table of cpendienteenvio%rowtype;

    vpendienteenvio tpendienteenvio;

    pragma autonomous_transaction;
-- Se controla el error del trigger pa.TRG_CREDITO_Control_Helado para que cuando de el error -20002 controlado sea procesado en forma correcta
begin
    -- Para registros Pendientes
    if pestado_query in ('P', 'R') then
    
        --insert into pa_depurador(usuario, fec_insercion, orden, linea)
        --values (user, sysdate, s_depurador.nextval, 'Inicio PA.cambiar_multiestado_rep_auto:IF pestado_query in (''P'', ''R'') idproceso[' || pidproceso || '] rownum['||prownum||'] listdoc['||plistatipodoc||']'); 

        open cpendientes(pestado_query, porigenpkm, prownum);

        loop
            
            fetch cpendientes bulk   collect into vpendiente limit prownum;

            begin
                forall i in 1 .. vpendiente.count
                    update pa.pa_reportes_automaticos
                    set idproceso = pidproceso, estado_reporte = pestado_update, mensaje = pmensaje
                    where codigo_reporte = vpendiente(i).codigo_reporte;

                commit;
            exception
                when others then
                    if sqlcode = -20002 then
                        null;
                    end if;
            end;

            exit when cpendientes%notfound;
        end loop;

        close cpendientes;

        --insert into pa_depurador(usuario, fec_insercion, orden, linea)
        --values (user, sysdate, s_depurador.nextval, 'Fin    PA.cambiar_multiestado_rep_auto:IF pestado_query in (''P'', ''R'') idproceso[' || pidproceso || '] rownum['||prownum||'] listdoc['||plistatipodoc||']');

    elsif pestado_query = 'D' then

        --insert into pa_depurador(usuario, fec_insercion, orden, linea)
        --values (user, sysdate, s_depurador.nextval, 'Inicio PA.cambiar_multiestado_rep_auto:ELSE estado_query in (''P'', ''R'') idproceso[' || pidproceso || '] rownum['||prownum||'] listdoc['||plistatipodoc||']');
        
        open cpendienteenvio(pestado_query, porigenpkm, prownum);

        loop
            fetch cpendienteenvio bulk   collect into vpendienteenvio limit prownum;

            begin
                forall i in 1 .. vpendienteenvio.count
                    update pa.pa_reportes_automaticos
                    set idproceso = pidproceso, estado_reporte = pestado_update, mensaje = pmensaje
                    where codigo_reporte = vpendienteenvio(i).codigo_reporte;

                commit;
            exception
                when others then
                    if sqlcode = -20002 then
                        null;
                    end if;
            end;

            exit when cpendienteenvio%notfound;
        end loop;

        close cpendienteenvio;
        
        --insert into pa_depurador(usuario, fec_insercion, orden, linea)
        --values (user, sysdate, s_depurador.nextval, 'Fin    PA.cambiar_multiestado_rep_auto:ELSE estado_query in (''P'', ''R'') idproceso[' || pidproceso || '] rownum['||prownum||'] listdoc['||plistatipodoc||']');
    end if;


    commit;
    
exception
    when others then
        dbms_output.put_line('Error: ' || sqlerrm);
        rollback;
        raise_application_error(-20100, 'Error: ' || sqlerrm);
end cambiar_multiestado_rep_auto;
/

