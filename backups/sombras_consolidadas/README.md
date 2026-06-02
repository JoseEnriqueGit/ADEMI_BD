# Sombras consolidadas

Archivos **históricos / no canónicos** que vivían dentro de `ENTORNOS_ORACLE/<ENTORNO>/schemas/`
y competían como "fuente de verdad" con el archivo canónico del objeto.

Se movieron aquí (con `git mv`, el historial se preserva) para cumplir la regla:

> Dentro de `ENTORNOS_ORACLE/<ENTORNO>/schemas/` debe existir **un solo archivo canónico por objeto**
> (para packages: `spec.sql` + `body.sql`). Nada de `_OLD`, `copy`, `_ORIGINAL`, `BACKUP`, `_v1`, `_TEST`.

**NO desplegar nada desde aquí.** Esto es archivo muerto de respaldo. Si necesitas una versión
anterior, usa `git log` / `git show` sobre el archivo canónico.

## Qué se movió (2026-06-02)

| Origen | Objeto | Por qué no era canónico |
|---|---|---|
| `ENTORNOS_ORACLE/DESARROLLO/.../PR/views/PR_V_ENVIO_REPRESTAMOS_OLD.sql` | `PR.PR_V_ENVIO_REPRESTAMOS` | Sufijo `_OLD`; el canónico es `.../views/PR_V_ENVIO_REPRESTAMOS.sql` |
| `ENTORNOS_ORACLE/QA/.../PR_PKG_REPRESTAMOS/body copy.sql` | `PR.PR_PKG_REPRESTAMOS` | Copia; canónico `body.sql` presente |
| `ENTORNOS_ORACLE/QA/.../PR_PKG_REPRESTAMOS/body_QA_ORIGINAL.sql` | `PR.PR_PKG_REPRESTAMOS` | Variante `_ORIGINAL`; canónico `body.sql` presente |
| `ENTORNOS_ORACLE/QA/.../PR_PKG_REPRESTAMOS/spec_QA_ORIGINAL.sql` | `PR.PR_PKG_REPRESTAMOS` | Variante `_ORIGINAL`; canónico `spec.sql` presente |
| `ENTORNOS_ORACLE/QA02/.../PKG_TIPO_DOCUMENTO_PKM/body BACKUP 30-04-2026.SQL` | `PA.PKG_TIPO_DOCUMENTO_PKM` | `BACKUP` fechado; canónico `body.sql` presente |
| `ENTORNOS_ORACLE/QA02/.../IA/Procedures/CHECK_ESTADO_REPORTE_TEST.sql` | `CHECK_ESTADO_REPORTE` | Variante `_TEST`; canónico `check_estado_reporte.sql` presente |
| `ENTORNOS_ORACLE/QA02/.../IA/Procedures/check_estado_reporte_v1.sql` | `CHECK_ESTADO_REPORTE` | Variante `_v1`; canónico `check_estado_reporte.sql` presente |

> Nota: el package suelto `ENTORNOS_ORACLE/Produccion/PKG_TIPO_DOCUMENTO_PKM.sql` **no** se archivó:
> es un objeto real de PROD y se **normalizó** a su ruta espejo
> `ENTORNOS_ORACLE/Produccion/schemas/PA/packages/PKG_TIPO_DOCUMENTO_PKM/body.sql`.
