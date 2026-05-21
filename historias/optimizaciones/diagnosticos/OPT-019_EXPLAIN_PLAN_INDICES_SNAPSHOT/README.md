# OPT-019 - Explain Plan de indices para INC SNAPSHOT TOO OLD

## Objetivo

Preparar una validacion controlada en Toad/QA para decidir si conviene crear
indices adicionales alrededor de `P_Generar_Bitacora`,
`P_Validar_Cambio_Estado`, `P_REGISTRO_SOLICITUD` y el cursor final de
`P_Carga_Precalifica_Cancelado`.

Esta OPT-019 no cambia `PR.PR_PKG_REPRESTAMOS`, no modifica `spec.sql` y no
reproduce `ORA-01555`. Solo compara planes antes/despues de indices candidatos.

## Prerrequisitos

- Ejecutar los explain plan con el mismo usuario con que se validara el job, o
  con un usuario que vea los objetos `PR` y `PA`.
- Ejecutar `CREATE_INDEXES.sql` y `ROLLBACK.sql` con el owner correspondiente o
  con un usuario DBA. El indice firme es sobre una tabla `PA`, por lo que un
  usuario `PR` normal puede no tener privilegio para crearlo.
- Confirmar en `Q00` si el indice ya existe en BD con otro nombre antes de crear
  un duplicado.
- Ejecutar los scripts completos con `Run Script/F5`. Los planes Q04/Q05 usan
  `SELECT` seguro equivalente al acceso por PK y no contienen `UPDATE`.
- Los scripts de explain plan no ejecutan `COMMIT`; si hay transacciones
  pendientes en la sesion, resolverlas manualmente antes de iniciar.
- Si se ejecuto un DML accidental en Toad durante la validacion, ejecutar
  `ROLLBACK;` en esa misma sesion antes de continuar.

## Consultas revisadas

| Codigo | Consulta | Evidencia en package | Estado de indice en repo |
|--------|----------|----------------------|--------------------------|
| Q01 | `PA.PA_PARAMETROS_MVP` por `CODIGO_EMPRESA`, `CODIGO_MVP`, `CODIGO_PARAMETRO` | `body.sql` 4031-4037 | Sin PK/indice visible en DDL del repo |
| Q02A | Query original reportado en trace: `ID_REPRESTAMO`, `ESTADO`, `XCORE_GLOBAL` por `ESTADO='RE'` | incidente documentado; cursor legado antes de OPT-017/018 | En BD real se confirmo `IDX_REPRESTAMOS_ESTADO_COV(ESTADO, ID_REPRESTAMO, XCORE_GLOBAL)` |
| Q02B | IDs `PR_REPRESTAMOS WHERE ESTADO='RE'` usados por OPT-017/018 | `body.sql` 7913-7916 y 7984-7987 | Cubierto por el prefijo de `IDX_REPRESTAMOS_ESTADO_COV` en BD real |
| Q03 | `PR_ESTADOS_REPRESTAMO` por `CODIGO_EMPRESA`, `CODIGO_ESTADO` | `body.sql` 5829-5833 | Cubierto por PK |
| Q04/Q05 | `SELECT` seguro equivalente al acceso de updates a `PR_REPRESTAMOS` por `CODIGO_EMPRESA`, `ID_REPRESTAMO` | `body.sql` 5850-5857 y 5901-5904 | Cubierto por PK |
| Q06 | Conteo de bitacora por `CODIGO_EMPRESA`, `ID_REPRESTAMO` | `body.sql` 5959-5963 | Cubierto por prefijo de PK |
| Q07 | Conteo de bitacora por `CODIGO_ESTADO`, `ID_REPRESTAMO` | `body.sql` 5915 | Cubierto por `IDX_BITREPRE_CODESTADO_ID` |

## Indices candidatos

### Firme para probar

```sql
CREATE INDEX PA.IDX_PARAM_MVP_EMP_MVP_PARAM
ON PA.PA_PARAMETROS_MVP (CODIGO_EMPRESA, CODIGO_MVP, CODIGO_PARAMETRO)
TABLESPACE PA_IDX;
```

Motivo: `F_Obt_Parametro_Represtamo` busca exactamente por esas columnas y el
DDL del repo no muestra indice/PK para esa tabla.

