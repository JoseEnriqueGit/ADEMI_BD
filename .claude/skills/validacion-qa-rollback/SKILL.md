---
name: validacion-qa-rollback
description: Usar cuando una tarea requiera scripts de validacion, pruebas QA02, rollback, reversa de paquetes/vistas/indices/parametros Oracle o documentacion de resultados de Toad/tracking.
---

# Validacion QA y Rollback

## Objetivo
Todo cambio Oracle debe ser verificable y reversible, con separacion clara entre QA02 y produccion.

## Reglas obligatorias
- Todo cambio debe tener script o pasos de validacion.
- Todo cambio de paquete, vista, indice o parametro debe tener rollback o estrategia de reversa.
- Separar QA02 de produccion en nombres, rutas y documentacion.
- Documentar resultados observados en Toad, tracking o salida SQL.
- No ejecutar DML/DDL contra base de datos desde el repo salvo pedido explicito.
- Si solo se puede validar en Toad, dejar instrucciones concretas.

## Estructura sugerida por historia
```text
README.md
ANTES.sql
DESPUES.sql
ROLLBACK.sql
VALIDACION.sql
RESULTADOS_QA02.md
HANDOFF.md
```

## Flujo
1. Identificar ambiente y objeto.
2. Capturar valor/estado antes.
3. Preparar cambio y validacion.
4. Preparar rollback o reversa.
5. Ejecutar o pedir ejecucion en Toad.
6. Registrar resultado con fecha, ambiente y evidencia.

## Ejemplos
- Parametro: `SELECT` actual, `UPDATE` propuesto, `COMMIT`, verificacion y rollback al valor original.
- Indice: `CREATE INDEX`, validacion de existencia/plan, `DROP INDEX`.
- Package: body anterior completo, body nuevo, compilacion, pruebas funcionales y reversa al body anterior.
