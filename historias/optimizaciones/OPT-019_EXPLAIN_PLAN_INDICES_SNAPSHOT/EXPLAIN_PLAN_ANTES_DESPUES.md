# Explain plan breve - OPT-019

## Objetivo

Validar el impacto del indice `PA.IDX_PA_PARAM_MVP_01` sobre la consulta de
parametros usada por `F_Obt_Parametro_Represtamo`.

## ANTES

Ejecutar antes de crear el indice:

```sql
EXPLAIN PLAN SET STATEMENT_ID = 'OPT019_Q01_PARAM_BEFORE' FOR
SELECT valor
  FROM PA.PA_PARAMETROS_MVP
 WHERE codigo_empresa = 1
   AND codigo_mvp = 'REPRESTAMOS'
   AND codigo_parametro = 'ESTADOS_DESACTIVAR_ACCESO_FRONTEND';
```

Resultado validado en DESARROLLO:

```text
TABLE ACCESS FULL PA.PA_PARAMETROS_MVP
Cost: 3
Cardinality: 1
```

## Crear indice

```sql
CREATE INDEX PA.IDX_PA_PARAM_MVP_01
ON PA.PA_PARAMETROS_MVP (CODIGO_EMPRESA, CODIGO_MVP, CODIGO_PARAMETRO);
```

## DESPUES

Ejecutar despues de crear el indice:

```sql
EXPLAIN PLAN SET STATEMENT_ID = 'OPT019_Q01_PARAM_AFTER' FOR
SELECT valor
  FROM PA.PA_PARAMETROS_MVP
 WHERE codigo_empresa = 1
   AND codigo_mvp = 'REPRESTAMOS'
   AND codigo_parametro = 'ESTADOS_DESACTIVAR_ACCESO_FRONTEND';

```

Resultado validado en DESARROLLO:

```text
TABLE ACCESS BY INDEX ROWID BATCHED PA.PA_PARAMETROS_MVP
INDEX RANGE SCAN PA.IDX_PA_PARAM_MVP_01
Cost total: 2
Cost indice: 1
Cardinality: 1
```

## Decision

Mantener recomendado `PA.IDX_PA_PARAM_MVP_01`.

No crear `PR.IDX_REPRE_ESTADO_ID_01`; ya existe
`IDX_REPRESTAMOS_ESTADO_COV(ESTADO, ID_REPRESTAMO, XCORE_GLOBAL)`.

## Borrar indice

Usar solo si se decide revertir la prueba:

```sql
DROP INDEX PA.IDX_PA_PARAM_MVP_01;
```
