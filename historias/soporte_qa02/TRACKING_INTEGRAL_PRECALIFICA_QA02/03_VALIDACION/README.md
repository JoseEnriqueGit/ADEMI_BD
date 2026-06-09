# Validacion

Los scripts de esta carpeta deben ejecutarse manualmente en Toad/QA02.

Orden previsto:

1. `00_VALIDACION_BASE_QA02.sql`
2. `01_VALIDAR_ESTRUCTURAS_INCREMENTO_A_QA02.sql`
3. Ejecutar como script el `body.sql` canonico modificado.
4. `02_VALIDAR_COMPILACION_INCREMENTO_A_QA02.sql`
5. Ejecutar de forma controlada `PR.JOB_CARGA_PRECALIFICA_RD`.
6. `03_VALIDAR_RESULTADO_INCREMENTO_A_QA02.sql`
7. comparar tiempos con el baseline;
8. probar el rollback del body si el resultado no es satisfactorio.

La `spec.sql` no se ejecuta ni se modifica para este incremento.

Guardar salidas y capturas en `../05_RESULTADOS/`.
