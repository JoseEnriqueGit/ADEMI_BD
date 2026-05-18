# OPT-020 - Resultados QA02

## 2026-05-18 - Creacion de vistas y equivalencia

El usuario ejecuto `01_CREATE_VIEWS.sql` y `02_VALIDAR_EQUIVALENCIA.sql` en QA02.

### Creacion de vistas

- Q00 retorno 12 columnas requeridas.
- `PR.V_REPRE_CREDITOS_GAR` creada y en estado `VALID`.
- `PR.V_REPRE_CREDITOS_HI_GAR` creada y en estado `VALID`.

### Equivalencia funcional

`02_VALIDAR_EQUIVALENCIA.sql` retorno:

| Consulta | Resultado |
|----------|-----------|
| Q01 - `F_TIENE_GARANTIA` vs `V_REPRE_CREDITOS_GAR` | 0 diferencias |
| Q02 - `F_TIENE_GARANTIA_HISTORICO` vs `V_REPRE_CREDITOS_HI_GAR` | 0 diferencias |
| Q03 - funcion actual `> 0` vs vista actual `EXISTS` | 12,293 vs 12,293 |
| Q04 - funcion historica `> 0` vs vista historica `EXISTS` | 0 vs 0 |

### Accion posterior

Con la equivalencia validada, se actualizo el body local de QA02 para migrar
solo los dos cursores masivos de cancelados:

- `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql`
- Lineas 478-485: reemplazo de `F_TIENE_GARANTIA(a.no_credito) = 0` por `NOT EXISTS` contra `PR.V_REPRE_CREDITOS_GAR`.
- Lineas 866-873: reemplazo de `F_TIENE_GARANTIA_HISTORICO(a.no_credito) = 0` por `NOT EXISTS` contra `PR.V_REPRE_CREDITOS_HI_GAR`.

No se modifico `spec.sql`.

Nota de control local: el archivo `body.sql` ya tenia cambios no relacionados
en el worktree antes de OPT-020. Para revisar exclusivamente esta OPT, usar las
lineas indicadas arriba o `03_PATCH_PAQUETE_SNIPPETS.sql`.
