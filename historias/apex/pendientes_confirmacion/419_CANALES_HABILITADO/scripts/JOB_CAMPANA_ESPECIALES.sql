BEGIN
  SYS.DBMS_SCHEDULER.DROP_JOB
    (job_name  => 'PR.JOB_CAMPANAS_ESPECIALES_RD');
END;
/

BEGIN
  SYS.DBMS_SCHEDULER.CREATE_JOB
    (
       job_name        => 'PR.JOB_CAMPANAS_ESPECIALES_RD'
      ,start_date      => TO_TIMESTAMP_TZ('2024/03/10 05:00:00.000000 America/La_Paz','yyyy/mm/dd hh24:mi:ss.ff tzr')
      ,repeat_interval => 'FREQ=DAILY; BYHOUR=05,06,07,08,09,10,11,12,13,14,15,16,17,18,19,20,21,22,23; BYMINUTE=0,5,10,15,20,25,30,35,40,45,50,55'
      ,end_date        => NULL
      ,job_class       => 'DEFAULT_JOB_CLASS'
      ,job_type        => 'PLSQL_BLOCK'
      ,job_action      => 'DECLARE 
  PMENSAJE VARCHAR2(32767);

BEGIN 
  PMENSAJE := NULL;

  PR.PR_PKG_REPRESTAMOS.P_CARGA_PRECALIFICA_CAMPANA_ESPECIAL ( PMENSAJE ); 
  COMMIT; 
END;'
      ,comments        => NULL
    );
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE
    ( name      => 'PR.JOB_CAMPANAS_ESPECIALES_RD'
     ,attribute => 'RESTARTABLE'
     ,value     => FALSE);
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE
    ( name      => 'PR.JOB_CAMPANAS_ESPECIALES_RD'
     ,attribute => 'LOGGING_LEVEL'
     ,value     => SYS.DBMS_SCHEDULER.LOGGING_RUNS);
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE_NULL
    ( name      => 'PR.JOB_CAMPANAS_ESPECIALES_RD'
     ,attribute => 'MAX_FAILURES');
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE_NULL
    ( name      => 'PR.JOB_CAMPANAS_ESPECIALES_RD'
     ,attribute => 'MAX_RUNS');
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE
    ( name      => 'PR.JOB_CAMPANAS_ESPECIALES_RD'
     ,attribute => 'STOP_ON_WINDOW_CLOSE'
     ,value     => FALSE);
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE
    ( name      => 'PR.JOB_CAMPANAS_ESPECIALES_RD'
     ,attribute => 'JOB_PRIORITY'
     ,value     => 1);
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE_NULL
    ( name      => 'PR.JOB_CAMPANAS_ESPECIALES_RD'
     ,attribute => 'SCHEDULE_LIMIT');
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE
    ( name      => 'PR.JOB_CAMPANAS_ESPECIALES_RD'
     ,attribute => 'AUTO_DROP'
     ,value     => TRUE);
END;
/
