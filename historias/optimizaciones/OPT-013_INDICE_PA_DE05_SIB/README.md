# OPT-013 - Indice covering en PA.PA_DE05_SIB para CUR_DE05_SIB

- **Paquete**: PR_PKG_REPRESTAMOS
- **Procedures afectados**: Actualiza_Preca_Dirigida, Actualiza_Preca_Campana_Especiale, Actualiza_Precalificacion
- **Cursor**: CUR_DE05_SIB (castigados a nivel interbancario)
- **Tabla afectada**: PA.PA_DE05_SIB (nuevo indice)
- **Entorno**: QA
- **Fecha**: 2026-04-07
- **Cost**: 120,122 → 11 (reduccion 99.99%)
- **Orquestador(es)**: Job1=P_Carga_Precalifica_Cancelado (paso 7 Actualiza_Precalificacion), Job3=P_Carga_Precalifica_Manual (Actualiza_Preca_Dirigida), Job4=P_Carga_Precalifica_Campana_Especial (Actualiza_Preca_Campana_Especiale)
- **Tipo**: Indice (IDX_DE05_SIB_CASTIGO_CEDULA)
- **Medido real**: ✅ (OPT-014 paso 7: 13.3→3.2s, -76%, LIO 742K→12K)

## Problema

El cursor CUR_DE05_SIB hace un HASH JOIN entre PA_DE05_SIB y PR_REPRESTAMOS.
La tabla PA_DE05_SIB no tenia ningun indice, causando:
1. TABLE ACCESS FULL sobre PA_DE05_SIB (1,435,279 filas, cost 60,083)
2. Segundo TABLE ACCESS FULL para el subquery MAX(FECHA_CASTIGO) (14,352,792 filas, cost 60,024)

Cost total: 120,122

## Solucion

Crear un indice covering que incluye todas las columnas que el query necesita:
```sql
CREATE INDEX PA.IDX_DE05_SIB_CASTIGO_CEDULA
ON PA.PA_DE05_SIB (FECHA_CASTIGO, CEDULA, ENTIDAD)
TABLESPACE PA_DAT;
```

No se requiere cambio de codigo en el paquete. Oracle usa el indice automaticamente.

**NOTA**: En QA el indice fue creado bajo schema JOOGANDO.
Para produccion debe crearse bajo PA.

## Razonamiento

El query original:
```sql
SELECT B.ROWID ID, b.id_represtamo, A.cedula, a.entidad, B.NO_CREDITO
FROM PA_DE05_SIB A,
        PR_REPRESTAMOS B
WHERE A.FECHA_CASTIGO = (SELECT MAX(FECHA_CASTIGO) FROM PA_DE05_SIB)
AND OBT_IDENTIFICACION_PERSONA(B.CODIGO_CLIENTE,'1') = A.cedula
AND B.ESTADO = 'RE'
AND PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO ( 'CASTIGOS_SIB' ) = 'S';
```

El indice (FECHA_CASTIGO, CEDULA, ENTIDAD) permite:
- INDEX FULL SCAN (MIN/MAX) para resolver MAX(FECHA_CASTIGO) sin tocar la tabla
- INDEX RANGE SCAN para filtrar por FECHA_CASTIGO y obtener CEDULA+ENTIDAD del indice

Se evaluo tambien reemplazar OBT_IDENTIFICACION_PERSONA con JOIN a ID_PERSONAS,
pero no aporto mejora (cost 120,124 vs 120,122). El cuello de botella era la falta de indice.

## Resultados verificados (Explain Plan en Toad)

| Version | Cost | Plan |
|---------|------|------|
| ANTES (sin indice) | 120,122 | TABLE ACCESS FULL x2 (1.4M + 14.3M filas) |
| DESPUES (con indice) | 11 | INDEX RANGE SCAN + INDEX FULL SCAN (MIN/MAX) |
| Con JOIN (sin indice) | 120,124 | TABLE ACCESS FULL (no mejoro) |

## Scripts para Explain Plan (ejecutar en Toad)

### CUR_DE05_SIB — ANTES y DESPUES (mismo query):
```sql
SELECT B.ROWID ID, b.id_represtamo, A.cedula, a.entidad, B.NO_CREDITO
FROM PA_DE05_SIB A,
        PR_REPRESTAMOS B
WHERE A.FECHA_CASTIGO = (SELECT MAX(FECHA_CASTIGO) FROM PA_DE05_SIB)
AND OBT_IDENTIFICACION_PERSONA(B.CODIGO_CLIENTE,'1') = A.cedula
AND B.ESTADO = 'RE'
AND PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO ( 'CASTIGOS_SIB' ) = 'S';
```

## Como revertir

### Rollback del indice:
```sql
DROP INDEX PA.IDX_DE05_SIB_CASTIGO_CEDULA;
-- O en QA: DROP INDEX JOOGANDO.IDX_DE05_SIB_CASTIGO_CEDULA;
```

No hay cambios en el paquete que revertir.
