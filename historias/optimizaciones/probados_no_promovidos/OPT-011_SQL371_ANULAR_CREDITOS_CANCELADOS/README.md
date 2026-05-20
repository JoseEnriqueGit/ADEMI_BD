# OPT-011 - SQL 371: Cursor CUR_Anular_creditos_cancelados

- **Paquete**: PR_PKG_REPRESTAMOS
- **Procedure**: P_Actualizar_Anular_Represtamo
- **Cursor**: CUR_Anular_creditos_cancelados (linea ~9391)
- **Entorno**: QA
- **Fecha**: 2026-04-07
- **SQL Quest**: SQL 371 (cost original 10,656)

## Lo que se hizo

Se creó un covering index en PR_REPRESTAMOS que permite a Oracle leer del indice en vez de hacer full table scan:

```sql
CREATE INDEX PR.IDX_REPRESTAMOS_EMP_EST_NOCRED
ON PR.PR_REPRESTAMOS (CODIGO_EMPRESA, ESTADO, NO_CREDITO, ID_REPRESTAMO)
TABLESPACE PR_DAT;
```

## Resultados

| Metrica | Original (PDF) | Despues (con indice) | Mejora |
|---------|---------------|---------------------|--------|
| Cost total | 10,656 | 9,748 | -8.5% |
| PR_REPRESTAMOS | FTS 887 | IDX 192 | -78.3% |

## Oportunidad adicional (pendiente de aprobacion)

Reemplazando las funciones TABLE con valores hardcodeados se podria bajar a cost **26** (-99.7%).
Ver `propuestas/SQL371_HARDCODEO_ESTADOS.md` para el analisis completo y scripts de prueba.

## Indices creados
- `PR.IDX_REPRESTAMOS_EMP_EST_NOCRED(CODIGO_EMPRESA, ESTADO, NO_CREDITO, ID_REPRESTAMO)`

## Como revertir
```sql
DROP INDEX PR.IDX_REPRESTAMOS_EMP_EST_NOCRED;
```
