# Validacion

Los scripts de esta carpeta deben ejecutarse manualmente en Toad/QA02.

## Incremento A (completado 2026-06-09)

1. `00_VALIDACION_BASE_QA02.sql`
2. `01_VALIDAR_ESTRUCTURAS_INCREMENTO_A_QA02.sql`
3. Ejecutar como script el `body.sql` canonico modificado.
4. `02_VALIDAR_COMPILACION_INCREMENTO_A_QA02.sql`
5. Ejecutar de forma controlada `PR.JOB_CARGA_PRECALIFICA_RD`.
6. `03_VALIDAR_RESULTADO_INCREMENTO_A_QA02.sql`
7. comparar tiempos con el baseline;
8. probar el rollback del body si el resultado no es satisfactorio.

## Incremento B (completado 2026-06-09, ejecucion `53D8BBE0BA0E44D9E063140311AC6BC6`)

1. `../01_DDL/04_ALTER_PR_JOB_PRECALIFICA_CANDIDATO_TRACK_QA02.sql`
   (obligatorio ANTES de compilar: el body referencia las columnas nuevas).
2. `04_VALIDAR_ESTRUCTURAS_INCREMENTO_B_QA02.sql`
3. Ejecutar como script el `body.sql` canonico (Incremento A+B).
4. `05_VALIDAR_COMPILACION_INCREMENTO_B_QA02.sql`
5. Ejecutar de forma controlada `PR.JOB_CARGA_PRECALIFICA_RD`
   con `TRACK_PRECALIFICA_ACTIVO='S'`.
6. `06_VALIDAR_RESULTADO_INCREMENTO_B_QA02.sql` (o el `07_*`, ver nota).
7. `07_RESUMEN_INCREMENTO_B_UNA_FILA_QA02.sql`: resumen de conciliacion en UNA
   fila + duraciones + costo por candidato vs corrida A. Usar con **F9** por
   query (Data Grid); creado porque Toad no volcaba los SELECT del 06 al
   Script Output.
8. si el resultado no es satisfactorio: `../04_ROLLBACK/ROLLBACK_INCREMENTO_B_BODY_QA02.sql`
   (y solo con aprobacion, la reversa del ALTER).

> Nota Toad: no poner `;` dentro del texto de un `PROMPT` (rompe "execute as
> script" con ORA-00900; incidencia vista en los scripts 00 y 05).

## Incremento C (pendiente de ejecutar)

No requiere DDL nuevo. Orden:

1. Ejecutar como script el `body.sql` canonico (A+B+C).
2. `08_VALIDAR_COMPILACION_INCREMENTO_C_QA02.sql` (BODY `VALID`, 0 errores,
   `lineas_helper = 7`, `lineas_flag = 10`).
3. Ejecutar de forma controlada `PR.JOB_CARGA_PRECALIFICA_RD`
   con `TRACK_PRECALIFICA_ACTIVO='S'`.
4. `09_VALIDAR_RESULTADO_INCREMENTO_C_QA02.sql` con **F9 por query**:
   Query 1 = resumen OK/REVISAR, Query 2 = bruto vs neto por flujo,
   Query 3 = recorrido individual, Query 4 = duraciones.
5. si el resultado no es satisfactorio: `../04_ROLLBACK/ROLLBACK_INCREMENTO_C_BODY_QA02.sql`
   (restaura el body B probado).

La `spec.sql` no se ejecuta ni se modifica en ningun incremento.

Guardar salidas y capturas en `../05_RESULTADOS/`.
