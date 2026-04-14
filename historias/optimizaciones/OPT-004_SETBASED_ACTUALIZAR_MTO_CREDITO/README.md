# OPT-004 - Convertir loop row-by-row a UPDATE set-based

- **Paquete**: PR_PKG_REPRESTAMOS
- **Procedure**: Actualiza_Precalificacion
- **Seccion**: Loop Actualizar_Mto_Credito_Actual (lineas ~2704-2731 originales)
- **Entorno**: QA
- **Fecha**: 2026-03-24
- **Tipo**: Codigo (eliminar cursor FOR loop → set-based UPDATE) + Indice (IDX_DE08_NOCRED_CALIF_FECHA)
- **Orquestador(es)**: Job1=P_Carga_Precalifica_Cancelado (paso 7 Actualiza_Precalificacion)
- **Medido real**: No (OPT-014 midio solo impacto de indices; el rewrite set-based no se valido en tiempo real)

## Problema
El cursor `Actualizar_Mto_Credito_Actual` seleccionaba todos los PR_REPRESTAMOS con ESTADO='RE'
y luego en un FOR loop ejecutaba 2 UPDATEs por cada fila:
1. UPDATE MTO_CREDITO_ACTUAL con subquery correlacionada a PA_DETALLADO_DE08 (monto_desembolsado)
2. UPDATE ESTADO='RSB' si CALIFICA_CLIENTE no cumple con la clasificacion SIB

Con N registros: N iteraciones x 2 UPDATEs = 2N sentencias SQL + N context switches PL/SQL-to-SQL.

## Cambio realizado
Reemplazar el FOR loop completo con 2 sentencias UPDATE directas (set-based):

### UPDATE 1: Actualizar monto credito actual
Actualiza MTO_CREDITO_ACTUAL para todos los represtamos en estado 'RE' de una sola vez,
usando subquery correlacionada para obtener el monto_desembolsado de la ultima fecha de corte.

### UPDATE 2: Marcar como RSB
Cambia ESTADO a 'RSB' para los que no cumplen clasificacion SIB,
usando EXISTS en vez del subquery escalar del cursor original.

Ver BEFORE.sql y AFTER.sql para el codigo exacto.

## Razonamiento
- ANTES: N iteraciones x 2 UPDATEs = 2N sentencias SQL + N context switches
- DESPUES: 2 sentencias SQL, 0 context switches, 1 COMMIT
- Oracle optimiza el UPDATE set-based internamente con batch processing
- El cursor Actualizar_Mto_Credito_Actual ya no se usa (codigo muerto eliminado)

## Indice creado para UPDATE 2
```sql
CREATE INDEX PA.IDX_DE08_NOCRED_CALIF_FECHA
ON PA.PA_DETALLADO_DE08 (NO_CREDITO, FECHA_CORTE, CALIFICA_CLIENTE)
TABLESPACE PA_DAT;
```
Covering index que permite a Oracle resolver el EXISTS sin acceder a la tabla.

## Resultados verificados (Explain Plan en Toad)

### UPDATE 1 (MTO_CREDITO_ACTUAL)
| Metrica | ANTES (por fila) | DESPUES (set-based) |
|---------|-----------------|---------------------|
| Cost    | 352             | 10                  |
| Ejecuciones | N          | 1                   |
| Cost total (200 filas) | 70,400 | 10        |

### UPDATE 2 (ESTADO='RSB')
| Metrica | ANTES (por fila) | DESPUES sin idx | DESPUES con idx |
|---------|-----------------|-----------------|-----------------|
| Cost    | 44              | 12,149          | 71              |
| Ejecuciones | N          | 1               | 1               |
| Cost total (200 filas) | 8,800 | 12,149  | 71              |

## Scripts para Explain Plan (ejecutar en Toad)

### UPDATE 1 — ANTES (por fila, como hacia el loop):
```sql
UPDATE PR.PR_REPRESTAMOS R SET R.MTO_CREDITO_ACTUAL = (SELECT monto_desembolsado
                                  FROM PA.PA_DETALLADO_DE08 D
                                 WHERE D.FUENTE         = 'PR'
                                   AND D.NO_CREDITO     = 12345
                                   AND D.CODIGO_CLIENTE  = 67890
                                   AND D.FECHA_CORTE    = (SELECT MAX(P.FECHA_CORTE)
                                                             FROM PA_DETALLADO_DE08 P
                                                            WHERE P.FUENTE       = 'PR'
                                                              AND P.NO_CREDITO   = 12345
                                                              AND P.CODIGO_CLIENTE = 67890))
WHERE R.CODIGO_EMPRESA = 1
  AND R.CODIGO_CLIENTE = 67890
  AND R.NO_CREDITO     = 12345
  AND R.ESTADO         = 'RE';
```

### UPDATE 1 — DESPUES (set-based):
```sql
UPDATE PR.PR_REPRESTAMOS R
SET R.MTO_CREDITO_ACTUAL = (SELECT D.monto_desembolsado
                              FROM PA.PA_DETALLADO_DE08 D
                             WHERE D.FUENTE         = 'PR'
                               AND D.NO_CREDITO     = R.NO_CREDITO
                               AND D.CODIGO_CLIENTE = R.CODIGO_CLIENTE
                               AND D.FECHA_CORTE    = (SELECT MAX(P.FECHA_CORTE)
                                                         FROM PA_DETALLADO_DE08 P
                                                        WHERE P.FUENTE         = 'PR'
                                                          AND P.NO_CREDITO     = R.NO_CREDITO
                                                          AND P.CODIGO_CLIENTE = R.CODIGO_CLIENTE))
WHERE R.CODIGO_EMPRESA = 1
  AND R.ESTADO = 'RE';
```

### UPDATE 2 — ANTES (por fila, como hacia el loop):
```sql
UPDATE PR_REPRESTAMOS SET ESTADO = 'RSB'
WHERE NO_CREDITO = (SELECT NO_CREDITO
                      FROM PA_DETALLADO_DE08
                     WHERE NO_CREDITO = 12345
                       AND CALIFICA_CLIENTE NOT IN (SELECT COLUMN_VALUE
                                                      FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('CLASIFICACION_SIB')))
                       AND fecha_corte = (SELECT MAX(FECHA_CORTE) FROM PA_DETALLADO_DE08 WHERE FUENTE = 'PR'));
```

### UPDATE 2 — DESPUES (set-based con EXISTS):
```sql
UPDATE PR_REPRESTAMOS R
SET R.ESTADO = 'RSB'
WHERE R.ESTADO = 'RE'
  AND EXISTS (SELECT 1
                FROM PA_DETALLADO_DE08 D
               WHERE D.NO_CREDITO = R.NO_CREDITO
                 AND D.CALIFICA_CLIENTE NOT IN (SELECT COLUMN_VALUE
                                                  FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('CLASIFICACION_SIB')))
                 AND D.FECHA_CORTE = (SELECT MAX(FECHA_CORTE) FROM PA_DETALLADO_DE08 WHERE FUENTE = 'PR'));
```

---

## Como verificar
```sql
SELECT COUNT(*) FROM PR_REPRESTAMOS WHERE ESTADO = 'RE';
-- Ejecutar el procedure
SELECT COUNT(*) FROM PR_REPRESTAMOS WHERE ESTADO IN ('RE','RSB');
```

## Como revertir

### Rollback del paquete:
Compilar rollback.sql en Toad o: `git revert <commit>`

### Rollback del indice:
```sql
DROP INDEX PA.IDX_DE08_NOCRED_CALIF_FECHA;
```
