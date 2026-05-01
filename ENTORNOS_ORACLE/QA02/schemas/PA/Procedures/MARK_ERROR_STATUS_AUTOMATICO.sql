-- =============================================================================
-- Entorno: QA02
-- Schema: PA
-- Objeto: PA.MARK_ERROR_STATUS_AUTOMATICO (PROCEDURE)
-- Fecha incorporacion: 2026-04-30
-- Origen: Toad / ALL_SOURCE en QADEMI02_19C
-- Motivo: Investigacion registros faltantes en Reportes Onboarding
-- Observacion: Objeto incorporado como referencia, sin alterar logica.
-- =============================================================================

CREATE OR REPLACE procedure PA.mark_error_status_automatico(p_doc_type in varchar2) as
------------------------------------------------------------------------------------------
-- OBJECT:
--         Update pa_reportes_automaticos.
--         Set as Error (estado_reporte=E) documents no processed.
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
  end loop;
  --
  commit;
  --
  --CN20240423
  update pa_reportes_automaticos r
  set r.estado_reporte = 'S',
      r.mensaje = 'REGISTRO CON ESTADO <H> ACTUALIZADO A <S> DEBIDO A QUE EXISTE UN REGISTRO EN BITACORA_REP_AUTOMATICOS CON ESTADO <S>'
  where r.estado_reporte = 'H'
    and r.origen_pkm = 'Normal'
    and exists(select 1  
               from pa.bitacora_rep_automaticos b
               where b.codigo_reporte = r.codigo_reporte
                 and b.estado_reporte = 'S');
  --
  update pa_reportes_automaticos r
  set r.estado_reporte = 'D',
      r.mensaje = 'REGISTRO CON ESTADO <H> ACTUALIZADO A <SP> DEBIDO A QUE EXISTE UN REGISTRO EN BITACORA_REP_AUTOMATICOS CON ESTADO <SP>'
  where r.estado_reporte = 'H'
    and r.origen_pkm = 'Normal'
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
end;
/

