# OPT-001 -- SQL 227: Optimizacion WORLD_COMPLIANCE

- **Paquete**: PR.PR_PKG_REPRESTAMOS
- **Procedure**: PVALIDA_WORLD_COMPLIANCE
- **Cursor afectado**: CARGAR_WORLD_COMPLIANCE (lineas 3741-3749)
- **Entorno**: QA
- **Fecha**: 2026-03-18
- **SQL ID en Quest Optimizer**: SQL 227
- **Cost**: 18,293 -> 15 (reduccion del 99.9%)
- **Commit Git**: ac552c5

---

## Problema detectado

El SQL Optimizer de Quest clasifico el SQL 227 como "Problematic" con cost 18,293.
El Explain Plan mostro 2 TABLE ACCESS FULL en tablas grandes:

1. **PERSONAS_FISICAS**: Full scan de 1.2M filas (40MB) - cost 10,572
2. **PR_SOLICITUD_REPRESTAMO**: Full scan de 405 filas - cost 308

Ademas, el COMMIT dentro del loop generaba un redo log flush por cada fila procesada.

---

## Cambios realizados

### Cambio 1 -- JOIN a PERSONAS_FISICAS (linea 3744)

**Causa**: Conversion implicita de tipos. `COD_PER_FISICA` es VARCHAR2, `CODIGO_CLIENTE` es NUMBER.
Oracle aplicaba `TO_NUMBER()` sobre la columna indexada, invalidando el PK.

**Fix**: Convertir el valor NUMBER con `TO_CHAR()` en vez de dejar que Oracle convierta la columna.

```sql
-- ANTES:
LEFT JOIN PERSONAS_FISICAS PF ON PF.COD_PER_FISICA = R.CODIGO_CLIENTE

-- DESPUES:
LEFT JOIN PERSONAS_FISICAS PF ON PF.COD_PER_FISICA = TO_CHAR(R.CODIGO_CLIENTE)
```

**Resultado**: De TABLE ACCESS FULL (cost 10,572) a INDEX UNIQUE SCAN PK_PERSONASFISICAS (cost 2).

### Cambio 2 -- JOIN a PR_SOLICITUD_REPRESTAMO (linea 3745)

**Causa**: El PK es compuesto `(CODIGO_EMPRESA, ID_REPRESTAMO)`. El JOIN solo usaba `ID_REPRESTAMO`
(segunda columna), impidiendo que Oracle use el PK.

**Fix**: Agregar `CODIGO_EMPRESA` al JOIN para permitir INDEX UNIQUE SCAN.

```sql
-- ANTES:
LEFT JOIN PR_SOLICITUD_REPRESTAMO S ON S.ID_REPRESTAMO = R.ID_REPRESTAMO

-- DESPUES:
LEFT JOIN PR_SOLICITUD_REPRESTAMO S ON S.CODIGO_EMPRESA = R.CODIGO_EMPRESA AND S.ID_REPRESTAMO = R.ID_REPRESTAMO
```

**Resultado**: De TABLE ACCESS FULL (cost 308) a INDEX UNIQUE SCAN PK_SOLICITUD_REPRESTAMO (cost 1).

### Cambio 3 -- COMMIT fuera del loop (linea 3838 -> 3858)

**Causa**: Un COMMIT por fila genera un flush del redo log buffer al disco por cada registro.

**Fix**: Mover el COMMIT despues del END LOOP para hacer 1 flush por lote.

```sql
-- ANTES: COMMIT dentro del FOR A IN CARGAR_WORLD_COMPLIANCE LOOP
-- DESPUES: COMMIT despues del END LOOP del cursor
```

---

## Indices verificados en QA

| Tabla                      | Indice                       | Columnas                        | Usado ahora |
|----------------------------|------------------------------|---------------------------------|-------------|
| PERSONAS_FISICAS           | PK_PERSONASFISICAS           | COD_PER_FISICA                  | Si          |
| PR_SOLICITUD_REPRESTAMO    | PK_SOLICITUD_REPRESTAMO      | CODIGO_EMPRESA, ID_REPRESTAMO   | Si          |
| CLIENTES_B2000             | IDX_CLIENTE_2000             | CODIGO_CLIENTE                  | Ya se usaba |
| PR_REPRESTAMOS             | IND02_PR_REPRESTAMOS         | (INDEX SKIP SCAN)               | Ya se usaba |

---

## Como revertir

**Opcion 1 - Git:**
```bash
git revert ac552c5
```

**Opcion 2 - SQL directo en Toad:**
Compilar el archivo `rollback.sql` de esta carpeta en el schema PR de QA.

---

## Archivos en esta carpeta

- `README.md` -- Este documento
- `BEFORE.sql` -- Codigo original del cursor y loop
- `AFTER.sql` -- Codigo optimizado
- `rollback.sql` -- Script para revertir en Toad
- `evidencia/` -- Capturas de Explain Plan antes/despues (agregar manualmente)
