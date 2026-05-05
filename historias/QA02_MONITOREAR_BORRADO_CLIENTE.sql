-- Ejecutar en otra conexion/sesion de Toad mientras corre QA02_BORRADO_CLIENTE_PARAMETRICO.sql.
-- No funciona en la misma pestana si esa pestana esta ocupada ejecutando el borrado.

SELECT sid,
       serial#,
       username,
       status,
       module,
       action,
       event,
       wait_class,
       seconds_in_wait,
       blocking_session,
       sql_id
  FROM v$session
 WHERE module = 'QA02_BORRADO_CLIENTE'
 ORDER BY last_call_et DESC;

SELECT s.sid,
       s.serial#,
       s.action,
       s.event,
       s.wait_class,
       s.seconds_in_wait,
       s.blocking_session,
       q.sql_text
  FROM v$session s
  LEFT JOIN v$sql q
    ON q.sql_id = s.sql_id
 WHERE s.module = 'QA02_BORRADO_CLIENTE'
 ORDER BY s.last_call_et DESC;
