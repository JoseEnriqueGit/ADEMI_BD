# Rollback

## Alcance

Rollback del body QA02 de `PR.PR_PKG_REPRESTAMOS` aplicado para que
`PR.JOB_CARGA_PRECALIFICA_RD` culmine completo en pruebas.

## Estrategia

Restaurar el body anterior de la ruta versionada:

```powershell
git show <commit_anterior>:ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql > body_rollback.sql
```

Luego ejecutar el contenido de `body_rollback.sql` en Toad contra QA02 y
compilar:

```sql
ALTER PACKAGE PR.PR_PKG_REPRESTAMOS COMPILE BODY;

SHOW ERRORS PACKAGE BODY PR.PR_PKG_REPRESTAMOS;
```

## Reversa manual minima

Si solo se desea revertir el bypass del `ORA-01407`, reemplazar las 7
ocurrencias:

```sql
SET     Y.DIAS_ATRASO   = NVL((SELECT MAX(D.DIAS_ATRASO)
...
), 0)
```

por el formato anterior:

```sql
SET     Y.DIAS_ATRASO   = (SELECT MAX(D.DIAS_ATRASO)
...
)
```

Advertencia: esa reversa puede reintroducir el error `ORA-01407` cuando
`MAX(D.DIAS_ATRASO)` no encuentre registros en `PA.PA_DETALLADO_DE08`.

