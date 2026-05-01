-- =============================================================================
-- Entorno: QA02
-- Schema: IA
-- Objeto: IA.CHECK_ESTADO_REPORTE (PROCEDURE)
-- Fecha incorporacion: 2026-04-30
-- Origen: Toad / ALL_SOURCE en QADEMI02_19C
-- Motivo: Investigacion registros faltantes en Reportes Onboarding
-- Observacion: Objeto incorporado como referencia, sin alterar logica.
-- =============================================================================

CREATE OR REPLACE procedure IA.check_estado_reporte(p_doc_type in varchar2) as
------------------------------------------------------------------------------------------
-- OBJECT:
--         Update pa_reportes_automaticos.
--         Set as Error (estado_reporte=E) documents no processed.
--         Modified more than xx minutes ago.
-- 
-- HISTORY CHANGES
-- WHEN         WHO          WHAT
-- 2024-Feb-16  JoseEsteban  Created 
-- 2024-Apr-23  JoseEsteban  CN20240423. Add functionality.
--                           1.- Update estado_reporte='S'  to records with estado_reporte='H' and exists same codigo_reporte with other estado_reporte=S' in bitacora table  
--                           2.- Update estado_reporte='SP' to records with estado_reporte='H' and exists same codigo_reporte with other estado_reporte='SP' in bitacora table  
------------------------------------------------------------------------------------------
  v_minutes_holded       varchar2(10)  := get_parameter('MINUTES_HOLDED_'||p_doc_type);
  v_doc_type             varchar2(10)  := get_parameter('DOC_TYPE_'||p_doc_type);
  v_upd_message          varchar2(200);
  l_body                 clob;
  l_num_row1             number := 0;
  l_num_row2             number := 0;
  l_num_row3             number := 0;
  --v_codigo_reporte       pa.pa_reportes_automaticos.codigo_reporte%type;
  --v_estado_reporte       pa.pa_reportes_automaticos.estado_reporte%type;
  --v_fecha_modificacion   pa.pa_reportes_automaticos.fecha_modificacion%type;
  --
  type codigo_reporte_ty     is table of pa.pa_reportes_automaticos.codigo_reporte%type;
  type estado_reporte_ty     is table of pa.pa_reportes_automaticos.estado_reporte%type;
  type fecha_modificacion_ty is table of pa.pa_reportes_automaticos.fecha_modificacion%type;
  --
  codigos               codigo_reporte_ty;
  estados               estado_reporte_ty;
  fechas_modificaciones fecha_modificacion_ty;
  --
  cursor c_states is
    select valor state
    from param_generales
    where abrev_parametro like 'ESTADO%_ERROR_'||p_doc_type; 
