# Tracking integral de precalificacion - QA02

## Objetivo

Implementar y probar en QA02 el tracking integral definido en:

`ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/diagnosticos_precalifica/PROPUESTA_TRACKING_INTEGRAL_PRECALIFICA_QA02.md`

El trabajo debe medir el recorrido real de
`PR.JOB_CARGA_PRECALIFICA_RD` sin cambiar las reglas de negocio ni la
interfaz publica del package.

## Objeto canonico

El unico body canonico que se modificara es:

`ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql`

La `spec.sql` no debe modificarse.

`body copy.sql` no forma parte de esta historia y no debe usarse como baseline
ni como rollback.

## Estructura

| Carpeta | Contenido |
|---|---|
| `00_ANTES/` | Copia exacta del body y spec antes de implementar. |
| `01_DDL/` | Tablas, secuencias, indices y parametros propuestos para QA02. |
| `02_PACKAGE/` | Inventario de cambios y snapshots del body implementado. |
| `03_VALIDACION/` | Validacion previa, compilacion, ejecucion y conciliacion. |
| `04_ROLLBACK/` | Body ejecutable de reversa y pasos para deshacer DDL/parametros. |
| `05_RESULTADOS/` | Evidencia de Toad, tiempos, conteos y errores observados. |
| `06_HANDOFF/` | Entrega tecnica y decision sobre siguientes pasos. |

## Orden de trabajo

1. Ejecutar y guardar la validacion base.
2. Preparar DDL y rollback de objetos auxiliares.
3. Implementar helpers privados en `body.sql`.
4. Instrumentar una etapa a la vez.
5. Compilar y validar despues de cada bloque.
6. Ejecutar el job en QA02.
7. Conciliar conteos y medir impacto.
8. Documentar resultados y decision.

## Limites

- Ambiente inicial: QA02.
- No ejecutar DDL/DML desde el repo.
- No promover a produccion desde esta historia.
- No modificar la `spec`.
- No reutilizar ni reactivar OPT-020.
- Un fallo de tracking no puede interrumpir la precalificacion.
