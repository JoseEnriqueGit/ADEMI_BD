# Consultas de Profiler para PR_PKG_REPRESTAMOS

Este directorio almacena los scripts SQL sugeridos para analizar el rendimiento del procedimiento `PR.PR_PKG_REPRESTAMOS.P_Carga_Precalifica_Cancelado` y el job asociado.

## 1. Ejecuciones recientes del profiler

```sql
SELECT runid,
       run_owner,
       run_comment,
       TO_CHAR(run_date,'YYYY-MM-DD HH24:MI:SS') AS run_start,
       ROUND(run_total_time / 1e9, 2)            AS total_seconds,
       total_elapsed_time                        AS elapsed_ticks
  FROM SROBLES.plsql_profiler_runs
 WHERE run_comment LIKE '%P_Carga_Precalifica_Cancelado%'
 ORDER BY runid DESC;
```

## 2. Tiempo por unidad

```sql
SELECT u.unit_type,
       u.unit_name,
       SUM(d.total_occur)                          AS exec_count,
       ROUND(SUM(d.total_time)/1e9, 3)             AS total_seconds,
       ROUND(SUM(d.total_time)
              / NULLIF(SUM(d.total_occur), 0) / 1e6, 3) AS avg_ms_per_call
  FROM SROBLES.plsql_profiler_units u
  JOIN SROBLES.plsql_profiler_data d
    ON u.runid = d.runid
   AND u.unit_number = d.unit_number
 WHERE u.runid = :runid
 GROUP BY u.unit_type, u.unit_name
 ORDER BY total_seconds DESC;
```

## 3. Líneas más costosas dentro de la unidad

```sql
SELECT d.line#,
       ROUND(d.total_time / 1e9, 4) AS seconds,
       d.total_occur,
       ROUND(d.total_time / NULLIF(d.total_occur, 0) / 1e6, 3) AS avg_ms,
       s.text
  FROM SROBLES.plsql_profiler_units u
  JOIN SROBLES.plsql_profiler_data d
    ON u.runid = d.runid
   AND u.unit_number = d.unit_number
  LEFT JOIN ALL_SOURCE s
    ON s.owner = u.unit_owner
   AND s.name  = u.unit_name
   AND s.type  = u.unit_type
   AND s.line  = d.line#
 WHERE u.runid = :runid
   AND u.unit_name = 'PR_PKG_REPRESTAMOS'
   AND d.total_time > 0
 ORDER BY d.total_time DESC
 FETCH FIRST 50 ROWS ONLY;
```

## 4. Historial de ejecución del job

```sql
SELECT log_id,
       TO_CHAR(actual_start_date, 'YYYY-MM-DD HH24:MI:SS') AS started_at,
       status,
       error#,
       EXTRACT(DAY    FROM run_duration) * 86400 +
       EXTRACT(HOUR   FROM run_duration) * 3600 +
       EXTRACT(MINUTE FROM run_duration) * 60 +
       EXTRACT(SECOND FROM run_duration)    AS duration_seconds,
       additional_info
  FROM dba_scheduler_job_run_details
 WHERE owner    = 'PR'
   AND job_name = 'P_CARGA_PRECALIFICA_CANCELADO'
 ORDER BY log_id DESC;
```

## 5. Correlación entre profiler y job scheduler

```sql
SELECT r.runid,
       TO_CHAR(r.run_date, 'YYYY-MM-DD HH24:MI:SS') AS profiler_start,
       ROUND(r.run_total_time / 1e9, 2)             AS profiler_seconds,
       j.actual_start_date,
       j.run_duration
  FROM SROBLES.plsql_profiler_runs r
  JOIN dba_scheduler_job_run_details j
    ON j.actual_start_date BETWEEN r.run_date - INTERVAL '5' MINUTE
                               AND r.run_date + INTERVAL '30' MINUTE
 WHERE r.run_comment LIKE '%P_Carga_Precalifica_Cancelado%'
   AND j.job_name = 'P_CARGA_PRECALIFICA_CANCELADO'
 ORDER BY r.runid DESC;
```

## 6. Pasos para verificar la configuración del profiler

- Compilar el paquete con símbolos de depuración: `ALTER PACKAGE PR.PR_PKG_REPRESTAMOS COMPILE BODY DEBUG;`.
- Confirmar que el usuario del job tiene permisos sobre `DBMS_PROFILER` y tablas `SROBLES.PLSQL_PROFILER_%`.
- Ejecutar el job y validar que se genera un nuevo `runid` consultando la Sección 1.
- Si los tiempos aparecen en cero, invocar `DBMS_PROFILER.FLUSH_DATA;` antes de `DBMS_PROFILER.STOP_PROFILER` y revisar errores en `SROBLES.TOAD_PROFILER.rollup_run`.
- Aprovechar `DBMS_PROFILER.PROFILER_PAUSE/RESUME` para aislar secciones específicas si se requiere mayor granularidad.
