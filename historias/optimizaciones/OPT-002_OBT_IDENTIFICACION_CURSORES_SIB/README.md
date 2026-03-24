# OPT-002 - Reemplazar OBT_IDENTIFICACION_PERSONA con JOIN en cursores SIB

- **Paquete**: PR_PKG_REPRESTAMOS
- **Procedure**: Actualiza_Precalificacion
- **Cursores**: CUR_DE08_SIB, CUR_DE05_SIB
- **Tabla afectada**: PA.PA_DE08_SIB (nuevo indice)
- **Entorno**: QA
- **Fecha**: 2026-03-24
- **SQL Quest**: SQL 303 y relacionados
- **Cost**: 64,753 -> 39 (reduccion 99.9%)

## Problema
Los cursores CUR_DE08_SIB y CUR_DE05_SIB usaban `OBT_IDENTIFICACION_PERSONA(B.CODIGO_CLIENTE,'1')` en el WHERE.
Esto causaba:
1. Ejecucion de una funcion PL/SQL por cada fila (context switch SQL-to-PL/SQL)
2. Oracle no podia usar indices sobre ID_DEUDOR/cedula
3. TABLE ACCESS FULL en PA_DE08_SIB (328K filas, 8MB)

## Cambios realizados (2 partes)

### Parte 1: Cambio en el paquete (body.sql)
Reemplazar la llamada a funcion PL/SQL con un JOIN directo a PA.ID_PERSONAS.
Ver BEFORE.sql y AFTER.sql para el codigo exacto de ambos cursores.

### Parte 2: Indice covering en PA.PA_DE08_SIB
Crear indice compuesto que incluye todas las columnas que el query necesita:
```sql
CREATE INDEX PA.IDX_DE08_SIB_FECHA_DEUDOR ON PA.PA_DE08_SIB (FECHA_CORTE, ID_DEUDOR, CLASIFICACION);
```
Esto permite que Oracle lea todo del indice sin acceder a la tabla.

**NOTA**: En QA el indice fue creado bajo schema JOOGANDO.
Para produccion debe crearse bajo PA.

## Razonamiento
La funcion OBT_IDENTIFICACION_PERSONA con tipo_id='1' internamente hace:
`SELECT num_id FROM PA.ID_PERSONAS WHERE cod_persona = inCodPersona AND cod_tipo_id = '1'`
Un JOIN directo permite a Oracle usar PK_IDPERSONAS y evita context switches.
El covering index elimina el TABLE ACCESS a PA_DE08_SIB (de 328K accesos a tabla a 0).

## Resultados verificados (Explain Plan en Toad)

| Etapa                     | Cost     | Detalle                            |
|---------------------------|----------|------------------------------------|
| Original (con funcion)    | 64,753   | FTS PA_DE08_SIB + context switches |
| Con JOIN (sin covering)   | 4,141    | IDX SCAN + TABLE ACCESS BY ROWID   |
| Con JOIN + covering index | 39       | Solo INDEX SCANS, 0 table access   |

## Como revertir

### Rollback del paquete:
```sql
-- Compilar rollback.sql en Toad (restaura cursores originales)
```
O en git: `git revert 14f64ff`

### Rollback del indice:
```sql
DROP INDEX PA.IDX_DE08_SIB_FECHA_DEUDOR;
-- O en QA: DROP INDEX JOOGANDO.IDX_DE08_SIB_FECHA_DEUDOR;
```
