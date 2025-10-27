BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
            job_name => '"PR".""',
            job_type => 'PLSQL_BLOCK',
            job_action => 'DECLARE 
  PMENSAJE VARCHAR2(32767);

BEGIN 
  PMENSAJE := NULL;

  PR.PR_PKG_REPRESTAMOS.P_CARGA_PRECALIFICA_CANCELADO ( PMENSAJE ); 
  COMMIT; 
END;',
            number_of_arguments => 0,
            start_date => TO_TIMESTAMP_TZ('2023-11-01 09:15:00.000000000 AMERICA/LA_PAZ','YYYY-MM-DD HH24:MI:SS.FF TZR'),
            repeat_interval => 'FREQ=DAILY; INTERVAL=30; BYHOUR=7; BYMINUTE=0;BYSECOND=0',
            end_date => NULL,
            enabled => FALSE,
            auto_drop => TRUE,
            comments => '');

         
     
 
    DBMS_SCHEDULER.SET_ATTRIBUTE( 
             name => '"PR".""', 
             attribute => 'store_output', value => TRUE);
    DBMS_SCHEDULER.SET_ATTRIBUTE( 
             name => '"PR".""', 
             attribute => 'job_priority', value => '1');
    DBMS_SCHEDULER.SET_ATTRIBUTE( 
             name => '"PR".""', 
             attribute => 'logging_level', value => DBMS_SCHEDULER.LOGGING_OFF);
      
   
  
    
END;
