-- =============================================================================
-- Entorno: QA02
-- Schema: IA
-- Objeto: IA.CHECK_ESTADO_REPORTE_V1 (PROCEDURE)
-- Fecha incorporacion: 2026-04-30
-- Origen: Toad / ALL_SOURCE en QADEMI02_19C
-- Motivo: Investigacion registros faltantes en Reportes Onboarding
-- Observacion: Objeto incorporado como referencia, sin alterar logica.
-- =============================================================================

CREATE OR REPLACE procedure IA.check_estado_reporte_v1(p_doc_type in varchar2) as
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
  --
  cursor c_states is
    select valor state
    from param_generales
    where abrev_parametro like 'ESTADO%_ERROR_'||p_doc_type; 
--
begin
  for s in c_states
  loop
    v_upd_message := nvl(get_parameter('UPD_MESSAGE_'||s.state||'_'||p_doc_type),'HA SUPERADO LOS '||v_minutes_holded||' MINUTES IN STATE '||s.state||'('||p_doc_type||')'); 
    --
    update pa.pa_reportes_automaticos
    set estado_reporte = 'E', 
        mensaje = v_upd_message
    where origen_pkm = 'Normal'
      and id_tipo_documento = v_doc_type
      and estado_reporte = s.state
      and fecha_modificacion <= sysdate - (v_minutes_holded / 60 / 24);
    --
  end loop;
  --
  commit;
  --
  --CN20240423
  update pa_reportes_automaticos r
  set r.estado_reporte = 'S',
      r.mensaje = 'REGISTRO CON ESTADO <H> ACTUALIZADO A <S> DEBIDO A QUE EXISTE UN REGISTRO EN BITACORA_REP_AUTOMATICOS CON ESTADO <S>'
  where r.estado_reporte = 'H'
    and exists(select 1  
               from pa.bitacora_rep_automaticos b
               where b.codigo_reporte = r.codigo_reporte
                 and b.estado_reporte = 'S');
  --
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
                     and b.estado_reporte = 'S');
  --CN20240423
  --  
  commit;
  
  --SEND NOTIFICATION
  execute immediate 'ALTER SESSION SET NLS_DATE_FORMAT=''DD-MON-YYYY'' ';
  
  l_body:='<TABLE BORDER=1 BGCOLOR="#82c4e8">';  --#EEEEEE
  l_body:=l_body||'<TR BGCOLOR="#092b7a">';    --BLACK
  l_body:=l_body||'<TH><FONT COLOR="WHITE">ESTADO</FONT>';
  l_body:=l_body||'<TH><FONT COLOR="WHITE">ERROR</FONT>';
  l_body:=l_body||'<TH><FONT COLOR="WHITE">NUM_CERTIFICADO</FONT>';
  l_body:=l_body||'<TH><FONT COLOR="WHITE">CLIENTE</FONT>';
  l_body:=l_body||'<TH><FONT COLOR="WHITE">COD_AGENCIA</FONT>';
  l_body:=l_body||'<TH><FONT COLOR="WHITE">COD_CARTERA</FONT>';
  l_body:=l_body||'<TH><FONT COLOR="WHITE">COD_PRODUCTO</FONT>';
  l_body:=l_body||'<TH><FONT COLOR="WHITE">CUENTA_CONTABLE</FONT>';
  l_body:=l_body||'</TR>';

  --for c in c_failure_jobs
  --loop
  -- dbms_lob.append(l_body,'<TR>');
  -- dbms_lob.append(l_body,'<TD>'||c.ESTADO          ||'</TD>');
  -- dbms_lob.append(l_body,'<TD>'||c.ERROR_          ||'</TD>');
  -- dbms_lob.append(l_body,'<TD>'||c.NUM_CERTIFICADO ||'</TD>');
  -- dbms_lob.append(l_body,'<TD>'||c.CLIENTE         ||'</TD>');
  -- dbms_lob.append(l_body,'<TD>'||c.COD_AGENCIA     ||'</TD>');
  -- dbms_lob.append(l_body,'<TD>'||c.COD_CARTERA     ||'</TD>');
  -- dbms_lob.append(l_body,'<TD>'||c.COD_PRODUCTO    ||'</TD>');
  -- dbms_lob.append(l_body,'<TD>'||c.CUENTA_CONTABLE ||'</TD>');
  -- dbms_lob.append(l_body,'</TR>');
  --end loop;
  
  dbms_lob.append(l_body,'</TABLE>');
  
  ia.html_email(p_to                => 'dba_ti@bancoademi.com.do; yalvarez@bancoademi.com.do; mmedrano@bancoademi.com.do; mialmanzar@bancoademi.com.do; josdiaz@bancoademi.com.do',  -- pass a valid email id
                p_from              => 'jesrodriguez@bancoademi.com.do',  -- pass a valid email id
                p_subject           => 'UPDATE ESTADO_REPORTE', --'Usage Report',
                p_text              => 'We just detected DOCUMENTS with Wrong ESTADO_REPORTE.'||chr(10)||chr(13)||'Please Call the technician on duty', --'A bit of text',
                p_html              => l_body,
                p_smtp_hostname     => pa.param.parametro_x_empresa (1,'SERVIDOR_SMTP','PA'), -- pass a valid server name
                p_smtp_portnum      => '25');
  
end;
/

