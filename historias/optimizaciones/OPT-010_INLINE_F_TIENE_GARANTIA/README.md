# OPT-010 - Inline F_TIENE_GARANTIA en cursores CREDITOS_PROCESAR

- **Paquete**: PR_PKG_REPRESTAMOS
- **Cursores**: CREDITOS_PROCESAR en Precalifica_Represtamo (L.125), Precalifica_Repre_Cancelado (L.480), Precalifica_Represtamo_fiadores (L.1240)
- **Entorno**: QA
- **Fecha**: 2026-03-19
- **SQL Quest**: SQL 399/400

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

## Como revertir
`git revert <commit>`
