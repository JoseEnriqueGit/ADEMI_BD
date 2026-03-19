# OPT-002 - Reemplazar OBT_IDENTIFICACION_PERSONA con JOIN en cursores SIB

- **Paquete**: PR_PKG_REPRESTAMOS
- **Procedure**: Actualiza_Precalificacion
- **Cursores**: CUR_DE08_SIB, CUR_DE05_SIB
- **Entorno**: QA
- **Fecha**: 2026-03-19
- **SQL Quest**: SQL 303 y relacionados (cost ~16,963)

## Problema
Los cursores CUR_DE08_SIB y CUR_DE05_SIB usaban `OBT_IDENTIFICACION_PERSONA(B.CODIGO_CLIENTE,'1')` en el WHERE/JOIN.
Esto causaba:
1. Ejecucion de una funcion PL/SQL por cada fila (context switch SQL-to-PL/SQL)
2. Oracle no podia usar indices sobre ID_DEUDOR/cedula
3. Full table scans en tablas SIB grandes

## Cambio realizado
Reemplazar la llamada a funcion con un JOIN directo a PA.ID_PERSONAS:
```sql
-- ANTES:
AND OBT_IDENTIFICACION_PERSONA(B.CODIGO_CLIENTE,'1') = A.ID_DEUDOR

-- DESPUES:
JOIN PA.ID_PERSONAS IP ON IP.COD_PERSONA = TO_CHAR(B.CODIGO_CLIENTE) AND IP.COD_TIPO_ID = '1'
...
AND IP.NUM_ID = A.ID_DEUDOR
```

## Razonamiento
La funcion OBT_IDENTIFICACION_PERSONA con tipo_id='1' simplemente busca:
`SELECT num_id FROM PA.ID_PERSONAS WHERE cod_persona = inCodPersona AND cod_tipo_id = '1'`
Un JOIN directo permite a Oracle usar indices y evita context switches.

## Nota
La funcion original tambien aplica formateo via `formatear_identificacion`.
Si ID_DEUDOR/cedula en las tablas SIB ya estan sin formato (solo numeros),
el JOIN directo con NUM_ID es equivalente. Verificar en QA.

## Como revertir
Compilar rollback.sql en Toad o: `git revert <commit>`