### Opcional historico, no recomendado con la evidencia actual

```sql
CREATE INDEX PR.IDX_REPRE_ESTADO_ID_01
ON PR.PR_REPRESTAMOS (ESTADO, ID_REPRESTAMO);
```

Motivo original: los bulk collect de OPT-017/OPT-018 leen `ID_REPRESTAMO`
filtrando solo por `ESTADO='RE'`. Con la evidencia de Q00 en DESARROLLO, ya
existe `IDX_REPRESTAMOS_ESTADO_COV(ESTADO, ID_REPRESTAMO, XCORE_GLOBAL)`, por
lo que este indice seria redundante y menos completo para Q02A/Q02B.

## Scripts

| Archivo | Uso |
|---------|-----|
| `ANTES.sql` | Explain Plan antes de crear indices candidatos |
| `BEFORE.sql` | Alias en ingles de `ANTES.sql` |
| `CREATE_INDEXES.sql` | Crea el indice firme; deja el indice opcional historico comentado y no recomendado si existe `IDX_REPRESTAMOS_ESTADO_COV` |
| `DESPUES.sql` | Explain Plan despues de crear indices candidatos |
| `AFTER.sql` | Alias en ingles de `DESPUES.sql` |
| `ROLLBACK.sql` | Elimina indices candidatos si fueron creados |
| `EXPLAIN_PLAN_ANTES_DESPUES.md` | Resumen breve con script exacto y resultado validado |

## Secuencia recomendada en Toad

1. Ajustar `DEFINE ID_REPRESTAMO` con un ID real existente en QA.
2. Ejecutar `ANTES.sql` y guardar la salida.
3. Ejecutar `CREATE_INDEXES.sql`; con la evidencia actual, no descomentar el
   indice opcional de `PR_REPRESTAMOS`.
4. Ejecutar `DESPUES.sql` y comparar con la salida del punto 2.
5. Validar que Q01 cambie de full scan a acceso por indice sobre
   `PA_PARAMETROS_MVP`.
6. Ejecutar `ROLLBACK.sql` si la evidencia no justifica dejar los indices.

## Criterio de decision

- Aprobar `IDX_PARAM_MVP_EMP_MVP_PARAM` si Q01 cambia de full scan a index access o
  reduce costo/lecturas de forma clara.
- No aprobar `IDX_REPRE_ESTADO_ID_01` si Q00 muestra
  `IDX_REPRESTAMOS_ESTADO_COV(ESTADO, ID_REPRESTAMO, XCORE_GLOBAL)` o cualquier
  indice equivalente con prefijo `(ESTADO, ID_REPRESTAMO)`.
- No crear indices adicionales sobre `PR_ESTADOS_REPRESTAMO`,
  `PR_BITACORA_REPRESTAMO` ni la PK de `PR_REPRESTAMOS` sin evidencia nueva,
  porque los predicados revisados ya estan cubiertos en el DDL del repo.

## Resultado validado en DESARROLLO

- Q01 antes de crear `PA.IDX_PARAM_MVP_EMP_MVP_PARAM`: `TABLE ACCESS FULL` sobre
  `PA.PA_PARAMETROS_MVP`, costo 3, cardinalidad 1.
- Q01 despues de crear `PA.IDX_PARAM_MVP_EMP_MVP_PARAM`: `INDEX RANGE SCAN` sobre
  `PA.IDX_PARAM_MVP_EMP_MVP_PARAM` y `TABLE ACCESS BY INDEX ROWID BATCHED`, costo total
  2, costo de indice 1, cardinalidad 1.
- Decision: mantener recomendado `PA.IDX_PARAM_MVP_EMP_MVP_PARAM` como indice de bajo
  riesgo para la ruta de parametros. Aprobado para pase a PROD (renombrado desde
  el candidato historico `IDX_PA_PARAM_MVP_01` para alinear con la convencion de
  los 8 indices ya en PROD y agregar TABLESPACE PA_IDX explicito).
- Decision: no crear `PR.IDX_REPRE_ESTADO_ID_01`; en DESARROLLO ya existe
  `IDX_REPRESTAMOS_ESTADO_COV(ESTADO, ID_REPRESTAMO, XCORE_GLOBAL)`.
