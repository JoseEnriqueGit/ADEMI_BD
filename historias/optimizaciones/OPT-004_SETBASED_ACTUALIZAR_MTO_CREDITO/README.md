# OPT-004 - Convertir loop row-by-row a UPDATE set-based

- **Paquete**: PR_PKG_REPRESTAMOS
- **Procedure**: Actualiza_Precalificacion
- **Seccion**: Loop Actualizar_Mto_Credito_Actual (lineas ~2704-2731 originales)
- **Entorno**: QA
- **Fecha**: 2026-03-24
- **Tipo**: Cambio estructural (eliminar cursor FOR loop)

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
