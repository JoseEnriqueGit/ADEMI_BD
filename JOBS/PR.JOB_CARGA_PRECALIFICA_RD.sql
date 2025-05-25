BEGIN
  SYS.DBMS_SCHEDULER.DROP_JOB
    (job_name  => 'PR.JOB_CARGA_PRECALIFICA_RD');
END;
/

BEGIN
  SYS.DBMS_SCHEDULER.CREATE_JOB
    (
       job_name        => 'PR.JOB_CARGA_PRECALIFICA_RD'
      ,start_date      => TO_TIMESTAMP_TZ('2023/11/01 09:15:00.000000 America/La_Paz','yyyy/mm/dd hh24:mi:ss.ff tzr')
      ,repeat_interval => 'FREQ=DAILY; INTERVAL=30; BYHOUR=7; BYMINUTE=0;BYSECOND=0'
      ,end_date        => NULL
      ,job_class       => 'DEFAULT_JOB_CLASS'
      ,job_type        => 'PLSQL_BLOCK'
      ,job_action      => 'DECLARE 
  PMENSAJE VARCHAR2(32767);

BEGIN 
  PMENSAJE := NULL;

  PR.PR_PKG_REPRESTAMOS.P_CARGA_PRECALIFICA_CANCELADO ( PMENSAJE ); 
  COMMIT; 
END;'
      ,comments        => NULL
    );
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE
    ( name      => 'PR.JOB_CARGA_PRECALIFICA_RD'
     ,attribute => 'RESTARTABLE'
     ,value     => FALSE);
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE
    ( name      => 'PR.JOB_CARGA_PRECALIFICA_RD'
     ,attribute => 'LOGGING_LEVEL'
     ,value     => SYS.DBMS_SCHEDULER.LOGGING_OFF);
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE_NULL
    ( name      => 'PR.JOB_CARGA_PRECALIFICA_RD'
     ,attribute => 'MAX_FAILURES');
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE_NULL
    ( name      => 'PR.JOB_CARGA_PRECALIFICA_RD'
     ,attribute => 'MAX_RUNS');
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE
    ( name      => 'PR.JOB_CARGA_PRECALIFICA_RD'
     ,attribute => 'STOP_ON_WINDOW_CLOSE'
     ,value     => FALSE);
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE
    ( name      => 'PR.JOB_CARGA_PRECALIFICA_RD'
     ,attribute => 'JOB_PRIORITY'
     ,value     => 1);
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE_NULL
    ( name      => 'PR.JOB_CARGA_PRECALIFICA_RD'
     ,attribute => 'SCHEDULE_LIMIT');
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE
    ( name      => 'PR.JOB_CARGA_PRECALIFICA_RD'
     ,attribute => 'AUTO_DROP'
     ,value     => TRUE);
END;
/
