BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
            job_name => '"PR".""',
            job_type => 'PLSQL_BLOCK',
            job_action => 'DECLARE 
  PMENSAJE VARCHAR2(32767);

BEGIN 
  PMENSAJE := NULL;

  PR.PR_PKG_REPRESTAMOS.P_CARGA_PRECALIFICA_CAMPANA_ESPECIAL ( PMENSAJE ); 
  COMMIT; 
END;',
            number_of_arguments => 0,
            start_date => TO_TIMESTAMP_TZ('2024-03-10 05:00:00.000000000 AMERICA/LA_PAZ','YYYY-MM-DD HH24:MI:SS.FF TZR'),
            repeat_interval => 'FREQ=DAILY; BYHOUR=05,06,07,08,09,10,11,12,13,14,15,16,17,18,19,20,21,22,23; BYMINUTE=0,5,10,15,20,25,30,35,40,45,50,55',
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
             attribute => 'logging_level', value => DBMS_SCHEDULER.LOGGING_RUNS);
      
   
  
    
    DBMS_SCHEDULER.enable(
             name => '"PR".""');
END;
