# Benchmark vista vieja vs nueva en SQL Developer (19c)

1. Crear clon de la vista anterior (no tocar la actual):
```sql
CREATE OR REPLACE VIEW pr.pr_v_envio_represtamos_old AS
/* pega aqui la version anterior completa */
CREATE OR REPLACE FORCE VIEW PR.PR_V_ENVIO_REPRESTAMOS (
        ID_REPRESTAMO, NUMERO_IDENTIFICACION, CANAL, CANAL_DESC, NOMBRES,
        APELLIDOS, MTO_PREAPROBADO, CONTACTO, SUBJECT_EMAIL, TEXTO_MENSAJE,
        FECHA_PROCESO, FECHA_VENCIMIENTO, ESTADO
    ) BEQUEATH DEFINER AS WITH params AS (
        SELECT UPPER(TRIM(column_value)) val
        FROM TABLE(pr.pr_pkg_represtamos.f_obt_valor_parametros('CANALES_HABILITADOS'))
    )
    SELECT ...  -- definicion original
;
```

2. Activar metricas en la sesion:
```sql
ALTER SESSION SET statistics_level = ALL;
SET TIMING ON;
```

3. Calentar cache (descartar estos tiempos):
```sql
SELECT /*+ gather_plan_statistics */ COUNT(*) FROM pr.pr_v_envio_represtamos_old;
SELECT /*+ gather_plan_statistics */ COUNT(*) FROM pr.pr_v_envio_represtamos;
```

4. Medir vista vieja y capturar plan:
```sql
SELECT /*+ gather_plan_statistics */ COUNT(*) FROM pr.pr_v_envio_represtamos_old;

SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL,NULL,'ALLSTATS LAST +PEEKED_BINDS'));
```

5. Medir vista nueva y capturar plan:
```sql
SELECT /*+ gather_plan_statistics */ COUNT(*) FROM pr.pr_v_envio_represtamos;

SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL,NULL,'ALLSTATS LAST +PEEKED_BINDS'));
```

Que mirar:
- `Elapsed` que muestra SQL Developer tras cada SELECT (tiempo wall-clock).
- En `DBMS_XPLAN`: columnas `E-Rows/A-Rows`, `A-Time`, `Buffers` y uso de indices vs FTS.
- `consistent gets` y `physical reads` si activas `SET AUTOTRACE TRACEONLY STATISTICS` (opcional).

Tips:
- Ejecuta cada SELECT dos veces; usa el segundo tiempo para comparacion justa (cache caliente).
- Si necesitas traer filas, usa `FETCH FIRST 200 ROWS ONLY` para no distorsionar con fetch completo.
- Para comparar sobre el mismo subconjunto, agrega `WHERE id_represtamo = :id` en ambas vistas.

Con este flujo obtienes tiempos y planes reales sin tocar la vista oficial en el entorno.
