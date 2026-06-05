# OPT-010 - Inline F_TIENE_GARANTIA en cursores CREDITOS_PROCESAR

- **Paquete**: PR_PKG_REPRESTAMOS
- **Cursores**: CREDITOS_PROCESAR en Precalifica_Represtamo (L.125), Precalifica_Repre_Cancelado (L.480), Precalifica_Represtamo_fiadores (L.1240)
- **Entorno**: QA
- **Fecha**: 2026-03-19
- **SQL Quest**: SQL 399/400
- **Orquestador(es)**: Job1=P_Carga_Precalifica_Cancelado (paso 2 Precalifica_Represtamo, paso 3 fiadores, paso 5 Precalifica_Repre_Cancelado)
- **Tipo**: Codigo (F_TIENE_GARANTIA → NOT EXISTS inline) + Indice (IDX_GARANTIAS_TIPO_SB)
- **Medido real**: Indice ✅ (OPT-014 pasos 2/3/5 mejoraron -65%/-72%/-41%) / Codigo ❌ no medido (rewrite no aplicado en DESA)

## Problema
La funcion `F_TIENE_GARANTIA(a.no_credito) = 0` se usaba en el WHERE de 3 cursores.
Oracle ejecutaba la funcion PL/SQL por cada fila candidata del cursor, causando:
1. Context switch SQL → PL/SQL → SQL por cada fila
2. Oracle no podia incorporar la logica al plan de ejecucion
3. No podia usar ANTI JOIN optimizado

La funcion internamente hace:
```sql
SELECT COUNT(1) FROM PR_CREDITOS A, PR_GARANTIAS_X_CREDITO B, PR_GARANTIAS C
WHERE A.codigo_empresa = 1 AND A.no_credito = pNoCredito
AND A.estado IN ('D','V','M','E','J')
AND B.codigo_empresa = A.codigo_empresa AND B.no_credito = A.no_credito
AND C.codigo_empresa = B.codigo_empresa AND C.numero_garantia = B.numero_garantia
AND C.codigo_tipo_garantia_sb != 'NA'
```

## Cambio realizado
Reemplazar `F_TIENE_GARANTIA(a.no_credito) = 0` con NOT EXISTS inline:
```sql
AND NOT EXISTS (SELECT 1
                  FROM PR_CREDITOS cr
                  JOIN PR_GARANTIAS_X_CREDITO gx ON ...
                  JOIN PR_GARANTIAS g ON ...
                 WHERE cr.CODIGO_EMPRESA = f_obt_Empresa_Represtamo
                   AND cr.NO_CREDITO = a.NO_CREDITO
                   AND cr.ESTADO IN ('D','V','M','E','J')
                   AND g.CODIGO_TIPO_GARANTIA_SB != 'NA')
```

Aplicado en 3 cursores (lineas 125, 480, 1240).

## Razonamiento
- NOT EXISTS permite a Oracle usar ANTI JOIN (hash o nested loops), mucho mas eficiente
- Elimina el context switch PL/SQL por fila
- Oracle puede optimizar el subquery como parte del plan completo del cursor
- Semanticamente equivalente: COUNT(1) = 0 es lo mismo que NOT EXISTS

## Indice creado
```sql
CREATE INDEX PR.IDX_GARANTIAS_TIPO_SB
ON PR.PR_GARANTIAS (CODIGO_EMPRESA, NUMERO_GARANTIA, CODIGO_TIPO_GARANTIA_SB)
TABLESPACE PR_DAT;
```

## Resultados verificados (Explain Plan en Toad)

| Metrica | ANTES (con funcion) | DESPUES (NOT EXISTS) |
|---------|--------------------|--------------------|
| Cost visible | 271 | 473 |
| Costo oculto funcion | 6 x 1,476 = 8,856 | 0 |
| **Costo real total** | **9,127** | **473** |
| Mejora real | | -94.8% |

**Nota**: El ANTES muestra cost 271 pero NO incluye el costo de la funcion PL/SQL que se ejecuta por cada fila. El DESPUES muestra todo el costo real.

## Scripts para Explain Plan (ejecutar en Toad)

### ANTES (con funcion PL/SQL):
```sql
SELECT a.no_credito, a.codigo_cliente
FROM PR_CREDITOS a
WHERE a.codigo_empresa = 1
  AND a.estado IN ('D','V','M','E','J')
  AND PR.PR_PKG_REPRESTAMOS.F_TIENE_GARANTIA(a.no_credito) = 0
  AND ROWNUM <= 100;
```

### DESPUES (con NOT EXISTS inline):
```sql
SELECT a.no_credito, a.codigo_cliente
FROM PR_CREDITOS a
WHERE a.codigo_empresa = 1
  AND a.estado IN ('D','V','M','E','J')
  AND NOT EXISTS (
      SELECT 1
      FROM PR_GARANTIAS_X_CREDITO B
      JOIN PR_GARANTIAS C ON C.codigo_empresa = B.codigo_empresa
                          AND C.numero_garantia = B.numero_garantia
      WHERE B.codigo_empresa = a.codigo_empresa
        AND B.no_credito = a.no_credito
        AND C.codigo_tipo_garantia_sb != 'NA'
  )
  AND ROWNUM <= 100;
```

### Costo de 1 ejecucion de la funcion (para calcular costo real del ANTES):
```sql
SELECT COUNT(1)
FROM PR_CREDITOS A,
     PR_GARANTIAS_X_CREDITO B,
     PR_GARANTIAS C
WHERE A.codigo_empresa = 1
  AND A.no_credito = 12345
  AND A.estado IN ('D','V','M','E','J')
  AND B.codigo_empresa = A.codigo_empresa
  AND B.no_credito = A.no_credito
  AND C.codigo_empresa = B.codigo_empresa
  AND C.numero_garantia = B.numero_garantia
  AND C.codigo_tipo_garantia_sb != 'NA';
```

## Como revertir

### Rollback del paquete:
```sql
-- Reemplazar los 3 NOT EXISTS con: AND PR.PR_PKG_REPRESTAMOS.F_TIENE_GARANTIA(a.no_credito) = 0
```
O en git: `git revert <commit>`

### Rollback del indice:
```sql
DROP INDEX PR.IDX_GARANTIAS_TIPO_SB;
```
