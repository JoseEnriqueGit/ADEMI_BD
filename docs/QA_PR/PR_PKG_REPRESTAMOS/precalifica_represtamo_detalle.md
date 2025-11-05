# Detalle de cambios en `Precalifica_Represtamo`

Este documento profundiza en las modificaciones aplicadas al procedimiento `Precalifica_Represtamo` dentro de `ENTORNOS_ORACLE/QA/PR/packages/PR_PKG_REPRESTAMOS/PR_PKG_REPRESTAMOS.sql`.

## Visión general

El objetivo del refactor fue conservar la lógica de negocio y los mensajes originales, reduciendo la carga de recursos y el tiempo de ejecución. Para lograrlo se trasladaron bucles PL/SQL a operaciones set-based y se evitaron lecturas repetitivas de parámetros.

## Cambios estructurales clave

1. **Declaración de variables**  
   - Se añadieron variables locales (`v_lote_carga`, `v_max_intentos_pin`, `v_param_deembolso_val`, etc.) situadas en `PR_PKG_REPRESTAMOS.sql:26-47`.  
   - **Razonamiento**: Las funciones `f_obt_parametro_represtamo` y `OBT_PARAMETROS` se invocaban múltiples veces; ahora cada parámetro se lee una sola vez y se reutiliza, disminuyendo llamadas a la base.

2. **Lectura de `FECHA_PROCESO`**  
   - El bloque que obtiene `v_fecha_proceso` se mantiene (`:52-60`), pero la comparación posterior reutiliza `v_dias_procesar` recién cacheado.  
   - **Razonamiento**: No cambia la regla de corte; simplemente reutiliza la variable ya traída, evitando funciones adicionales.

3. **Selección de la fecha corte**  
   - Continúa la consulta original (`:68-75`) que obtiene la penúltima fecha de corte; solo se usa después en un `INSERT` directo.  
   - **Razonamiento**: Mantener la semántica original mientras se prepara el set-based insert.

4. **Carga set-based a `PR_REPRESTAMOS`**  
   - El `CURSOR CREDITOS_PROCESAR` + `BULK COLLECT/FORALL` fue reemplazado por un `INSERT ... SELECT` en `:76-137`.  
   - La selección replica todos los filtros previos: tipos de crédito, clasificaciones, capital pagado, exclusión de créditos recientes, validación de personas físicas, listas negras, etc.  
   - **Razonamiento**: Ejecutar la lógica en SQL puro elimina la necesidad de materializar colecciones PL/SQL, reduciendo consumo de PGA y llamadas a la base. Además, se aprovechan los índices existentes durante la evaluación de los filtros.

5. **Actualización de `DIAS_ATRASO`**  
   - Sustitución del `FORALL` que hacía `UPDATE` fila a fila por una única sentencia set-based en `:139-148`.  
   - **Razonamiento**: La subconsulta correlacionada calcula el máximo atraso en los últimos seis meses para cada registro recién insertado usando la marca `fecha_proceso`, replicando el comportamiento previo sin loops.

6. **Reglas de exclusión (`X3`, `X1`, `X2`)**  
   - Cada regla ahora es un `UPDATE` masivo (`:150-186`).  
   - Se generan las mismas observaciones, tomando ventaja de los parámetros ya cacheados (`v_atraso_30`, `v_param_deembolso_text`, `v_param_mora_val`).  
   - **Razonamiento**: Aplicar estas reglas por lote garantiza consistencia y reduce la cantidad de consultas a `PA_DETALLADO_DE08` y `PR_CREDITOS`.

7. **Eliminaciones finales**  
   - Las verificaciones de cuentas mancomunadas y validación de edad se ejecutan con `DELETE` set-based (`:188-200`).  
   - Se elimina el bloque que invocaba `DELETE` por cada elemento del cursor.  
   - **Razonamiento**: Las mismas revisiones se aplican ahora en bloque sobre la marca de proceso, sin modificar la regla funcional.

8. **`COMMIT` y manejo de errores**  
   - Se preserva el `COMMIT;` original y el bloque `EXCEPTION` con `setError` (`:202-221`).  
   - **Razonamiento**: Mantener la integración con el orquestador y la bitácora de errores sin alteraciones.

## Resultado

El procedimiento conserva los mismos filtros, estados (`RE`, `X1`, `X2`, `X3`), observaciones y puntos de control, pero ahora:

- Recupera parámetros sólo una vez.  
- Inserta y depura información mediante operaciones set-based.  
- Reduce drásticamente las llamadas redundantes a tablas de soporte y elimina trabajo en memoria intermedia.

Se recomienda monitorizar los tiempos del job para validar la mejora de rendimiento obtenida con estos ajustes.