--
begin
  l_body:='<title>&_user@&_connect_identifier &_date</title> -
           <!-- Generated on &_DATE for user &_USER.@&_CONNECT_IDENTIFIER --> 
           <style> 
           html { 
              font-family: consolas, monospace; 
              font-size: 9pt; 
              background-color: #dce1e9; 
           } 
           table, td, th { 
              vertical-align: top; 
              border: 1px solid #808090; 
              background: white; 
              padding: .5em .6em; 
           } 
           table { 
              border-collapse: collapse; 
              margin-top: 1.2em;  /* space above table itself */ 
              border-width: 3px; 
              margin-bottom: 1em; 
           } 
           td { 
              margin: .2em; 
              font-size: 80%; 
           } 
           th { 
              background: #f0f4fd;  /* #96D4D4 */
              font-weight: bold; 
              font-size: 88%; 
              margin: .2em; 
              padding-bottom: .4em; 
           } 
           /*
           tr:nth-child(even) {
              background-color: #D6EEEE;
           }*/
           </style>';

  --
  --<table>
  -- <caption>Monthly savings</caption>
  --<tr>
  for s in c_states
  loop
    v_upd_message := nvl(get_parameter('UPD_MESSAGE_'||s.state||'_'||p_doc_type),'HA SUPERADO LOS '||v_minutes_holded||' MINUTES IN STATE '||s.state||'('||p_doc_type||')'); 
    --
    update pa.pa_reportes_automaticos r
    set r.estado_reporte = 'E', 
        r.mensaje = v_upd_message
    where r.origen_pkm         = 'Normal'
      and r.id_tipo_documento  = v_doc_type
      and r.estado_reporte     = s.state
      and r.fecha_modificacion <= sysdate - (v_minutes_holded / 60 / 24)
    returning r.codigo_reporte, r.estado_reporte, r.fecha_modificacion bulk collect into codigos, estados, fechas_modificaciones;  
    --
    if sql%rowcount > 0 then
      l_body:=l_body||'<h3>Documentos '||s.state||' Marcados con estado_reporte=E por tener mas de '||v_minutes_holded||' minutos en Hold.</h3>';  
      l_body:=l_body||'<TABLE>';  
      
      l_body:=l_body||'<TR>';    
      l_body:=l_body||'<TH>NUM</TH>';
      l_body:=l_body||'<TH>CODIGO_REPORTE</TH>';
      l_body:=l_body||'<TH>ESTADO_REPORTE_ANTERIOR</TH>';
      l_body:=l_body||'<TH>ESTADO_REPORTE_NUEVO</TH>';
      l_body:=l_body||'<TH>FECHA_MODIFICACION</TH>';
      l_body:=l_body||'</TR>';

      l_num_row1 := 0;
      for i in codigos.FIRST .. codigos.LAST
      loop
        l_num_row1 := l_num_row1 + 1;
        --
        l_body:=l_body||'<TR>';
        l_body:=l_body||'<TD>'||to_char(l_num_row1)     ||'</TD>';
        l_body:=l_body||'<TD>'||codigos(i)              ||'</TD>';
        l_body:=l_body||'<TD>'||s.state                 ||'</TD>';
        l_body:=l_body||'<TD>'||estados(i)              ||'</TD>';
        l_body:=l_body||'<TD>'||to_char(fechas_modificaciones(i),'dd-mon-yyyy hh24:mi:ss')||'</TD>';
        l_body:=l_body||'<TR>';

        codigos.delete(i);
        estados.delete(i);
        fechas_modificaciones.delete(i);

      end loop;
      dbms_lob.append(l_body,'</TABLE>');
    end if;      
  end loop;
  --
  --rollback;
  --drop table ia.log_table
  --create table ia.log_table(log clob);
  --insert into log_table values(l_body);
  --commit;

  --UPDATE S
  --CN20240423
  update pa_reportes_automaticos r
  set r.estado_reporte = 'S',
      r.mensaje = 'REGISTRO CON ESTADO <H> ACTUALIZADO A <S> DEBIDO A QUE EXISTE UN REGISTRO EN BITACORA_REP_AUTOMATICOS CON ESTADO <S>'
  where r.estado_reporte = 'H'
    and exists(select 1  
               from pa.bitacora_rep_automaticos b
               where b.codigo_reporte = r.codigo_reporte
                 and b.estado_reporte = 'S')
  returning r.codigo_reporte, r.estado_reporte, r.fecha_modificacion bulk collect into codigos, estados, fechas_modificaciones;  
  --
  if sql%rowcount > 0 then
    l_body:=l_body||'<h3>Documentos marcados con estado_reporte=S porque existe un registro en la bitacora con estado S.</h3>';  
    l_body:=l_body||'<TABLE>';  
    
    l_body:=l_body||'<TR>';    
    l_body:=l_body||'<TH>NUM</TH>';
    l_body:=l_body||'<TH>CODIGO_REPORTE</TH>';
    l_body:=l_body||'<TH>ESTADO_REPORTE_ANTERIOR</TH>';
    l_body:=l_body||'<TH>ESTADO_REPORTE_NUEVO</TH>';
    l_body:=l_body||'<TH>FECHA_MODIFICACION</TH>';
    l_body:=l_body||'</TR>';
  
    l_num_row2 := 0;
    for i in codigos.first .. codigos.last
    loop
      l_num_row2 := l_num_row2 + 1;
      l_body:=l_body||'<TR>';
      l_body:=l_body||'<TD>'||to_char(l_num_row2)     ||'</TD>';
      l_body:=l_body||'<TD>'||codigos(i)              ||'</TD>';
      l_body:=l_body||'<TD>H</TD>';
      l_body:=l_body||'<TD>'||estados(i)              ||'</TD>';
      l_body:=l_body||'<TD>'||to_char(fechas_modificaciones(i),'dd-mon-yyyy hh24:mi:ss')||'</TD>';
      l_body:=l_body||'<TR>';

      codigos.delete(i);
      estados.delete(i);
      fechas_modificaciones.delete(i);
    end loop;
    --
    dbms_lob.append(l_body,'</TABLE>');
  end if;
  
  --UPDATE SP
  update pa_reportes_automaticos r
  set r.estado_reporte = 'SP',
      r.mensaje = 'REGISTRO CON ESTADO <H> ACTUALIZADO A <SP> DEBIDO A QUE EXISTE UN REGISTRO EN BITACORA_REP_AUTOMATICOS CON ESTADO <SP>'
  where r.estado_reporte = 'H'
    and exists(select 1  
               from pa.bitacora_rep_automaticos b
               where b.codigo_reporte = r.codigo_reporte
                 and b.estado_reporte = 'SP')
    and not exists(select 1  
                   from pa.bitacora_rep_automaticos b
                   where b.codigo_reporte = r.codigo_reporte
                     and b.estado_reporte = 'S')
  returning r.codigo_reporte, r.estado_reporte, r.fecha_modificacion bulk collect into codigos, estados, fechas_modificaciones;  
  --CN20240423

  if sql%rowcount > 0 then  
    l_body:=l_body||'<h3>Documentos marcados con estado_reporte=SP porque existe un registro en la bitacora con estado SP.</h3>';  
    l_body:=l_body||'<TABLE>';  
    
    l_body:=l_body||'<TR>';    
    l_body:=l_body||'<TH>NUM</TH>';
    l_body:=l_body||'<TH>CODIGO_REPORTE</TH>';
    l_body:=l_body||'<TH>ESTADO_REPORTE_ANTERIOR</TH>';
    l_body:=l_body||'<TH>ESTADO_REPORTE_NUEVO</TH>';
    l_body:=l_body||'<TH>FECHA_MODIFICACION</TH>';
    l_body:=l_body||'</TR>';
    
    l_num_row3 := 0;
    for i in codigos.first .. codigos.last
    loop
      l_num_row3 := l_num_row3 + 1;
      l_body:=l_body||'<TR>';
      l_body:=l_body||'<TD>'||to_char(l_num_row3)     ||'</TD>';
      l_body:=l_body||'<TD>'||codigos(i)              ||'</TD>';
      l_body:=l_body||'<TD>H</TD>';
      l_body:=l_body||'<TD>'||estados(i)              ||'</TD>';
      l_body:=l_body||'<TD>'||to_char(fechas_modificaciones(i),'dd-mon-yyyy hh24:mi:ss')||'</TD>';
      l_body:=l_body||'<TR>';
      --
      codigos.delete(i);
      estados.delete(i);
      fechas_modificaciones.delete(i);
    end loop;
    --
    dbms_lob.append(l_body,'</TABLE>');
  end if;
  
  commit;
    
  if l_num_row1 + l_num_row2 + l_num_row3 > 0 then
    ia.html_email(p_to                => 'dba_ti@bancoademi.com.do;yalvarez@bancoademi.com.do;mmedrano@bancoademi.com.do;mialmanzar@bancoademi.com.do;josdiaz@bancoademi.com.do',  -- pass a valid email id
    --ia.html_email(p_to                => 'jesrodriguez@bancoademi.com.do',  -- pass a valid email id
                  p_from              => 'oracle@coreademidb01.bancoademi.local',  -- pass a valid email id
                  p_subject           => 'UPDATE ESTADO_REPORTE', --'Usage Report',
                  p_text              => 'We just detected DOCUMENTS with Wrong ESTADO_REPORTE.'||chr(10)||chr(13)||'Please Call the technician on duty', --'A bit of text',
                  p_html              => l_body,
                  p_smtp_hostname     => pa.param.parametro_x_empresa (1,'SERVIDOR_SMTP','PA'), -- pass a valid server name
                  p_smtp_portnum      => '25');
  end if;
  
end;
/

